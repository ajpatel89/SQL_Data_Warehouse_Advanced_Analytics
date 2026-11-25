/*
===============================================================================
Cumulative Analysis
===============================================================================
Purpose:
    - To calculate running totals or moving averages for key metrics.
    - To track performance over time cumulatively.
    - Useful for growth analysis or identifying long-term trends.

SQL Functions Used:
    - Window Functions: OVER(PARTITION BY ...)

===============================================================================
*/

-- Calculate the total sales per month, running total of sales over time & moving average price.
    -- resetting for each year.

SELECT
    order_date,
    total_sales,
    SUM(total_sales) OVER (PARTITION BY order_date ORDER BY order_date) AS running_total_sales,
    AVG(avg_price) OVER (PARTITION BY order_date ORDER BY order_date) AS moving_avg_price
FROM (
    SELECT
        date_trunc('month', order_date) AS order_date,
        SUM(sales_amount)               AS total_sales,
        AVG(price)                      AS avg_price
    FROM
        gold.fact_sales
    WHERE 
        order_date IS NOT NULL
    GROUP BY
        date_trunc('month', order_date)
    ORDER BY
        date_trunc('month', order_date)
);