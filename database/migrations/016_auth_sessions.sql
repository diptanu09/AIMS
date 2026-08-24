CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    user_id UUID NOT NULL
        REFERENCES users(id) ON DELETE CASCADE,

    token_hash CHAR(64) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ NOT NULL,

    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    revoked_at TIMESTAMPTZ,

    client_ip INET,
    user_agent TEXT,

    CONSTRAINT uq_user_sessions_token_hash
        UNIQUE (token_hash),

    CONSTRAINT ck_user_sessions_expiry
        CHECK (expires_at > created_at)
);

CREATE INDEX IF NOT EXISTS idx_user_sessions_user
    ON user_sessions(user_id, expires_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_sessions_active
    ON user_sessions(token_hash, expires_at)
    WHERE revoked_at IS NULL;
