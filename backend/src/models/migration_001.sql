-- Migration script: Zero-Knowledge Schema Update

-- 1. Accounts Table (Encrypted)
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

-- 2. Transactions Table (Encrypted)
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID REFERENCES accounts(id) ON DELETE CASCADE,
    user_id VARCHAR(128) REFERENCES users(uid) ON DELETE CASCADE,
    encrypted_amount TEXT NOT NULL,      -- Base64 AES-256 (amount stored as string)
    encrypted_description TEXT NOT NULL, -- Base64 AES-256
    category VARCHAR(100),               -- Can be plain for budgeting or encrypted
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    external_id VARCHAR(255),            -- Deduplication from provider
    
    UNIQUE(account_id, external_id)
);

-- 3. Budgets Table
CREATE TABLE IF NOT EXISTS budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(128) REFERENCES users(uid) ON DELETE CASCADE,
    category VARCHAR(100) NOT NULL,
    "limit" NUMERIC(15, 2) NOT NULL,     -- Limits are usually plain for server-side alerts, or encrypted if purely client-side
    period VARCHAR(20) DEFAULT 'MONTHLY',-- MONTHLY, WEEKLY, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_accounts_user_id ON accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_account_id ON transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_budgets_user_id ON budgets(user_id);
