-- Investigate top spenders
SELECT customer_id,
	customer_tenure_days,
	invoice_count,
    countries,
    overall_quantity,
    overall_spend
FROM e_commerce_case_study.valid_customers 
ORDER BY overall_spend DESC
LIMIT 5;

-- investigate customer_id 14646
SELECT * FROM e_commerce_events WHERE customer_id = 14646;
-- investigate customer_id 18102
SELECT * FROM e_commerce_events WHERE customer_id = 18102;
-- investigate customer_id 17350
SELECT * FROM e_commerce_events WHERE customer_id = 17450;

-- Investigate top selling items By Spend
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

-- Investigate top selling items By quantity
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

-- Investigate Large Batch orders
SELECT * 
FROM invoices
ORDER BY overall_quantity DESC;

-- Investigate Large Batch refunds
SELECT * 
FROM invoices
ORDER BY overall_quantity;

-- Highest invoice count per country
SELECT country,
	invoice_count,
    customer_count,
    overall_quantity,
    overall_spend,
    avg_spend_per_customer
FROM countries
ORDER BY invoice_count DESC;

-- Highest Customer count per country
SELECT country,
	invoice_count,
    customer_count,
    overall_quantity,
    overall_spend,
    avg_spend_per_customer
FROM countries
ORDER BY customer_count DESC;

-- Highest Quantity count per country
SELECT country,
	invoice_count,
    customer_count,
    overall_quantity,
    overall_spend,
    avg_spend_per_customer
FROM countries
ORDER BY overall_quantity DESC;

-- Highest spend per country
SELECT country,
	invoice_count,
    customer_count,
    overall_quantity,
    overall_spend,
    avg_spend_per_customer
FROM countries
ORDER BY overall_spend DESC;

-- Highest spend per customer country
SELECT country,
	invoice_count,
    customer_count,
    overall_quantity,
    overall_spend,
    avg_spend_per_customer
FROM countries
ORDER BY avg_spend_per_customer DESC;

-- Investigate high invoice date
SELECT invoice_date,
invoice_count,
customer_count,
overall_quantity,
overall_spend
FROM e_commerce_case_study.dates
ORDER BY invoice_count DESC;

-- Investigate high customer date
SELECT invoice_date,
invoice_count,
customer_count,
overall_quantity,
overall_spend
FROM e_commerce_case_study.dates
ORDER BY customer_count DESC;

-- Investigate high quantity date
SELECT invoice_date,
invoice_count,
customer_count,
overall_quantity,
overall_spend
FROM e_commerce_case_study.dates
ORDER BY overall_quantity DESC;

-- Investigate high spend date
SELECT invoice_date,
invoice_count,
customer_count,
overall_quantity,
overall_spend
FROM e_commerce_case_study.dates
ORDER BY overall_spend DESC;


