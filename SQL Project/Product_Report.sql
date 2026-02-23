WITH base_query AS (
SELECT 
	p.product_key,
	p.product_name,
	p.category,
	p.subcategory,
	p.cost,
	f.order_number,
	f.sales_amount,
	f.quantity,
	f.customer_key,
	f.order_date
FROM gold.dim_products p
LEFT JOIN gold.fact_sales f
ON p.product_key = f.product_key
WHERE order_date IS NOT NULL
)

, product_aggregation AS (
SELECT
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity_sold,
	COUNT(DISTINCT customer_key) AS totals_customers,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan,
	MAX(order_date) AS last_order_date,
	ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price
FROM base_query 

GROUP BY
	product_key,
	product_name,
	category,
	subcategory,
	cost
)

SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	CASE
		WHEN total_sales > 50000 THEN 'High-Performer'
		WHEN total_sales between 10000 and 50000 THEN 'Mid-Performer'
		ELSE 'Low-Performer'
	END AS Performance,
	total_orders,
	total_sales,
	total_quantity_sold,
	totals_customers,
	avg_selling_price,
	lifespan,
	DATEDIFF(month, last_order_date, GETDATE()) AS recency,
	CASE WHEN total_orders = 0 THEN 0
		 ELSE total_sales / total_orders
	END AS avg_order_revenue,
	CASE WHEN lifespan = 0 THEN total_sales 
		 ELSE  total_sales / lifespan
	END AS avg_monthly_revenue
FROM product_aggregation