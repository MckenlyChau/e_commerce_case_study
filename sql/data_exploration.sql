-- Top Customer Spenders
SELECT customer_id,
	customer_tenure_days,
	invoice_count,
    countries,
    overall_quantity,
    overall_spend
FROM e_commerce_case_study.valid_customers 
ORDER BY overall_spend DESC
LIMIT 5;

-- Sample Top Customers
SELECT * FROM e_commerce_events WHERE customer_id = 14646;
SELECT * FROM e_commerce_events WHERE customer_id = 18102;
SELECT * FROM e_commerce_events WHERE customer_id = 17450;

-- Top Products by Revenue
SELECT stock_code,
	description,
    overall_quantity,
    average_price,
    lowest_price,
    highest_price,
    usual_price,
    overall_spend
FROM products
ORDER BY overall_spend DESC;

-- Top Products by Volume
SELECT stock_code,
	description,
    overall_quantity,
    average_price,
    lowest_price,
    highest_price,
    usual_price,
    overall_spend
FROM products
ORDER BY overall_quantity DESC;

-- Largest Orders by Quantity
SELECT * 
FROM invoices
ORDER BY overall_quantity DESC;

-- Largest Refunds by Quantity
SELECT * 
FROM invoices
ORDER BY overall_quantity;

-- Top Countries by Invoices
SELECT country,
	invoice_count,
    customer_count,
    overall_quantity,
    overall_spend,
    avg_spend_per_customer
FROM countries
ORDER BY invoice_count DESC;

-- Top Countries by Customers
SELECT country,
	invoice_count,
    customer_count,
    overall_quantity,
    overall_spend,
    avg_spend_per_customer
FROM countries
ORDER BY customer_count DESC;

-- Top Countries by Units Sold
SELECT country,
	invoice_count,
    customer_count,
    overall_quantity,
    overall_spend,
    avg_spend_per_customer
FROM countries
ORDER BY overall_quantity DESC;

-- Top Countries by Total Spend
SELECT country,
	invoice_count,
    customer_count,
    overall_quantity,
    overall_spend,
    avg_spend_per_customer
FROM countries
ORDER BY overall_spend DESC;

-- Top Countries by Avg. Spend per Customer
SELECT country,
	invoice_count,
    customer_count,
    overall_quantity,
    overall_spend,
    avg_spend_per_customer
FROM countries
ORDER BY avg_spend_per_customer DESC;

-- Dates with Most Invoices
SELECT invoice_date,
invoice_count,
customer_count,
overall_quantity,
overall_spend
FROM e_commerce_case_study.dates
ORDER BY invoice_count DESC;

-- Dates with Most Customers
SELECT invoice_date,
invoice_count,
customer_count,
overall_quantity,
overall_spend
FROM e_commerce_case_study.dates
ORDER BY customer_count DESC;

-- Dates with Highest Sales Volume
SELECT invoice_date,
invoice_count,
customer_count,
overall_quantity,
overall_spend
FROM e_commerce_case_study.dates
ORDER BY overall_quantity DESC;

-- Dates with Highest Revenue
SELECT invoice_date,
invoice_count,
customer_count,
overall_quantity,
overall_spend
FROM e_commerce_case_study.dates
ORDER BY overall_spend DESC;


