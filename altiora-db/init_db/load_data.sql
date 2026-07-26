-- ============================================================
--  load_data.sql
--  Carga los CSVs generados por create_data.py
--  Se ejecuta automáticamente después de schema.sql
--  Usa las direcciones de carpetas en el contenedor, no local
-- ============================================================

-- 1. Users (no depende de nadie)
\copy users (id, email, password, role, created_at, updated_at) FROM '/data/csv/users.csv' WITH (FORMAT csv, HEADER true);

-- 2. Buyer profiles (depende de users)
\copy buyer_profiles (user_id, first_name, last_name, phone, avatar_url, bio, country, city, created_at, updated_at) FROM '/data/csv/buyer_profiles.csv' WITH (FORMAT csv, HEADER true);

-- 3. Agency profiles (depende de users)
\copy agency_profiles (user_id, agency_name, description, website_url, phone, email_contact, country, city, address, founded_year, is_verified, created_at, updated_at) FROM '/data/csv/agency_profiles.csv' WITH (FORMAT csv, HEADER true);

-- 4. Properties (depende de agency_profiles vía agency_user_id)
\copy properties (id, agency_user_id, title, description, property_type, status, price, currency, area_m2, bedrooms, bathrooms, parking_spots, floor_number, total_floors, year_built, province, city, district, address, latitude, longitude, has_pool, has_gym, has_garden, is_featured, views_count, published_at, updated_at) FROM '/data/csv/properties.csv' WITH (FORMAT csv, HEADER true);

-- 5. Property images (depende de properties)
\copy property_images (property_id, url, display_order) FROM '/data/csv/property_images.csv' WITH (FORMAT csv, HEADER true);

-- 6. Purchase requests (depende de properties y users)
\copy purchase_requests (id, property_id, buyer_user_id, status, message, rejection_reason, price_at_request, currency_at_request, buyer_notified, agency_notified, requested_at, responded_at, created_at, updated_at) FROM '/data/csv/purchase_requests.csv' WITH (FORMAT csv, HEADER true);

-- 7. Agency reviews (depende de users, ambos roles)
\copy agency_reviews (id, agency_user_id, buyer_user_id, rating, title, body, is_visible, created_at, updated_at) FROM '/data/csv/agency_reviews.csv' WITH (FORMAT csv, HEADER true);

-- 8. Email logs (depende opcionalmente de users)
\copy email_logs (receiver_email, receiver_user_id, subject, template_name, related_entity, related_id, sent_at, error_message, success, created_at) FROM '/data/csv/email_logs.csv' WITH (FORMAT csv, HEADER true);
