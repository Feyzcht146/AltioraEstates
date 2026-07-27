-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp"; -- to generate UUIDs
CREATE EXTENSION IF NOT EXISTS "unaccent";   -- to search without accents

-- ============================================================
--  TYPES / ENUMERATES
-- ============================================================

CREATE TYPE user_role         AS ENUM ('user', 'agency', 'admin');
CREATE TYPE property_status   AS ENUM ('available', 'sold_out', 'paused'); -- paused: properties that agencies doesn't want to show yet
CREATE TYPE property_type     AS ENUM ('house', 'apartment', 'land', 'commercial', 'condominium');
CREATE TYPE purchase_status   AS ENUM ('pending', 'accepted', 'rejected', 'cancelled');
CREATE TYPE currency_code     AS ENUM ('CRC', 'USD', 'EUR');

-- ============================================================
--  TABLES: Users
-- ============================================================

CREATE TABLE users (
    id              UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    email           VARCHAR(60)     NOT NULL UNIQUE,
    password        VARCHAR(255)    NOT NULL,   -- encrypted
    role            user_role       NOT NULL,
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE TABLE buyer_profiles (
    id              UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID            NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    first_name      VARCHAR(40)     NOT NULL,
    last_name       VARCHAR(40)     NOT NULL,
    phone           VARCHAR(8),
    avatar_url      VARCHAR(255),
    bio             VARCHAR(250),
    country         VARCHAR(50),
    city            VARCHAR(50),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- ============================================================
--  TABLES: Agency
-- ============================================================

CREATE TABLE agency_profiles (
    id              UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID            NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    agency_name     VARCHAR(50)     NOT NULL,
    logo_url        VARCHAR(255),
    cover_url       VARCHAR(255),
    description     VARCHAR(100),
    website_url     VARCHAR(255),
    phone           VARCHAR(8),
    email_contact   VARCHAR(60),
    country         VARCHAR(50),
    city            VARCHAR(50),
    address         VARCHAR(50),
    founded_year    SMALLINT,
    is_verified     BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- ============================================================
--  TABLES: Properties
-- ============================================================

CREATE TABLE properties (
    id              UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    agency_user_id  UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title           VARCHAR(100)    NOT NULL,
    description     VARCHAR(250)    NOT NULL,
    property_type   property_type   NOT NULL,
    status          property_status NOT NULL DEFAULT 'available',
    price           NUMERIC(14, 2)  NOT NULL,
    currency        currency_code   NOT NULL DEFAULT 'CRC',
    area_m2         NUMERIC(10, 2),
    bedrooms        SMALLINT        DEFAULT 0,
    bathrooms       SMALLINT        DEFAULT 0,
    parking_spots   SMALLINT        DEFAULT 0,
    floor_number    SMALLINT, -- for apartments
    total_floors    SMALLINT        DEFAULT 0, -- here is take in count houses, condos and commercials premises
    year_built      SMALLINT,
    -- Ubicación
    province        VARCHAR(20),
    city            VARCHAR(40), -- cantón
    district        VARCHAR(40), -- ciudad/distrito
    address         VARCHAR(100),
    latitude        NUMERIC(10, 7), -- show in maps
    longitude       NUMERIC(10, 7),
    -- Features/Características
    has_pool        BOOLEAN         DEFAULT FALSE,
    has_gym         BOOLEAN         DEFAULT FALSE,
    has_garden      BOOLEAN         DEFAULT FALSE,
    is_featured     BOOLEAN         DEFAULT FALSE, -- destacado
    -- Control
    views_count     INT             NOT NULL DEFAULT 0, -- popular
    published_at    TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- minimum of 5, maximum of 15 images for properties
CREATE TABLE property_images (
    id              UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id     UUID            NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    url             VARCHAR(100)    NOT NULL,
    display_order   SMALLINT        NOT NULL DEFAULT 0  -- the first image, index 0, is the cover
);

-- ============================================================
--  TABLES: Purchase requests
--  Buy request from a user about a property propiedad
--  A property can only have 1 active request at a time
-- ============================================================

CREATE TABLE purchase_requests (
    id                  UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id         UUID            NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    buyer_user_id       UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status              purchase_status NOT NULL DEFAULT 'pending',
    message             TEXT,           -- optional message from buyer
    rejection_reason    TEXT,           -- agency rejection reason
    -- Snapshot from price at the time of request
    price_at_request    NUMERIC(14, 2)  NOT NULL,
    currency_at_request currency_code   NOT NULL,
    -- Notifications
    buyer_notified      BOOLEAN         NOT NULL DEFAULT FALSE,
    agency_notified     BOOLEAN         NOT NULL DEFAULT FALSE,
    -- Stream Timestamps
    requested_at        TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    responded_at        TIMESTAMPTZ,    -- when agency accept/reject
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Only 1 request pending or accepted per property at a time
    CONSTRAINT exclude_active_property_request
        EXCLUDE USING btree (property_id WITH =)
        WHERE (status IN ('pending', 'accepted'))
);

-- ============================================================
--  TABLE: agency_reviews
--  Buyers review about agencies
--  A buyer only can review one time the agency (editable)
-- ============================================================

CREATE TABLE agency_reviews (
    id              UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    agency_user_id  UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    buyer_user_id   UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating          SMALLINT        NOT NULL CHECK (rating BETWEEN 1 AND 5),
    title           VARCHAR(100),
    body            TEXT,
    is_visible      BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     DEFAULT NULL,   -- updates at modifying

    -- A buyer only gives one review per agency (can review other agencies but just leave one review to each one)
    CONSTRAINT unique_buyer_review_agency
        UNIQUE (agency_user_id, buyer_user_id)
);

-- ============================================================
--  TABLE: email_logs
--  Register of all the sent emails by the system
-- ============================================================

CREATE TABLE email_logs (
    id                  UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    receiver_email      VARCHAR(255)    NOT NULL,
    receiver_user_id    UUID            REFERENCES users(id) ON DELETE SET NULL,
    subject             VARCHAR(150)    NOT NULL,
    template_name       VARCHAR(100),   -- ex: 'purchase_confirmed', 'review_rejected', 'account_banned'
    related_entity      VARCHAR(50),    -- ex: 'purchase_request', 'review_request', 'sell_request'
    related_id          UUID,           -- uuid-from-request
    sent_at             TIMESTAMPTZ,
    error_message       VARCHAR(200),
    success             BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- ============================================================
--  INDICES
-- ============================================================

-- Frequent searches in properties
CREATE INDEX idx_properties_agency          ON properties(agency_user_id);
CREATE INDEX idx_properties_status          ON properties(status);
CREATE INDEX idx_properties_type            ON properties(property_type);
CREATE INDEX idx_properties_city            ON properties(city);
CREATE INDEX idx_properties_price           ON properties(price);
CREATE INDEX idx_properties_published_at    ON properties(published_at DESC);
CREATE INDEX idx_properties_featured        ON properties(is_featured) WHERE is_featured = TRUE;

-- Reviews
CREATE INDEX idx_reviews_agency             ON agency_reviews(agency_user_id);
CREATE INDEX idx_reviews_buyer              ON agency_reviews(buyer_user_id);

-- Purchase requests
CREATE INDEX idx_purchase_property          ON purchase_requests(property_id);
CREATE INDEX idx_purchase_buyer             ON purchase_requests(buyer_user_id);
CREATE INDEX idx_purchase_status            ON purchase_requests(status);

-- Imeges
CREATE INDEX idx_images_property            ON property_images(property_id);

-- Email logs
CREATE INDEX idx_email_related              ON email_logs(related_entity, related_id);
CREATE INDEX idx_email_receiver             ON email_logs(receiver_user_id);

-- ============================================================
--  FUNCTION: UPDATE automatically updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all the tables with the updated_at column, each time they a row is updated/modify (only applies to the updated row, not all)
DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'users', 'buyer_profiles', 'agency_profiles',
        'properties', 'purchase_requests', 'agency_reviews'
    ] LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_%s_updated_at
             BEFORE UPDATE ON %s
             FOR EACH ROW EXECUTE FUNCTION set_updated_at();',
            t, t
        );
    END LOOP;
END;
$$;

-- ============================================================
--  VIEW: Agencies rating summary (useful for the API)
-- ============================================================

CREATE VIEW agency_rating_summary AS
SELECT
    ap.user_id                               AS agency_user_id,
    ap.agency_name,
    COUNT(r.id)                              AS total_reviews,
    ROUND(AVG(r.rating)::NUMERIC, 2)         AS avg_rating,
    COUNT(r.id) FILTER (WHERE r.rating = 5)  AS five_stars,
    COUNT(r.id) FILTER (WHERE r.rating = 4)  AS four_stars,
    COUNT(r.id) FILTER (WHERE r.rating = 3)  AS three_stars,
    COUNT(r.id) FILTER (WHERE r.rating = 2)  AS two_stars,
    COUNT(r.id) FILTER (WHERE r.rating = 1)  AS one_star
FROM agency_profiles ap
LEFT JOIN agency_reviews r
    ON r.agency_user_id = ap.user_id
    AND r.is_visible = TRUE
GROUP BY ap.user_id, ap.agency_name;

-- ============================================================
--  VIEW: Properties details (useful for the API)
-- ============================================================

CREATE VIEW property_detail AS
SELECT
    p.*,
    ap.agency_name,
    ap.logo_url         AS agency_logo,
    ap.is_verified      AS agency_verified,
    ars.avg_rating      AS agency_avg_rating,
    ars.total_reviews   AS agency_total_reviews,
    pi_cover.url        AS cover_image_url
FROM properties p
JOIN agency_profiles ap      ON ap.user_id = p.agency_user_id
LEFT JOIN agency_rating_summary ars ON ars.agency_user_id = p.agency_user_id
LEFT JOIN property_images pi_cover
    ON pi_cover.property_id = p.id AND pi_cover.display_order = 0;
