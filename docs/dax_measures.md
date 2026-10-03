# DAX Measures & Calculated Columns Reference

All measures are created in `analytics fact_orders`, `analytics fact_sales`, or a dedicated `_Measures` table unless noted. Calculated columns are created directly on the table they belong to.

## Date Table

```dax
DateTable =
VAR MinDate = MIN('analytics fact_orders'[PurchaseDate])
VAR MaxDate = MAX('analytics fact_orders'[PurchaseDate])
RETURN
ADDCOLUMNS(
    CALENDAR(MinDate, MaxDate),
    "Year", YEAR([Date]),
    "Month Number", MONTH([Date]),
    "Month", FORMAT([Date], "MMM"),
    "Year Month", FORMAT([Date], "YYYY-MM"),
    "Quarter", "Q" & QUARTER([Date])
)
```
`Year Month` has **Sort by column** set to a true chronological key (e.g. Date or Month Number) so it never sorts alphabetically on charts.

## Calculated Columns

**In `analytics fact_orders`:**
```dax
PurchaseDate =
DATE(YEAR([order_purchase_timestamp]), MONTH([order_purchase_timestamp]), DAY([order_purchase_timestamp]))

Delivery Status =
IF(ISBLANK([order_delivered_customer_date]), "not_delivered",
IF([order_delivered_customer_date] <= [order_estimated_delivery_date], "on_time_or_early", "late"))
```

**In `analytics dim_customer`:**
```dax
StateFullName =
SWITCH(
    'analytics dim_customer'[customer_state],
    "SP", "São Paulo, Brazil",
    "RJ", "Rio de Janeiro, Brazil",
    "MG", "Minas Gerais, Brazil",
    "RS", "Rio Grande do Sul, Brazil",
    "PR", "Paraná, Brazil",
    "SC", "Santa Catarina, Brazil",
    "BA", "Bahia, Brazil",
    "DF", "Distrito Federal, Brazil",
    "ES", "Espírito Santo, Brazil",
    "GO", "Goiás, Brazil",
    "PE", "Pernambuco, Brazil",
    "CE", "Ceará, Brazil",
    "PA", "Pará, Brazil",
    "MT", "Mato Grosso, Brazil",
    "MA", "Maranhão, Brazil",
    "MS", "Mato Grosso do Sul, Brazil",
    "PB", "Paraíba, Brazil",
    "PI", "Piauí, Brazil",
    "RN", "Rio Grande do Norte, Brazil",
    "AL", "Alagoas, Brazil",
    "SE", "Sergipe, Brazil",
    "TO", "Tocantins, Brazil",
    "RO", "Rondônia, Brazil",
    "AM", "Amazonas, Brazil",
    "AC", "Acre, Brazil",
    "AP", "Amapá, Brazil",
    "RR", "Roraima, Brazil",
    'analytics dim_customer'[customer_state]
)

Customer Order Count =
CALCULATE(
    DISTINCTCOUNT('analytics dim_customer'[customer_id]),
    ALLEXCEPT('analytics dim_customer', 'analytics dim_customer'[customer_unique_id])
)

Customer Type = IF([Customer Order Count] > 1, "Returning", "New")
```

## Core Measures

```dax
Total Orders = DISTINCTCOUNT('analytics fact_orders'[order_id])
Total Sales = SUM('analytics fact_sales'[item_total_value])
Unique Customers = DISTINCTCOUNT('analytics fact_orders'[customer_id])
True Unique Customers = DISTINCTCOUNT('analytics dim_customer'[customer_unique_id])
Unique Products = DISTINCTCOUNT('analytics fact_sales'[product_id])
Avg Order Value = DIVIDE([Total Sales], [Total Orders])
Avg Review Score = AVERAGE('clean order_reviews'[review_score])

Product Revenue = SUM('analytics fact_sales'[price])
Freight Revenue = SUM('analytics fact_sales'[freight_value])

Customer Spend = SUM('analytics fact_sales'[item_total_value])

Unique Customers by Payment = DISTINCTCOUNT('analytics fact_orders'[customer_id])
```

## Delivery & Operations Measures

```dax
Avg Delivery Days = AVERAGE('analytics fact_orders'[delivery_days])

Delivery Gap Days =
AVERAGEX(
    'analytics fact_orders',
    DATEDIFF('analytics fact_orders'[order_estimated_delivery_date], 'analytics fact_orders'[order_delivered_customer_date], DAY)
)

On Time Rate =
DIVIDE(
    CALCULATE([Total Orders], 'analytics fact_orders'[Delivery Status] = "on_time_or_early"),
    [Total Orders]
)
```

## Customer Experience Measures

```dax
Total Reviews = COUNTROWS('clean order_reviews')

5-Star Rate =
DIVIDE(
    CALCULATE([Total Reviews], 'clean order_reviews'[review_score] = 5),
    [Total Reviews]
)
```

## Month-over-Month Growth Measures

```dax
Total Sales PM = CALCULATE([Total Sales], DATEADD('DateTable'[Date], -1, MONTH))
Total Sales MoM % = DIVIDE([Total Sales] - [Total Sales PM], [Total Sales PM])

Total Orders PM = CALCULATE([Total Orders], DATEADD('DateTable'[Date], -1, MONTH))
Total Orders MoM % = DIVIDE([Total Orders] - [Total Orders PM], [Total Orders PM])

Sales MoM Badge =
VAR Pct = [Total Sales MoM %]
RETURN
IF(
    ISBLANK(Pct), "",
    IF(Pct >= 0, "▲ " & FORMAT(Pct, "0.0%") & " vs last month", "▼ " & FORMAT(ABS(Pct), "0.0%") & " vs last month")
)
```
Duplicate the `PM` / `MoM %` / `Badge` pattern above for any other measure you want trended month-over-month (e.g. Avg Order Value).

## Misc

```dax
Last Refresh = "Last Refresh: " & FORMAT(NOW(), "DD-MMM-YYYY")

StateCentroids =
SUMMARIZE(
    'clean geolocation',
    'clean geolocation'[geolocation_state],
    "AvgLat", AVERAGE('clean geolocation'[geolocation_lat]),
    "AvgLng", AVERAGE('clean geolocation'[geolocation_lng])
)
```

---

## Key relationships (Model view)

| From (1 side) | To (many side) | Cross filter |
|---|---|---|
| DateTable[Date] | fact_orders[PurchaseDate] | Single |
| dim_customer[customer_id] | fact_orders[customer_id] | Single |
| fact_orders[order_id] | fact_sales[order_id] | Single |
| fact_orders[order_id] | order_payments[order_id] | **Both** (needed so payment_type can filter back to customer-level measures) |
| fact_orders[order_id] | order_reviews[order_id] | Single |
| dim_product[product_id] | fact_sales[product_id] | Single |
| dim_seller[seller_id] | fact_sales[seller_id] | Single |
| StateCentroids[geolocation_state] | dim_customer[customer_state] | Single |

`reporting.*` and `business.*` tables are intentionally **not** related to any of the above — see `docs/data_dictionary.md`.
