-- PostgreSQL schema for ZHAKAS FASHION
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    phone TEXT,
    hashed_password TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_admin BOOLEAN DEFAULT FALSE,
    profile_image TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    description TEXT
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    price NUMERIC(12,2) NOT NULL,
    discount NUMERIC(12,2) DEFAULT 0,
    stock INTEGER DEFAULT 0,
    category_id INTEGER REFERENCES categories(id),
    images JSONB DEFAULT '[]'::jsonb,
    video_url TEXT,
    sizes JSONB DEFAULT '[]'::jsonb,
    colors JSONB DEFAULT '[]'::jsonb,
    is_featured BOOLEAN DEFAULT FALSE,
    is_trending BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE coupons (
    id SERIAL PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    discount_type TEXT NOT NULL,
    discount_value NUMERIC(12,2) NOT NULL,
    minimum_order_value NUMERIC(12,2) DEFAULT 0,
    maximum_discount NUMERIC(12,2),
    expiry_date TIMESTAMP NOT NULL,
    usage_limit INTEGER DEFAULT 0,
    per_user_limit INTEGER DEFAULT 1,
    applicable_to TEXT DEFAULT 'all',
    category TEXT,
    product_ids JSONB DEFAULT '[]'::jsonb,
    first_time_user BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    total_used INTEGER DEFAULT 0
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    status TEXT DEFAULT 'pending',
    shipping_name TEXT NOT NULL,
    shipping_address TEXT NOT NULL,
    shipping_phone TEXT NOT NULL,
    payment_proof TEXT,
    coupon_code TEXT,
    discount_amount NUMERIC(12,2) DEFAULT 0,
    total_amount NUMERIC(12,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id),
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL,
    size TEXT,
    color TEXT,
    price NUMERIC(12,2) NOT NULL
);

CREATE TABLE coupon_usages (
    id SERIAL PRIMARY KEY,
    coupon_id INTEGER REFERENCES coupons(id),
    user_id INTEGER REFERENCES users(id),
    used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE wishlists (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    product_id INTEGER REFERENCES products(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
