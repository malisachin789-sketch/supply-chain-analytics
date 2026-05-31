-- ================================================
-- PROJECT 3: Supply Chain Performance Analysis
-- TOOL: MySQL
-- DATASET: DataCo Supply Chain (Kaggle)
-- ROWS: 1,80,519 | COLS: 43
-- ANALYST: Sachin Malee
-- ================================================

USE supply_chain_db;

-- ==================================================
-- BUSINESS PROBLEM 1: Overall Business Health Check
-- ==================================================
SELECT
    COUNT(DISTINCT order_id)            AS total_orders,
    COUNT(DISTINCT customer_id)         AS total_customers,
    COUNT(DISTINCT product_id)          AS total_products,
    ROUND(SUM(sales), 2)               AS total_revenue,
    ROUND(SUM(profit), 2)              AS total_profit,
    ROUND(AVG(profit_ratio)*100, 2)    AS avg_profit_margin_pct,
    SUM(quantity)                      AS total_units_sold,
    -- Late delivery rate
    ROUND(SUM(late_delivery_risk)*100.0
        / COUNT(*), 2)                 AS late_delivery_rate_pct,
    -- Loss making orders
    SUM(CASE WHEN profit < 0
        THEN 1 ELSE 0 END)             AS loss_making_orders,
    ROUND(SUM(CASE WHEN profit < 0
        THEN 1 ELSE 0 END)*100.0
        / COUNT(*), 2)                 AS loss_order_pct
FROM supply_chain;


-- ====================================================
-- BUSINESS PROBLEM 2: Department Performance Analysis
-- ====================================================
SELECT
    department_name,
    COUNT(DISTINCT order_id)           AS total_orders,
    SUM(quantity)                      AS units_sold,
    ROUND(SUM(sales), 2)              AS total_revenue,
    ROUND(SUM(profit), 2)             AS total_profit,
    ROUND(AVG(profit_ratio)*100, 2)   AS avg_margin_pct,
    ROUND(SUM(late_delivery_risk)*100.0
        / COUNT(*), 2)                AS late_risk_pct,
    RANK() OVER (
        ORDER BY SUM(profit) DESC)    AS profit_rank
FROM supply_chain
GROUP BY department_name
ORDER BY total_profit DESC;


-- ================================================
-- BUSINESS PROBLEM 3: Shipping Mode Analysis
-- ================================================
SELECT
    shipping_mode,
    COUNT(*)                           AS total_shipments,
    ROUND(AVG(days_shipment_scheduled),1)
                                       AS avg_days_promised,
    ROUND(AVG(days_shipping_real),1)   AS avg_days_actual,
    ROUND(AVG(days_shipping_real) -
        AVG(days_shipment_scheduled),1)AS avg_delay_days,
    SUM(late_delivery_risk)            AS late_orders,
    ROUND(SUM(late_delivery_risk)*100.0
        / COUNT(*), 2)                 AS late_risk_pct,
    ROUND(SUM(profit), 2)             AS total_profit,
    ROUND(AVG(profit_ratio)*100, 2)   AS avg_margin_pct
FROM supply_chain
GROUP BY shipping_mode
ORDER BY late_risk_pct DESC;


-- ================================================
-- BUSINESS PROBLEM 4: Market Performance
-- ================================================
SELECT
    market,
    COUNT(DISTINCT order_id)           AS total_orders,
    COUNT(DISTINCT customer_id)        AS customers,
    ROUND(SUM(sales), 2)              AS revenue,
    ROUND(SUM(profit), 2)             AS profit,
    ROUND(AVG(profit_ratio)*100, 2)   AS margin_pct,
    ROUND(SUM(late_delivery_risk)*100.0
        / COUNT(*), 2)                AS late_risk_pct,
    ROUND(SUM(profit)*100.0
        / SUM(SUM(profit)) OVER(), 2) AS profit_share_pct,
    RANK() OVER (
        ORDER BY SUM(profit) DESC)    AS profit_rank
FROM supply_chain
GROUP BY market
ORDER BY profit DESC;


-- ================================================
-- BUSINESS PROBLEM 5: Discount Impact on Profit
-- ================================================
WITH discount_buckets AS (
    SELECT *,
        CASE
            WHEN discount_rate = 0
                THEN '1. No Discount'
            WHEN discount_rate <= 0.05
                THEN '2. Low (1-5%)'
            WHEN discount_rate <= 0.10
                THEN '3. Medium (6-10%)'
            WHEN discount_rate <= 0.20
                THEN '4. High (11-20%)'
            ELSE '5. Very High (20%+)'
        END                           AS discount_band
    FROM supply_chain
)
SELECT
    discount_band,
    COUNT(*)                          AS orders,
    ROUND(AVG(sales), 2)             AS avg_sales,
    ROUND(AVG(profit), 2)            AS avg_profit,
    ROUND(AVG(profit_ratio)*100, 2)  AS avg_margin_pct,
    SUM(CASE WHEN profit < 0
        THEN 1 ELSE 0 END)           AS loss_orders,
    ROUND(SUM(CASE WHEN profit < 0
        THEN 1 ELSE 0 END)*100.0
        / COUNT(*), 2)               AS loss_order_pct
FROM discount_buckets
GROUP BY discount_band
ORDER BY discount_band;


-- ================================================
-- BUSINESS PROBLEM 6: Late Delivery Risk Analysis
-- ================================================
WITH late_risk AS (
    SELECT
        shipping_mode,
        order_region,
        COUNT(*)                      AS total,
        SUM(late_delivery_risk)       AS late_count,
        ROUND(SUM(late_delivery_risk)
            *100.0/COUNT(*), 2)       AS late_pct
    FROM supply_chain
    GROUP BY shipping_mode, order_region
)
SELECT *,
    CASE
        WHEN late_pct >= 70
            THEN '🔴 Critical Risk'
        WHEN late_pct >= 50
            THEN '🟠 High Risk'
        WHEN late_pct >= 30
            THEN '🟡 Medium Risk'
        ELSE '🟢 Low Risk'
    END                               AS risk_level
FROM late_risk
WHERE total > 100
ORDER BY late_pct DESC
LIMIT 15;


-- ================================================
-- BUSINESS PROBLEM 7: Customer Segment Analysis
-- ================================================
SELECT
    customer_segment,
    COUNT(DISTINCT customer_id)       AS customers,
    COUNT(DISTINCT order_id)          AS orders,
    ROUND(SUM(sales), 2)             AS revenue,
    ROUND(SUM(profit), 2)            AS profit,
    ROUND(AVG(sales), 2)             AS avg_order_value,
    ROUND(AVG(profit_ratio)*100, 2)  AS avg_margin_pct,
    ROUND(SUM(late_delivery_risk)
        *100.0/COUNT(*), 2)          AS late_risk_pct,
    ROUND(SUM(profit)*100.0
        / SUM(SUM(profit)) OVER(), 2)AS profit_share_pct
FROM supply_chain
GROUP BY customer_segment
ORDER BY profit DESC;


-- ================================================
-- BUSINESS PROBLEM 8: Top 10 Products
-- ================================================
SELECT
    product_name,
    category_name,
    department_name,
    COUNT(DISTINCT order_id)          AS orders,
    SUM(quantity)                     AS units_sold,
    ROUND(SUM(sales), 2)             AS revenue,
    ROUND(SUM(profit), 2)            AS profit,
    ROUND(AVG(profit_ratio)*100, 2)  AS margin_pct,
    RANK() OVER (
        ORDER BY SUM(profit) DESC)   AS profit_rank
FROM supply_chain
GROUP BY product_name,
         category_name,
         department_name
ORDER BY profit DESC
LIMIT 10;


-- ================================================
-- BUSINESS PROBLEM 9: Loss Making Products
-- ================================================
SELECT
    product_name,
    category_name,
    COUNT(DISTINCT order_id)          AS orders,
    ROUND(SUM(sales), 2)             AS revenue,
    ROUND(SUM(profit), 2)            AS total_loss,
    ROUND(AVG(discount_rate)*100, 2) AS avg_discount_pct
FROM supply_chain
WHERE profit < 0
GROUP BY product_name, category_name
HAVING SUM(profit) < -1000
ORDER BY total_loss ASC
LIMIT 10;


-- ================================================
-- BUSINESS PROBLEM 10: Monthly Revenue Trend
-- ================================================
WITH monthly AS (
    SELECT
        YEAR(order_date)              AS yr,
        MONTH(order_date)             AS mn,
        DATE_FORMAT(order_date,
            '%Y-%m')                  AS years_month,
        COUNT(DISTINCT order_id)      AS orders,
        ROUND(SUM(sales), 2)         AS revenue,
        ROUND(SUM(profit), 2)        AS profit,
        SUM(late_delivery_risk)       AS late_count
    FROM supply_chain
    WHERE order_date IS NOT NULL
    GROUP BY yr, mn, years_month
)
SELECT
    years_month,
    orders,
    revenue,
    profit,
    ROUND(profit/revenue*100, 2)     AS margin_pct,
    LAG(revenue) OVER (
        ORDER BY yr, mn)             AS prev_revenue,
    ROUND((revenue -
        LAG(revenue) OVER (
            ORDER BY yr, mn))*100.0
        / NULLIF(LAG(revenue) OVER (
            ORDER BY yr, mn),0)
    , 2)                             AS mom_growth_pct,
    SUM(revenue) OVER (
        ORDER BY yr, mn
        ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW)             AS cumulative_revenue
FROM monthly
ORDER BY yr, mn;


-- ================================================
-- BUSINESS PROBLEM 11: Payment Type Analysis
-- ================================================
SELECT
    payment_type,
    COUNT(DISTINCT order_id)          AS total_orders,
    ROUND(SUM(sales), 2)             AS total_revenue,
    ROUND(AVG(sales), 2)             AS avg_order_value,
    ROUND(SUM(profit), 2)            AS total_profit,
    ROUND(COUNT(DISTINCT order_id)
        *100.0/SUM(COUNT(DISTINCT order_id))
        OVER(), 2)                   AS usage_pct
FROM supply_chain
GROUP BY payment_type
ORDER BY total_revenue DESC;


-- ================================================
-- BUSINESS PROBLEM 12: Order Region Analysis
-- ================================================
SELECT
    order_region,
    market,
    COUNT(DISTINCT order_id)          AS orders,
    ROUND(SUM(sales), 2)             AS revenue,
    ROUND(SUM(profit), 2)            AS profit,
    ROUND(AVG(profit_ratio)*100, 2)  AS margin_pct,
    ROUND(SUM(late_delivery_risk)
        *100.0/COUNT(*), 2)          AS late_risk_pct,
    RANK() OVER (
        ORDER BY SUM(profit) DESC)   AS rank_num
FROM supply_chain
GROUP BY order_region, market
ORDER BY profit DESC
LIMIT 15;







