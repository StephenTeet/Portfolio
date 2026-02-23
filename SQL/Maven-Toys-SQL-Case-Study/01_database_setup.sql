-- ============================================================================
-- MAVEN TOYS SQL CASE STUDY
-- File: 01_database_setup.sql
-- Purpose: Create database schema and load data
-- ============================================================================

-- Create and use database
DROP DATABASE IF EXISTS maven_toys;
CREATE DATABASE maven_toys;
USE maven_toys;

-- ============================================================================
-- CREATE TABLES
-- ============================================================================

-- Products table
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    product_category VARCHAR(50) NOT NULL,
    product_cost DECIMAL(10,2) NOT NULL,
    product_price DECIMAL(10,2) NOT NULL
);

-- Stores table
CREATE TABLE stores (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    store_city VARCHAR(50) NOT NULL,
    store_location VARCHAR(50) NOT NULL,
    store_open_date DATE NOT NULL
);

-- Calendar table
CREATE TABLE calendar (
    date DATE PRIMARY KEY
);

-- Sales table
CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    date DATE NOT NULL,
    store_id INT NOT NULL,
    product_id INT NOT NULL,
    units INT NOT NULL CHECK (units > 0),
    FOREIGN KEY (date) REFERENCES calendar(date),
    FOREIGN KEY (store_id) REFERENCES stores(store_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Inventory table
CREATE TABLE inventory (
    store_id INT NOT NULL,
    product_id INT NOT NULL,
    stock_on_hand INT NOT NULL CHECK (stock_on_hand >= 0),
    PRIMARY KEY (store_id, product_id),
    FOREIGN KEY (store_id) REFERENCES stores(store_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ============================================================================
-- LOAD DATA
-- ============================================================================

-- Note: Update file paths to match your local environment
-- For CSV loading to work, you may need to adjust MySQL secure_file_priv settings

-- Load calendar data
LOAD DATA INFILE '/path/to/calendar.csv'
INTO TABLE calendar
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@date_str)
SET date = STR_TO_DATE(@date_str, '%m/%d/%Y');

-- Load stores data
LOAD DATA INFILE '/path/to/stores.csv'
INTO TABLE stores
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Load products data (remove $ and spaces from cost/price columns)
LOAD DATA INFILE '/path/to/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_name, product_category, @cost, @price)
SET 
    product_cost = CAST(REPLACE(REPLACE(@cost, '$', ''), ' ', '') AS DECIMAL(10,2)),
    product_price = CAST(REPLACE(REPLACE(@price, '$', ''), ' ', '') AS DECIMAL(10,2));

-- Load inventory data
LOAD DATA INFILE '/path/to/inventory.csv'
INTO TABLE inventory
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Load sales data
LOAD DATA INFILE '/path/to/sales.csv'
INTO TABLE sales
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ============================================================================
-- CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

-- Sales table indexes (critical for performance with 829K rows)
CREATE INDEX idx_sales_date ON sales(date);
CREATE INDEX idx_sales_store ON sales(store_id);
CREATE INDEX idx_sales_product ON sales(product_id);
CREATE INDEX idx_sales_date_store ON sales(date, store_id);

-- Inventory indexes
CREATE INDEX idx_inventory_store ON inventory(store_id);
CREATE INDEX idx_inventory_product ON inventory(product_id);

-- Stores indexes
CREATE INDEX idx_stores_city ON stores(store_city);
CREATE INDEX idx_stores_location ON stores(store_location);
CREATE INDEX idx_stores_open_date ON stores(store_open_date);

-- Products indexes
CREATE INDEX idx_products_category ON products(product_category);

-- ============================================================================
-- DATA VALIDATION CHECKS
-- ============================================================================

-- Check row counts
SELECT 'Products' AS table_name, COUNT(*) AS row_count FROM products
UNION ALL
SELECT 'Stores', COUNT(*) FROM stores
UNION ALL
SELECT 'Calendar', COUNT(*) FROM calendar
UNION ALL
SELECT 'Sales', COUNT(*) FROM sales
UNION ALL
SELECT 'Inventory', COUNT(*) FROM inventory;

-- Verify date ranges
SELECT 
    'Sales Date Range' AS check_type,
    MIN(date) AS min_date,
    MAX(date) AS max_date,
    DATEDIFF(MAX(date), MIN(date)) AS days_span
FROM sales;

-- Check for NULL values
SELECT 
    'Products NULL Check' AS check_type,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_count
FROM products
UNION ALL
SELECT 'Sales NULL Check', 
    SUM(CASE WHEN sale_id IS NULL OR date IS NULL OR store_id IS NULL 
        OR product_id IS NULL OR units IS NULL THEN 1 ELSE 0 END)
FROM sales;

-- Verify referential integrity
SELECT 'Orphan Sales Records' AS check_type, COUNT(*) AS count
FROM sales s
LEFT JOIN products p ON s.product_id = p.product_id
WHERE p.product_id IS NULL
UNION ALL
SELECT 'Orphan Inventory Records', COUNT(*)
FROM inventory i
LEFT JOIN stores st ON i.store_id = st.store_id
WHERE st.store_id IS NULL;

-- ============================================================================
-- SUMMARY STATISTICS
-- ============================================================================

SELECT 
    'Database Setup Complete' AS status,
    (SELECT COUNT(*) FROM products) AS products,
    (SELECT COUNT(*) FROM stores) AS stores,
    (SELECT COUNT(*) FROM sales) AS sales_transactions,
    (SELECT COUNT(*) FROM inventory) AS inventory_records;
