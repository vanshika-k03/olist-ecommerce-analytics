# 🛒 Olist E-Commerce Data Analytics

An end-to-end **E-Commerce Data Analytics project** using the Brazilian Olist marketplace dataset to analyze sales performance, customer behavior, revenue concentration, and delivery operations.

The project combines **Python, PostgreSQL/SQL, and Power BI** to transform raw transactional data into actionable business insights and an interactive stakeholder-facing dashboard.

---

## 📌 Project Overview

Olist is a Brazilian e-commerce marketplace that connects sellers with customers across Brazil.

The objective of this project is to answer key business questions such as:

* How is marketplace sales performance changing over time?
* Which product categories and sellers contribute most to GMV?
* How concentrated is revenue across customers?
* What proportion of customers are repeat buyers?
* What does customer segmentation reveal about high-value customers?
* How do delivery performance and delays affect the customer experience?

The analysis covers data from **September 2016 to September 2018**.

> **Note:** The dataset does not contain complete calendar years at both ends of the period, so year-over-year comparisons are interpreted carefully.

---

## 🎯 Business Objectives

1. Analyze overall marketplace sales and order trends.
2. Measure **GMV, Orders, Customers, and Average Order Value (AOV)**.
3. Identify high-performing product categories and products.
4. Understand customer purchase frequency and retention.
5. Analyze customer value using **RFM segmentation**.
6. Measure revenue concentration across customer segments.
7. Investigate delivery and logistics performance.
8. Build an executive-friendly dashboard for business stakeholders.

---

## 🗂️ Dataset

The project uses the **Olist Brazilian E-Commerce Public Dataset**, consisting of multiple relational tables:

| Table                  | Description                                |
| ---------------------- | ------------------------------------------ |
| `customers`            | Customer and location information          |
| `orders`               | Order status and timestamps                |
| `order_items`          | Products purchased within orders           |
| `payments`             | Payment information                        |
| `reviews`              | Customer reviews and ratings               |
| `products`             | Product attributes                         |
| `sellers`              | Seller information                         |
| `geolocation`          | Brazilian ZIP-code geolocation data        |
| `category_translation` | Portuguese-to-English category translation |

The tables were joined using appropriate primary/foreign-key relationships to create analytical datasets and SQL views.

---

## 🛠️ Tools & Technologies

**Python**

* Pandas
* NumPy
* Matplotlib
* Jupyter Notebook

**SQL / PostgreSQL**

* Joins
* CTEs
* Window Functions
* `LAG()` / `LEAD()`
* `NTILE()`
* Aggregations
* Date & time functions
* Views

**Power BI**

* Data modeling
* DAX measures
* KPI cards
* Interactive visualizations
* Tooltips
* Slicers
* Dashboard design

---

## 🔄 Analytical Workflow

```text
Raw Olist Dataset
       ↓
Data Cleaning & Exploration
       ↓
Python EDA
       ↓
PostgreSQL Data Modeling & SQL Analysis
       ↓
Analytical Views
       ↓
Power BI Data Model
       ↓
Interactive Dashboard
       ↓
Business Insights & Recommendations
```

---

## 🐍 Python Analysis

Python was used for:

* Data loading and inspection
* Missing-value analysis
* Duplicate checks
* Data-type validation
* Exploratory Data Analysis
* Customer/order analysis
* Distribution analysis
* Initial trend exploration

Particular attention was given to missing timestamps in the `orders` table and missing review/comment fields.

---

## 🗄️ SQL Analysis

PostgreSQL was used to perform business-focused analysis and create reusable analytical views.

Key analyses included:

* Monthly GMV and order trends
* Month-over-month growth
* Category-level GMV contribution
* Customer purchase frequency
* Customer revenue deciles
* RFM segmentation
* Revenue concentration
* Delivery-time analysis
* Customer and seller performance

Example SQL techniques used:

```sql
LAG() OVER()
LEAD() OVER()
NTILE()
SUM() OVER()
AVG() OVER()
DATE_TRUNC()
EXTRACT()
NULLIF()
COALESCE()
ROUND()
CAST()
```

---

## 📊 Power BI Dashboard

The final Power BI dashboard is structured around three business perspectives:

### 1. Executive Overview

Focuses on overall marketplace performance.

Key KPIs include:

* **Total GMV:** $13.59M
* **Total Orders:** 99K
* **Total Customers:** 96K
* **AOV:** $136.68

The page also includes monthly GMV and order trends and product/category performance analysis.

### 2. Customer Growth & Retention Diagnostics

Focuses on customer behavior and revenue concentration.

Key areas:

* Repeat customer rate
* Repeat-customer revenue contribution
* Purchase-frequency distribution
* Customer revenue concentration
* RFM segmentation
* High-value customer analysis

A major finding is the highly skewed purchase-frequency distribution:

* **96.95%** of customers placed exactly one order
* **2.80%** placed two orders
* **0.20%** placed three orders
* Only a very small proportion placed four or more orders

### 3. Delivery & Logistics

Focuses on operational performance and customer experience.

Analysis includes:

* Delivery time
* Estimated vs. actual delivery
* Late-delivery patterns
* Order status
* Seller/logistics performance

---

## 🔍 Key Insights

### Customer Retention

The customer base is heavily dominated by one-time purchasers, indicating that **repeat purchasing is relatively limited** within the dataset period.

This makes customer retention and post-purchase engagement important areas for further analysis.

### Revenue Concentration

Customer revenue is not evenly distributed. A relatively small group of customers contributes a disproportionate share of marketplace revenue.

This was examined using **customer deciles and RFM-based segmentation**.

### Sales Performance

Monthly analysis reveals fluctuations in GMV and order volume over the marketplace's observed operating period.

GMV and order trends were analyzed together to distinguish changes driven by **order volume** from changes in **order value**.

### Data Quality

Several fields contain missing values, particularly delivery-related timestamps and review comments.

Rather than automatically dropping these records, missingness was considered in the context of the business process—for example, some missing delivery timestamps can be associated with orders that did not reach a particular fulfillment stage.

---

## 💡 Business Recommendations

Based on the analysis, potential business actions include:

* Develop targeted **post-purchase retention campaigns**.
* Identify high-value customers using RFM segments.
* Encourage second purchases through personalized offers and recommendations.
* Monitor categories and products contributing significantly to GMV.
* Investigate recurring causes of delivery delays.
* Use customer and seller segmentation to prioritize operational improvements.
* Track retention and repeat-purchase KPIs alongside GMV and order growth.

---

## 📁 Project Structure

```text
Olist-Ecommerce-Analytics/
│
├── data/
│   ├── customers.csv
│   ├── orders.csv
│   ├── order_items.csv
│   ├── payments.csv
│   ├── products.csv
│   ├── sellers.csv
│   ├── reviews.csv
│   └── ...
│
├── python/
│   └── olist_eda.ipynb
│
├── sql/
│   ├── sales_analysis.sql
│   ├── customer_analysis.sql
│   ├── rfm_analysis.sql
│   └── analytical_views.sql
│
├── powerbi/
│   └── Olist_Dashboard.pbix
│
├── dashboard/
│   └── dashboard_preview.png
│
└── README.md
```

---

## 📈 Skills Demonstrated

**Data Analysis:** Exploratory Data Analysis, KPI analysis, customer segmentation, cohort/retention analysis

**SQL:** Advanced querying, CTEs, window functions, analytical views, time-series analysis

**Python:** Pandas, NumPy, data cleaning, exploratory analysis, visualization

**Power BI:** Data modeling, DAX, dashboard design, KPI reporting, interactive visualizations

**Business Analytics:** Revenue analysis, customer retention, revenue concentration, operational diagnostics

---

## 👩‍💻 Author

**Vanshika Kapil**

BA (Hons) Economics — University of Delhi

Aspiring **Data Analyst | Business Analyst**

---

## ⭐ Project Takeaway

This project demonstrates an end-to-end analytics workflow—from **raw transactional data → data cleaning → SQL analysis → customer segmentation → Power BI visualization → business recommendations**.

It focuses not only on reporting what happened, but also on identifying **where the business has opportunities to improve customer retention, revenue growth, and operational performance**.

