-- ============================================================================
-- MAVEN TOYS SQL CASE STUDY
-- File: 02_beginner_queries.sql
-- Purpose: Basic SQL queries for foundational analysis
-- Skills: SELECT, WHERE, GROUP BY, ORDER BY, JOINs, Basic Aggregations
-- ============================================================================

USE maven_toys;

-- ============================================================================
-- SECTION 1: BASIC DATA EXPLORATION
-- ============================================================================

-- Query 1.1: View all product categories
SELECT DISTINCT product_category
FROM products
ORDER BY product_category;

-- Query 1.2: Count products by category
SELECT 
    product_category,
    COUNT(*) AS product_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM products), 2) AS percentage
FROM products
GROUP BY product_category
ORDER BY product_count DESC;

-- Query 1.3: Price range by category
SELECT 
    product_category,
    COUNT(*) AS products,
    CONCAT('$', MIN(product_price)) AS min_price,
    CONCAT('$', MAX(product_price)) AS max_price,
    CONCAT('$', ROUND(AVG(product_price), 2)) AS avg_price
FROM products
GROUP BY product_category
ORDER BY avg_price DESC;

-- Query 1.4: Most and least expensive products
(SELECT 'Most Expensive' AS type, product_name, product_category, product_price
FROM products
ORDER BY product_price DESC
LIMIT 5)
UNION ALL
(SELECT 'Least Expensive', product_name, product_category, product_price
FROM products
ORDER BY product_price ASC
LIMIT 5);

-- ============================================================================
-- SECTION 2: STORE ANALYSIS
-- ============================================================================

-- Query 2.1: Stores by city
SELECT 
    store_city,
    COUNT(*) AS store_count
FROM stores
GROUP BY store_city
HAVING store_count > 1
ORDER BY store_count DESC;

-- Query 2.2: Store distribution by location type
SELECT 
    store_location,
    COUNT(*) AS store_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM stores), 2) AS percentage
FROM stores
GROUP BY store_location
ORDER BY store_count DESC;

-- Query 2.3: Newest and oldest stores
(SELECT 'Newest' AS type, store_name, store_city, store_open_date,
    TIMESTAMPDIFF(YEAR, store_open_date, CURDATE()) AS years_open
FROM stores
ORDER BY store_open_date DESC
LIMIT 5)
UNION ALL
(SELECT 'Oldest', store_name, store_city, store_open_date,
    TIMESTAMPDIFF(YEAR, store_open_date, CURDATE())
FROM stores
ORDER BY store_open_date ASC
LIMIT 5);

-- Query 2.4: Stores opened by year
SELECT 
    YEAR(store_open_date) AS year,
    COUNT(*) AS stores_opened,
    SUM(COUNT(*)) OVER (ORDER BY YEAR(store_open_date)) AS cumulative_stores
FROM stores
GROUP BY YEAR(store_open_date)
ORDER BY year;

-- ============================================================================
-- SECTION 3: SALES OVERVIEW
-- ============================================================================

-- Query 3.1: Total sales volume and revenue
SELECT 
    COUNT(DISTINCT sale_id) AS total_transactions,
    SUM(units) AS total_units_sold,
    CONCAT('$', FORMAT(SUM(s.units * p.product_price), 2)) AS total_revenue,
    CONCAT('$', FORMAT(AVG(s.units * p.product_price), 2)) AS avg_transaction_value
FROM sales s
JOIN products p ON s.product_id = p.product_id;

-- Query 3.2: Sales by product category
SELECT 
    p.product_category,
    COUNT(DISTINCT s.sale_id) AS transactions,
    SUM(s.units) AS units_sold,
    CONCAT('$', FORMAT(SUM(s.units * p.product_price), 2)) AS revenue,
    ROUND(SUM(s.units * p.product_price) * 100.0 / 
        (SELECT SUM(s2.units * p2.product_price) FROM sales s2 
         JOIN products p2 ON s2.product_id = p2.product_id), 2) AS revenue_pct
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_category
ORDER BY SUM(s.units * p.product_price) DESC;

-- Query 3.3: Top 10 best-selling products by units
SELECT 
    p.product_name,
    p.product_category,
    SUM(s.units) AS units_sold,
    COUNT(DISTINCT s.sale_id) AS transactions,
    CONCAT('$', FORMAT(SUM(s.units * p.product_price), 2)) AS revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.product_category
ORDER BY units_sold DESC
LIMIT 10;

-- Query 3.4: Top 10 products by revenue
SELECT 
    p.product_name,
    p.product_category,
    SUM(s.units) AS units_sold,
    CONCAT('$', FORMAT(SUM(s.units * p.product_price), 2)) AS revenue,
    CONCAT('$', FORMAT(AVG(p.product_price), 2)) AS avg_price
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.product_category
ORDER BY SUM(s.units * p.product_price) DESC
LIMIT 10;

-- Query 3.5: Products with no sales
SELECT 
    p.product_name,
    p.product_category,
    p.product_price
FROM products p
LEFT JOIN sales s ON p.product_id = s.product_id
WHERE s.sale_id IS NULL;

-- ============================================================================
-- SECTION 4: TIME-BASED ANALYSIS
-- ============================================================================

-- Query 4.1: Sales by month
SELECT 
    DATE_FORMAT(s.date, '%Y-%m') AS month,
    COUNT(DISTINCT s.sale_id) AS transactions,
    SUM(s.units) AS units_sold,
    CONCAT('$', FORMAT(SUM(s.units * p.product_price), 2)) AS revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY DATE_FORMAT(s.date, '%Y-%m')
ORDER BY month;

-- Query 4.2: Sales by day of week
SELECT 
    DAYNAME(date) AS day_of_week,
    COUNT(DISTINCT sale_id) AS transactions,
    SUM(units) AS units_sold,
    CONCAT('$', FORMAT(SUM(s.units * p.product_price), 2)) AS revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY DAYNAME(date), DAYOFWEEK(date)
ORDER BY DAYOFWEEK(date);

-- Query 4.3: Busiest sales days
SELECT 
    s.date,
    DAYNAME(s.date) AS day_of_week,
    COUNT(DISTINCT s.sale_id) AS transactions,
    SUM(s.units) AS units_sold,
    CONCAT('$', FORMAT(SUM(s.units * p.product_price), 2)) AS revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY s.date, DAYNAME(s.date)
ORDER BY SUM(s.units * p.product_price) DESC
LIMIT 10;

-- Query 4.4: Monthly growth comparison
SELECT 
    DATE_FORMAT(s.date, '%Y-%m') AS month,
    SUM(s.units * p.product_price) AS revenue,
    LAG(SUM(s.units * p.product_price)) OVER (ORDER BY DATE_FORMAT(s.date, '%Y-%m')) AS prev_month_revenue,
    ROUND((SUM(s.units * p.product_price) - 
           LAG(SUM(s.units * p.product_price)) OVER (ORDER BY DATE_FORMAT(s.date, '%Y-%m'))) * 100.0 /
          LAG(SUM(s.units * p.product_price)) OVER (ORDER BY DATE_FORMAT(s.date, '%Y-%m')), 2) AS growth_pct
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY DATE_FORMAT(s.date, '%Y-%m')
ORDER BY month;

-- ============================================================================
-- SECTION 5: INVENTORY BASICS
-- ============================================================================

-- Query 5.1: Total inventory value
SELECT 
    CONCAT('$', FORMAT(SUM(i.stock_on_hand * p.product_cost), 2)) AS total_inventory_cost,
    CONCAT('$', FORMAT(SUM(i.stock_on_hand * p.product_price), 2)) AS total_inventory_value,
    SUM(i.stock_on_hand) AS total_units_in_stock
FROM inventory i
JOIN products p ON i.product_id = p.product_id;

-- Query 5.2: Inventory by category
SELECT 
    p.product_category,
    SUM(i.stock_on_hand) AS units_in_stock,
    CONCAT('$', FORMAT(SUM(i.stock_on_hand * p.product_cost), 2)) AS inventory_cost,
    CONCAT('$', FORMAT(SUM(i.stock_on_hand * p.product_price), 2)) AS inventory_value
FROM inventory i
JOIN products p ON i.product_id = p.product_id
GROUP BY p.product_category
ORDER BY SUM(i.stock_on_hand) DESC;

-- Query 5.3: Products with zero stock across all stores
SELECT 
    p.product_name,
    p.product_category,
    COUNT(*) AS stores_out_of_stock
FROM inventory i
JOIN products p ON i.product_id = p.product_id
WHERE i.stock_on_hand = 0
GROUP BY p.product_id, p.product_name, p.product_category
ORDER BY stores_out_of_stock DESC;

-- Query 5.4: Stores with most stockouts
SELECT 
    st.store_name,
    st.store_city,
    COUNT(*) AS products_out_of_stock,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT product_id) FROM products), 2) AS stockout_pct
FROM inventory i
JOIN stores st ON i.store_id = st.store_id
WHERE i.stock_on_hand = 0
GROUP BY st.store_id, st.store_name, st.store_city
ORDER BY products_out_of_stock DESC
LIMIT 10;

-- Query 5.5: Average inventory per store by category
SELECT 
    p.product_category,
    ROUND(AVG(i.stock_on_hand), 2) AS avg_stock_per_store,
    MIN(i.stock_on_hand) AS min_stock,
    MAX(i.stock_on_hand) AS max_stock
FROM inventory i
JOIN products p ON i.product_id = p.product_id
GROUP BY p.product_category
ORDER BY avg_stock_per_store DESC;

-- ============================================================================
-- SECTION 6: SIMPLE STORE PERFORMANCE
-- ============================================================================

-- Query 6.1: Top 10 stores by revenue
SELECT 
    st.store_name,
    st.store_city,
    st.store_location,
    COUNT(DISTINCT s.sale_id) AS transactions,
    SUM(s.units) AS units_sold,
    CONCAT('$', FORMAT(SUM(s.units * p.product_price), 2)) AS revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN stores st ON s.store_id = st.store_id
GROUP BY st.store_id, st.store_name, st.store_city, st.store_location
ORDER BY SUM(s.units * p.product_price) DESC
LIMIT 10;

-- Query 6.2: Bottom 10 stores by revenue
SELECT 
    st.store_name,
    st.store_city,
    st.store_location,
    COUNT(DISTINCT s.sale_id) AS transactions,
    SUM(s.units) AS units_sold,
    CONCAT('$', FORMAT(SUM(s.units * p.product_price), 2)) AS revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN stores st ON s.store_id = st.store_id
GROUP BY st.store_id, st.store_name, st.store_city, st.store_location
ORDER BY SUM(s.units * p.product_price) ASC
LIMIT 10;

-- Query 6.3: Store performance by location type
SELECT 
    st.store_location,
    COUNT(DISTINCT st.store_id) AS stores,
    COUNT(DISTINCT s.sale_id) AS total_transactions,
    SUM(s.units) AS total_units,
    CONCAT('$', FORMAT(SUM(s.units * p.product_price), 2)) AS total_revenue,
    CONCAT('$', FORMAT(SUM(s.units * p.product_price) / COUNT(DISTINCT st.store_id), 2)) AS avg_revenue_per_store
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN stores st ON s.store_id = st.store_id
GROUP BY st.store_location
ORDER BY SUM(s.units * p.product_price) DESC;

-- Query 6.4: City performance comparison
SELECT 
    st.store_city,
    COUNT(DISTINCT st.store_id) AS stores,
    CONCAT('$', FORMAT(SUM(s.units * p.product_price), 2)) AS total_revenue,
    CONCAT('$', FORMAT(SUM(s.units * p.product_price) / COUNT(DISTINCT st.store_id), 2)) AS revenue_per_store
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN stores st ON s.store_id = st.store_id
GROUP BY st.store_city
ORDER BY SUM(s.units * p.product_price) / COUNT(DISTINCT st.store_id) DESC
LIMIT 15;

-- ============================================================================
-- END OF BEGINNER QUERIES
-- ============================================================================
