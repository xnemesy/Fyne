-- Database Schema for Fyne (Zero-Knowledge & Banking Abstraction)

-- 1. Users table (linked to Firebase UID)
CREATE TABLE IF NOT EXISTS users (
    uid VARCHAR(128) PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Banking Connections (Provider Metadata)
CREATE TABLE IF NOT EXISTS banking_connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_uid VARCHAR(128) REFERENCES users(uid) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL,
    provider_requisition_id VARCHAR(255) UNIQUE,
    status VARCHAR(50) DEFAULT 'CREATED',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Accounts Table (Encrypted)
CREATE TABLE IF NOT EXISTS accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(128) REFERENCES users(uid) ON DELETE CASCADE,
    encrypted_name TEXT NOT NULL,       -- Base64 AES-256
    encrypted_balance TEXT NOT NULL,    -- Base64 AES-256
    currency VARCHAR(3) NOT NULL,
    provider_id VARCHAR(50),            -- e.g. 'gocardless'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Transactions Table (Encrypted)
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID REFERENCES accounts(id) ON DELETE CASCADE,
    user_id VARCHAR(128) REFERENCES users(uid) ON DELETE CASCADE,
    encrypted_amount TEXT NOT NULL,      -- Base64 AES-256
    encrypted_description TEXT NOT NULL, -- Base64 AES-256
    category VARCHAR(100),               
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    external_id VARCHAR(255),            -- Deduplication
    
    UNIQUE(account_id, external_id)
);

-- 5. Budgets Table
CREATE TABLE IF NOT EXISTS budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(128) REFERENCES users(uid) ON DELETE CASCADE,
    category VARCHAR(100) NOT NULL,
    "limit" NUMERIC(15, 2) NOT NULL,     
    period VARCHAR(20) DEFAULT 'MONTHLY',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_uid ON users(uid);
CREATE INDEX IF NOT EXISTS idx_accounts_user ON accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_account ON transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_budgets_user ON budgets(user_id);
