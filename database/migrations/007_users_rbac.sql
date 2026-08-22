CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    organization_id UUID NOT NULL
        REFERENCES organizations(id) ON DELETE CASCADE,

    employee_id UUID
        REFERENCES employees(id) ON DELETE SET NULL,

    username VARCHAR(64) NOT NULL,
    email VARCHAR(128) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(128) NOT NULL,

    status user_status NOT NULL DEFAULT 'ACTIVE',
    last_login_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_users_org_username
        UNIQUE (organization_id, username),

    CONSTRAINT uq_users_org_email
        UNIQUE (organization_id, email)
);

CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    organization_id UUID NOT NULL
        REFERENCES organizations(id) ON DELETE CASCADE,

    code VARCHAR(32) NOT NULL,
    name VARCHAR(64) NOT NULL,
    description TEXT,
    is_system BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_roles_org_code
        UNIQUE (organization_id, code)
);

CREATE TRIGGER trg_roles_updated_at
BEFORE UPDATE ON roles
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    code VARCHAR(64) NOT NULL UNIQUE,
    name VARCHAR(128) NOT NULL,
    module VARCHAR(64) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE role_permissions (
    role_id UUID NOT NULL
        REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL
        REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE user_roles (
    user_id UUID NOT NULL
        REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL
        REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE user_section_assignments (
    id UUID PRIMARY KEY DEFAULT uuidv7(),

    user_id UUID NOT NULL
        REFERENCES users(id) ON DELETE CASCADE,

    section_id UUID NOT NULL
        REFERENCES sections(id) ON DELETE CASCADE,

    role_in_section VARCHAR(32) NOT NULL DEFAULT 'MEMBER',

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_user_section_assignments
        UNIQUE (user_id, section_id)
);

CREATE INDEX idx_user_section_assignments_user
    ON user_section_assignments(user_id);

CREATE INDEX idx_user_section_assignments_section
    ON user_section_assignments(section_id);
