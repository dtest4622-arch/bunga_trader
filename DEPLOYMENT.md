# 🚀 Render Deployment Guide

This guide shows you how to deploy Bunga Trader backend to Render (no Docker required).

## ✅ What Render Supports

| Feature | Support |
|---------|---------|
| FastAPI Server | ✅ Full support |
| PostgreSQL | ✅ Managed DB included |
| Redis | ✅ Managed Redis included |
| Background Tasks | ✅ Worker services |
| Telegram Listener | ✅ Worker services |
| Celery Workers | ✅ Worker services |
| WebSockets | ✅ Full support |

---

## 📋 Prerequisites

1. **GitHub Account** - Your code should be on GitHub
2. **Render Account** - Sign up at [render.com](https://render.com)

---

## 🚀 Quick Deploy (5 minutes)

### Step 1: Push Code to GitHub

```bash
cd "c:\Users\ADMIN\Downloads\Bunga Trader"
git init
git add .
git commit -m "Initial commit for Render deployment"
# Add your remote and push
git remote add origin https://github.com/yourusername/bunga-trader.git
git push -u origin main
```

### Step 2: One-Click Deploy with render.yaml

**Option A: Using render.yaml (Recommended)**

1. Go to [render.com/dashboard](https://dashboard.render.com)
2. Click **"New +"** → **"Blueprint"**
3. Connect your GitHub repository
4. Select `bunga-trader` repository
5. Render reads `render.yaml` and creates all services automatically!
6. Click **"Apply"**

That's it! Render will create:
- ✅ FastAPI Web Service
- ✅ PostgreSQL Database
- ✅ Redis Cache
- ✅ Celery Worker
- ✅ Celery Scheduler

---

### Step 3: Manual Deploy (Alternative)

If you prefer to set up manually:

#### 3.1: Create PostgreSQL Database

1. In Render dashboard, click **"New +"** → **"PostgreSQL"**
2. Name: `bunga-trader-db`
3. Region: Choose closest to you
4. Plan: **Starter** (free for 90 days, then $7/month)
5. Click **"Create Database"**
6. Copy the **Internal Database URL**

#### 3.2: Create Redis (Optional - for Celery)

1. Click **"New +"** → **"Redis"**
2. Name: `bunga-trader-redis`
3. Plan: **Starter** (free)
4. Click **"Create Database"**
5. Copy the **Redis URL**

#### 3.3: Create Web Service

1. Click **"New +"** → **"Web Service"**
2. Connect your GitHub repository
3. Configure:
   - **Name**: `bunga-trader-api`
   - **Region**: Same as database
   - **Branch**: `main`
   - **Root Directory**: `backend`
   - **Runtime**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - **Instance Type**: **Starter** (free tier available)

4. **Environment Variables** - Add these:
   ```
   DEBUG=false
   SECRET_KEY=your-production-secret-key-here
   DATABASE_URL=<paste PostgreSQL Internal URL>
   REDIS_URL=<paste Redis URL>
   SUPABASE_URL=https://xvpggkaavmekkencdkbh.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   GROQ_API_KEY=your-groq-key
   TELEGRAM_API_ID=your-telegram-id
   TELEGRAM_API_HASH=your-telegram-hash
   MPESA_CONSUMER_KEY=your-mpesa-key
   MPESA_CONSUMER_SECRET=your-mpesa-secret
   MPESA_PASSKEY=your-mpesa-passkey
   ```

5. Click **"Create Web Service"**

#### 3.4: Create Worker Service (Optional)

1. Click **"New +"** → **"Worker Service"**
2. Connect the same GitHub repository
3. Configure:
   - **Name**: `bunga-trader-worker`
   - **Root Directory**: `backend`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `celery -A app.services.celery_app worker --loglevel=info`
4. Add same environment variables as web service
5. Click **"Create Worker Service"**

---

## 🔧 Update Frontend

Update `frontend/lib/core/constants/app_constants.dart`:

```dart
// Replace with your Render URL
static const String apiBaseUrl = 'https://bunga-trader-api.onrender.com/v1';
static const String wsBaseUrl = 'wss://bunga-trader-api.onrender.com/ws';
```

---

## 💰 Render Pricing

| Plan | Web Service | Database | Redis | Total (Estimate) |
|------|-------------|----------|-------|------------------|
| **Free Tier** | Free (750 hrs/mo) | N/A | N/A | $0 (limited) |
| **Starter** | $7/month | $7/month | Free | ~$14-21/month |
| **Standard** | $25/month | $25/month | Free | ~$50-75/month |

**Free Tier Notes:**
- Web services spin down after 15 min inactivity
- First request after spin-down takes ~30 seconds
- Databases free for 90 days, then $7/month
- Great for testing, upgrade for production

---

## 📊 Service Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Render                           │
│                                                     │
│  ┌─────────────────┐                               │
│  │  Web Service    │ ← HTTPS/WSS                   │
│  │  (FastAPI)      │                               │
│  └────────┬────────┘                               │
│           │                                        │
│  ┌────────▼────────┐     ┌─────────────────┐      │
│  │  PostgreSQL     │     │     Redis       │      │
│  │  (Database)     │     │   (Cache/Queue) │      │
│  └─────────────────┘     └─────────────────┘      │
│           ▲                        ▲               │
│  ┌────────┴────────┐     ┌────────┴────────┐      │
│  │  Worker         │     │   Scheduler     │      │
│  │  (Celery)       │     │   (Celery Beat) │      │
│  └─────────────────┘     └─────────────────┘      │
└─────────────────────────────────────────────────────┘
```

---

## 🔍 Monitoring

- **Logs**: Dashboard → Service → Logs
- **Metrics**: Dashboard → Service → Metrics
- **Health**: `https://your-app.onrender.com/health`
- **API Docs**: `https://your-app.onrender.com/docs`

---

## 🛠️ Troubleshooting

### Build Fails

```
Error: No module named 'xxx'
```
→ Ensure all dependencies are in `backend/requirements.txt`

### Database Connection Fails

```
Error: could not connect to database
```
→ Use **Internal Database URL** (not External)
→ Check service is in same region as database

### Service Spins Down (Free Tier)

```
First request takes 30+ seconds
```
→ This is normal for free tier
→ Upgrade to Starter plan for always-on service

### WebSocket Disconnects

```
WebSocket connection closed
```
→ Ensure you're using `wss://` (secure)
→ Check Render logs for errors
→ Free tier may disconnect - upgrade for stability

### Port Error

```
Error: Port is not specified
```
→ Render sets `$PORT` automatically
→ Don't hardcode port in your code

---

## 📝 Using Supabase Instead of Render PostgreSQL

If you prefer to use your existing Supabase:

1. Get connection string from Supabase Dashboard:
   - Settings → Database → Connection string (URI)
   - Format: `postgresql://postgres.xxx:password@db.xvpggkaavmekkencdkbh.supabase.co:5432/postgres`

2. Convert to async format:
   ```
   postgresql+asyncpg://postgres.xxx:password@db.xvpggkaavmekkencdkbh.supabase.co:5432/postgres
   ```

3. Set as `DATABASE_URL` environment variable in Render

**Benefits:**
- Keep existing Supabase data
- Use Supabase Auth + Storage
- No need for Render PostgreSQL (save $7/month)

---

## ✅ Post-Deployment Checklist

- [ ] Web service builds successfully
- [ ] Health check passes: `/health`
- [ ] Registration works: `/v1/auth/register`
- [ ] Login works: `/v1/auth/login`
- [ ] Database tables created
- [ ] Frontend can connect
- [ ] WebSocket works: `/ws`
- [ ] Worker service running (if deployed)
- [ ] Environment variables set correctly

---

## 🎯 Render vs Railway Comparison

| Feature | Render | Railway |
|---------|--------|---------|
| **Free Tier** | ✅ 750 hours/month | ✅ $5 credit |
| **Always-On** | $7/month | ~$5/month |
| **PostgreSQL** | $7/month | $5/month |
| **Redis** | Free | Free tier |
| **Deploy Config** | `render.yaml` | `railway.json` |
| **UI/UX** | Excellent | Good |
| **Auto-Deploy** | ✅ Yes | ✅ Yes |
| **Multiple Services** | ✅ Easy | ✅ Easy |

**Verdict:** Both are great! Render has better UI, Railway is slightly cheaper.

---

## 🎯 Next Steps

1. Test registration flow
2. Connect MT5 bridge
3. Configure M-Pesa for production
4. Set up custom domain (optional)
5. Enable auto-deploy from GitHub

---

**Need help?** Check Render docs: https://render.com/docs
