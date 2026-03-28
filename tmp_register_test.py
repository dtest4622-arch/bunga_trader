import requests

payload = {
    'email': 'testuser2@example.com',
    'password': 'TestPass123',
    'phone_number': '0712345678',
    'mpesa_number': '254712345678',
    'full_name': 'Test User',
}

url = 'https://bunga-trader.onrender.com/v1/auth/register'
resp = requests.post(url, json=payload, timeout=15)
print('status', resp.status_code)
print('content-type', resp.headers.get('content-type'))
print('body', resp.text)
