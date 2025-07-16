-- Calculate and Add Total Spend
ALTER TABLE e_commerce_events ADD total_spend DECIMAL(10,2);
UPDATE e_commerce_events
SET total_spend = unit_price * quantity;
ALTER TABLE e_commerce_events 
MODIFY COLUMN total_spend DECIMAL(10,2) AFTER unit_price;

-- Invoice Summary Table
CREATE TABLE invoices AS
SELECT
  invoice_no,
  invoice_date,
  MIN(invoice_time) AS invoice_time, -- Use earliest time per invoice
  customer_id,
  country,
  SUM(quantity) AS overall_quantity,
  SUM(total_spend) AS overall_spend,
  GROUP_CONCAT(DISTINCT transaction_type ORDER BY transaction_type SEPARATOR ', ') AS transaction_types
FROM e_commerce_events
GROUP BY invoice_no, invoice_date, customer_id, country
ORDER BY invoice_no;

-- Daily Performance Overview
CREATE TABLE dates AS
SELECT
  invoice_date,
  COUNT(DISTINCT invoice_no) AS invoice_count,
  COUNT(DISTINCT customer_id) AS customer_count,
  GROUP_CONCAT(DISTINCT country ORDER BY country SEPARATOR ', ') AS countries,
  SUM(quantity) AS overall_quantity,  -- Sum of Overall Quantity
  SUM(total_spend) AS overall_spend, -- Sum of Overall Spend
  GROUP_CONCAT(DISTINCT transaction_type ORDER BY transaction_type SEPARATOR ', ') AS transaction_types
FROM e_commerce_events
GROUP BY invoice_date
ORDER BY invoice_date;

-- Customer Activity Summary
CREATE TABLE customers AS
SELECT
  customer_id,
  MIN(invoice_date) AS earliest_transaction_date,
  MAX(invoice_date) AS latest_transaction_date,
  DATEDIFF(MAX(invoice_date), MIN(invoice_date)) AS customer_tenure_days,
  COUNT(DISTINCT invoice_no) AS invoice_count,
  GROUP_CONCAT(DISTINCT country ORDER BY country SEPARATOR ', ') AS countries, 
  SUM(quantity) AS overall_quantity,
  SUM(total_spend) AS overall_spend,
  GROUP_CONCAT(DISTINCT transaction_type ORDER BY transaction_type SEPARATOR ', ') AS transaction_types
FROM e_commerce_events
GROUP BY customer_id
ORDER BY customer_id;

-- Active Customers Non-Zero Spend
CREATE TABLE valid_customers AS
SELECT *
FROM customers
WHERE overall_spend > 0
AND overall_quantity > 0;

-- Product Master Table
CREATE TABLE products AS
WITH mode_cte AS (
  SELECT stock_code, unit_price AS usual_price,
         ROW_NUMBER() OVER (PARTITION BY stock_code ORDER BY COUNT(*) DESC) AS rn
  FROM e_commerce_events
  GROUP BY stock_code, unit_price
), -- CTE to determine the most frequent (mode) unit_price for each stock_code
top_descriptions AS (
  SELECT stock_code, description
  FROM (
    SELECT stock_code, description,
           ROW_NUMBER() OVER (PARTITION BY stock_code ORDER BY COUNT(*) DESC) AS rn
    FROM e_commerce_events
    GROUP BY stock_code, description
  ) ranked
  WHERE rn = 1
), -- CTE to select the most commonly used description per stock_code
mode_filtered AS (
  SELECT stock_code, usual_price
  FROM mode_cte
  WHERE rn = 1
) -- CTE to retain only the most frequent unit_price per product
-- Final product-level aggregation query
SELECT 
  td.stock_code,
  td.description,
  MIN(e.invoice_date) AS earliest_order_date, 
  MAX(e.invoice_date) AS latest_order_date,
  SUM(e.quantity) AS overall_quantity,
  ROUND(AVG(e.unit_price), 2) AS average_price,
  MIN(e.unit_price) AS lowest_price,
  MAX(e.unit_price) AS highest_price,
  mf.usual_price,
  SUM(e.total_spend) AS overall_spend
FROM e_commerce_events e
JOIN top_descriptions td ON e.stock_code = td.stock_code
JOIN mode_filtered mf ON e.stock_code = mf.stock_code
GROUP BY td.stock_code, td.description, mf.usual_price
ORDER BY td.stock_code;

-- Country-Level Aggregates
CREATE TABLE countries AS
SELECT
  country,
  MIN(invoice_date) AS earliest_transaction_date,
  MAX(invoice_date) AS latest_transaction_date,
  COUNT(DISTINCT invoice_no) AS invoice_count,
  COUNT(DISTINCT customer_id) AS customer_count,
  SUM(quantity) AS overall_quantity,
  SUM(total_spend) AS overall_spend,
  ROUND(SUM(total_spend) / COUNT(DISTINCT customer_id), 2) AS avg_spend_per_customer,
  GROUP_CONCAT(DISTINCT transaction_type ORDER BY transaction_type SEPARATOR ', ') AS transaction_types
FROM e_commerce_events
GROUP BY country
ORDER BY country;

-- Transaction Type Breakdown
CREATE TABLE transaction_types AS
SELECT
  transaction_type,
  COUNT(DISTINCT invoice_no) AS invoice_count,
  COUNT(DISTINCT customer_id) AS customer_count,
  SUM(quantity) AS overall_quantity,
  SUM(total_spend) AS overall_spend
FROM e_commerce_events
GROUP BY transaction_type
ORDER BY transaction_type;

-- Add Primary Keys to Summary Tables
ALTER TABLE invoices ADD PRIMARY KEY (invoice_no);
ALTER TABLE dates ADD PRIMARY KEY (invoice_date);
ALTER TABLE valid_customers ADD PRIMARY KEY (customer_id);
ALTER TABLE countries ADD PRIMARY KEY (country);
ALTER TABLE products ADD PRIMARY KEY (stock_code);
ALTER TABLE transaction_types ADD PRIMARY KEY (transaction_type);