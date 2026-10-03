-- =====================================================================
-- NovMart | business schema
-- Pre-aggregated summary views, kept separate from the star schema.
-- NOTE: these are representative reconstructions of the aggregation
-- logic based on the known output columns — adjust if your original
-- view definitions differ.
-- =====================================================================

-- ---------------------------------------------------------------------
-- business.kpi_summary  (single-row overall summary — no date grain)
-- ---------------------------------------------------------------------
CREATE VIEW business.kpi_summary AS
SELECT
    COUNT(DISTINCT fo.order_id)                              AS total_orders,
    COUNT(DISTINCT fo.order_id) FILTER (
        WHERE fo.order_status = 'delivered')                 AS delivered_orders,
    SUM(fs.order_item_id IS NOT NULL)::BIGINT                AS total_items_sold,
    SUM(fs.price)                                             AS product_revenue,
    SUM(fs.freight_value)                                     AS freight_revenue,
    SUM(fs.item_total_value)                                  AS total_sales_value,
    AVG(fs.item_total_value)                                  AS average_order_value,
    AVG(orv.review_score)                                     AS average_review_score
FROM analytics.fact_orders fo
LEFT JOIN analytics.fact_sales fs   ON fs.order_id = fo.order_id
LEFT JOIN clean.order_reviews orv   ON orv.order_id = fo.order_id;

-- ---------------------------------------------------------------------
-- business.monthly_sales  (grain: one row per calendar month)
-- ---------------------------------------------------------------------
CREATE VIEW business.monthly_sales AS
SELECT
    DATE_TRUNC('month', fo.order_purchase_timestamp)::DATE   AS month,
    COUNT(DISTINCT fo.order_id)                               AS total_orders,
    COUNT(fs.order_item_id)                                   AS items_sold,
    SUM(fs.price)                                              AS product_revenue,
    SUM(fs.freight_value)                                      AS freight_revenue,
    SUM(fs.item_total_value)                                   AS total_sales_value,
    AVG(fs.item_total_value)                                   AS average_order_value
FROM analytics.fact_orders fo
JOIN analytics.fact_sales fs ON fs.order_id = fo.order_id
GROUP BY 1
ORDER BY 1;
