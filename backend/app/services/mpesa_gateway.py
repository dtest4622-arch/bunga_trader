import base64
import requests
import json
from datetime import datetime
from typing import Dict, Optional, Any
from app.core.config import settings


class MpesaGateway:
    """M-Pesa Daraja API integration."""
    
    def __init__(self):
        self.base_url = (
            "https://sandbox.safaricom.co.ke"
            if settings.MPESA_ENV == "sandbox"
            else "https://api.safaricom.co.ke"
        )
        self.consumer_key = settings.MPESA_CONSUMER_KEY
        self.consumer_secret = settings.MPESA_CONSUMER_SECRET
        self.passkey = settings.MPESA_PASSKEY
        self.shortcode = settings.MPESA_SHORTCODE
        self.callback_url = settings.MPESA_CALLBACK_URL
    
    def _get_access_token(self) -> str:
        """Get M-Pesa access token."""
        credentials = base64.b64encode(
            f"{self.consumer_key}:{self.consumer_secret}".encode()
        ).decode()
        
        response = requests.get(
            f"{self.base_url}/oauth/v1/generate?grant_type=client_credentials",
            headers={"Authorization": f"Basic {credentials}"},
            timeout=30
        )
        
        response.raise_for_status()
        return response.json()["access_token"]
    
    def _format_phone_number(self, phone_number: str) -> str:
        """Format phone number to required format (2547XXXXXXXX)."""
        # Remove any non-digit characters
        phone = ''.join(filter(str.isdigit, phone_number))
        
        # Handle different formats
        if phone.startswith("+"):
            phone = phone[1:]
        if phone.startswith("0"):
            phone = "254" + phone[1:]
        if phone.startswith("7") and len(phone) == 9:
            phone = "254" + phone
        
        return phone
    
    def initiate_stk_push(
        self, 
        phone_number: str, 
        amount: int, 
        account_reference: str,
        description: str = "Bunga Trader Deposit"
    ) -> Dict[str, Any]:
        """
        Initiate STK push for deposit.
        
        Args:
            phone_number: Customer phone number
            amount: Amount in KES
            account_reference: Account reference (e.g., user ID)
            description: Transaction description
        
        Returns:
            Response from M-Pesa API
        """
        token = self._get_access_token()
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        
        # Generate password
        password_str = f"{self.shortcode}{self.passkey}{timestamp}"
        password = base64.b64encode(password_str.encode()).decode()
        
        # Format phone number
        formatted_phone = self._format_phone_number(phone_number)
        
        payload = {
            "BusinessShortCode": self.shortcode,
            "Password": password,
            "Timestamp": timestamp,
            "TransactionType": "CustomerPayBillOnline",
            "Amount": amount,
            "PartyA": formatted_phone,
            "PartyB": self.shortcode,
            "PhoneNumber": formatted_phone,
            "CallBackURL": self.callback_url,
            "AccountReference": account_reference,
            "TransactionDesc": description
        }
        
        response = requests.post(
            f"{self.base_url}/mpesa/stkpush/v1/processrequest",
            json=payload,
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            },
            timeout=30
        )
        
        response.raise_for_status()
        return response.json()
    
    def query_stk_status(self, checkout_request_id: str) -> Dict[str, Any]:
        """
        Query STK push transaction status.
        
        Args:
            checkout_request_id: Checkout request ID from STK push
        
        Returns:
            Transaction status
        """
        token = self._get_access_token()
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        
        password_str = f"{self.shortcode}{self.passkey}{timestamp}"
        password = base64.b64encode(password_str.encode()).decode()
        
        payload = {
            "BusinessShortCode": self.shortcode,
            "Password": password,
            "Timestamp": timestamp,
            "CheckoutRequestID": checkout_request_id
        }
        
        response = requests.post(
            f"{self.base_url}/mpesa/stkpushquery/v1/query",
            json=payload,
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            },
            timeout=30
        )
        
        response.raise_for_status()
        return response.json()
    
    def process_callback(self, callback_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Process M-Pesa callback.
        
        Args:
            callback_data: Callback data from M-Pesa
        
        Returns:
            Processed result
        """
        try:
            stk_callback = callback_data.get("Body", {}).get("stkCallback", {})
            result_code = stk_callback.get("ResultCode")
            
            if result_code == 0:
                # Success
                metadata = stk_callback.get("CallbackMetadata", {}).get("Item", [])
                
                amount = next(
                    (item.get("Value") for item in metadata if item.get("Name") == "Amount"),
                    None
                )
                receipt = next(
                    (item.get("Value") for item in metadata if item.get("Name") == "MpesaReceiptNumber"),
                    None
                )
                phone = next(
                    (item.get("Value") for item in metadata if item.get("Name") == "PhoneNumber"),
                    None
                )
                transaction_date = next(
                    (item.get("Value") for item in metadata if item.get("Name") == "TransactionDate"),
                    None
                )
                
                return {
                    "success": True,
                    "amount": amount,
                    "receipt_number": receipt,
                    "phone_number": phone,
                    "transaction_date": transaction_date,
                    "checkout_request_id": stk_callback.get("CheckoutRequestID"),
                    "merchant_request_id": stk_callback.get("MerchantRequestID"),
                    "result_desc": stk_callback.get("ResultDesc")
                }
            else:
                # Failed
                return {
                    "success": False,
                    "error_code": result_code,
                    "error_message": stk_callback.get("ResultDesc"),
                    "checkout_request_id": stk_callback.get("CheckoutRequestID")
                }
                
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    def initiate_b2c_payment(
        self,
        phone_number: str,
        amount: int,
        occasion: str = "Withdrawal",
        remarks: str = "Bunga Trader Withdrawal"
    ) -> Dict[str, Any]:
        """
        Initiate B2C payment (withdrawal).
        
        Args:
            phone_number: Recipient phone number
            amount: Amount in KES
            occasion: Occasion
            remarks: Remarks
        
        Returns:
            Response from M-Pesa API
        """
        token = self._get_access_token()
        
        # Format phone number
        formatted_phone = self._format_phone_number(phone_number)
        
        payload = {
            "InitiatorName": "BungaTrader",
            "SecurityCredential": self._get_security_credential(),
            "CommandID": "BusinessPayment",
            "Amount": amount,
            "PartyA": self.shortcode,
            "PartyB": formatted_phone,
            "Remarks": remarks,
            "QueueTimeOutURL": f"{self.callback_url}/timeout",
            "ResultURL": f"{self.callback_url}/result",
            "Occasion": occasion
        }
        
        response = requests.post(
            f"{self.base_url}/mpesa/b2c/v1/paymentrequest",
            json=payload,
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            },
            timeout=30
        )
        
        response.raise_for_status()
        return response.json()
    
    def _get_security_credential(self) -> str:
        """Generate security credential for B2C."""
        # In production, this should be properly encrypted
        # For now, return a placeholder
        return base64.b64encode(self.passkey.encode()).decode()
    
    @staticmethod
    def kes_to_usd(kes_amount: float, exchange_rate: float = 0.0077) -> float:
        """Convert KES to USD."""
        return round(kes_amount * exchange_rate, 2)
    
    @staticmethod
    def usd_to_kes(usd_amount: float, exchange_rate: float = 130.0) -> float:
        """Convert USD to KES."""
        return round(usd_amount * exchange_rate, 2)


# Global instance
mpesa_gateway = MpesaGateway()
