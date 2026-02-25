-- ============================================================================
-- MAVEN TOYS SQL CASE STUDY
-- File: 03_intermediate_queries.sql
-- Purpose: Intermediate SQL queries for deeper business insights
-- Skills: CTEs, Window Functions, Subqueries, CASE statements, Date Functions
-- ============================================================================

USE maven_toys;

-- ============================================================================
-- SECTION 1: PROFITABILITY ANALYSIS
-- ============================================================================

-- Query 1.1: Profit margin by product
SELECT 
    product_name,
    product_category,
    CONCAT('$', product_cost) AS cost,
    CONCAT('$', product_price) AS price,
    CONCAT('$', ROUND(product_price - product_cost, 2)) AS profit_per_unit,
    ROUND((product_price - product_cost) / product_price * 100, 2) AS margin_pct,
    CASE 
        WHEN (product_price - product_cost) / product_price > 0.50 THEN 'High Margin'
        WHEN (product_price - product_cost) / product_price > 0.30 THEN 'Medium Margin'
        ELSE 'Low Margin'
    END AS margin_category
FROM products
ORDER BY margin_pct DESC;

-- Query 1.2: Total profit by category with performance metrics
SELECT 
    p.product_category,
    COUNT(DISTINCT s.sale_id) AS transactions,
    SUM(s.units) AS units_sold,
    CONCAT('$', FORMAT(SUM(s.units * p.product_price), 2)) AS revenue,
    CONCAT('$', FORMAT(SUM(s.units * p.product_cost), 2)) AS cost,
    CONCAT('$', FORMAT(SUM(s.units * (p.product_price - p.product_cost)), 2)) AS profit,
    ROUND(SUM(s.units * (p.product_price - p.product_cost)) / 
          SUM(s.units * p.product_price) * 100, 2) AS profit_margin_pct
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_category
ORDER BY SUM(s.units * (p.product_price - p.product_cost)) DESC;

-- Query 1.3: Monthly revenue and profit trends with growth
WITH monthly_performance AS (
    SELECT 
        DATE_FORMAT(s.date, '%Y-%m') AS month,
        SUM(s.units * p.product_price) AS revenue,
        SUM(s.units * p.product_cost) AS cost,
        SUM(s.units * (p.product_price - p.product_cost)) AS profit
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY DATE_FORMAT(s.date, '%Y-%m')
)
SELECT 
    month,
    CONCAT('$', FORMAT(revenue, 2)) AS revenue,
    CONCAT('$', FORMAT(profit, 2)) AS profit,
    ROUND(profit / revenue * 100, 2) AS margin_pct,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY month)) / 
          LAG(revenue) OVER (ORDER BY month) * 100, 2) AS revenue_growth_pct,
    ROUND((profit - LAG(profit) OVER (ORDER BY month)) / 
          LAG(profit) OVER (ORDER BY month) * 100, 2) AS profit_growth_pct
FROM monthly_performance
ORDER BY month;

-- Query 1.4: Product profitability ranking
WITH product_profit AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.product_category,
        SUM(s.units) AS units_sold,
        SUM(s.units * p.product_price) AS revenue,
        SUM(s.units * (p.product_price - p.product_cost)) AS profit
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY p.product_id, p.product_name, p.product_category
)
SELECT 
    product_name,
    product_category,
    units_sold,
    CONCAT('$', FORMAT(revenue, 2)) AS revenue,
    CONCAT('$', FORMAT(profit, 2)) AS profit,
    RANK() OVER (ORDER BY profit DESC) AS profit_rank,
    ROUND(profit * 100.0 / SUM(profit) OVER (), 2) AS pct_of_total_profit
FROM product_profit
ORDER BY profit DESC
LIMIT 15;

-- ============================================================================
-- SECTION 2: SEASONAL AND TREND ANALYSIS
-- ============================================================================

-- Query 2.1: Quarter-over-quarter performance
WITH quarterly_sales AS (
    SELECT 
        YEAR(s.date) AS year,
        QUARTER(s.date) AS quarter,
        SUM(s.units * p.product_price) AS revenue,
        SUM(s.units) AS units_sold
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY YEAR(s.date), QUARTER(s.date)
)
SELECT 
    CONCAT(year, '-Q', quarter) AS period,
    CONCAT('$', FORMAT(revenue, 2)) AS revenue,
    units_sold,
    CONCAT('$', FORMAT(LAG(revenue) OVER (ORDER BY year, quarter), 2)) AS prev_quarter_revenue,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY year, quarter)) / 
          LAG(revenue) OVER (ORDER BY year, quarter) * 100, 2) AS qoq_growth_pct
FROM quarterly_sales
ORDER BY year, quarter;

-- Query 2.2: Year-over-year comparison by month
WITH monthly_sales AS (
    SELECT 
        YEAR(s.date) AS year,
        MONTH(s.date) AS month,
        MONTHNAME(s.date) AS month_name,
        SUM(s.units * p.product_price) AS revenue
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY YEAR(s.date), MONTH(s.date), MONTHNAME(s.date)
)
SELECT 
    month_name,
    CONCAT('$', FORMAT(MAX(CASE WHEN year = 2022 THEN revenue END), 2)) AS revenue_2022,
    CONCAT('$', FORMAT(MAX(CASE WHEN year = 2023 THEN revenue END), 2)) AS revenue_2023,
    ROUND((MAX(CASE WHEN year = 2023 THEN revenue END) - 
           MAX(CASE WHEN year = 2022 THEN revenue END)) * 100.0 /
          MAX(CASE WHEN year = 2022 THEN revenue END), 2) AS yoy_growth_pct
FROM monthly_sales
GROUP BY month, month_name
ORDER BY month;

-- Query 2.3: Moving averages for trend smoothing
SELECT 
    DATE_FORMAT(s.date, '%Y-%m') AS month,
    SUM(s.units * p.product_price) AS monthly_revenue,
    ROUND(AVG(SUM(s.units * p.product_price)) OVER (
        ORDER BY DATE_FORMAT(s.date, '%Y-%m')
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS three_month_avg,
    ROUND(AVG(SUM(s.units * p.product_price)) OVER (
        ORDER BY DATE_FORMAT(s.date, '%Y-%m')
        ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
    ), 2) AS six_month_avg
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY DATE_FORMAT(s.date, '%Y-%m')
ORDER BY month;

-- Query 2.4: Best and worst performing months
SELECT 
    DATE_FORMAT(s.date, '%Y-%m') AS month,
    MONTHNAME(s.date) AS month_name,
    SUM(s.units * p.product_price) AS revenue,
    SUM(s.units) AS units_sold,
    COUNT(DISTINCT s.sale_id) AS transactions,
    RANK() OVER (ORDER BY SUM(s.units * p.product_price) DESC) AS revenue_rank
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY DATE_FORMAT(s.date, '%Y-%m'), MONTHNAME(s.date)
ORDER BY revenue DESC;

-- ============================================================================
-- SECTION 3: CATEGORY DEEP DIVE
-- ============================================================================

-- Query 3.1: Category performance by store location type
SELECT 
    st.store_location,
    p.product_category,
    COUNT(DISTINCT s.sale_id) AS transactions,
    SUM(s.units) AS units_sold,
    CONCAT('$', FORMAT(SUM(s.units * p.product_price), 2)) AS revenue,
    ROUND(SUM(s.units * p.product_price) * 100.0 / 
          SUM(SUM(s.units * p.product_price)) OVER (PARTITION BY st.store_location), 2) AS pct_of_location_revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN stores st ON s.store_id = st.store_id
GROUP BY st.store_location, p.product_category
ORDER BY st.store_location, revenue DESC;

-- Query 3.2: Top 3 products per category
WITH product_revenue AS (
    SELECT 
        p.product_category,
        p.product_name,
        SUM(s.units * p.product_price) AS revenue,
        RANK() OVER (PARTITION BY p.product_category ORDER BY SUM(s.units * p.product_price) DESC) AS rank_in_category
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY p.product_category, p.product_name, p.product_id
)
SELECT 
    product_category,
    product_name,
    CONCAT('$', FORMAT(revenue, 2)) AS revenue,
    rank_in_category
FROM product_revenue
WHERE rank_in_category <= 3
ORDER BY product_category, rank_in_category;

-- Query 3.3: Category mix by city
SELECT 
    st.store_city,
    p.product_category,
    SUM(s.units * p.product_price) AS revenue,
    ROUND(SUM(s.units * p.product_price) * 100.0 / 
          SUM(SUM(s.units * p.product_price)) OVER (PARTITION BY st.store_city), 2) AS pct_of_city_revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN stores st ON s.store_id = st.store_id
GROUP BY st.store_city, p.product_category
HAVING SUM(s.units * p.product_price) > 10000
ORDER BY st.store_city, revenue DESC;

-- ============================================================================
-- SECTION 4: CUSTOMER BEHAVIOR METRICS
-- ============================================================================

-- Query 4.1: Average basket size by store
WITH daily_baskets AS (
    SELECT 
        s.date,
        s.store_id,
        SUM(s.units * p.product_price) AS basket_value,
        SUM(s.units) AS items_in_basket
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY s.date, s.store_id
)
SELECT 
    st.store_name,
    st.store_city,
    COUNT(*) AS transaction_days,
    CONCAT('$', ROUND(AVG(db.basket_value), 2)) AS avg_basket_value,
    ROUND(AVG(db.items_in_basket), 2) AS avg_items_per_basket,
    CONCAT('$', ROUND(MIN(db.basket_value), 2)) AS min_basket,
    CONCAT('$', ROUND(MAX(db.basket_value), 2)) AS max_basket
FROM daily_baskets db
JOIN stores st ON db.store_id = st.store_id
GROUP BY st.store_id, st.store_name, st.store_city
ORDER BY AVG(db.basket_value) DESC
LIMIT 15;

-- Query 4.2: Purchase frequency patterns
SELECT 
    DAYNAME(date) AS day_of_week,
    HOUR(date) AS hour_if_available,
    COUNT(DISTINCT sale_id) AS transactions,
    SUM(units) AS units_sold,
    ROUND(AVG(units), 2) AS avg_units_per_transaction
FROM sales
GROUP BY DAYNAME(date), DAYOFWEEK(date)
ORDER BY DAYOFWEEK(date);

-- Query 4.3: Multi-item transaction analysis
WITH transaction_items AS (
    SELECT 
        date,
        store_id,
        COUNT(DISTINCT product_id) AS unique_products,
        SUM(units) AS total_items
    FROM sales
    GROUP BY date, store_id
)
SELECT 
    CASE 
        WHEN unique_products = 1 THEN 'Single Product'
        WHEN unique_products BETWEEN 2 AND 3 THEN '2-3 Products'
        WHEN unique_products BETWEEN 4 AND 5 THEN '4-5 Products'
        ELSE '6+ Products'
    END AS basket_size,
    COUNT(*) AS transaction_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_transactions,
    ROUND(AVG(total_items), 2) AS avg_total_items
FROM transaction_items
GROUP BY 
    CASE 
        WHEN unique_products = 1 THEN 'Single Product'
        WHEN unique_products BETWEEN 2 AND 3 THEN '2-3 Products'
        WHEN unique_products BETWEEN 4 AND 5 THEN '4-5 Products'
        ELSE '6+ Products'
    END
ORDER BY transaction_count DESC;

-- ============================================================================
-- SECTION 5: STORE COMPARISON AND BENCHMARKING
-- ============================================================================

-- Query 5.1: Store performance vs city average
WITH city_avg AS (
    SELECT 
        st.store_city,
        AVG(s.units * p.product_price) AS avg_city_revenue
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    JOIN stores st ON s.store_id = st.store_id
    GROUP BY st.store_city
),
store_revenue AS (
    SELECT 
        st.store_id,
        st.store_name,
        st.store_city,
        SUM(s.units * p.product_price) AS store_revenue
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    JOIN stores st ON s.store_id = st.store_id
    GROUP BY st.store_id, st.store_name, st.store_city
)
SELECT 
    sr.store_name,
    sr.store_city,
    CONCAT('$', FORMAT(sr.store_revenue, 2)) AS revenue,
    CONCAT('$', FORMAT(ca.avg_city_revenue, 2)) AS city_avg_revenue,
    ROUND((sr.store_revenue - ca.avg_city_revenue) * 100.0 / ca.avg_city_revenue, 2) AS vs_city_avg_pct,
    CASE 
        WHEN sr.store_revenue > ca.avg_city_revenue * 1.2 THEN 'Outperformer'
        WHEN sr.store_revenue < ca.avg_city_revenue * 0.8 THEN 'Underperformer'
        ELSE 'Average'
    END AS performance_category
FROM store_revenue sr
JOIN city_avg ca ON sr.store_city = ca.store_city
ORDER BY sr.store_city, sr.store_revenue DESC;

-- Query 5.2: Store age vs performance correlation
SELECT 
    CASE 
        WHEN TIMESTAMPDIFF(YEAR, st.store_open_date, CURDATE()) < 5 THEN '0-5 years'
        WHEN TIMESTAMPDIFF(YEAR, st.store_open_date, CURDATE()) < 10 THEN '5-10 years'
        WHEN TIMESTAMPDIFF(YEAR, st.store_open_date, CURDATE()) < 15 THEN '10-15 years'
        ELSE '15+ years'
    END AS age_group,
    COUNT(DISTINCT st.store_id) AS store_count,
    CONCAT('$', FORMAT(AVG(revenue), 2)) AS avg_revenue,
    CONCAT('$', FORMAT(MIN(revenue), 2)) AS min_revenue,
    CONCAT('$', FORMAT(MAX(revenue), 2)) AS max_revenue
FROM stores st
JOIN (
    SELECT 
        store_id,
        SUM(s.units * p.product_price) AS revenue
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY store_id
) rev ON st.store_id = rev.store_id
GROUP BY 
    CASE 
        WHEN TIMESTAMPDIFF(YEAR, st.store_open_date, CURDATE()) < 5 THEN '0-5 years'
        WHEN TIMESTAMPDIFF(YEAR, st.store_open_date, CURDATE()) < 10 THEN '5-10 years'
        WHEN TIMESTAMPDIFF(YEAR, st.store_open_date, CURDATE()) < 15 THEN '10-15 years'
        ELSE '15+ years'
    END
ORDER BY AVG(revenue) DESC;

-- Query 5.3: Location type performance by category
SELECT 
    st.store_location,
    p.product_category,
    SUM(s.units * p.product_price) AS revenue,
    RANK() OVER (PARTITION BY st.store_location ORDER BY SUM(s.units * p.product_price) DESC) AS category_rank,
    ROUND(SUM(s.units * p.product_price) * 100.0 / 
          SUM(SUM(s.units * p.product_price)) OVER (PARTITION BY st.store_location), 2) AS pct_of_location
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN stores st ON s.store_id = st.store_id
GROUP BY st.store_location, p.product_category
ORDER BY st.store_location, revenue DESC;

-- ============================================================================
-- END OF INTERMEDIATE QUERIES
-- ============================================================================
