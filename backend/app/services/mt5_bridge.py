import zmq
import json
import asyncio
from typing import Dict, Optional, List, Any
from datetime import datetime
from app.core.config import settings


class MT5Bridge:
    """Bridge to MetaTrader 5 via ZeroMQ."""
    
    def __init__(self):
        self.context = zmq.Context()
        self.socket = self.context.socket(zmq.REQ)
        self.socket.setsockopt(zmq.RCVTIMEO, settings.MT5_TIMEOUT)
        self.socket.setsockopt(zmq.LINGER, 0)
        self._connected = False
        self._lock = asyncio.Lock()
    
    async def connect(self, host: str = None, port: int = None):
        """Connect to MT5 EA."""
        host = host or settings.MT5_HOST
        port = port or settings.MT5_PORT
        
        try:
            self.socket.connect(f"tcp://{host}:{port}")
            self._connected = True
            return True
        except Exception as e:
            print(f"MT5 connection error: {e}")
            return False
    
    async def disconnect(self):
        """Disconnect from MT5 EA."""
        if self._connected:
            self.socket.disconnect(f"tcp://{settings.MT5_HOST}:{settings.MT5_PORT}")
            self._connected = False
    
    async def _send_command(self, message: Dict[str, Any]) -> Dict[str, Any]:
        """Send command to MT5 and get response."""
        async with self._lock:
            try:
                if not self._connected:
                    await self.connect()
                
                self.socket.send_string(json.dumps(message))
                
                try:
                    response = self.socket.recv_string()
                    return json.loads(response)
                except zmq.Again:
                    return {"error": "MT5 timeout", "success": False}
                    
            except Exception as e:
                return {"error": str(e), "success": False}
    
    async def execute_trade(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute a trade on MT5.
        
        Args:
            params: Trade parameters
                - pair: Symbol (e.g., "EURUSD")
                - direction: "BUY" or "SELL"
                - lot_size: Volume
                - stop_loss: SL price
                - take_profit: TP price
                - comment: Optional comment
        
        Returns:
            Response from MT5
        """
        message = {
            "action": "EXECUTE",
            "symbol": params['pair'],
            "type": "ORDER_TYPE_BUY" if params['direction'] == 'BUY' else "ORDER_TYPE_SELL",
            "volume": float(params['lot_size']),
            "price": 0,  # Market order
            "sl": float(params['stop_loss']),
            "tp": float(params['take_profit']),
            "deviation": 10,
            "magic": settings.MT5_MAGIC_NUMBER,
            "comment": params.get('comment', f"Bunga_{params.get('signal_id', 'manual')[:8]}"),
            "type_filling": "ORDER_FILLING_IOC"
        }
        
        return await self._send_command(message)
    
    async def close_position(
        self, 
        ticket: int, 
        partial_percent: Optional[float] = None
    ) -> Dict[str, Any]:
        """
        Close a position.
        
        Args:
            ticket: Position ticket
            partial_percent: Percentage to close (100 = full close)
        
        Returns:
            Response from MT5
        """
        message = {
            "action": "CLOSE",
            "ticket": ticket,
            "partial_percent": partial_percent or 100.0
        }
        
        return await self._send_command(message)
    
    async def modify_position(
        self, 
        ticket: int, 
        sl: Optional[float] = None, 
        tp: Optional[float] = None
    ) -> Dict[str, Any]:
        """
        Modify position SL/TP.
        
        Args:
            ticket: Position ticket
            sl: New stop loss price
            tp: New take profit price
        
        Returns:
            Response from MT5
        """
        message = {
            "action": "MODIFY",
            "ticket": ticket
        }
        
        if sl is not None:
            message["sl"] = sl
        if tp is not None:
            message["tp"] = tp
        
        return await self._send_command(message)
    
    async def get_account_info(self) -> Dict[str, Any]:
        """Get account information from MT5."""
        return await self._send_command({"action": "ACCOUNT_INFO"})
    
    async def get_positions(self) -> List[Dict[str, Any]]:
        """Get all open positions."""
        response = await self._send_command({"action": "GET_POSITIONS"})
        return response.get('positions', [])
    
    async def get_position(self, ticket: int) -> Optional[Dict[str, Any]]:
        """Get specific position by ticket."""
        positions = await self.get_positions()
        for pos in positions:
            if pos.get('ticket') == ticket:
                return pos
        return None
    
    async def close_all_positions(self, symbol: Optional[str] = None) -> Dict[str, Any]:
        """
        Close all positions.
        
        Args:
            symbol: Optional symbol to filter by
        
        Returns:
            Summary of closed positions
        """
        positions = await self.get_positions()
        
        closed = []
        failed = []
        
        for pos in positions:
            if symbol and pos.get('symbol') != symbol:
                continue
            
            result = await self.close_position(pos['ticket'])
            if result.get('success'):
                closed.append(pos['ticket'])
            else:
                failed.append({'ticket': pos['ticket'], 'error': result.get('error')})
        
        return {
            'success': len(failed) == 0,
            'closed_count': len(closed),
            'failed_count': len(failed),
            'closed': closed,
            'failed': failed
        }
    
    async def get_symbol_info(self, symbol: str) -> Dict[str, Any]:
        """Get symbol information."""
        return await self._send_command({
            "action": "SYMBOL_INFO",
            "symbol": symbol
        })
    
    async def get_market_price(self, symbol: str) -> Dict[str, Any]:
        """Get current market price for a symbol."""
        return await self._send_command({
            "action": "MARKET_PRICE",
            "symbol": symbol
        })
    
    def __del__(self):
        """Cleanup on destruction."""
        try:
            self.socket.close()
            self.context.term()
        except:
            pass


# Global instance
mt5_bridge = MT5Bridge()
