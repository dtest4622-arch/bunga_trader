import asyncio
import re
from typing import Dict, Any, Optional, List
from telethon import TelegramClient, events
from telethon.tl.types import Channel
from app.core.config import settings
from app.services.groq_ai import ai_risk_manager


class TelegramSignalListener:
    """Listen to Telegram channels for trading signals."""
    
    def __init__(self):
        self.client: Optional[TelegramClient] = None
        self.is_running = False
        self.signal_handlers = []
        self.monitored_groups = set()
    
    async def start(self):
        """Start the Telegram listener."""
        if self.is_running:
            return
        
        if not settings.TELEGRAM_API_ID or not settings.TELEGRAM_API_HASH:
            print("Telegram credentials not configured")
            return
        
        self.client = TelegramClient(
            settings.TELEGRAM_SESSION_NAME,
            settings.TELEGRAM_API_ID,
            settings.TELEGRAM_API_HASH
        )
        
        await self.client.start()
        
        # Set up message handler
        self.client.on(events.NewMessage)(self._handle_message)
        
        # Load monitored groups
        await self._load_monitored_groups()
        
        self.is_running = True
        print("Telegram listener started")
    
    async def stop(self):
        """Stop the Telegram listener."""
        if self.client and self.is_running:
            await self.client.disconnect()
            self.is_running = False
            print("Telegram listener stopped")
    
    async def _load_monitored_groups(self):
        """Load groups to monitor from settings."""
        for group_id in settings.TELEGRAM_SIGNAL_GROUPS:
            try:
                entity = await self.client.get_entity(int(group_id))
                if isinstance(entity, Channel):
                    self.monitored_groups.add(int(group_id))
                    print(f"Monitoring group: {entity.title}")
            except Exception as e:
                print(f"Failed to load group {group_id}: {e}")
    
    async def _handle_message(self, event):
        """Handle incoming messages."""
        try:
            # Check if message is from monitored group
            if event.chat_id not in self.monitored_groups:
                return
            
            message_text = event.message.message
            if not message_text:
                return
            
            # Parse signal from message
            signal_data = self._parse_signal(message_text)
            
            if signal_data:
                signal_data['group_id'] = str(event.chat_id)
                signal_data['group_name'] = event.chat.title if event.chat else "Unknown"
                signal_data['message_id'] = str(event.message.id)
                signal_data['raw_message'] = message_text
                
                # Notify handlers
                for handler in self.signal_handlers:
                    try:
                        await handler(signal_data)
                    except Exception as e:
                        print(f"Signal handler error: {e}")
                        
        except Exception as e:
            print(f"Message handling error: {e}")
    
    def _parse_signal(self, text: str) -> Optional[Dict[str, Any]]:
        """Parse trading signal from message text."""
        text = text.upper().strip()
        
        # Check for signal keywords
        if not any(word in text for word in ['BUY', 'SELL', 'LONG', 'SHORT']):
            return None
        
        signal = {
            'pair': self._extract_pair(text),
            'direction': self._extract_direction(text),
            'entry_price': self._extract_price(text, ['ENTRY', 'ENTER', 'AT', '@']),
            'stop_loss': self._extract_price(text, ['SL', 'STOP LOSS', 'STOP-LOSS']),
            'take_profit': self._extract_price(text, ['TP', 'TAKE PROFIT', 'TAKE-PROFIT', 'TARGET']),
            'take_profit_2': self._extract_price(text, ['TP2', 'TP 2', 'TARGET 2']),
            'take_profit_3': self._extract_price(text, ['TP3', 'TP 3', 'TARGET 3']),
            'time_frame': self._extract_timeframe(text),
        }
        
        # Remove None values
        signal = {k: v for k, v in signal.items() if v is not None}
        
        # Must have at least pair and direction
        if not signal.get('pair') or not signal.get('direction'):
            return None
        
        return signal
    
    def _extract_pair(self, text: str) -> Optional[str]:
        """Extract currency pair from text."""
        # Common patterns
        patterns = [
            r'\b([A-Z]{6})\b',  # EURUSD
            r'\b([A-Z]{3}/[A-Z]{3})\b',  # EUR/USD
            r'\b(XAUUSD|XAGUSD)\b',  # Gold/Silver
            r'\b(GOLD|SILVER)\b',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, text)
            if match:
                pair = match.group(1).replace('/', '')
                return pair
        
        return None
    
    def _extract_direction(self, text: str) -> Optional[str]:
        """Extract trade direction from text."""
        if 'BUY' in text or 'LONG' in text:
            return 'BUY'
        elif 'SELL' in text or 'SHORT' in text:
            return 'SELL'
        return None
    
    def _extract_price(self, text: str, keywords: List[str]) -> Optional[float]:
        """Extract price value after keywords."""
        for keyword in keywords:
            # Pattern: keyword followed by number
            pattern = rf'{keyword}[\s:]*([0-9]+\.?[0-9]*)'
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                try:
                    return float(match.group(1))
                except ValueError:
                    continue
        
        return None
    
    def _extract_timeframe(self, text: str) -> Optional[str]:
        """Extract timeframe from text."""
        patterns = [
            r'\b(M1|M5|M15|M30|H1|H4|D1|W1|MN)\b',
            r'\b(1M|5M|15M|30M|1H|4H|1D|1W)\b',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                return match.group(1).upper()
        
        return None
    
    def add_handler(self, handler):
        """Add a signal handler callback."""
        self.signal_handlers.append(handler)
    
    def remove_handler(self, handler):
        """Remove a signal handler callback."""
        if handler in self.signal_handlers:
            self.signal_handlers.remove(handler)
    
    async def add_group(self, group_id: int):
        """Add a group to monitor."""
        try:
            entity = await self.client.get_entity(group_id)
            if isinstance(entity, Channel):
                self.monitored_groups.add(group_id)
                return True
        except Exception as e:
            print(f"Failed to add group {group_id}: {e}")
        return False
    
    async def remove_group(self, group_id: int):
        """Remove a group from monitoring."""
        if group_id in self.monitored_groups:
            self.monitored_groups.remove(group_id)
            return True
        return False
    
    async def get_monitored_groups(self) -> List[Dict[str, Any]]:
        """Get list of monitored groups."""
        groups = []
        for group_id in self.monitored_groups:
            try:
                entity = await self.client.get_entity(group_id)
                groups.append({
                    'id': group_id,
                    'title': entity.title,
                    'username': entity.username,
                })
            except:
                pass
        return groups


# Global instance
telegram_listener = TelegramSignalListener()
