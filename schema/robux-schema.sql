-- Robux System Database Schema
-- Created: 2025-12-23 14:27:44 UTC
-- Description: Schema for managing Robux currency, transactions, and user accounts

-- ============================================================================
-- USERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_username (username),
    INDEX idx_email (email)
);

-- ============================================================================
-- ROBUX ACCOUNTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS robux_accounts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL UNIQUE,
    balance DECIMAL(15, 2) DEFAULT 0.00,
    total_earned DECIMAL(15, 2) DEFAULT 0.00,
    total_spent DECIMAL(15, 2) DEFAULT 0.00,
    last_balance_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_balance (balance)
);

-- ============================================================================
-- ROBUX TRANSACTIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS robux_transactions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    robux_account_id BIGINT NOT NULL,
    transaction_type ENUM('credit', 'debit') NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    description VARCHAR(500),
    reference_id VARCHAR(255),
    balance_before DECIMAL(15, 2),
    balance_after DECIMAL(15, 2),
    status ENUM('pending', 'completed', 'failed', 'reversed') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (robux_account_id) REFERENCES robux_accounts(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_robux_account_id (robux_account_id),
    INDEX idx_transaction_type (transaction_type),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);

-- ============================================================================
-- ROBUX PRODUCTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS robux_products (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(15, 2) NOT NULL,
    robux_cost DECIMAL(15, 2) NOT NULL,
    category VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_is_active (is_active)
);

-- ============================================================================
-- ROBUX PURCHASES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS robux_purchases (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    robux_account_id BIGINT NOT NULL,
    quantity INT DEFAULT 1,
    total_cost DECIMAL(15, 2) NOT NULL,
    purchase_status ENUM('pending', 'completed', 'cancelled', 'refunded') DEFAULT 'pending',
    transaction_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES robux_products(id),
    FOREIGN KEY (robux_account_id) REFERENCES robux_accounts(id) ON DELETE CASCADE,
    FOREIGN KEY (transaction_id) REFERENCES robux_transactions(id),
    INDEX idx_user_id (user_id),
    INDEX idx_product_id (product_id),
    INDEX idx_purchase_status (purchase_status),
    INDEX idx_created_at (created_at)
);

-- ============================================================================
-- ROBUX REWARDS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS robux_rewards (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    reward_name VARCHAR(255) NOT NULL,
    description TEXT,
    robux_amount DECIMAL(15, 2) NOT NULL,
    reward_type ENUM('daily', 'achievement', 'referral', 'event', 'bonus') NOT NULL,
    max_claims INT,
    current_claims INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_reward_type (reward_type),
    INDEX idx_is_active (is_active)
);

-- ============================================================================
-- USER REWARD CLAIMS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_reward_claims (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    reward_id BIGINT NOT NULL,
    robux_account_id BIGINT NOT NULL,
    transaction_id BIGINT,
    claimed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (reward_id) REFERENCES robux_rewards(id),
    FOREIGN KEY (robux_account_id) REFERENCES robux_accounts(id) ON DELETE CASCADE,
    FOREIGN KEY (transaction_id) REFERENCES robux_transactions(id),
    UNIQUE KEY unique_user_reward (user_id, reward_id),
    INDEX idx_user_id (user_id),
    INDEX idx_reward_id (reward_id),
    INDEX idx_claimed_at (claimed_at)
);

-- ============================================================================
-- ROBUX TRANSFER TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS robux_transfers (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    sender_id BIGINT NOT NULL,
    receiver_id BIGINT NOT NULL,
    sender_account_id BIGINT NOT NULL,
    receiver_account_id BIGINT NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    transfer_status ENUM('pending', 'completed', 'failed', 'cancelled') DEFAULT 'pending',
    sender_transaction_id BIGINT,
    receiver_transaction_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_account_id) REFERENCES robux_accounts(id),
    FOREIGN KEY (receiver_account_id) REFERENCES robux_accounts(id),
    FOREIGN KEY (sender_transaction_id) REFERENCES robux_transactions(id),
    FOREIGN KEY (receiver_transaction_id) REFERENCES robux_transactions(id),
    INDEX idx_sender_id (sender_id),
    INDEX idx_receiver_id (receiver_id),
    INDEX idx_transfer_status (transfer_status),
    INDEX idx_created_at (created_at)
);

-- ============================================================================
-- ROBUX AUDIT LOG TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS robux_audit_log (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT,
    action VARCHAR(255) NOT NULL,
    entity_type VARCHAR(100),
    entity_id BIGINT,
    old_value JSON,
    new_value JSON,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at)
);

-- ============================================================================
-- ROBUX RESTRICTIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS robux_restrictions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL UNIQUE,
    restriction_type ENUM('purchase_ban', 'transfer_ban', 'withdrawal_ban', 'full_ban') NOT NULL,
    reason TEXT,
    restricted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    unrestricted_at TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_is_active (is_active)
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================
CREATE INDEX idx_robux_transactions_date_range ON robux_transactions(created_at, user_id);
CREATE INDEX idx_robux_purchases_date_range ON robux_purchases(created_at, user_id);
CREATE INDEX idx_robux_accounts_balance_sort ON robux_accounts(balance DESC);

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- User Robux Summary View
CREATE OR REPLACE VIEW user_robux_summary AS
SELECT 
    u.id,
    u.username,
    u.email,
    ra.balance,
    ra.total_earned,
    ra.total_spent,
    ra.created_at as account_created_at
FROM users u
LEFT JOIN robux_accounts ra ON u.id = ra.user_id
WHERE u.is_active = TRUE;

-- Recent Transactions View
CREATE OR REPLACE VIEW recent_transactions AS
SELECT 
    rt.id,
    u.username,
    rt.transaction_type,
    rt.amount,
    rt.description,
    rt.status,
    rt.balance_before,
    rt.balance_after,
    rt.created_at
FROM robux_transactions rt
JOIN users u ON rt.user_id = u.id
ORDER BY rt.created_at DESC;
