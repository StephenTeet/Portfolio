# Maven Toys SQL Case Study
## Business Analytics Portfolio Project

---

## 📊 Executive Summary

This case study analyzes sales, inventory, and store performance data from Maven Toys, a toy store chain with 50 locations across Mexico. The dataset contains 829,000+ sales transactions from 2022-2023, covering 35 products across 5 categories.

**Key Business Questions Explored:**
- Revenue and profitability analysis
- Product performance and category trends
- Store location optimization
- Inventory management efficiency
- Seasonal patterns and forecasting

---

## 🗄️ Database Schema

### Entity Relationship Diagram

```
Products (35 products)
├── Product_ID (PK)
├── Product_Name
├── Product_Category
├── Product_Cost
└── Product_Price

Stores (50 stores)
├── Store_ID (PK)
├── Store_Name
├── Store_City
├── Store_Location
└── Store_Open_Date

Sales (829,000+ transactions)
├── Sale_ID (PK)
├── Date (FK → Calendar)
├── Store_ID (FK → Stores)
├── Product_ID (FK → Products)
└── Units

Inventory (1,594 records)
├── Store_ID (FK → Stores)
├── Product_ID (FK → Products)
└── Stock_On_Hand

Calendar (639 dates)
└── Date (PK)
```

---

## 🛠️ Database Setup

### Step 1: Create Database and Tables

```sql
-- Create database
CREATE DATABASE maven_toys;
USE maven_toys;

-- Products table
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    product_category VARCHAR(50),
    product_cost DECIMAL(10,2),
    product_price DECIMAL(10,2)
);

-- Stores table
CREATE TABLE stores (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(100),
    store_city VARCHAR(50),
    store_location VARCHAR(50),
    store_open_date DATE
);

-- Calendar table
CREATE TABLE calendar (
    date DATE PRIMARY KEY
);

-- Sales table
CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    date DATE,
    store_id INT,
    product_id INT,
    units INT,
    FOREIGN KEY (date) REFERENCES calendar(date),
    FOREIGN KEY (store_id) REFERENCES stores(store_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Inventory table
CREATE TABLE inventory (
    store_id INT,
    product_id INT,
    stock_on_hand INT,
    PRIMARY KEY (store_id, product_id),
    FOREIGN KEY (store_id) REFERENCES stores(store_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
```

### Step 2: Load Data

```sql
-- Load products (remove $ and spaces from cost/price columns)
LOAD DATA LOCAL INFILE 'products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_name, product_category, 
 @cost, @price)
SET 
    product_cost = CAST(REPLACE(REPLACE(@cost, '$', ''), ' ', '') AS DECIMAL(10,2)),
    product_price = CAST(REPLACE(REPLACE(@price, '$', ''), ' ', '') AS DECIMAL(10,2));

-- Load stores
LOAD DATA LOCAL INFILE 'stores.csv'
INTO TABLE stores
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Load calendar
LOAD DATA LOCAL INFILE 'calendar.csv'
INTO TABLE calendar
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@date_str)
SET date = STR_TO_DATE(@date_str, '%m/%d/%Y');

-- Load sales
LOAD DATA LOCAL INFILE 'sales.csv'
INTO TABLE sales
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Load inventory
LOAD DATA LOCAL INFILE 'inventory.csv'
INTO TABLE inventory
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
```

---

## 📈 SQL Query Categories for Portfolio

Below are progressive query examples organized by skill level and business function.

---

## 🟢 BEGINNER LEVEL QUERIES

### 1. Basic Aggregations and Filtering

**Q1.1: Total revenue generated across all stores**
```sql
SELECT 
    SUM(s.units * p.product_price) AS total_revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id;
```

**Q1.2: Number of products in each category**
```sql
SELECT 
    product_category,
    COUNT(*) AS product_count
FROM products
GROUP BY product_category
ORDER BY product_count DESC;
```

**Q1.3: Top 10 best-selling products by units sold**
```sql
SELECT 
    p.product_name,
    SUM(s.units) AS total_units_sold
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_units_sold DESC
LIMIT 10;
```

**Q1.4: Stores opened in the last 10 years**
```sql
SELECT 
    store_name,
    store_city,
    store_open_date,
    TIMESTAMPDIFF(YEAR, store_open_date, CURDATE()) AS years_open
FROM stores
WHERE store_open_date >= DATE_SUB(CURDATE(), INTERVAL 10 YEAR)
ORDER BY store_open_date DESC;
```

---

## 🟡 INTERMEDIATE LEVEL QUERIES

### 2. Profitability Analysis

**Q2.1: Profit margin by product**
```sql
SELECT 
    product_name,
    product_category,
    product_cost,
    product_price,
    (product_price - product_cost) AS profit_per_unit,
    ROUND(((product_price - product_cost) / product_price) * 100, 2) AS profit_margin_pct
FROM products
ORDER BY profit_margin_pct DESC;
```

**Q2.2: Monthly revenue and profit trends**
```sql
SELECT 
    DATE_FORMAT(s.date, '%Y-%m') AS month,
    SUM(s.units * p.product_price) AS revenue,
    SUM(s.units * p.product_cost) AS cost,
    SUM(s.units * (p.product_price - p.product_cost)) AS profit,
    ROUND(SUM(s.units * (p.product_price - p.product_cost)) / 
          SUM(s.units * p.product_price) * 100, 2) AS profit_margin_pct
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY DATE_FORMAT(s.date, '%Y-%m')
ORDER BY month;
```

**Q2.3: Category performance comparison**
```sql
SELECT 
    p.product_category,
    COUNT(DISTINCT s.sale_id) AS transaction_count,
    SUM(s.units) AS units_sold,
    SUM(s.units * p.product_price) AS revenue,
    SUM(s.units * (p.product_price - p.product_cost)) AS profit,
    ROUND(AVG(p.product_price), 2) AS avg_price,
    ROUND(AVG(s.units), 2) AS avg_units_per_transaction
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_category
ORDER BY revenue DESC;
```

### 3. Time-Based Analysis

**Q3.1: Day of week sales patterns**
```sql
SELECT 
    DAYNAME(s.date) AS day_of_week,
    DAYOFWEEK(s.date) AS day_number,
    COUNT(DISTINCT s.sale_id) AS transactions,
    SUM(s.units) AS units_sold,
    SUM(s.units * p.product_price) AS revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY DAYNAME(s.date), DAYOFWEEK(s.date)
ORDER BY day_number;
```

**Q3.2: Quarter-over-quarter growth**
```sql
WITH quarterly_sales AS (
    SELECT 
        YEAR(s.date) AS year,
        QUARTER(s.date) AS quarter,
        SUM(s.units * p.product_price) AS revenue
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY YEAR(s.date), QUARTER(s.date)
)
SELECT 
    year,
    quarter,
    revenue,
    LAG(revenue) OVER (ORDER BY year, quarter) AS prev_quarter_revenue,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY year, quarter)) / 
          LAG(revenue) OVER (ORDER BY year, quarter) * 100, 2) AS growth_pct
FROM quarterly_sales
ORDER BY year, quarter;
```

### 4. Store Performance

**Q4.1: Top performing stores by revenue**
```sql
SELECT 
    st.store_name,
    st.store_city,
    st.store_location,
    COUNT(DISTINCT s.sale_id) AS transactions,
    SUM(s.units) AS units_sold,
    SUM(s.units * p.product_price) AS revenue,
    SUM(s.units * (p.product_price - p.product_cost)) AS profit
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN stores st ON s.store_id = st.store_id
GROUP BY st.store_id, st.store_name, st.store_city, st.store_location
ORDER BY revenue DESC
LIMIT 10;
```

**Q4.2: Store performance by location type**
```sql
SELECT 
    st.store_location,
    COUNT(DISTINCT st.store_id) AS store_count,
    SUM(s.units * p.product_price) AS total_revenue,
    ROUND(AVG(s.units * p.product_price), 2) AS avg_revenue_per_transaction,
    SUM(s.units * p.product_price) / COUNT(DISTINCT st.store_id) AS revenue_per_store
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN stores st ON s.store_id = st.store_id
GROUP BY st.store_location
ORDER BY total_revenue DESC;
```

---

## 🔴 ADVANCED LEVEL QUERIES

### 5. Window Functions and Ranking

**Q5.1: Product ranking within each category by revenue**
```sql
SELECT 
    product_category,
    product_name,
    revenue,
    category_rank,
    ROUND(revenue / SUM(revenue) OVER (PARTITION BY product_category) * 100, 2) AS pct_of_category_revenue
FROM (
    SELECT 
        p.product_category,
        p.product_name,
        SUM(s.units * p.product_price) AS revenue,
        RANK() OVER (PARTITION BY p.product_category ORDER BY SUM(s.units * p.product_price) DESC) AS category_rank
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY p.product_category, p.product_name, p.product_id
) ranked
WHERE category_rank <= 5
ORDER BY product_category, category_rank;
```

**Q5.2: Running total of revenue by month**
```sql
SELECT 
    DATE_FORMAT(s.date, '%Y-%m') AS month,
    SUM(s.units * p.product_price) AS monthly_revenue,
    SUM(SUM(s.units * p.product_price)) OVER (ORDER BY DATE_FORMAT(s.date, '%Y-%m')) AS running_total
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY DATE_FORMAT(s.date, '%Y-%m')
ORDER BY month;
```

**Q5.3: Moving average for smoothing trends**
```sql
SELECT 
    DATE_FORMAT(s.date, '%Y-%m') AS month,
    SUM(s.units * p.product_price) AS monthly_revenue,
    ROUND(AVG(SUM(s.units * p.product_price)) OVER (
        ORDER BY DATE_FORMAT(s.date, '%Y-%m')
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS three_month_moving_avg
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY DATE_FORMAT(s.date, '%Y-%m')
ORDER BY month;
```

### 6. Inventory Management

**Q6.1: Stock-to-sales ratio (inventory turnover indicator)**
```sql
SELECT 
    p.product_name,
    p.product_category,
    SUM(i.stock_on_hand) AS total_stock,
    COALESCE(SUM(s.units), 0) AS units_sold_last_30_days,
    CASE 
        WHEN SUM(s.units) = 0 THEN NULL
        ELSE ROUND(SUM(i.stock_on_hand) / (SUM(s.units) / 30.0), 1)
    END AS days_of_inventory
FROM inventory i
JOIN products p ON i.product_id = p.product_id
LEFT JOIN sales s ON i.product_id = s.product_id 
    AND s.date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY p.product_id, p.product_name, p.product_category
ORDER BY days_of_inventory DESC;
```

**Q6.2: Stores with stockouts (products with zero inventory)**
```sql
SELECT 
    st.store_name,
    st.store_city,
    COUNT(*) AS stockout_count,
    GROUP_CONCAT(p.product_name ORDER BY p.product_name SEPARATOR ', ') AS out_of_stock_products
FROM inventory i
JOIN stores st ON i.store_id = st.store_id
JOIN products p ON i.product_id = p.product_id
WHERE i.stock_on_hand = 0
GROUP BY st.store_id, st.store_name, st.store_city
HAVING stockout_count > 5
ORDER BY stockout_count DESC;
```

**Q6.3: Overstock vs understock analysis**
```sql
WITH recent_sales AS (
    SELECT 
        product_id,
        store_id,
        SUM(units) AS units_sold_30d
    FROM sales
    WHERE date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY product_id, store_id
),
stock_status AS (
    SELECT 
        i.store_id,
        i.product_id,
        p.product_name,
        i.stock_on_hand,
        COALESCE(rs.units_sold_30d, 0) AS units_sold_30d,
        CASE 
            WHEN COALESCE(rs.units_sold_30d, 0) = 0 THEN 'No Sales'
            WHEN i.stock_on_hand >= rs.units_sold_30d * 2 THEN 'Overstock'
            WHEN i.stock_on_hand < rs.units_sold_30d * 0.5 THEN 'Understock'
            ELSE 'Healthy'
        END AS stock_status
    FROM inventory i
    JOIN products p ON i.product_id = p.product_id
    LEFT JOIN recent_sales rs ON i.store_id = rs.store_id AND i.product_id = rs.product_id
)
SELECT 
    stock_status,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM stock_status
GROUP BY stock_status
ORDER BY count DESC;
```

### 7. Customer Behavior Insights

**Q7.1: Product affinity analysis (products frequently bought together)**
```sql
SELECT 
    p1.product_name AS product_1,
    p2.product_name AS product_2,
    COUNT(*) AS times_purchased_together,
    ROUND(COUNT(*) * 100.0 / (
        SELECT COUNT(DISTINCT date, store_id) 
        FROM sales 
        WHERE product_id = s1.product_id
    ), 2) AS affinity_pct
FROM sales s1
JOIN sales s2 ON s1.date = s2.date 
    AND s1.store_id = s2.store_id 
    AND s1.product_id < s2.product_id
JOIN products p1 ON s1.product_id = p1.product_id
JOIN products p2 ON s2.product_id = p2.product_id
GROUP BY s1.product_id, s2.product_id, p1.product_name, p2.product_name
HAVING times_purchased_together >= 100
ORDER BY times_purchased_together DESC
LIMIT 20;
```

**Q7.2: Average transaction value by store**
```sql
WITH daily_transactions AS (
    SELECT 
        s.date,
        s.store_id,
        SUM(s.units * p.product_price) AS transaction_value
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY s.date, s.store_id
)
SELECT 
    st.store_name,
    st.store_city,
    COUNT(*) AS transaction_count,
    ROUND(AVG(dt.transaction_value), 2) AS avg_transaction_value,
    ROUND(MIN(dt.transaction_value), 2) AS min_transaction_value,
    ROUND(MAX(dt.transaction_value), 2) AS max_transaction_value,
    ROUND(STDDEV(dt.transaction_value), 2) AS stddev_transaction_value
FROM daily_transactions dt
JOIN stores st ON dt.store_id = st.store_id
GROUP BY st.store_id, st.store_name, st.store_city
ORDER BY avg_transaction_value DESC;
```

### 8. Cohort Analysis

**Q8.1: Store cohort analysis by opening year**
```sql
SELECT 
    YEAR(st.store_open_date) AS cohort_year,
    COUNT(DISTINCT st.store_id) AS stores_opened,
    SUM(s.units * p.product_price) AS total_revenue,
    ROUND(SUM(s.units * p.product_price) / COUNT(DISTINCT st.store_id), 2) AS avg_revenue_per_store,
    ROUND(AVG(DATEDIFF(CURDATE(), st.store_open_date) / 365.25), 1) AS avg_age_years
FROM stores st
LEFT JOIN sales s ON st.store_id = s.store_id
LEFT JOIN products p ON s.product_id = p.product_id
GROUP BY YEAR(st.store_open_date)
ORDER BY cohort_year;
```

### 9. Advanced Segmentation

**Q9.1: RFM-style store segmentation**
```sql
WITH store_metrics AS (
    SELECT 
        s.store_id,
        MAX(s.date) AS last_sale_date,
        COUNT(DISTINCT s.date) AS frequency,
        SUM(s.units * p.product_price) AS monetary_value
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY s.store_id
),
store_scores AS (
    SELECT 
        store_id,
        DATEDIFF((SELECT MAX(date) FROM sales), last_sale_date) AS recency_days,
        frequency,
        monetary_value,
        NTILE(4) OVER (ORDER BY DATEDIFF((SELECT MAX(date) FROM sales), last_sale_date) DESC) AS recency_score,
        NTILE(4) OVER (ORDER BY frequency) AS frequency_score,
        NTILE(4) OVER (ORDER BY monetary_value) AS monetary_score
    FROM store_metrics
)
SELECT 
    st.store_name,
    st.store_city,
    ss.recency_days,
    ss.frequency,
    ROUND(ss.monetary_value, 2) AS revenue,
    ss.recency_score + ss.frequency_score + ss.monetary_score AS rfm_score,
    CASE 
        WHEN ss.recency_score + ss.frequency_score + ss.monetary_score >= 10 THEN 'Champions'
        WHEN ss.recency_score + ss.frequency_score + ss.monetary_score >= 7 THEN 'Loyal'
        WHEN ss.recency_score + ss.frequency_score + ss.monetary_score >= 5 THEN 'Potential'
        ELSE 'At Risk'
    END AS segment
FROM store_scores ss
JOIN stores st ON ss.store_id = st.store_id
ORDER BY rfm_score DESC;
```

### 10. Complex Business Questions

**Q10.1: Which cities should we expand to next?**
```sql
WITH city_performance AS (
    SELECT 
        st.store_city,
        COUNT(DISTINCT st.store_id) AS store_count,
        SUM(s.units * p.product_price) AS total_revenue,
        SUM(s.units * p.product_price) / COUNT(DISTINCT st.store_id) AS revenue_per_store,
        ROUND(AVG(DATEDIFF(CURDATE(), st.store_open_date) / 365.25), 1) AS avg_store_age
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    JOIN stores st ON s.store_id = st.store_id
    GROUP BY st.store_city
)
SELECT 
    store_city,
    store_count,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(revenue_per_store, 2) AS revenue_per_store,
    avg_store_age,
    CASE 
        WHEN store_count = 1 AND revenue_per_store > (SELECT AVG(revenue_per_store) FROM city_performance) 
            THEN 'High Priority - Single store performing well'
        WHEN store_count <= 2 AND revenue_per_store > (SELECT AVG(revenue_per_store) FROM city_performance)
            THEN 'Consider Expansion'
        ELSE 'Monitor'
    END AS expansion_recommendation
FROM city_performance
ORDER BY revenue_per_store DESC;
```

**Q10.2: Product lifecycle analysis**
```sql
WITH monthly_product_sales AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.product_category,
        DATE_FORMAT(s.date, '%Y-%m') AS month,
        SUM(s.units) AS units_sold,
        ROW_NUMBER() OVER (PARTITION BY p.product_id ORDER BY DATE_FORMAT(s.date, '%Y-%m')) AS month_number
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY p.product_id, p.product_name, p.product_category, DATE_FORMAT(s.date, '%Y-%m')
),
lifecycle_stage AS (
    SELECT 
        product_name,
        product_category,
        COUNT(*) AS months_on_market,
        ROUND(AVG(units_sold), 2) AS avg_monthly_units,
        MAX(units_sold) AS peak_monthly_units,
        ROUND(STDDEV(units_sold), 2) AS volatility,
        CASE 
            WHEN month_number <= 3 THEN 'Introduction'
            WHEN month_number <= 12 AND units_sold >= AVG(units_sold) OVER (PARTITION BY product_id) * 1.2 THEN 'Growth'
            WHEN units_sold >= AVG(units_sold) OVER (PARTITION BY product_id) * 0.8 THEN 'Maturity'
            ELSE 'Decline'
        END AS lifecycle_stage
    FROM monthly_product_sales
    GROUP BY product_id, product_name, product_category
)
SELECT 
    product_category,
    lifecycle_stage,
    COUNT(*) AS product_count,
    ROUND(AVG(avg_monthly_units), 2) AS avg_units_per_month
FROM lifecycle_stage
GROUP BY product_category, lifecycle_stage
ORDER BY product_category, 
    FIELD(lifecycle_stage, 'Introduction', 'Growth', 'Maturity', 'Decline');
```

---

**Created by:** Stephen Teet  
**Date:** February 23, 2026
**Tools:** MySQL, Python (optional for data prep)  
**Dataset:** Maven Toys Sales Data (2022-2023)

