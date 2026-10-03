# Data Dictionary

Documents every table used in the NovMart Power BI data model. See `sql/schema_analytics.sql` for the DDL.

## analytics.fact_orders — grain: one row per order

| Column | Type | Description |
|---|---|---|
| order_id | text | Primary key, unique order identifier |
| customer_id | text | Order-level customer reference (FK → dim_customer) |
| order_status | text | delivered, shipped, canceled, unavailable, invoiced, processing, created, approved |
| order_purchase_timestamp | timestamp | When the order was placed |
| order_approved_at | timestamp | When payment was approved |
| order_delivered_carrier_date | timestamp | When handed to the carrier |
| order_delivered_customer_date | timestamp | When the customer received it (blank if undelivered) |
| order_estimated_delivery_date | timestamp | Promised delivery date |
| purchase_year / month / day / day_of_week | integer | Date parts of the purchase timestamp |
| delivery_days | numeric | Days between purchase and delivery |
| PurchaseDate *(calculated column)* | date | Date-only version of order_purchase_timestamp, used to relate to DateTable |
| Delivery Status *(calculated column)* | text | on_time_or_early / late / not_delivered |

## analytics.fact_sales — grain: one row per order line item

| Column | Type | Description |
|---|---|---|
| order_id | text | FK → fact_orders |
| order_item_id | bigint | Line item sequence within the order |
| customer_id | text | FK → dim_customer |
| product_id | text | FK → dim_product |
| seller_id | text | FK → dim_seller |
| price | numeric | Item price |
| freight_value | numeric | Shipping cost for this item |
| item_total_value | numeric | price + freight_value |
| product_category_name_english | text | English-translated category |
| customer_state / seller_state | text | 2-letter Brazilian state codes |

## analytics.dim_customer — grain: one row per order-level customer_id

| Column | Type | Description |
|---|---|---|
| customer_id | text | Primary key — unique **per order**, not per person |
| customer_unique_id | text | The true deduplicated person-level identifier |
| customer_state / city | text | Location |
| StateFullName *(calculated column)* | text | Full Brazilian state name, used for map geocoding |
| Customer Order Count *(calculated column)* | integer | Total orders placed by this customer_unique_id |
| Customer Type *(calculated column)* | text | "New" (1 order) or "Returning" (2+ orders) |

## analytics.dim_product — grain: one row per product

| Column | Type | Description |
|---|---|---|
| product_id | text | Primary key |
| product_category_name_english | text | English category name |
| product_weight_g / length_cm / height_cm / width_cm | numeric | Physical dimensions |

## analytics.dim_seller — grain: one row per seller

| Column | Type | Description |
|---|---|---|
| seller_id | text | Primary key |
| seller_state / city | text | Seller location |

## clean.order_payments — grain: one row per payment installment

| Column | Type | Description |
|---|---|---|
| order_id | text | FK → fact_orders |
| payment_type | text | credit_card, boleto, voucher, debit_card, not_defined |
| payment_installments | integer | Number of installments |
| payment_value | numeric | Amount for this payment record |

## clean.order_reviews — grain: one row per review

| Column | Type | Description |
|---|---|---|
| order_id | text | FK → fact_orders |
| review_score | integer | 1–5 star rating |
| review_creation_date | timestamp | When the review was submitted |
| review_sentiment_group | text | positive / neutral / negative (if populated) |

## clean.geolocation — grain: one row per zip-code-prefix observation

| Column | Type | Description |
|---|---|---|
| geolocation_zip_code_prefix | bigint | Postal code prefix |
| geolocation_lat / lng | double precision | Coordinates, averaged per state to build `StateCentroids` |
| geolocation_state | text | Used to relate to dim_customer[customer_state] |

## DateTable — custom calendar table

| Column | Description |
|---|---|
| Date | One row per calendar day, marked as the official Date table |
| Year / Month / Month Number / Year Month / Quarter | Standard calendar breakdowns used across every time-based visual |

---

**Note on `reporting.*` and `business.*` schemas:** these are pre-aggregated, chart-ready summary views (one row per month, per category, per state, etc.) used only as reference/fast-query layers — they are **not** related to the star schema inside Power BI, since mixing both causes ambiguous relationship paths. See `sql/schema_business.sql` and `sql/schema_reporting.sql` for their definitions.
