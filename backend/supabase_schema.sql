-- ============================================
-- Bunga Trader - Supabase Database Schema
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- PROFILES TABLE (extends Supabase Auth)
-- ============================================
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    phone_number TEXT,
    mpesa_number TEXT,
    profile_picture TEXT,
    default_account_id UUID,
    compounding_settings JSONB DEFAULT '{}',
    risk_settings JSONB DEFAULT '{}',
    notification_settings JSONB DEFAULT '{"push_enabled": true, "signal_alerts": true, "trade_alerts": true, "deposit_alerts": true}',
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policies for profiles
CREATE POLICY "Users can view their own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Function to auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, phone_number, mpesa_number)
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'phone_number',
        NEW.raw_user_meta_data->>'mpesa_number'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for auto-creating profile
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- TRADING ACCOUNTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS trading_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    broker TEXT NOT NULL,
    login TEXT NOT NULL,
    password_encrypted TEXT NOT NULL,
    server TEXT NOT NULL,
    platform TEXT DEFAULT 'MT5',
    account_type TEXT,
    balance REAL DEFAULT 0,
    equity REAL DEFAULT 0,
    currency TEXT DEFAULT 'USD',
    leverage INTEGER DEFAULT 100,
    account_status TEXT DEFAULT 'pending',
    is_active BOOLEAN DEFAULT true,
    is_default BOOLEAN DEFAULT false,
    last_synced_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE trading_accounts ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own trading accounts"
    ON trading_accounts FOR SELECT
    USING (user_id = (SELECT id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can create trading accounts"
    ON trading_accounts FOR INSERT
    WITH CHECK (user_id = (SELECT id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can update their own trading accounts"
    ON trading_accounts FOR UPDATE
    USING (user_id = (SELECT id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can delete their own trading accounts"
    ON trading_accounts FOR DELETE
    USING (user_id = (SELECT id FROM profiles WHERE id = auth.uid()));

-- ============================================
-- SIGNALS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS signals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pair TEXT NOT NULL,
    direction TEXT NOT NULL CHECK (direction IN ('BUY', 'SELL')),
    entry_price REAL,
    stop_loss REAL,
    take_profit_1 REAL,
    take_profit_2 REAL,
    take_profit_3 REAL,
    lot_size REAL DEFAULT 0.01,
    risk_percent REAL DEFAULT 1.0,
    confidence INTEGER DEFAULT 70,
    status TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'EXECUTED', 'REJECTED', 'EXPIRED', 'CLOSED')),
    reason TEXT,
    ai_analysis TEXT,
    signal_source TEXT,
    expires_at TIMESTAMPTZ,
    executed_at TIMESTAMPTZ,
    closed_at TIMESTAMPTZ,
    profit REAL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE signals ENABLE ROW LEVEL SECURITY;

-- Policies (signals are public read, admin write)
CREATE POLICY "Anyone can view signals"
    ON signals FOR SELECT
    USING (true);

CREATE POLICY "Service role can create signals"
    ON signals FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Service role can update signals"
    ON signals FOR UPDATE
    USING (true);

-- ============================================
-- EXECUTED SIGNALS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS executed_signals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    signal_id UUID NOT NULL REFERENCES signals(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES trading_accounts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    executed_lot_size REAL,
    executed_entry_price REAL,
    executed_stop_loss REAL,
    executed_take_profit_1 REAL,
    executed_take_profit_2 REAL,
    executed_take_profit_3 REAL,
    auto_execute BOOLEAN DEFAULT false,
    executed_at TIMESTAMPTZ DEFAULT NOW(),
    closed_at TIMESTAMPTZ,
    profit REAL DEFAULT 0,
    status TEXT DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CLOSED'))
);

-- Enable RLS
ALTER TABLE executed_signals ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own executed signals"
    ON executed_signals FOR SELECT
    USING (user_id = (SELECT id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can create executed signals"
    ON executed_signals FOR INSERT
    WITH CHECK (user_id = (SELECT id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can update their own executed signals"
    ON executed_signals FOR UPDATE
    USING (user_id = (SELECT id FROM profiles WHERE id = auth.uid()));

-- ============================================
-- TRADES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS trades (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    account_id UUID NOT NULL REFERENCES trading_accounts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    ticket_number TEXT,
    pair TEXT NOT NULL,
    direction TEXT NOT NULL CHECK (direction IN ('BUY', 'SELL')),
    lot_size REAL NOT NULL,
    open_price REAL NOT NULL,
    current_price REAL,
    stop_loss REAL,
    take_profit REAL,
    take_profit_2 REAL,
    take_profit_3 REAL,
    profit REAL DEFAULT 0,
    swap REAL DEFAULT 0,
    commission REAL DEFAULT 0,
    status TEXT DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CLOSED')),
    opened_at TIMESTAMPTZ DEFAULT NOW(),
    closed_at TIMESTAMPTZ,
    close_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE trades ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own trades"
    ON trades FOR SELECT
    USING (user_id = (SELECT id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can create trades"
    ON trades FOR INSERT
    WITH CHECK (user_id = (SELECT id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can update their own trades"
    ON trades FOR UPDATE
    USING (user_id = (SELECT id FROM profiles WHERE id = auth.uid()));

-- ============================================
-- M-PESA DEPOSITS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS mpesa_deposits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    amount_kes REAL NOT NULL,
    amount_usd REAL,
    phone_number TEXT NOT NULL,
    checkout_request_id TEXT,
    mpesa_receipt_number TEXT,
    status TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'CANCELLED')),
    transaction_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE mpesa_deposits ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own deposits"
    ON mpesa_deposits FOR SELECT
    USING (user_id = (SELECT id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can create deposits"
    ON mpesa_deposits FOR INSERT
    WITH CHECK (user_id = (SELECT id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can update their own deposits"
    ON mpesa_deposits FOR UPDATE
    USING (user_id = (SELECT id FROM profiles WHERE id = auth.uid()));

-- ============================================
-- M-PESA WITHDRAWALS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS mpesa_withdrawals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    amount_usd REAL NOT null,
    amount_kes REAL,
    phone_number TEXT NOT NULL,
    status TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'CANCELLED')),
    mpesa_receipt_number TEXT,
    conversation_id TEXT,
    transaction_id TEXT,
    withdrawal_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE mpesa_withdrawals ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own withdrawals"
    ON mpesa_withdrawals FOR SELECT
    USING (user_id = (SELECT id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can create withdrawals"
    ON mpesa_withdrawals FOR INSERT
    WITH CHECK (user_id = (SELECT id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can update their own withdrawals"
    ON mpesa_withdrawals FOR UPDATE
    USING (user_id = (SELECT id FROM profiles WHERE id = auth.uid()));

-- ============================================
-- USER SETTINGS TABLE (optional key-value store)
-- ============================================
CREATE TABLE IF NOT EXISTS user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    key TEXT NOT NULL,
    value JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, key)
);

-- Enable RLS
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own settings"
    ON user_settings FOR SELECT
    USING (user_id = (SELECT id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can create settings"
    ON user_settings FOR INSERT
    WITH CHECK (user_id = (SELECT id FROM profiles WHERE id = auth.uid()));

CREATE POLICY "Users can update their own settings"
    ON user_settings FOR UPDATE
    USING (user_id = (SELECT id FROM profiles WHERE id = auth.uid()));

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX IF NOT EXISTS idx_trading_accounts_user_id ON trading_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_signals_status ON signals(status);
CREATE INDEX IF NOT EXISTS idx_signals_created_at ON signals(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_trades_user_id ON trades(user_id);
CREATE INDEX IF NOT EXISTS idx_trades_status ON trades(status);
CREATE INDEX IF NOT EXISTS idx_trades_created_at ON trades(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mpesa_deposits_user_id ON mpesa_deposits(user_id);
CREATE INDEX IF NOT EXISTS idx_mpesa_withdrawals_user_id ON mpesa_withdrawals(user_id);
CREATE INDEX IF NOT EXISTS idx_executed_signals_user_id ON executed_signals(user_id);
CREATE INDEX IF NOT EXISTS idx_executed_signals_signal_id ON executed_signals(signal_id);

-- ============================================
-- STORAGE FOR PROFILE PICTURES
-- ============================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Anyone can view avatars"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload avatars"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own avatars"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
