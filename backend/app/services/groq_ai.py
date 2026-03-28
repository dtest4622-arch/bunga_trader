import json
import asyncio
from decimal import Decimal, ROUND_DOWN
from typing import Dict, Optional, Any
import groq
from app.core.config import settings


class AIRiskManager:
    """AI-powered risk management using Groq API."""
    
    def __init__(self):
        self.client = groq.Groq(api_key=settings.GROQ_API_KEY)
        self.model = settings.GROQ_MODEL
        self.hard_limits = {
            'max_risk_percent': settings.MAX_RISK_PERCENT,
            'min_lot_size': 0.0001,
            'max_daily_loss': settings.MAX_DAILY_LOSS_PERCENT,
            'min_rr_ratio': settings.MIN_RR_RATIO,
        }
    
    async def calculate_position(
        self, 
        signal: Dict[str, Any], 
        account_balance: float,
        compounding_state: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """
        Calculate optimal trade parameters using AI.
        
        Args:
            signal: Signal data with pair, direction, entry, sl, tp
            account_balance: Current account balance
            compounding_state: Optional compounding state data
        
        Returns:
            Dictionary with calculated trade parameters
        """
        if compounding_state is None:
            compounding_state = {
                'daily_target_percent': 5.0,
                'current_streak': 0,
                'trades_today': 0,
                'daily_pnl': 0.0,
            }
        
        prompt = self._build_prompt(signal, account_balance, compounding_state)
        
        try:
            response = await asyncio.to_thread(
                self.client.chat.completions.create,
                model=self.model,
                messages=[
                    {
                        "role": "system", 
                        "content": "You are a professional forex risk manager. Return only valid JSON."
                    },
                    {"role": "user", "content": prompt}
                ],
                response_format={"type": "json_object"},
                max_tokens=500,
                temperature=0.1,
            )
            
            ai_result = json.loads(response.choices[0].message.content)
            return self._apply_safety_limits(ai_result, account_balance, compounding_state)
            
        except Exception as e:
            print(f"AI calculation error: {e}")
            return self._fallback_calculation(signal, account_balance, compounding_state)
    
    def _build_prompt(
        self, 
        signal: Dict[str, Any], 
        account_balance: float,
        compounding_state: Dict
    ) -> str:
        """Build the prompt for AI risk calculation."""
        return f"""
You are a professional forex risk manager. Calculate optimal trade parameters.

ACCOUNT STATE:
- Balance: ${account_balance:.2f} USD
- Daily Target: {compounding_state['daily_target_percent']}%
- Current Win/Loss Streak: {compounding_state['current_streak']}
- Trades Today: {compounding_state['trades_today']}
- Daily P&L So Far: ${compounding_state['daily_pnl']:.2f}

SIGNAL DETAILS:
- Pair: {signal['pair']}
- Direction: {signal['direction']}
- Suggested Entry: {signal.get('entry_price', 'Market')}
- Suggested SL: {signal.get('stop_loss', 'None')} pips
- Suggested TP: {signal.get('take_profit', 'None')} pips
- Source Quality Score: {signal.get('quality_score', 50)}/100

Calculate and return ONLY this JSON:
{{
    "lot_size": "0.001",
    "sl_pips": 45,
    "tp_pips": 90,
    "risk_percent": 1.5,
    "rr_ratio": 2.0,
    "confidence": 85,
    "reasoning": "Brief explanation",
    "warning": null
}}

RULES:
- Risk 1-2% max per trade
- Minimum 1:1.5 R:R ratio
- If streak <= -2, reduce size by 25%
- If daily loss > 3%, suggest pause
- For $10-100 accounts, use micro lots (0.01 or less)
- For $100-1000 accounts, use mini lots (0.01-0.1)
- For $1000+ accounts, use standard lots (0.1+)
"""
    
    def _apply_safety_limits(
        self, 
        ai_result: Dict[str, Any], 
        balance: float, 
        compounding: Dict
    ) -> Dict[str, Any]:
        """Apply hard safety limits to AI results."""
        # Cap risk percentage
        risk_pct = min(
            float(ai_result.get('risk_percent', 1.0)), 
            self.hard_limits['max_risk_percent']
        )
        max_risk_amount = balance * (risk_pct / 100)
        
        # Adjust lot size for small accounts
        suggested_lot = float(ai_result.get('lot_size', 0.01))
        
        if balance < 100:
            max_lot = 0.01
            if suggested_lot > max_lot:
                ai_result['lot_size'] = str(max_lot)
                ai_result['safety_override'] = f"Reduced lot size from {suggested_lot} to {max_lot}"
        elif balance < 1000:
            max_lot = 0.1
            if suggested_lot > max_lot:
                ai_result['lot_size'] = str(max_lot)
                ai_result['safety_override'] = f"Reduced lot size from {suggested_lot} to {max_lot}"
        
        # Check R:R ratio
        rr_ratio = float(ai_result.get('rr_ratio', 1.0))
        if rr_ratio < self.hard_limits['min_rr_ratio']:
            ai_result['warning'] = f"R:R below {self.hard_limits['min_rr_ratio']}:1 minimum"
            ai_result['confidence'] = min(int(ai_result.get('confidence', 50)), 50)
        
        # Check daily loss limit
        daily_loss_pct = abs(min(compounding.get('daily_pnl', 0), 0)) / balance * 100
        if daily_loss_pct > self.hard_limits['max_daily_loss']:
            ai_result['warning'] = "Daily loss limit exceeded - trading paused"
            ai_result['confidence'] = 0
            ai_result['should_trade'] = False
        
        # Apply streak adjustment
        if compounding.get('current_streak', 0) <= -2:
            current_lot = float(ai_result.get('lot_size', 0.01))
            ai_result['lot_size'] = str(current_lot * 0.75)
            ai_result['streak_adjustment'] = "Reduced 25% due to losing streak"
        
        ai_result['risk_percent'] = risk_pct
        ai_result['max_risk_usd'] = max_risk_amount
        ai_result['should_trade'] = ai_result.get('should_trade', True)
        
        return ai_result
    
    def _fallback_calculation(
        self, 
        signal: Dict[str, Any], 
        balance: float, 
        compounding: Dict
    ) -> Dict[str, Any]:
        """Fallback calculation when AI fails."""
        risk_amount = balance * 0.01
        
        # Determine lot size based on balance
        if balance < 100:
            lot_size = 0.01
        elif balance < 1000:
            lot_size = 0.02
        else:
            lot_size = 0.05
        
        return {
            'lot_size': str(lot_size),
            'sl_pips': 30,
            'tp_pips': 60,
            'risk_percent': 1.0,
            'rr_ratio': 2.0,
            'confidence': 50,
            'reasoning': 'Fallback calculation due to AI error',
            'warning': 'Using conservative defaults',
            'max_risk_usd': risk_amount,
            'should_trade': True,
        }
    
    async def analyze_signal_quality(self, signal_text: str) -> Dict[str, Any]:
        """Analyze the quality of a signal from text."""
        prompt = f"""
Analyze this trading signal and return a quality score:

Signal: {signal_text}

Return JSON:
{{
    "quality_score": 75,
    "has_entry": true,
    "has_stop_loss": true,
    "has_take_profit": true,
    "clarity": "high",
    "issues": []
}}
"""
        
        try:
            response = await asyncio.to_thread(
                self.client.chat.completions.create,
                model=self.model,
                messages=[
                    {"role": "system", "content": "You analyze forex signal quality."},
                    {"role": "user", "content": prompt}
                ],
                response_format={"type": "json_object"},
                max_tokens=300,
                temperature=0.1,
            )
            
            return json.loads(response.choices[0].message.content)
        except Exception as e:
            return {
                "quality_score": 50,
                "has_entry": True,
                "has_stop_loss": True,
                "has_take_profit": True,
                "clarity": "medium",
                "issues": ["Analysis failed"]
            }


# Global instance
ai_risk_manager = AIRiskManager()
