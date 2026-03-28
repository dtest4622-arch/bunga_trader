# Bunga Trader

Kenya's Smart Semi-Auto Trading Platform

## Overview

Bunga Trader is a comprehensive forex trading platform designed for Kenyan traders, featuring:

- **Flutter Mobile App**: Beautiful, responsive UI for iOS and Android
- **FastAPI Backend**: High-performance Python API
- **AI-Powered Risk Management**: Groq AI for intelligent position sizing
- **Telegram Signal Integration**: Auto-parse signals from Telegram groups
- **MT4/MT5 Bridge**: Execute trades directly on MetaTrader
- **M-Pesa Integration**: Deposit and withdraw via M-Pesa

## Project Structure

```
bunga_trader/
├── frontend/                    # Flutter Application
│   ├── lib/
│   │   ├── core/               # Theme, constants, utils
│   │   ├── data/               # Models, repositories, services
│   │   ├── presentation/       # UI screens and BLoCs
│   │   └── main.dart
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
├── backend/                     # FastAPI Application
│   ├── app/
│   │   ├── api/                # API routes
│   │   ├── core/               # Config, security
│   │   ├── models/             # SQLAlchemy models
│   │   ├── services/           # Business logic
│   │   └── main.py
│   ├── mt5_ea/                 # MQL5 Expert Advisor
│   ├── Dockerfile
│   └── requirements.txt
├── database/                    # Migrations
├── infrastructure/              # Docker, K8s, Terraform
└── docker-compose.yml
```

## Deployment

### Railway (Free Tier)

1. **Connect Repository**
   - Push code to GitHub
   - Connect Railway to your GitHub repo

2. **Add Database**
   - In Railway dashboard, add a PostgreSQL database
   - Note: Railway free tier includes 512MB Postgres

3. **Connect Database to Service**
   - Go to your web service → Database tab
   - Click "Connect" next to your Postgres database
   - This automatically injects `DATABASE_URL`

4. **Deploy**
   - Railway auto-detects `Procfile` and `requirements.txt`
   - Service deploys automatically

5. **Verify**
   - Check `/health` endpoint for database status
   - If DATABASE_URL is missing, run `python debug_env.py` in Railway logs

### Local Development

```bash
# Backend
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
python serve.py

# Frontend
cd frontend
flutter pub get
flutter run
```

### Docker

```bash
docker-compose up --build
```
- MetaTrader 4 or 5 (for trading)

### 1. Clone and Configure

```bash
git clone https://github.com/yourusername/bunga_trader.git
cd bunga_trader
cp .env.example .env
# Edit .env with your credentials
```

### 2. Start Backend Services

```bash
docker-compose up -d postgres redis
```

### 3. Run Backend API

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### 4. Run Flutter App

```bash
cd frontend
flutter pub get
flutter run
```

### 5. Setup MT5 EA

1. Copy `backend/mt5_ea/BungaTrader_EA.mq5` to your MT5 Experts folder
2. Compile and run the EA
3. Note the port (default: 5555)

## Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `SECRET_KEY` | JWT secret key | Yes |
| `DB_PASSWORD` | PostgreSQL password | Yes |
| `GROQ_API_KEY` | Groq AI API key | Yes |
| `TELEGRAM_API_ID` | Telegram API ID | For signals |
| `TELEGRAM_API_HASH` | Telegram API Hash | For signals |
| `MPESA_CONSUMER_KEY` | M-Pesa consumer key | For payments |
| `MPESA_CONSUMER_SECRET` | M-Pesa consumer secret | For payments |
| `MPESA_PASSKEY` | M-Pesa passkey | For payments |

## API Documentation

Once the backend is running, access:

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Features

### Trading Features

- **Semi-Auto Trading**: Review signals before execution
- **AI Risk Management**: Intelligent lot sizing and SL/TP calculation
- **Multiple Accounts**: Connect multiple MT4/MT5 accounts
- **Real-time Updates**: WebSocket for live trade updates
- **Trade History**: Complete trade logging and analytics

### Payment Features

- **M-Pesa STK Push**: Easy deposits
- **Withdrawals**: Direct to M-Pesa
- **Transaction History**: Track all payments

### Security Features

- **JWT Authentication**: Secure API access
- **Encrypted Credentials**: Broker passwords encrypted
- **2FA Support**: Optional two-factor authentication
- **Biometric Login**: Fingerprint/Face ID on mobile

## Development

### Backend Development

```bash
cd backend
pip install -r requirements.txt
pytest  # Run tests
black .  # Format code
```

### Frontend Development

```bash
cd frontend
flutter pub get
flutter analyze
flutter test
```

## Deployment

### Production Deployment

```bash
# Using Docker Compose
docker-compose -f docker-compose.yml --profile production up -d
```

### Kubernetes Deployment

See `infrastructure/k8s/` for Kubernetes manifests.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - see LICENSE file for details

## Support

- Email: support@bungatrader.com
- Telegram: @bungatrader_support
- Website: https://bungatrader.com

## Disclaimer

Trading forex involves significant risk. Bunga Trader is a tool to assist with trading decisions, not financial advice. Always trade responsibly and never risk more than you can afford to lose.
