# 📊 SQL Data Analytics & Reporting Project

## 📌 Project Overview
This project demonstrates advanced SQL data analytics techniques applied to a relational sales database (`fact_sales`, `dim_customers`, and `dim_products`). The objective is to extract actionable business insights through time-series trends, cumulative aggregations, Year-over-Year (YoY) product performance, category contribution analysis, and behavioral segmentation, culminating in two reusable SQL views (`report_customers` and `report_products`) for BI dashboards and executive reporting.

![Database Architecture](assets/schema_workflow.png)

---

## 🗄️ Database Schema
The project follows a **Star Schema** data model consisting of one central fact table and two dimension tables:

* **`fact_sales` (Fact Table):** Contains transactional sales records (`order_number`, `product_key`, `customer_key`, `order_date`, `sales_amount`, `quantity`, `price`).
* **`dim_customers` (Dimension Table):** Stores customer demographic details (`customer_key`, `customer_number`, `first_name`, `last_name`, `birthdate`).
* **`dim_products` (Dimension Table):** Stores product catalog metadata (`product_key`, `product_name`, `category`, `subcategory`, `cost`).

---

## 🛠️ Key SQL Concepts Used
* **Aggregate Functions:** `SUM()`, `COUNT(DISTINCT ...)`, `AVG()`, `MIN()`, `MAX()`
* **Date & Time Manipulation:** `YEAR()`, `MONTH()`, `DATETRUNC()`, `DATEDIFF()`, `GETDATE()`
* **Window Functions:** `SUM() OVER()`, `AVG() OVER()` with `PARTITION BY` and `ORDER BY`
* **Common Table Expressions (CTEs):** Multi-stage modular queries (`WITH ... AS`)
* **Conditional Logic:** `CASE WHEN` statements for dynamic customer and product bucketing
* **Data Type & Null Handling:** `CAST()`, `ROUND()`, `NULLIF()`, `CONCAT()`
* **Database Objects:** DDL statements (`CREATE VIEW`, `DROP VIEW`, `OBJECT_ID()`)

---

## 📈 Analytical Modules & Key Insights

### 1. Change Over Time Analysis (`01_change_over_time_analysis.sql`)
* **Objective:** Track sales revenue, distinct customer count, and total quantity sold across years and months.
* **Insight:** Identifies macro growth trends and seasonal peaks/troughs across different months of the year.

### 2. Cumulative Analysis (`02_cumulative_analysis.sql`)
* **Objective:** Compute monthly running total sales and moving average prices using window functions (`SUM() OVER` and `AVG() OVER`).
* **Insight:** Measures long-term revenue momentum and price stability across historical periods.

### 3. Performance Analysis (`03_performance_analysis.sql`)
* **Objective:** Evaluate yearly product sales (`Current_sales`) against each product's historical average (`AVG() OVER (PARTITION BY product_name)`).
* **Insight:** Pinpoints which products are outperforming or underperforming their historical baseline.

### 4. Part-to-Whole Analysis (`04_part_to_whole_analysis.sql`)
* **Objective:** Calculate each product category's percentage contribution to overall company revenue.
* **Insight:** Highlights core revenue-driving categories (Pareto principle) to guide inventory and marketing focus.

### 5. Data Segmentation (`05_data_segmentation.sql`)
* **Product Cost Tiers:** Categorizes products into `Below 100`, `100-500`, `500-1000`, and `Above 1000`.
* **Customer Tiers:** Groups customers by lifespan and total spend:
  * **VIP:** Lifespan ≥ 12 months and spending > $5,000
  * **Regular:** Lifespan ≥ 12 months and spending ≤ $5,000
  * **New:** Lifespan < 12 months

---

## 📋 Consolidated Analytical Reports (SQL Views)

### 👥 Customer Report (`06_report_customers.sql`)
Creates the `report_customers` view consolidating customer demographics, transaction history, and behavioral KPIs:
* **Segments:** `VIP`, `Regular`, `New` and Age Groups (`Under 20`, `20-29`, `30-39`, `40-49`, `50 and above`).
* **Metrics & KPIs:** Total Orders, Total Sales, Total Quantity, Total Products, Lifespan (Months), **Recency**, **Average Order Value (AOV)**, and **Average Monthly Spend**.

![Customer Report Overview](assets/customer_report_overview.png)

### 📦 Product Report (`07_report_products.sql`)
Creates the `report_products` view consolidating product performance and revenue KPIs:
* **Segments:** `High-Performer` (> $50,000), `Mid-Range` ($10,000–$50,000), and `Low-Performer` (< $10,000).
* **Metrics & KPIs:** Total Orders, Total Sales, Total Quantity Sold, Unique Customers, Average Selling Price, Lifespan, **Recency (Months)**, **Average Order Revenue (AOR)**, and **Average Monthly Revenue**.

![Product Report Overview](assets/product_report_overview.png)

---

## 🚀 How to Use
1. Clone this repository:
   ```bash
   git clone [https://github.com/your-username/sql-data-analytics-project.git](https://github.com/your-username/sql-data-analytics-project.git)
   ```
2. Open the `.sql` scripts inside the `scripts/` folder in **SQL Server Management Studio (SSMS)** or **Azure Data Studio**.
3. Ensure your database contains `fact_sales`, `dim_customers`, and `dim_products`, then execute scripts `01` through `07` sequentially.
