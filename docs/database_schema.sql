-- ============================================================
-- ESQUEMA DE BASE DE DATOS - INVENTORY APP
-- ============================================================
-- Sistema de Gestión de Inventario Multi-tienda
-- Base de datos: SQLite (Drift/Moor)
-- ============================================================

PRAGMA foreign_keys = ON;

-- ==================== USUARIOS Y ROLES ====================

CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE CHECK(length(username) >= 3 AND length(username) <= 30),
    password_hash TEXT NOT NULL CHECK(length(password_hash) >= 60),
    full_name TEXT NOT NULL CHECK(length(full_name) >= 1 AND length(full_name) <= 100),
    email TEXT UNIQUE CHECK(length(email) <= 100),
    phone TEXT CHECK(length(phone) <= 20),
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    last_sync_at TEXT,
    store_id INTEGER REFERENCES stores(id) ON DELETE SET NULL,
    warehouse_id INTEGER REFERENCES warehouses(id) ON DELETE SET NULL
);

CREATE TABLE roles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT NOT NULL UNIQUE CHECK(length(code) >= 1 AND length(code) <= 50),
    name TEXT NOT NULL CHECK(length(name) >= 1 AND length(name) <= 100),
    description TEXT CHECK(length(description) <= 500),
    permissions_json TEXT NOT NULL DEFAULT '[]',
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE user_roles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    store_id INTEGER REFERENCES stores(id) ON DELETE SET NULL,
    warehouse_id INTEGER REFERENCES warehouses(id) ON DELETE SET NULL,
    is_primary INTEGER NOT NULL DEFAULT 0,
    assigned_at TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(user_id, role_id, store_id, warehouse_id)
);

-- ==================== UBICACIONES ====================

CREATE TABLE stores (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT NOT NULL UNIQUE CHECK(length(code) >= 1 AND length(code) <= 20),
    name TEXT NOT NULL CHECK(length(name) >= 1 AND length(name) <= 100),
    address TEXT NOT NULL CHECK(length(address) <= 255),
    phone TEXT CHECK(length(phone) <= 20),
    email TEXT CHECK(length(email) <= 100),
    manager_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    latitude REAL,
    longitude REAL,
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    last_sync_at TEXT
);

CREATE TABLE warehouses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT NOT NULL UNIQUE CHECK(length(code) >= 1 AND length(code) <= 20),
    name TEXT NOT NULL CHECK(length(name) >= 1 AND length(name) <= 100),
    address TEXT NOT NULL CHECK(length(address) <= 255),
    phone TEXT CHECK(length(phone) <= 20),
    email TEXT CHECK(length(email) <= 100),
    manager_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    latitude REAL,
    longitude REAL,
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    last_sync_at TEXT
);

-- ==================== PRODUCTOS ====================

CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT NOT NULL UNIQUE CHECK(length(code) >= 1 AND length(code) <= 50),
    name TEXT NOT NULL CHECK(length(name) >= 1 AND length(name) <= 200),
    description TEXT CHECK(length(description) <= 1000),
    brand TEXT CHECK(length(brand) <= 100),
    category TEXT NOT NULL CHECK(length(category) <= 50),
    base_price REAL NOT NULL DEFAULT 0.0,
    cost_price REAL NOT NULL DEFAULT 0.0,
    image_url TEXT CHECK(length(image_url) <= 500),
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    last_sync_at TEXT
);

CREATE TABLE product_variants (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    sku TEXT NOT NULL UNIQUE CHECK(length(sku) >= 1 AND length(sku) <= 100),
    size TEXT CHECK(length(size) <= 20),
    color TEXT CHECK(length(color) <= 50),
    barcode TEXT UNIQUE CHECK(length(barcode) <= 50),
    additional_price REAL NOT NULL DEFAULT 0.0,
    notes TEXT CHECK(length(notes) <= 500),
    image_url TEXT CHECK(length(image_url) <= 500),
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    last_sync_at TEXT
);

-- ==================== INVENTARIO ====================

CREATE TABLE inventory (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_variant_id INTEGER NOT NULL REFERENCES product_variants(id) ON DELETE CASCADE,
    location_type TEXT NOT NULL CHECK(length(location_type) <= 20),
    location_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    min_stock INTEGER NOT NULL DEFAULT 0,
    max_stock INTEGER NOT NULL DEFAULT 1000,
    last_updated TEXT NOT NULL DEFAULT (datetime('now')),
    updated_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    last_sync_at TEXT,
    UNIQUE(product_variant_id, location_type, location_id)
);

CREATE TABLE inventory_movements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_variant_id INTEGER NOT NULL REFERENCES product_variants(id) ON DELETE CASCADE,
    location_type TEXT NOT NULL CHECK(length(location_type) <= 20),
    location_id INTEGER NOT NULL,
    movement_type TEXT NOT NULL CHECK(length(movement_type) <= 30),
    reference_type TEXT CHECK(length(reference_type) <= 30),
    reference_id INTEGER,
    quantity_change INTEGER NOT NULL,
    quantity_before INTEGER NOT NULL,
    quantity_after INTEGER NOT NULL,
    notes TEXT CHECK(length(notes) <= 500),
    created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    last_sync_at TEXT
);

-- ==================== VENTAS ====================

CREATE TABLE sales (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sale_number TEXT NOT NULL UNIQUE CHECK(length(sale_number) >= 1 AND length(sale_number) <= 50),
    store_id INTEGER NOT NULL REFERENCES stores(id) ON DELETE RESTRICT,
    customer_name TEXT CHECK(length(customer_name) <= 200),
    customer_document TEXT CHECK(length(customer_document) <= 20),
    customer_phone TEXT CHECK(length(customer_phone) <= 20),
    customer_email TEXT CHECK(length(customer_email) <= 100),
    sale_date TEXT NOT NULL,
    subtotal REAL NOT NULL DEFAULT 0.0,
    discount REAL NOT NULL DEFAULT 0.0,
    tax REAL NOT NULL DEFAULT 0.0,
    total REAL NOT NULL DEFAULT 0.0,
    payment_method TEXT NOT NULL CHECK(length(payment_method) <= 20),
    cash_amount REAL,
    card_amount REAL,
    notes TEXT CHECK(length(notes) <= 1000),
    status TEXT NOT NULL DEFAULT 'COMPLETED' CHECK(length(status) <= 20),
    created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    last_sync_at TEXT
);

CREATE TABLE sale_details (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sale_id INTEGER NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    product_variant_id INTEGER NOT NULL REFERENCES product_variants(id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL,
    unit_price REAL NOT NULL,
    discount REAL NOT NULL DEFAULT 0.0,
    subtotal REAL NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    last_sync_at TEXT
);

-- ==================== COMPRAS ====================

CREATE TABLE purchases (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    purchase_number TEXT NOT NULL UNIQUE CHECK(length(purchase_number) >= 1 AND length(purchase_number) <= 50),
    supplier_name TEXT NOT NULL CHECK(length(supplier_name) >= 1 AND length(supplier_name) <= 200),
    supplier_ruc TEXT CHECK(length(supplier_ruc) <= 20),
    supplier_phone TEXT CHECK(length(supplier_phone) <= 20),
    supplier_email TEXT CHECK(length(supplier_email) <= 100),
    warehouse_id INTEGER NOT NULL REFERENCES warehouses(id) ON DELETE RESTRICT,
    purchase_date TEXT NOT NULL,
    total_amount REAL NOT NULL DEFAULT 0.0,
    notes TEXT CHECK(length(notes) <= 1000),
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK(length(status) <= 20),
    created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    last_sync_at TEXT
);

CREATE TABLE purchase_details (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    purchase_id INTEGER NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
    product_variant_id INTEGER NOT NULL REFERENCES product_variants(id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL,
    unit_cost REAL NOT NULL,
    subtotal REAL NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    last_sync_at TEXT
);

-- ==================== TRANSFERENCIAS ====================

CREATE TABLE transfers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    transfer_number TEXT NOT NULL UNIQUE CHECK(length(transfer_number) >= 1 AND length(transfer_number) <= 50),
    from_type TEXT NOT NULL CHECK(length(from_type) <= 20),
    from_id INTEGER NOT NULL,
    to_type TEXT NOT NULL CHECK(length(to_type) <= 20),
    to_id INTEGER NOT NULL,
    transfer_date TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK(length(status) <= 20),
    notes TEXT CHECK(length(notes) <= 1000),
    created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    approved_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    approved_at TEXT,
    received_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    received_at TEXT,
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    last_sync_at TEXT
);

CREATE TABLE transfer_details (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    transfer_id INTEGER NOT NULL REFERENCES transfers(id) ON DELETE CASCADE,
    product_variant_id INTEGER NOT NULL REFERENCES product_variants(id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL,
    received_quantity INTEGER,
    notes TEXT CHECK(length(notes) <= 500),
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    last_sync_at TEXT
);

-- ==================== SINCRONIZACIÓN ====================

CREATE TABLE sync_queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    table_name TEXT NOT NULL CHECK(length(table_name) <= 50),
    record_id INTEGER NOT NULL,
    operation TEXT NOT NULL CHECK(length(operation) <= 20),
    data TEXT,
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK(length(status) <= 20),
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    processed_at TEXT
);

-- ==================== ÍNDICES ====================

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_store_id ON users(store_id);
CREATE INDEX idx_users_warehouse_id ON users(warehouse_id);

CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role_id ON user_roles(role_id);

CREATE INDEX idx_products_code ON products(code);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_brand ON products(brand);

CREATE INDEX idx_product_variants_product_id ON product_variants(product_id);
CREATE INDEX idx_product_variants_sku ON product_variants(sku);
CREATE INDEX idx_product_variants_barcode ON product_variants(barcode);

CREATE INDEX idx_inventory_variant_location ON inventory(product_variant_id, location_type, location_id);
CREATE INDEX idx_inventory_location ON inventory(location_type, location_id);

CREATE INDEX idx_inventory_movements_variant ON inventory_movements(product_variant_id);
CREATE INDEX idx_inventory_movements_location ON inventory_movements(location_type, location_id);
CREATE INDEX idx_inventory_movements_date ON inventory_movements(created_at);

CREATE INDEX idx_sales_store_id ON sales(store_id);
CREATE INDEX idx_sales_sale_date ON sales(sale_date);
CREATE INDEX idx_sales_status ON sales(status);
CREATE INDEX idx_sales_customer_name ON sales(customer_name);

CREATE INDEX idx_sale_details_sale_id ON sale_details(sale_id);
CREATE INDEX idx_sale_details_variant_id ON sale_details(product_variant_id);

CREATE INDEX idx_purchases_warehouse_id ON purchases(warehouse_id);
CREATE INDEX idx_purchases_purchase_date ON purchases(purchase_date);
CREATE INDEX idx_purchases_status ON purchases(status);

CREATE INDEX idx_purchase_details_purchase_id ON purchase_details(purchase_id);

CREATE INDEX idx_transfers_from ON transfers(from_type, from_id);
CREATE INDEX idx_transfers_to ON transfers(to_type, to_id);
CREATE INDEX idx_transfers_status ON transfers(status);
CREATE INDEX idx_transfers_date ON transfers(transfer_date);

CREATE INDEX idx_transfer_details_transfer_id ON transfer_details(transfer_id);

CREATE INDEX idx_sync_queue_status ON sync_queue(status);
CREATE INDEX idx_sync_queue_table ON sync_queue(table_name);

-- ============================================================
-- FIN DEL ESQUEMA
-- ============================================================
