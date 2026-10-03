# Olist E-Commerce Analytics

**End-to-end e-commerce analytics project focused on marketplace performance, customer value, repeat purchasing, segmentation, and operational performance.**


![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat&logo=postgresql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=flat&logo=powerbi&logoColor=black)
![Pandas](https://img.shields.io/badge/Pandas-150458?style=flat&logo=pandas&logoColor=white)
![NumPy](https://img.shields.io/badge/NumPy-013243?style=flat&logo=numpy&logoColor=white)

---

## Project Snapshot

| Area                   | Details                                                    |
| ---------------------- | ---------------------------------------------------------- |
| **Domain**             | E-commerce / Marketplace                                   |
| **Dataset**            | Olist Brazilian E-Commerce Public Dataset                  |
| **Observation Period** | September 2016 – September 2018                            |
| **Database**           | PostgreSQL                                                 |
| **Programming**        | Python, Pandas, NumPy                                      |
| **BI & Visualization** | Power BI, DAX                                              |
| **Key Areas**          | Sales, customers, RFM, sellers, delivery, reviews, freight |
| **Final Output**       | SQL analytical views + Power BI dashboard                  |

> **Note:** The dataset begins and ends in incomplete calendar periods. Therefore, the analysis does not treat 2016–2018 as three complete calendar years.

---

## 1. Project Overview

This project analyzes the **Olist Brazilian e-commerce marketplace** to understand how marketplace performance, customer value, repeat purchasing, and operational execution interact.

The analysis moves from high-level business performance into customer economics and operational diagnostics:

```text
Raw Marketplace Data
        ↓
Data Validation & Preparation
        ↓
SQL Data Modeling & Metric Construction
        ↓
Marketplace Performance
        ↓
Customer Value & Repeat Behavior
        ↓
RFM Segmentation
        ↓
Delivery & Seller Performance
        ↓
Power BI Dashboard
```

The goal was not simply to report KPIs, but to translate business questions into **well-defined metrics, analytical views, customer segments, and stakeholder-facing visualizations**.

---

# 2. Business Problem

An e-commerce marketplace needs visibility into both **commercial performance** and **customer/operational behavior**.

This project addresses questions such as:

* How is marketplace GMV and order volume changing over time?
* Which categories contribute most to marketplace revenue?
* How is customer value distributed across the customer base?
* What proportion of customers are repeat purchasers?
* How much GMV comes from repeat customers?
* Which repeat customers show different combinations of recency, frequency, and monetary value?
* Which high-value customers have become inactive within the observed dataset?
* How does seller performance vary across volume, GMV, AOV, and delivery reliability?
* What relationship can be observed between delivery performance and review scores?
* How significant is freight relative to product GMV?

---

# 3. Analytical Strategy

The project follows four analytical layers.

### 01 — Marketplace Performance

Analyze:

* GMV
* Orders
* AOV
* Monthly sales trends
* Category performance
* Category scale versus order value

This establishes the overall commercial picture before moving into customer-level analysis.

### 02 — Customer Value

Analyze:

* One-time versus repeat customers
* Customer-level GMV
* Average customer value
* Repeat-customer value
* Revenue concentration

This identifies how marketplace revenue is distributed across customers.

### 03 — Customer Segmentation

Apply **RFM analysis to repeat customers** to understand differences in:

* Recency
* Frequency
* Monetary value

The analysis also identifies high-value customers who have relatively high historical value but low recent activity.

### 04 — Operations & Customer Experience

Analyze:

* Delivery time
* Late delivery
* Seller performance
* Review scores
* Freight burden

This connects commercial performance with operational execution and observed customer experience.

---

# 4. Dataset

The project uses the **Olist Brazilian E-Commerce Public Dataset**, which contains relational data covering customers, orders, products, sellers, payments, and reviews.

### Main Tables

| Table                  | Analytical Purpose                           |
| ---------------------- | -------------------------------------------- |
| `orders`               | Order lifecycle, timestamps, delivery status |
| `order_items`          | Product-level price and freight              |
| `customers`            | Customer identifiers and geography           |
| `products`             | Product and category information             |
| `sellers`              | Seller-level analysis                        |
| `payments`             | Payment information                          |
| `reviews`              | Customer review scores                       |
| `category_translation` | Category translation                         |

The observation period is approximately **September 2016 to September 2018**.

Because the observation window does not contain complete calendar years at both ends, comparisons are interpreted within the available observation period rather than as full-year comparisons.

---

# 5. Data Architecture & Analytical Grain

A key part of the analysis was accounting for the different **grains of the Olist relational data**.

Important grains include:

* **Order level** — one record per order
* **Order-item level** — multiple products/items can belong to one order
* **Customer level** — multiple orders can belong to one customer
* **Seller level** — multiple order items can belong to one seller
* **Review level** — reviews are associated with orders

### Why Grain Matters

Directly joining multiple one-to-many tables can unintentionally duplicate records and inflate metrics.

For example:

```text
orders
   ↓
order_items
   ↓
multiple item rows per order
```

and

```text
orders
   ↓
reviews
   ↓
potentially multiple review-related rows
```

If these relationships are joined without controlling the grain, a single order's GMV can appear multiple times.

For category-level GMV combined with delivery/review analysis, review information is therefore **aggregated to the order level before being joined with item-level order data**.

This preserves the intended GMV calculation and avoids duplication caused by mismatched analytical grains.

---

# 6. Data Preparation & Validation

Python was used for initial data inspection and preparation, including:

* Dataset loading
* Shape and column inspection
* Data-type checks
* Missing-value profiling
* Duplicate checks
* Date handling
* Basic validation

Important data-quality considerations identified during the project include:

* Missing delivery timestamps
* Incomplete review text
* Geolocation duplication/data-quality issues
* Different analytical grains across tables
* Incomplete observation periods

Missing values were not automatically treated as zero or imputed without analytical justification.

---

# 7. Metric Definitions

| Metric                    | Definition                                                                |
| ------------------------- | ------------------------------------------------------------------------- |
| **GMV**                   | Sum of order-item price; freight excluded                                 |
| **Orders**                | Distinct orders                                                           |
| **Customers**             | Distinct customers                                                        |
| **AOV**                   | GMV ÷ distinct orders                                                     |
| **Repeat Customer**       | Customer with more than one order during the available observation period |
| **Repeat Customer Rate**  | Repeat customers ÷ total customers                                        |
| **Late Delivery Rate**    | Late delivered orders ÷ delivered orders                                  |
| **Average Delivery Days** | Average observed delivery duration                                        |
| **Customer GMV**          | Total GMV associated with a customer                                      |
| **Freight Burden**        | Freight considered separately from product GMV                            |

Orders without a customer delivery date are treated separately as **Not Delivered**, rather than automatically being classified as late.

---

# 8. Marketplace Performance

The marketplace analysis focuses on understanding the commercial trajectory of Olist.

### Key analyses

* Monthly GMV and order trends
* AOV
* Category GMV
* Category order volume
* Category-level value differences

The visual approach is designed to answer different questions:

| Analysis                  | Purpose                                                      |
| ------------------------- | ------------------------------------------------------------ |
| **GMV + Orders Trend**    | Understand marketplace activity over time                    |
| **Category Ranking**      | Identify major revenue contributors                          |
| **Category Scale vs AOV** | Separate high-volume categories from higher-value categories |

---

# 9. Customer Value & Repeat Purchasing

Customer analysis revealed a highly concentrated purchase-frequency distribution.

### Key findings

* **96.95%** of customers placed exactly one order.
* **3.05%** of customers were repeat customers.
* Repeat customers contributed approximately **5.62% of GMV**.
* Average total customer GMV for repeat customers was approximately **1.89×** that of one-time customers.

These results are interpreted as observations within the available dataset period.

A customer classified as a one-time customer placed only one order **within the observed period**. This does not establish that the customer never purchased again outside the dataset window.

### Why Repeat Purchasing Matters

The analysis separates **customer count** from **customer economic value**.

This makes it possible to see whether a relatively small repeat-customer population contributes a different level of value than the much larger one-time customer population.

---

# 10. Customer Revenue Concentration

Customer-level GMV is analyzed using **deciles**.

Customers are:

1. Ranked according to total GMV.
2. Divided into ten groups using `NTILE(10)`.
3. Evaluated based on each decile's GMV contribution.
4. Compared using cumulative contribution.

Deciles provide a structured way to examine customer-value concentration without relying on arbitrary customer buckets.

---

# 11. RFM Segmentation

RFM analysis is applied specifically to **repeat customers**.

This decision reflects the highly skewed purchase-frequency distribution: frequency-based segmentation provides limited differentiation for customers who have placed only one order.

### Recency

Measures the time since a customer's most recent purchase relative to the **latest available dataset date**.

### Frequency

Measures the distinct number of orders placed by the customer.

### Monetary

Measures the customer's total GMV.

### Scoring

Each RFM component uses a **1–5 scoring framework**.

Frequency scoring uses explicit project-defined bands because the distribution is highly skewed and contains very few customers with high order counts.

### Project-Defined Segments

The analysis includes segments such as:

* **Champions**
* **Loyal Customers**
* **Potential Loyalists**
* **At Risk**
* **Hibernating**
* **Occasional Repeaters**

These are **analytical segments defined for this project**, not universally validated industry standards.

---

# 12. High-Value Inactive Customers

The analysis also identifies customers who combine:

* Relatively high historical monetary value
* Lower recent purchasing activity

These customers represent an analytical opportunity for further investigation.

However, they are **not automatically classified as churned customers**.

Because the dataset represents a historical observation window, inactivity within the dataset does not prove that a customer permanently stopped purchasing.

---

# 13. Operations & Customer Experience

The operational analysis examines how marketplace execution varies across sellers and orders.

### Delivery Analysis

Key measures include:

* Delivery time
* Delivered orders
* Late orders
* Late delivery rate
* Not Delivered orders

The analysis distinguishes:

```text
On Time
Late
Not Delivered
```

This prevents orders without a customer delivery date from being incorrectly classified as late.

### Review Analysis

Review scores are examined alongside delivery status to explore the **observed relationship** between delivery performance and customer feedback.

This analysis is observational and does **not establish that delivery performance causes a particular review score**.

### Freight Analysis

Freight is excluded from GMV and analyzed separately to understand its burden relative to marketplace product value.

---

# 14. Seller Performance

Seller-level analysis considers:

* Orders
* GMV
* AOV
* Delivered orders
* Late orders
* Late delivery rate

A minimum threshold of **20 orders** is applied when evaluating seller performance.

This is a practical analytical filter intended to reduce unstable performance rates among sellers with very small order volumes. It is **not a statistically optimized threshold**.

---

# 15. Power BI Dashboard

The final analysis is presented through a three-page Power BI dashboard.

## Page 1 — Executive Performance

Provides a high-level view of:

* GMV
* Orders
* Customers
* AOV
* Monthly GMV and order trends
* Category performance
* Customer revenue concentration
* Category scale and value

**Purpose:** Establish the overall marketplace performance before moving into deeper diagnostics.

---

## Page 2 — Customer Value & Repeat Behavior Diagnostics

Focuses on:

* One-time versus repeat customers
* Customer share versus GMV contribution
* Repeat-customer value
* Revenue concentration
* RFM segmentation
* High-value inactive customers

**Purpose:** Understand how customer value is distributed and where repeat-purchase behavior differs across the customer base.

---

## Page 3 — Operations & Customer Experience

Focuses on:

* Late delivery rate
* Late orders
* Average delivery time
* Seller performance
* Delivery reliability
* Review scores by delivery status

**Purpose:** Diagnose operational performance and its observed relationship with customer experience.

## 📊 Dashboard Preview

### 1. Executive Performance
![Executive Performance Dashboard](screenshots/executive_overview.png)

### 2. Customer Value & Repeat Behavior
![Customer Value Dashboard](screenshots/customer_value.png)

### 3. Operations & Customer Experience
![Operations Dashboard](screenshots/operations.png)
---

# 16. Key Findings

### Customer Base

**96.95% of customers placed one order**, while approximately **3.05% were repeat customers**.

### Repeat-Customer Economics

Repeat customers represented approximately **5.62% of GMV**, with approximately **1.89× higher average total customer GMV** than one-time customers.

### Customer Concentration

Customer-level decile analysis demonstrates that marketplace GMV is not evenly distributed across customers, allowing high-value customer groups to be examined separately.

### Operational Performance

Delivery performance is evaluated through late delivery rates, delivery duration, seller-level reliability, and review-score relationships rather than treating delivery as a single KPI.

---

# 17. Key Analytical Decisions

Several methodological decisions were made to keep the analysis aligned with the underlying data.

| Decision                                       | Rationale                                                          |
| ---------------------------------------------- | ------------------------------------------------------------------ |
| **GMV excludes freight**                       | Keeps product sales value separate from shipping economics         |
| **AOV uses distinct orders**                   | Prevents multiple order-item rows from inflating order count       |
| **Repeat = >1 order**                          | Directly captures repeat purchasing within the observation window  |
| **RFM limited to repeat customers**            | Frequency provides little differentiation among one-time customers |
| **Custom frequency bands**                     | Addresses the highly skewed order-frequency distribution           |
| **Customer deciles**                           | Provides a structured view of revenue concentration                |
| **20-order seller threshold**                  | Reduces instability from very small seller samples                 |
| **Not Delivered separated from Late**          | Missing delivery does not automatically mean a late delivery       |
| **Reviews aggregated before item-level joins** | Prevents one-to-many joins from inflating GMV                      |
| **No causal interpretation of reviews**        | Delivery/review analysis is observational                          |
| **No full-year comparison**                    | Dataset boundaries do not represent complete calendar years        |

These decisions are intended to make the metrics more defensible and reduce common analytical errors.

---

# 18. Data Quality & Limitations

### Incomplete Observation Window

The dataset does not represent complete calendar years at both ends of the observation period.

### Repeat Purchasing

One-time customers are defined based on the available observation window. Their classification does not prove that they never purchased again outside the dataset.

### RFM Recency

Recency is calculated relative to the **latest available date in the dataset**, not the current date.

### Missing Delivery Data

Some orders do not contain complete delivery timestamps, requiring separate treatment of undelivered orders.

### Review Data

Review information, particularly review text, can be incomplete.

### Geolocation Quality

The geolocation data contains duplication and data-quality inconsistencies.

### RFM Segments

RFM thresholds and segment definitions are project-specific analytical rules rather than externally validated standards.

### Causality

Observed relationships between delivery performance and review scores should not be interpreted as causal effects.

---

# 19. Future Analysis

Potential extensions to the project include:

* Customer-level repeat-purchase prediction
* Longer-window customer lifecycle analysis
* Predictive churn/repeat-purchase modeling
* Customer Lifetime Value modeling
* More robust seller reliability estimation
* Delivery SLA analysis
* Controlled experiments for customer re-engagement

These are **future analytical extensions**, not part of the completed analysis.

---

# 20. Technical Skills Demonstrated

### Data Analysis

* Python
* Pandas
* NumPy
* Exploratory data analysis
* Data validation

### SQL & Database

* PostgreSQL
* Joins
* CTEs
* Window functions
* Aggregations
* `CASE`
* `FILTER`
* NULL handling
* Analytical views

### Business Intelligence

* Power BI
* DAX
* KPI design
* Interactive dashboards
* Tooltips
* Slicers
* Data storytelling

### Analytical Methods

* Customer segmentation
* RFM analysis
* Revenue concentration
* Trend analysis
* Seller analysis
* Delivery diagnostics
* Metric design

---

# 21. Repository Structure

```text
olist-ecommerce-analytics/
│
├── python/
│   └── olist_eda.ipynb
│
├── sql/
│   └── olist_analysis.sql
│
├── powerbi/
│   └── Olist_Analytics.pbix
│
├── screenshots/
│   ├── executive_overview.png
│   ├── customer_value.png
│   └── operations.png
│
└── README.md
```

> Update the filenames above to match the final repository structure before publishing.

---

# 22. Reproducing the Analysis

The general workflow is:

1. Obtain the Olist dataset.
2. Inspect and validate the datasets using Python.
3. Load the required tables into PostgreSQL.
4. Execute the SQL queries and analytical views.
5. Connect the resulting data to Power BI.
6. Refresh the Power BI model and dashboard.

If the Power BI file uses a local PostgreSQL connection, the database connection must be configured using the user's own environment.

**No credentials or connection secrets should be stored in the repository.**

---

# 23. Project Outcome

This project demonstrates an end-to-end analytics workflow:

```text
Business Question
      ↓
Data Validation
      ↓
Metric Definition
      ↓
SQL Modeling
      ↓
Customer & Operational Analysis
      ↓
Segmentation
      ↓
Power BI Visualization
      ↓
Business Interpretation
```

More importantly, the project demonstrates the ability to think beyond individual queries or visualizations by considering:

* **Business context**
* **Metric definitions**
* **Data grain**
* **Aggregation logic**
* **Customer economics**
* **Segmentation methodology**
* **Operational diagnostics**
* **Data-quality limitations**
* **Appropriate interpretation of analytical results**

---

## Author

**Vanshika Kapil**
BA (Hons) Economics | University of Delhi

**Skills demonstrated:** Python · SQL · PostgreSQL · Power BI · DAX · Customer Analytics · Data Visualization


