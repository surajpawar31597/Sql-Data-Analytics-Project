#1 Change over time analysis
Analyze sales performance over time.

Year on year sales

select
year(order_date) as Order_Year,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customer,
sum(quantity) as total_quantity
from fact_sales
where order_date is not  null
group by year(order_date)
order  by year(order_date)

Month on Month sales

select
Month(order_date) as Order_Month,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customer,
sum(quantity) as total_quantity
from fact_sales
where order_date is not  null
group by month(order_date)
order  by month(order_date)



select
year(order_date) as Order_Year,
Month(order_date) as Order_Month,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customer,
sum(quantity) as total_quantity
from fact_sales
where order_date is not  null
group by year(order_date), month(order_date)  (Combined Year + Month Sales)

#2 Cumulative Analysis:-
Calculate the total sales per month and the running total of sales over time

Select
order_date,
total_sales,
Sum(Total_sales) over (order by order_date) as running_total_sales from
(
Select
datetrunc(Month, order_date) as Order_date,
Sum(sales_amount) as Total_sales
from fact_sales
where order_date is not null
group by datetrunc(Month, order_date)
) as sub
order by order_date (Running total sales)

Select
order_date,
total_sales,
Sum(Total_sales) over ( partition by order_date order by order_date) as running_total_sales from
(
Select
datetrunc(Month, order_date) as Order_date,
Sum(sales_amount) as Total_sales
from fact_sales
where order_date is not null
group by datetrunc(Month, order_date)
) as sub
order by order_date (Running total sales - Partition by year)

Select
order_date,
total_sales,
Sum(Total_sales) over ( partition by order_date order by order_date) as running_total_sales,
Avg(avg_price) over ( partition by order_date order by order_date) as running_avg_price
from
(
Select
datetrunc(Month, order_date) as Order_date,
Sum(sales_amount) as Total_sales,
Avg(price) as avg_price
from fact_sales
where order_date is not null
group by datetrunc(Month, order_date)
) as sub
order by order_date (Running avg price)

#3 Performance Analysis: - Year  on Year
Analyze the yearly performance of products by comparing each product's sales to both its average sales performance and the previous year's sales.

With yearly_product_sales as (
select
year(F.order_date) as order_year,
P.product_name,
Sum(F.sales_amount) as Current_sales
from fact_sales F
left join dim_products P
on F.product_key = P.product_key
where order_date is not null
group by year(F.order_date), P.product_name
)
select
order_year,
product_name,
current_sales,
avg(Current_sales) over (partition by product_name) as Avg_sales
from yearly_product_sales

#4 Part to whole analysis

Which categories contribute the most to overall sales?

With Category_sales as (
Select
category,
sum(sales_amount) as total_sales
from fact_sales F
left Join dim_products P
ON P.product_key = F.product_key
group by category )

Select
category,
total_sales,
sum(total_sales) over () Overall_sales,
concat(round((cast(total_sales as float) / sum(total_sales) over ())*100, 2), '%') as percentage_of_total_sales
from category_sales
order by total_sales Desc

#5 Data Segmentation

Select how many products fall into each segment

With Product_Segment as (
Select
product_key,
product_name,
cost,
case when cost < 100 then 'Below 100'
when cost between 100 and 500 then '100-500'
when cost between 500 and 100 then '500-1000'
Else 'Above 1000'
End as Cost_Range
From dim_products)

select
cost_range,
count(product_key) as total_products
from product_segment
group by cost_range
order by  total_products Desc

Group customers into three segments based on their spending behavior:
- VIP : Customer with at least 12 months of history and spending more than $5000.
Regular : Customer with at least 12 months of history but spending $5000 or less.
New : Customer  with a lifespan less than 12 months.
and find the total number of customers by each group.
With Customer_spending as (
Select
C.customer_key,
Sum(F.sales_amount) as total_spending,
Min(order_date) as first_order,
Max(order_date) as last_order,
Datediff(Month, min(order_date), max(order_date)) as Lifespan
From fact_sales F
Left Join dim_customers C
on F.customer_key = C.customer_key
Group By C.customer_key)

Select
customer_segment,
count(customer_key) as Total_customers
from (
Select
customer_key,
total_spending,
Lifespan,
Case When Lifespan >= 12 and total_spending > 5000 then 'Vip'
when Lifespan >= 12 and total_spending <= 5000 then 'Regular'
ELSE 'New'
End Customer_Segment
from customer_spending ) as sub
group by customer_segment
order by total_customers Desc
/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
    2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
       - total orders
       - total sales
       - total quantity purchased
       - total products
       - lifespan (in months)
    4. Calculates valuable KPIs:
        - recency (months since last order)
        - average order value
        - average monthly spend
===============================================================================
*/

-- =============================================================================
-- Create Report: report_customers
-- =============================================================================
IF OBJECT_ID('report_customers', 'V') IS NOT NULL
    DROP VIEW report_customers;
GO

CREATE VIEW report_customers AS

WITH base_query AS (
    /* 1. Base Query: Retrieve core columns from tables */
    SELECT
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        DATEDIFF(YEAR, c.birthdate, GETDATE()) AS age
    FROM fact_sales AS f
    LEFT JOIN dim_customers AS c
        ON c.customer_key = f.customer_key
    WHERE f.order_date IS NOT NULL
),

customer_aggregation AS (
    /* 2. Customer Aggregations: Summarize metrics at customer level */
    SELECT
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT product_key) AS total_products,
        MAX(order_date) AS last_order_date,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
    FROM base_query
    GROUP BY
        customer_key,
        customer_number,
        customer_name,
        age
)

SELECT
    customer_key,
    customer_number,
    customer_name,
    age,

    CASE
        WHEN age IS NULL THEN 'n/a'
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and above'
    END AS age_group,

    CASE
        WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,

    last_order_date,
    DATEDIFF(MONTH, last_order_date, GETDATE()) AS recency,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    lifespan,

    -- Average order value (AOV)
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE total_sales * 1.0 / total_orders
    END AS avg_order_value,

    -- Average monthly spend
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales * 1.0 / lifespan
    END AS avg_monthly_spend

FROM customer_aggregation;
GO

/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/
-- =============================================================================
-- Create Report: gold.report_products
-- =============================================================================
IF OBJECT_ID('report_products', 'V') IS NOT NULL
    DROP VIEW report_products;
GO

CREATE VIEW report_products AS

WITH base_query AS (
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from fact_sales and dim_products
---------------------------------------------------------------------------*/
    SELECT
        f.order_number,
        f.order_date,
        f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM fact_sales f
    LEFT JOIN dim_products p
        ON f.product_key = p.product_key
    WHERE order_date IS NOT NULL  -- only consider valid sales dates
),

product_aggregations AS (
/*---------------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
---------------------------------------------------------------------------*/
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date))               AS lifespan,
    MAX(order_date)                                                 AS last_sale_date,
    COUNT(DISTINCT order_number)                                    AS total_orders,
    COUNT(DISTINCT customer_key)                                    AS total_customers,
    SUM(sales_amount)                                               AS total_sales,
    SUM(quantity)                                                   AS total_quantity,
    ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price
FROM base_query

GROUP BY
    product_key,
    product_name,
    category,
    subcategory,
    cost
)

/*---------------------------------------------------------------------------
  3) Final Query: Combines all product results into one output
---------------------------------------------------------------------------*/
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_sale_date,
    DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,
    CASE
        WHEN total_sales > 50000 THEN 'High-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Range'
        ELSE 'Low-Performer'
    END                                        AS product_segment,
    lifespan,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,
    -- Average Order Revenue (AOR)
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_revenue,

    -- Average Monthly Revenue
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_revenue

FROM product_aggregations
