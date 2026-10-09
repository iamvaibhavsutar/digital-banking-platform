CREATE TABLE accounts (
    id              BIGSERIAL PRIMARY KEY,
    account_number  VARCHAR(20)  NOT NULL UNIQUE,
    holder_name     VARCHAR(100) NOT NULL,
    balance         NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
    currency        CHAR(3)      NOT NULL DEFAULT 'INR',
    status          VARCHAR(10)  NOT NULL DEFAULT 'ACTIVE',
    version         BIGINT       NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE transactions (
    id               BIGSERIAL PRIMARY KEY,
    idempotency_key  VARCHAR(64)  NOT NULL UNIQUE,
    from_account     VARCHAR(20)  NOT NULL REFERENCES accounts(account_number),
    to_account       VARCHAR(20)  NOT NULL REFERENCES accounts(account_number),
    amount           NUMERIC(15,2) NOT NULL CHECK (amount > 0),
    status           VARCHAR(15)  NOT NULL,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX idx_txn_from ON transactions(from_account, created_at DESC);
CREATE INDEX idx_txn_to   ON transactions(to_account, created_at DESC);
