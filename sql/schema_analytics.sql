-- =====================================================================
-- NovMart | analytics schema (star schema used directly by Power BI)
-- =====================================================================

-- ---------------------------------------------------------------------
-- analytics.fact_orders  (grain: one row per order)
-- ---------------------------------------------------------------------
CREATE TABLE analytics.fact_orders (
    order_id                       TEXT PRIMARY KEY,
    customer_id                    TEXT NOT NULL,
    order_status                   TEXT,
    order_purchase_timestamp       TIMESTAMP,
    order_approved_at              TIMESTAMP,
    order_delivered_carrier_date   TIMESTAMP,
    order_delivered_customer_date  TIMESTAMP,
    order_estimated_delivery_date  TIMESTAMP,
    purchase_year                  INTEGER,
    purchase_month                 INTEGER,
    purchase_day                   INTEGER,
    purchase_day_of_week           INTEGER,
    delivery_days                  NUMERIC
);

-- ---------------------------------------------------------------------
-- analytics.fact_sales  (grain: one row per order line item)
-- ---------------------------------------------------------------------
CREATE TABLE analytics.fact_sales (
    order_id                        TEXT NOT NULL,
    order_item_id                   BIGINT NOT NULL,
    customer_id                     TEXT NOT NULL,
    product_id                      TEXT NOT NULL,
    seller_id                       TEXT NOT NULL,
    order_status                    TEXT,
    order_purchase_timestamp        TIMESTAMP,
    purchase_year                   INTEGER,
    purchase_month                  INTEGER,
    purchase_day                    INTEGER,
    purchase_day_of_week            INTEGER,
    shipping_limit_date              TIMESTAMP,
    price                           NUMERIC,
    freight_value                   NUMERIC,
    item_total_value                NUMERIC,
    product_category_name           TEXT,
    product_category_name_english   TEXT,
    seller_city                     TEXT,
    seller_state                    TEXT,
    customer_city                   TEXT,
    customer_state                  TEXT,
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id)   REFERENCES analytics.fact_orders (order_id),
    FOREIGN KEY (product_id) REFERENCES analytics.dim_product (product_id),
    FOREIGN KEY (seller_id)  REFERENCES analytics.dim_seller (seller_id)
);

-- ---------------------------------------------------------------------
-- analytics.dim_customer  (grain: one row per order-level customer_id)
-- ---------------------------------------------------------------------
CREATE TABLE analytics.dim_customer (
    customer_id             TEXT PRIMARY KEY,
    customer_unique_id      TEXT NOT NULL,   -- true deduplicated person id
    customer_zip_code_prefix BIGINT,
    customer_city           TEXT,
    customer_state          TEXT
);

-- ---------------------------------------------------------------------
-- analytics.dim_product  (grain: one row per product)
-- ---------------------------------------------------------------------
CREATE TABLE analytics.dim_product (
    product_id                      TEXT PRIMARY KEY,
    product_category_name           TEXT,
    product_category_name_english   TEXT,
    product_name_length             INTEGER,
    product_description_length      INTEGER,
    product_photos_qty              INTEGER,
    product_weight_g                NUMERIC,
    product_length_cm               NUMERIC,
    product_height_cm               NUMERIC,
    product_width_cm                NUMERIC,
    product_volume_cm3              NUMERIC
);

-- ---------------------------------------------------------------------
-- analytics.dim_seller  (grain: one row per seller)
-- ---------------------------------------------------------------------
CREATE TABLE analytics.dim_seller (
    seller_id               TEXT PRIMARY KEY,
    seller_zip_code_prefix  BIGINT,
    seller_city             TEXT,
    seller_state            TEXT
);

-- =====================================================================
-- Supporting tables (from the "clean" schema) kept directly in the
-- Power BI model and related to fact_orders via order_id
-- =====================================================================

-- clean.order_payments  (grain: one row per payment installment)
CREATE TABLE clean.order_payments (
    order_id              TEXT NOT NULL,
    payment_sequential    BIGINT,
    payment_type          TEXT,
    payment_installments  INTEGER,
    payment_value         NUMERIC,
    FOREIGN KEY (order_id) REFERENCES analytics.fact_orders (order_id)
);

-- clean.order_reviews  (grain: one row per review)
CREATE TABLE clean.order_reviews (
    review_id                 TEXT PRIMARY KEY,
    order_id                  TEXT NOT NULL,
    review_score              INTEGER,
    review_comment_title      TEXT,
    review_comment_message    TEXT,
    review_creation_date      TIMESTAMP,
    review_answer_timestamp   TIMESTAMP,
    review_sentiment_group    TEXT,
    FOREIGN KEY (order_id) REFERENCES analytics.fact_orders (order_id)
);

-- clean.geolocation  (grain: one row per zip-code-prefix observation; used
-- to build the StateCentroids table for the Sales by State map)
CREATE TABLE clean.geolocation (
    geolocation_zip_code_prefix  BIGINT,
    geolocation_lat              DOUBLE PRECISION,
    geolocation_lng              DOUBLE PRECISION,
    geolocation_city             TEXT,
    geolocation_state            TEXT
);
