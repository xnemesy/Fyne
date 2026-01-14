-- Refined Zero-Knowledge Schema for Budgeting & Private Categorization

-- 1. Users table
CREATE TABLE IF NOT EXISTS users (
    uid VARCHAR(128) PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Encrypted Accounts
CREATE TABLE IF NOT EXISTS accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(128) REFERENCES users(uid) ON DELETE CASCADE,
    encrypted_name TEXT NOT NULL,       -- Base64 AES-256
    encrypted_balance TEXT NOT NULL,    -- Base64 AES-256
    currency VARCHAR(3) NOT NULL,
    provider_id VARCHAR(50), 
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Transactions with Anonymous Category IDs
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID REFERENCES accounts(id) ON DELETE CASCADE,
    user_id VARCHAR(128) REFERENCES users(uid) ON DELETE CASCADE,
    amount NUMERIC(15, 2) NOT NULL,      -- Clear amount for budgeting math
    currency VARCHAR(3) NOT NULL,
    encrypted_description TEXT NOT NULL, -- Encrypted
    encrypted_counter_party TEXT,        -- Encrypted
    category_uuid UUID NOT NULL,         -- Anonymous UUID, client knows what it means
    booking_date DATE NOT NULL,
    external_id VARCHAR(255),
    
    UNIQUE(account_id, external_id)
);

-- 4. Budgets with Anonymous Categories
CREATE TABLE IF NOT EXISTS budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(128) REFERENCES users(uid) ON DELETE CASCADE,
    category_uuid UUID NOT NULL,         -- Matches transaction.category_uuid
    encrypted_category_name TEXT NOT NULL, -- "Sushi" (encrypted)
    limit_amount NUMERIC(15, 2) NOT NULL,
    current_spent NUMERIC(15, 2) DEFAULT 0,
    period VARCHAR(20) DEFAULT 'MONTHLY',
    
    UNIQUE(user_id, category_uuid)
);

-- Trigger Function to update Budget automatically
CREATE OR REPLACE FUNCTION update_budget_on_transaction()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE budgets
    SET current_spent = current_spent + NEW.amount
    WHERE user_id = NEW.user_id AND category_uuid = NEW.category_uuid;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Set up the trigger
DROP TRIGGER IF EXISTS trg_update_budget ON transactions;
CREATE TRIGGER trg_update_budget
AFTER INSERT ON transactions
FOR EACH ROW EXECUTE FUNCTION update_budget_on_transaction();

-- Indexes
CREATE INDEX IF NOT EXISTS idx_tx_cat_user ON transactions(user_id, category_uuid);
CREATE INDEX IF NOT EXISTS idx_budgets_lookup ON budgets(user_id, category_uuid);
