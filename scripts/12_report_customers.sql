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
-- Create Report: gold.report_customers
-- =============================================================================
CREATE VIEW gold.report_customers AS

WITH base_query AS (

/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
---------------------------------------------------------------------------*/

SELECT
	f.order_number,
	f.product_key,
	f.order_date,
	f.sales_amount,
	f.quantity,
	c.customer_id,
	c.customer_number,
	CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
	EXTRACT(YEAR FROM AGE(c.birth_date)) AS age,
	c.birth_date
FROM
	gold.fact_sales f
LEFT JOIN gold.dim_customers c
	ON f.customer_id = c.customer_id
WHERE
	f.order_date IS NOT NULL
)	

/*---------------------------------------------------------------------------
2) Customer Aggregations: Summarises key metrics at the customer level
---------------------------------------------------------------------------*/
, customer_aggregation AS(

	SELECT
		customer_id,
		customer_number,
		customer_name,
		age,
		COUNT(DISTINCT order_number) AS total_orders,
		SUM(sales_amount) 			 AS total_sales,
		COUNT(DISTINCT product_key)  AS total_products,
		MAX(order_date)				 AS last_order_date,
		(EXTRACT(YEAR FROM MAX(order_date)) - EXTRACT(YEAR FROM MIN(order_date))) * 12 + 
		(EXTRACT(MONTH FROM MAX(order_date)) - EXTRACT(MONTH FROM MIN(order_date))) AS lifespan_months
	FROM
		base_query
	GROUP BY
		customer_id,
		customer_number,
		customer_name,
		age
)

SELECT
	customer_id,
	customer_number,
	customer_name,
	age,
	CASE WHEN age < 20 THEN 'Under 20'
		 WHEN age BETWEEN 20 AND 29 THEN '20-29'
		 WHEN age BETWEEN 30 AND 39 THEN '30-39'
		 WHEN age BETWEEN 40 AND 49 THEN '40-49'
		 ELSE '50 & Above'
	END AS age_group,
	CASE WHEN lifespan_months >= 12 AND total_sales > 5000 THEN 'VIP'
         WHEN lifespan_months >= 12 AND total_sales < 5000 THEN 'Regular'
         ELSE 'New'
	END AS customer_segment,
	last_order_date,
	(EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM last_order_date)) * 12 +
	(EXTRACT(MONTH FROM CURRENT_DATE) - EXTRACT(MONTH FROM last_order_date)) AS recency_months, -- months since last order
	total_sales,
	total_products,
	lifespan_months,

-- Compute average order value (AOV)

	CASE WHEN total_orders = 0 THEN 0
		 ELSE total_sales / total_orders
	END  AS avg_order_value,

-- Compute average monthly spend

	CASE WHEN lifespan_months = 0 THEN total_sales
		 ELSE total_sales / lifespan_months
	END  AS avg_monthly_spend
FROM
	customer_aggregation