-- =====================================================================
-- NovMart | reporting schema
-- Pre-aggregated, chart-ready views. Kept SEPARATE from the star schema
-- in Power BI — do not relate these to analytics.* tables, since mixing
-- both causes ambiguous relationship paths (see docs/dax_measures.md).
-- NOTE: representative reconstructions based on known output columns.
-- =====================================================================

-- reporting.sales_trend  (grain: one row per month)
CREATE VIEW reporting.sales_trend AS
SELECT
    DATE_TRUNC('month', fo.order_purchase_timestamp)::DATE AS month,
    COUNT(DISTINCT fo.order_id)        AS total_orders,
    COUNT(DISTINCT fo.customer_id)     AS unique_customers,
    COUNT(fs.order_item_id)            AS items_sold,
    SUM(fs.price)                      AS product_revenue,
    SUM(fs.freight_value)              AS freight_value,
    SUM(fs.item_total_value)           AS total_sales_value,
    AVG(fs.item_total_value)           AS average_order_value
FROM analytics.fact_orders fo
JOIN analytics.fact_sales fs ON fs.order_id = fo.order_id
GROUP BY 1
ORDER BY 1;

-- reporting.category_analysis  (grain: one row per product category)
CREATE VIEW reporting.category_analysis AS
SELECT
    fs.product_category_name_english                       AS category,
    COUNT(DISTINCT fs.order_id)                             AS total_orders,
    COUNT(fs.order_item_id)                                 AS items_sold,
    SUM(fs.price)                                           AS product_revenue,
    SUM(fs.freight_value)                                   AS freight_value,
    SUM(fs.item_total_value)                                AS total_sales_value,
    SUM(fs.item_total_value) * 100.0 / SUM(SUM(fs.item_total_value)) OVER ()
                                                              AS sales_contribution_percentage
FROM analytics.fact_sales fs
GROUP BY 1;

-- reporting.seller_analysis  (grain: one row per seller)
CREATE VIEW reporting.seller_analysis AS
SELECT
    fs.seller_id,
    fs.seller_city,
    fs.seller_state,
    COUNT(DISTINCT fs.order_id)   AS total_orders,
    COUNT(fs.order_item_id)       AS items_sold,
    SUM(fs.price)                 AS product_revenue,
    SUM(fs.freight_value)         AS freight_value,
    SUM(fs.item_total_value)      AS total_sales_value,
    AVG(fs.item_total_value)      AS average_order_value
FROM analytics.fact_sales fs
GROUP BY 1, 2, 3;

-- reporting.customer_analysis  (grain: one row per unique customer)
CREATE VIEW reporting.customer_analysis AS
SELECT
    dc.customer_unique_id,
    COUNT(DISTINCT fo.order_id)        AS total_orders,
    COUNT(fs.order_item_id)            AS total_items,
    SUM(fs.item_total_value)           AS total_spend,
    AVG(fs.item_total_value)           AS average_order_value,
    MIN(fo.order_purchase_timestamp)::DATE AS first_order_date,
    MAX(fo.order_purchase_timestamp)::DATE AS last_order_date
FROM analytics.dim_customer dc
JOIN analytics.fact_orders fo ON fo.customer_id = dc.customer_id
JOIN analytics.fact_sales fs  ON fs.order_id = fo.order_id
GROUP BY 1;

-- reporting.delivery_analysis  (grain: one row per order)
CREATE VIEW reporting.delivery_analysis AS
SELECT
    fo.order_id,
    fo.order_status,
    fo.order_purchase_timestamp::DATE          AS purchase_date,
    fo.order_delivered_customer_date::DATE     AS delivered_date,
    fo.order_estimated_delivery_date::DATE     AS estimated_delivery_date,
    fo.delivery_days,
    CASE
        WHEN fo.order_delivered_customer_date IS NULL THEN 'not_delivered'
        WHEN fo.order_delivered_customer_date <= fo.order_estimated_delivery_date THEN 'on_time_or_early'
        ELSE 'late'
    END AS delivery_status
FROM analytics.fact_orders fo;

-- reporting.state_analysis  (grain: one row per customer state)
CREATE VIEW reporting.state_analysis AS
SELECT
    dc.customer_state,
    COUNT(DISTINCT fo.order_id)        AS total_orders,
    COUNT(DISTINCT dc.customer_unique_id) AS unique_customers,
    COUNT(fs.order_item_id)            AS items_sold,
    SUM(fs.item_total_value)           AS total_sales_value,
    AVG(fs.item_total_value)           AS average_order_value,
    SUM(fs.item_total_value) * 100.0 / SUM(SUM(fs.item_total_value)) OVER ()
                                        AS sales_contribution_percentage
FROM analytics.dim_customer dc
JOIN analytics.fact_orders fo ON fo.customer_id = dc.customer_id
JOIN analytics.fact_sales fs  ON fs.order_id = fo.order_id
GROUP BY 1;

-- reporting.review_analysis  (grain: one row per review score, 1-5)
CREATE VIEW reporting.review_analysis AS
SELECT
    review_score,
    CASE
        WHEN review_score >= 4 THEN 'positive'
        WHEN review_score = 3 THEN 'neutral'
        ELSE 'negative'
    END AS review_group,
    COUNT(*) AS review_count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS review_percentage
FROM clean.order_reviews
GROUP BY 1;

-- reporting.executive_kpis  (single-row overall summary — no date grain)
CREATE VIEW reporting.executive_kpis AS
SELECT
    COUNT(DISTINCT fo.order_id)            AS total_orders,
    COUNT(DISTINCT dc.customer_unique_id)  AS unique_customers,
    COUNT(DISTINCT fs.product_id)          AS unique_products,
    COUNT(DISTINCT fs.seller_id)           AS unique_sellers,
    COUNT(fs.order_item_id)                AS total_items_sold,
    SUM(fs.price)                          AS product_revenue,
    SUM(fs.freight_value)                  AS freight_value,
    SUM(fs.item_total_value)               AS total_sales_value,
    AVG(fs.item_total_value)               AS average_order_value
FROM analytics.fact_orders fo
JOIN analytics.dim_customer dc ON dc.customer_id = fo.customer_id
JOIN analytics.fact_sales fs   ON fs.order_id = fo.order_id;
