-- ============================================================================
-- MAVEN TOYS SQL CASE STUDY
-- File: 04_advanced_queries.sql
-- Purpose: Advanced SQL queries for sophisticated business analytics
-- Skills: Complex Window Functions, CTEs, Cohort Analysis, Advanced Aggregations
-- ============================================================================

USE maven_toys;

-- ============================================================================
-- SECTION 1: ADVANCED WINDOW FUNCTIONS
-- ============================================================================

-- Query 1.1: Running totals and cumulative metrics by month
WITH monthly_metrics AS (
    SELECT 
        DATE_FORMAT(s.date, '%Y-%m') AS month,
        SUM(s.units * p.product_price) AS revenue,
        SUM(s.units * (p.product_price - p.product_cost)) AS profit,
        COUNT(DISTINCT s.sale_id) AS transactions
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY DATE_FORMAT(s.date, '%Y-%m')
)
SELECT 
    month,
    CONCAT('$', FORMAT(revenue, 2)) AS monthly_revenue,
    CONCAT('$', FORMAT(SUM(revenue) OVER (ORDER BY month), 2)) AS cumulative_revenue,
    ROUND(revenue * 100.0 / SUM(revenue) OVER (), 2) AS pct_of_total,
    CONCAT('$', FORMAT(profit, 2)) AS monthly_profit,
    ROUND(profit / revenue * 100, 2) AS margin_pct,
    transactions,
    CONCAT('$', FORMAT(revenue / transactions, 2)) AS revenue_per_transaction
FROM monthly_metrics
ORDER BY month;

-- Query 1.2: Product ranking with percentile analysis
WITH product_metrics AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.product_category,
        SUM(s.units) AS total_units,
        SUM(s.units * p.product_price) AS revenue,
        SUM(s.units * (p.product_price - p.product_cost)) AS profit
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY p.product_id, p.product_name, p.product_category
)
SELECT 
    product_name,
    product_category,
    total_units,
    CONCAT('$', FORMAT(revenue, 2)) AS revenue,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
    DENSE_RANK() OVER (ORDER BY revenue DESC) AS dense_rank,
    NTILE(4) OVER (ORDER BY revenue DESC) AS quartile,
    ROUND(PERCENT_RANK() OVER (ORDER BY revenue DESC) * 100, 2) AS percentile,
    CASE 
        WHEN NTILE(4) OVER (ORDER BY revenue DESC) = 1 THEN 'Top 25%'
        WHEN NTILE(4) OVER (ORDER BY revenue DESC) = 2 THEN 'Second 25%'
        WHEN NTILE(4) OVER (ORDER BY revenue DESC) = 3 THEN 'Third 25%'
        ELSE 'Bottom 25%'
    END AS performance_tier
FROM product_metrics
ORDER BY revenue DESC;

-- Query 1.3: Category contribution to total with running percentage
WITH category_revenue AS (
    SELECT 
        p.product_category,
        SUM(s.units * p.product_price) AS revenue
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY p.product_category
)
SELECT 
    product_category,
    CONCAT('$', FORMAT(revenue, 2)) AS revenue,
    ROUND(revenue * 100.0 / SUM(revenue) OVER (), 2) AS pct_of_total,
    CONCAT('$', FORMAT(SUM(revenue) OVER (ORDER BY revenue DESC), 2)) AS cumulative_revenue,
    ROUND(SUM(revenue) OVER (ORDER BY revenue DESC) * 100.0 / SUM(revenue) OVER (), 2) AS cumulative_pct,
    CASE 
        WHEN ROUND(SUM(revenue) OVER (ORDER BY revenue DESC) * 100.0 / SUM(revenue) OVER (), 2) <= 80 
        THEN 'Top 80%'
        ELSE 'Bottom 20%'
    END AS pareto_group
FROM category_revenue
ORDER BY revenue DESC;

-- Query 1.4: Month-over-month growth with 3-month comparison
WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(s.date, '%Y-%m') AS month,
        SUM(s.units * p.product_price) AS revenue
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY DATE_FORMAT(s.date, '%Y-%m')
)
SELECT 
    month,
    CONCAT('$', FORMAT(revenue, 2)) AS revenue,
    CONCAT('$', FORMAT(LAG(revenue, 1) OVER (ORDER BY month), 2)) AS prev_month,
    CONCAT('$', FORMAT(LAG(revenue, 3) OVER (ORDER BY month), 2)) AS three_months_ago,
    ROUND((revenue - LAG(revenue, 1) OVER (ORDER BY month)) * 100.0 / 
          LAG(revenue, 1) OVER (ORDER BY month), 2) AS mom_growth_pct,
    ROUND((revenue - LAG(revenue, 3) OVER (ORDER BY month)) * 100.0 / 
          LAG(revenue, 3) OVER (ORDER BY month), 2) AS three_month_growth_pct
FROM monthly_revenue
ORDER BY month;

-- ============================================================================
-- SECTION 2: INVENTORY ANALYTICS
-- ============================================================================

-- Query 2.1: Advanced inventory turnover with sales velocity
WITH product_sales_30d AS (
    SELECT 
        product_id,
        SUM(units) AS units_sold_30d
    FROM sales
    WHERE date >= DATE_SUB((SELECT MAX(date) FROM sales), INTERVAL 30 DAY)
    GROUP BY product_id
),
inventory_analysis AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.product_category,
        SUM(i.stock_on_hand) AS total_stock,
        COALESCE(ps.units_sold_30d, 0) AS units_sold_30d,
        SUM(i.stock_on_hand * p.product_cost) AS inventory_value
    FROM inventory i
    JOIN products p ON i.product_id = p.product_id
    LEFT JOIN product_sales_30d ps ON i.product_id = ps.product_id
    GROUP BY p.product_id, p.product_name, p.product_category, ps.units_sold_30d
)
SELECT 
    product_name,
    product_category,
    total_stock,
    units_sold_30d,
    CONCAT('$', FORMAT(inventory_value, 2)) AS inventory_value,
    CASE 
        WHEN units_sold_30d = 0 THEN 'No Sales'
        ELSE CONCAT(ROUND(total_stock * 30.0 / units_sold_30d, 1), ' days')
    END AS days_of_inventory,
    CASE 
        WHEN units_sold_30d = 0 THEN 'Dead Stock'
        WHEN total_stock * 30.0 / units_sold_30d > 60 THEN 'Overstock'
        WHEN total_stock * 30.0 / units_sold_30d < 15 THEN 'Understock'
        ELSE 'Healthy'
    END AS stock_status,
    ROUND(units_sold_30d / 30.0, 2) AS avg_daily_sales
FROM inventory_analysis
WHERE total_stock > 0 OR units_sold_30d > 0
ORDER BY 
    CASE 
        WHEN units_sold_30d = 0 THEN 999999
        ELSE total_stock * 30.0 / units_sold_30d
    END DESC;

-- Query 2.2: Store-level inventory efficiency
WITH store_inventory_value AS (
    SELECT 
        i.store_id,
        SUM(i.stock_on_hand * p.product_cost) AS total_inventory_cost,
        SUM(i.stock_on_hand * p.product_price) AS potential_revenue,
        COUNT(CASE WHEN i.stock_on_hand = 0 THEN 1 END) AS stockout_count,
        COUNT(*) AS total_products
    FROM inventory i
    JOIN products p ON i.product_id = p.product_id
    GROUP BY i.store_id
),
store_sales_30d AS (
    SELECT 
        s.store_id,
        SUM(s.units * p.product_price) AS revenue_30d,
        SUM(s.units * p.product_cost) AS cogs_30d
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    WHERE s.date >= DATE_SUB((SELECT MAX(date) FROM sales), INTERVAL 30 DAY)
    GROUP BY s.store_id
)
SELECT 
    st.store_name,
    st.store_city,
    st.store_location,
    CONCAT('$', FORMAT(siv.total_inventory_cost, 2)) AS inventory_value,
    CONCAT('$', FORMAT(ss.revenue_30d, 2)) AS revenue_30d,
    ROUND(siv.total_inventory_cost / (ss.cogs_30d / 30.0), 1) AS days_inventory_on_hand,
    ROUND(ss.revenue_30d * 12 / siv.total_inventory_cost, 2) AS inventory_turnover_ratio,
    siv.stockout_count,
    ROUND(siv.stockout_count * 100.0 / siv.total_products, 2) AS stockout_pct
FROM store_inventory_value siv
JOIN stores st ON siv.store_id = st.store_id
JOIN store_sales_30d ss ON siv.store_id = ss.store_id
ORDER BY inventory_turnover_ratio DESC;

-- Query 2.3: Identify products needing restock by store
WITH recent_sales AS (
    SELECT 
        store_id,
        product_id,
        SUM(units) AS units_sold_14d
    FROM sales
    WHERE date >= DATE_SUB((SELECT MAX(date) FROM sales), INTERVAL 14 DAY)
    GROUP BY store_id, product_id
)
SELECT 
    st.store_name,
    st.store_city,
    p.product_name,
    p.product_category,
    i.stock_on_hand,
    COALESCE(rs.units_sold_14d, 0) AS sold_last_14_days,
    ROUND(COALESCE(rs.units_sold_14d, 0) / 14.0, 2) AS avg_daily_sales,
    CASE 
        WHEN COALESCE(rs.units_sold_14d, 0) = 0 THEN 'No Sales'
        ELSE CONCAT(ROUND(i.stock_on_hand / (rs.units_sold_14d / 14.0), 1), ' days')
    END AS days_until_stockout,
    CASE 
        WHEN i.stock_on_hand = 0 THEN 'URGENT - Out of Stock'
        WHEN COALESCE(rs.units_sold_14d, 0) > 0 AND i.stock_on_hand / (rs.units_sold_14d / 14.0) < 7 
        THEN 'Restock Soon'
        ELSE 'OK'
    END AS restock_priority
FROM inventory i
JOIN stores st ON i.store_id = st.store_id
JOIN products p ON i.product_id = p.product_id
LEFT JOIN recent_sales rs ON i.store_id = rs.store_id AND i.product_id = rs.product_id
WHERE COALESCE(rs.units_sold_14d, 0) > 0 
    AND (i.stock_on_hand = 0 OR i.stock_on_hand / (rs.units_sold_14d / 14.0) < 7)
ORDER BY 
    CASE 
        WHEN i.stock_on_hand = 0 THEN 1
        ELSE 2
    END,
    i.stock_on_hand / (rs.units_sold_14d / 14.0);

-- ============================================================================
-- SECTION 3: COHORT ANALYSIS
-- ============================================================================

-- Query 3.1: Store cohort analysis by opening year
WITH store_cohorts AS (
    SELECT 
        st.store_id,
        st.store_name,
        st.store_city,
        YEAR(st.store_open_date) AS cohort_year,
        TIMESTAMPDIFF(MONTH, st.store_open_date, (SELECT MAX(date) FROM sales)) AS months_since_open
    FROM stores st
),
cohort_revenue AS (
    SELECT 
        sc.cohort_year,
        sc.months_since_open,
        COUNT(DISTINCT sc.store_id) AS stores_in_cohort,
        SUM(s.units * p.product_price) AS total_revenue,
        SUM(s.units * (p.product_price - p.product_cost)) AS total_profit
    FROM store_cohorts sc
    LEFT JOIN sales s ON sc.store_id = s.store_id
    LEFT JOIN products p ON s.product_id = p.product_id
    GROUP BY sc.cohort_year, sc.months_since_open
)
SELECT 
    cohort_year,
    stores_in_cohort,
    ROUND(months_since_open / 12.0, 1) AS avg_age_years,
    CONCAT('$', FORMAT(total_revenue, 2)) AS total_revenue,
    CONCAT('$', FORMAT(total_revenue / stores_in_cohort, 2)) AS revenue_per_store,
    CONCAT('$', FORMAT(total_profit / stores_in_cohort, 2)) AS profit_per_store,
    ROUND(total_profit * 100.0 / total_revenue, 2) AS margin_pct
FROM cohort_revenue
GROUP BY cohort_year, stores_in_cohort, months_since_open
ORDER BY cohort_year;

-- Query 3.2: Product lifecycle by month since launch
WITH product_monthly_sales AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.product_category,
        DATE_FORMAT(s.date, '%Y-%m') AS month,
        SUM(s.units) AS units_sold,
        SUM(s.units * p.product_price) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY p.product_id ORDER BY DATE_FORMAT(s.date, '%Y-%m')) AS month_number
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY p.product_id, p.product_name, p.product_category, DATE_FORMAT(s.date, '%Y-%m')
),
lifecycle_metrics AS (
    SELECT 
        product_id,
        product_name,
        product_category,
        COUNT(*) AS months_on_market,
        MAX(revenue) AS peak_revenue,
        AVG(revenue) AS avg_revenue,
        SUM(revenue) AS total_revenue,
        STDDEV(revenue) AS revenue_volatility
    FROM product_monthly_sales
    GROUP BY product_id, product_name, product_category
)
SELECT 
    product_name,
    product_category,
    months_on_market,
    CONCAT('$', FORMAT(total_revenue, 2)) AS total_revenue,
    CONCAT('$', FORMAT(avg_revenue, 2)) AS avg_monthly_revenue,
    CONCAT('$', FORMAT(peak_revenue, 2)) AS peak_monthly_revenue,
    ROUND(revenue_volatility, 2) AS volatility,
    CASE 
        WHEN months_on_market < 6 THEN 'Introduction'
        WHEN avg_revenue > peak_revenue * 0.7 THEN 'Growth/Maturity'
        WHEN avg_revenue < peak_revenue * 0.5 THEN 'Decline'
        ELSE 'Mature'
    END AS lifecycle_stage
FROM lifecycle_metrics
ORDER BY total_revenue DESC;

-- ============================================================================
-- SECTION 4: PRODUCT AFFINITY & BASKET ANALYSIS
-- ============================================================================

-- Query 4.1: Products frequently purchased together
WITH same_day_purchases AS (
    SELECT DISTINCT
        s1.date,
        s1.store_id,
        s1.product_id AS product_1,
        s2.product_id AS product_2
    FROM sales s1
    JOIN sales s2 ON s1.date = s2.date 
        AND s1.store_id = s2.store_id 
        AND s1.product_id < s2.product_id
),
product_pairs AS (
    SELECT 
        product_1,
        product_2,
        COUNT(*) AS times_together
    FROM same_day_purchases
    GROUP BY product_1, product_2
    HAVING COUNT(*) >= 50
)
SELECT 
    p1.product_name AS product_1,
    p2.product_name AS product_2,
    p1.product_category AS category_1,
    p2.product_category AS category_2,
    pp.times_together,
    ROUND(pp.times_together * 100.0 / (
        SELECT COUNT(DISTINCT date, store_id) 
        FROM sales 
        WHERE product_id = pp.product_1
    ), 2) AS affinity_pct
FROM product_pairs pp
JOIN products p1 ON pp.product_1 = p1.product_id
JOIN products p2 ON pp.product_2 = p2.product_id
ORDER BY pp.times_together DESC
LIMIT 20;

-- Query 4.2: Category cross-sell analysis
WITH category_pairs AS (
    SELECT DISTINCT
        s1.date,
        s1.store_id,
        p1.product_category AS category_1,
        p2.product_category AS category_2
    FROM sales s1
    JOIN sales s2 ON s1.date = s2.date 
        AND s1.store_id = s2.store_id 
        AND s1.product_id < s2.product_id
    JOIN products p1 ON s1.product_id = p1.product_id
    JOIN products p2 ON s2.product_id = p2.product_id
    WHERE p1.product_category != p2.product_category
)
SELECT 
    category_1,
    category_2,
    COUNT(*) AS times_purchased_together,
    ROUND(COUNT(*) * 100.0 / (
        SELECT COUNT(DISTINCT s.date, s.store_id)
        FROM sales s
        JOIN products p ON s.product_id = p.product_id
        WHERE p.product_category = cp.category_1
    ), 2) AS cross_sell_rate
FROM category_pairs cp
GROUP BY category_1, category_2
ORDER BY times_purchased_together DESC;

-- ============================================================================
-- SECTION 5: RFM SEGMENTATION
-- ============================================================================

-- Query 5.1: Store segmentation using RFM methodology
WITH store_rfm AS (
    SELECT 
        s.store_id,
        MAX(s.date) AS last_purchase_date,
        COUNT(DISTINCT s.date) AS frequency,
        SUM(s.units * p.product_price) AS monetary
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY s.store_id
),
rfm_scores AS (
    SELECT 
        store_id,
        DATEDIFF((SELECT MAX(date) FROM sales), last_purchase_date) AS recency_days,
        frequency,
        monetary,
        NTILE(4) OVER (ORDER BY DATEDIFF((SELECT MAX(date) FROM sales), last_purchase_date) DESC) AS recency_score,
        NTILE(4) OVER (ORDER BY frequency) AS frequency_score,
        NTILE(4) OVER (ORDER BY monetary) AS monetary_score
    FROM store_rfm
)
SELECT 
    st.store_name,
    st.store_city,
    st.store_location,
    rs.recency_days,
    rs.frequency AS shopping_days,
    CONCAT('$', FORMAT(rs.monetary, 2)) AS total_revenue,
    rs.recency_score + rs.frequency_score + rs.monetary_score AS rfm_score,
    CASE 
        WHEN rs.recency_score + rs.frequency_score + rs.monetary_score >= 11 THEN 'Champions'
        WHEN rs.recency_score + rs.frequency_score + rs.monetary_score >= 9 THEN 'Loyal Customers'
        WHEN rs.recency_score + rs.frequency_score + rs.monetary_score >= 7 THEN 'Potential Loyalists'
        WHEN rs.recency_score >= 3 AND rs.frequency_score <= 2 THEN 'Recent but Infrequent'
        WHEN rs.recency_score <= 2 THEN 'At Risk'
        ELSE 'Needs Attention'
    END AS segment,
    CONCAT(rs.recency_score, '-', rs.frequency_score, '-', rs.monetary_score) AS rfm_code
FROM rfm_scores rs
JOIN stores st ON rs.store_id = st.store_id
ORDER BY rfm_score DESC, monetary DESC;

-- Query 5.2: Segment performance summary
WITH store_rfm AS (
    SELECT 
        s.store_id,
        MAX(s.date) AS last_purchase_date,
        COUNT(DISTINCT s.date) AS frequency,
        SUM(s.units * p.product_price) AS monetary
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY s.store_id
),
rfm_scores AS (
    SELECT 
        store_id,
        NTILE(4) OVER (ORDER BY DATEDIFF((SELECT MAX(date) FROM sales), last_purchase_date) DESC) AS recency_score,
        NTILE(4) OVER (ORDER BY frequency) AS frequency_score,
        NTILE(4) OVER (ORDER BY monetary) AS monetary_score,
        monetary
    FROM store_rfm
),
segments AS (
    SELECT 
        CASE 
            WHEN recency_score + frequency_score + monetary_score >= 11 THEN 'Champions'
            WHEN recency_score + frequency_score + monetary_score >= 9 THEN 'Loyal Customers'
            WHEN recency_score + frequency_score + monetary_score >= 7 THEN 'Potential Loyalists'
            ELSE 'Needs Attention'
        END AS segment,
        COUNT(*) AS store_count,
        SUM(monetary) AS total_revenue
    FROM rfm_scores
    GROUP BY 
        CASE 
            WHEN recency_score + frequency_score + monetary_score >= 11 THEN 'Champions'
            WHEN recency_score + frequency_score + monetary_score >= 9 THEN 'Loyal Customers'
            WHEN recency_score + frequency_score + monetary_score >= 7 THEN 'Potential Loyalists'
            ELSE 'Needs Attention'
        END
)
SELECT 
    segment,
    store_count,
    ROUND(store_count * 100.0 / SUM(store_count) OVER (), 2) AS pct_of_stores,
    CONCAT('$', FORMAT(total_revenue, 2)) AS total_revenue,
    ROUND(total_revenue * 100.0 / SUM(total_revenue) OVER (), 2) AS pct_of_revenue,
    CONCAT('$', FORMAT(total_revenue / store_count, 2)) AS avg_revenue_per_store
FROM segments
ORDER BY total_revenue DESC;

-- ============================================================================
-- SECTION 6: PREDICTIVE & STRATEGIC ANALYSIS
-- ============================================================================

-- Query 6.1: Expansion opportunity analysis
WITH city_metrics AS (
    SELECT 
        st.store_city,
        COUNT(DISTINCT st.store_id) AS current_stores,
        SUM(s.units * p.product_price) AS total_revenue,
        SUM(s.units * p.product_price) / COUNT(DISTINCT st.store_id) AS revenue_per_store,
        AVG(TIMESTAMPDIFF(YEAR, st.store_open_date, CURDATE())) AS avg_store_age
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    JOIN stores st ON s.store_id = st.store_id
    GROUP BY st.store_city
),
avg_performance AS (
    SELECT AVG(revenue_per_store) AS system_avg_revenue_per_store
    FROM city_metrics
)
SELECT 
    cm.store_city,
    cm.current_stores,
    CONCAT('$', FORMAT(cm.total_revenue, 2)) AS total_revenue,
    CONCAT('$', FORMAT(cm.revenue_per_store, 2)) AS revenue_per_store,
    CONCAT('$', FORMAT(ap.system_avg_revenue_per_store, 2)) AS system_average,
    ROUND((cm.revenue_per_store - ap.system_avg_revenue_per_store) * 100.0 / 
          ap.system_avg_revenue_per_store, 2) AS vs_system_avg_pct,
    ROUND(cm.avg_store_age, 1) AS avg_store_age_years,
    CASE 
        WHEN cm.current_stores = 1 AND cm.revenue_per_store > ap.system_avg_revenue_per_store * 1.1 
            THEN 'High Priority - Strong single store'
        WHEN cm.current_stores <= 2 AND cm.revenue_per_store > ap.system_avg_revenue_per_store
            THEN 'Consider Expansion'
        WHEN cm.current_stores >= 3 AND cm.revenue_per_store > ap.system_avg_revenue_per_store * 1.2
            THEN 'Saturated but Strong'
        ELSE 'Monitor'
    END AS expansion_recommendation
FROM city_metrics cm
CROSS JOIN avg_performance ap
ORDER BY cm.revenue_per_store DESC;

-- Query 6.2: Underperforming store diagnostics
WITH store_performance AS (
    SELECT 
        st.store_id,
        st.store_name,
        st.store_city,
        st.store_location,
        SUM(s.units * p.product_price) AS revenue,
        COUNT(DISTINCT s.date) AS active_days,
        SUM(s.units) AS units_sold
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    JOIN stores st ON s.store_id = st.store_id
    GROUP BY st.store_id, st.store_name, st.store_city, st.store_location
),
system_avg AS (
    SELECT AVG(revenue) AS avg_revenue
    FROM store_performance
),
underperformers AS (
    SELECT 
        sp.*,
        sa.avg_revenue,
        ROUND((sp.revenue - sa.avg_revenue) * 100.0 / sa.avg_revenue, 2) AS vs_avg_pct
    FROM store_performance sp
    CROSS JOIN system_avg sa
    WHERE sp.revenue < sa.avg_revenue * 0.7
)
SELECT 
    u.store_name,
    u.store_city,
    u.store_location,
    CONCAT('$', FORMAT(u.revenue, 2)) AS revenue,
    CONCAT('$', FORMAT(u.avg_revenue, 2)) AS system_average,
    u.vs_avg_pct AS performance_gap_pct,
    u.active_days,
    CONCAT('$', FORMAT(u.revenue / u.active_days, 2)) AS revenue_per_day,
    CASE 
        WHEN u.active_days < 300 THEN 'Low Sales Activity'
        WHEN u.units_sold / u.active_days < 10 THEN 'Low Conversion'
        ELSE 'Review Needed'
    END AS likely_issue
FROM underperformers u
ORDER BY u.vs_avg_pct ASC;

-- ============================================================================
-- END OF ADVANCED QUERIES
-- ============================================================================
