# NovMart E-Commerce Analytics Dashboard

![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=flat&logo=powerbi&logoColor=black)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat&logo=postgresql&logoColor=white)
![DAX](https://img.shields.io/badge/DAX-Data%20Modeling-5E2D91?style=flat)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)

A 6-page interactive Power BI dashboard analyzing e-commerce performance across sales, products, customers, delivery operations, and customer experience — built on a star-schema data model connected to a PostgreSQL database.

---

## Overview

NovMart is an end-to-end e-commerce analytics project built on a Brazilian e-commerce order dataset (customers, orders, products, sellers, payments, reviews, and delivery logistics). The dashboard gives stakeholders a single place to track revenue performance, customer behavior, delivery reliability, and customer satisfaction — with full cross-filtering across every page.

**Key metrics tracked:**
- ~99,441 total orders / ~15.8M in total sales value
- 96,096+ unique customers, 32,951 unique products
- Average review score of 4.09 / 5
- 96.88% new customers vs 3.12% returning — a key retention insight surfaced by this dashboard

---

## Dashboard Pages

| Page | What it shows |
|---|---|
| **Home** | Branded landing page with navigation to every report page |
| **Executive Overview** | Headline KPIs (orders, sales, customers, products, review score, AOV), monthly sales trend, sales by state, payment method mix, category breakdown, delivery performance, top 5 sellers |
| **Sales & Product** | Revenue by category, product revenue vs freight revenue, top sellers by revenue and order count, average order value trend |
| **Customers** | Unique customer count, new vs returning split, customers by state, top 10 customers by spend, purchase frequency distribution |
| **Operation & Delivery** | Delivery status breakdown (on-time / late / not delivered), average delivery time trend, on-time vs late by state, delivery gap analysis |
| **Customer Experience** | Review score distribution, review score trend over time, delivery status vs. review score correlation, review sentiment breakdown |

---

## Data Model

The dashboard is built on a star schema for reliable cross-filtering across every visual:

```
DateTable ──┐
            ├──▶ fact_orders ──┬──▶ fact_sales ──┬──▶ dim_product
dim_customer┘                  │                 └──▶ dim_seller
                                ├──▶ order_payments
                                └──▶ order_reviews
```

- **fact_orders** — one row per order (status, dates, delivery days) — the central hub table
- **fact_sales** — one row per order line item (price, freight, product, seller)
- **dim_customer / dim_product / dim_seller** — lookup dimensions
- **DateTable** — a dedicated calendar table (marked as the official Date table) enabling month-over-month growth measures and consistent time intelligence across every page
- **order_payments / order_reviews** — supporting fact tables joined through `fact_orders`

---

## Key DAX Measures

```dax
Total Orders = DISTINCTCOUNT('analytics fact_orders'[order_id])
Total Sales = SUM('analytics fact_sales'[item_total_value])
Avg Order Value = DIVIDE([Total Sales], [Total Orders])

Total Sales PM = CALCULATE([Total Sales], DATEADD('DateTable'[Date], -1, MONTH))
Total Sales MoM % = DIVIDE([Total Sales] - [Total Sales PM], [Total Sales PM])

Delivery Status =
IF(ISBLANK([order_delivered_customer_date]), "not_delivered",
IF([order_delivered_customer_date] <= [order_estimated_delivery_date], "on_time_or_early", "late"))
```

---

## Tech Stack

- **Power BI Desktop** — data modeling, DAX measures, report design
- **PostgreSQL** — source database (customers, orders, products, sellers, payments, reviews, geolocation)
- **DAX** — custom measures, calculated columns, time intelligence
- **Power Query (M)** — data transformation and date-only column extraction

---

## Setup

1. Clone this repository.
2. Open `NovMart_Dashboard.pbix` in Power BI Desktop.
3. When prompted, update the PostgreSQL connection details (**Transform data → Data source settings**) to point to your own database instance.
4. Refresh the data model.
5. A custom theme file (`NovMart_Theme.json`) is included — apply it via **View → Themes → Browse for themes** if not already applied.

> Using the template version instead? Open `NovMart_Dashboard.pbit` — you'll be prompted to connect your own PostgreSQL credentials before any data loads, since templates ship structure only, not data.

---

## Repository Structure

```
EDIE/
├── assets/
│   ├── NovMart_Theme.json
│   ├── home_background.svg
│   └── icons/
├── data/
│   └── raw/
│       └── ...
├── docs/
│   ├── data_dictionary.md
│   ├── dax_measures.md
│   └── data_model.png
├── powerbi/
│   ├── .gitkeep
│   ├── novmart_dashboard.pbit
│   └── novmart_dashboard.pbix
├── screenshots/
│   └── ...
├── scripts/
│   └── load_raw_data.py
├── sql/
│   ├── schema_analytics.sql
│   ├── schema_business.sql
│   └── schema_reporting.sql
├── .env.example
├── .gitattributes
├── .gitignore
├── LICENSE
├── README.md
└── requirements.txt
```

---

## Key Insights

- **Retention gap:** Over 96% of customers never place a second order — a clear signal for where a retention/loyalty initiative would have the most impact.
- **Delivery and satisfaction are linked:** Review scores drop measurably for late and non-delivered orders, confirmed directly in the Customer Experience page.
- **Seller concentration:** A small set of top sellers accounts for a disproportionate share of total revenue, visible on the Sales & Product page.

---

## Author

**Built by:** Pranoti Munjankar
**LinkedIn:** https://www.linkedin.com/in/pranoti-munjankar-1760092b9/

---



## Acknowledgments

Built using a Brazilian e-commerce dataset structure inspired by the public Olist e-commerce dataset.
