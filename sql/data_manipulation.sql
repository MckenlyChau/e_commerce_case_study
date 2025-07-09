-- Add Total Spend Column
ALTER TABLE e_commerce_events ADD total_spend DECIMAL(10,2);
UPDATE e_commerce_events
SET total_spend = unit_price * quantity;
ALTER TABLE e_commerce_events 
MODIFY COLUMN total_spend DECIMAL(10,2) AFTER unit_price;

-- Create table for invoices
CREATE TABLE invoices AS
SELECT
  invoice_no,
  invoice_date,
  MIN(invoice_time) AS invoice_time,
  customer_id,
  country,
  SUM(quantity) AS overall_quantity,
  SUM(total_spend) AS overall_spend,
  GROUP_CONCAT(DISTINCT transaction_type ORDER BY transaction_type SEPARATOR ', ') AS transaction_types
FROM e_commerce_events
GROUP BY invoice_no, invoice_date, customer_id, country
ORDER BY invoice_no;

-- Create table for dates
CREATE TABLE dates AS
SELECT
  invoice_date,
  COUNT(DISTINCT invoice_no) AS invoice_count,
  COUNT(DISTINCT customer_id) AS customer_count,
  GROUP_CONCAT(DISTINCT country ORDER BY country SEPARATOR ', ') AS countries,
  SUM(quantity) AS overall_quantity,
  SUM(total_spend) AS overall_spend,
  GROUP_CONCAT(DISTINCT transaction_type ORDER BY transaction_type SEPARATOR ', ') AS transaction_types
FROM e_commerce_events
GROUP BY invoice_date
ORDER BY invoice_date;

-- Create table for customers
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

-- Create table for valid customers
CREATE TABLE valid_customers AS
SELECT *
FROM customers
WHERE overall_spend > 0
AND overall_quantity > 0;

-- Create table for products
CREATE TABLE products AS
SELECT 
  rd.stock_code,
  rd.description,
  MIN(e.invoice_date) AS earliest_order_date,
  MAX(e.invoice_date) AS latest_order_date,
  SUM(e.quantity) AS overall_quantity,
  ROUND(AVG(e.unit_price), 2) AS average_price,
  MIN(e.unit_price) AS lowest_price,
  MAX(e.unit_price) AS highest_price,
  SUM(e.total_spend) AS overall_spend
FROM (
  SELECT stock_code, description
  FROM (
    SELECT 
      stock_code, 
      description,
      ROW_NUMBER() OVER (PARTITION BY stock_code ORDER BY COUNT(*) DESC) AS rn
    FROM e_commerce_events
    GROUP BY stock_code, description
  ) ranked
  WHERE rn = 1
) rd
JOIN e_commerce_events e ON rd.stock_code = e.stock_code
GROUP BY rd.stock_code, rd.description
ORDER BY rd.stock_code;

-- Create table for countries
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

-- Create table for transaction_types
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

-- Create PRIMARY KEYs for created tables
ALTER TABLE invoices ADD PRIMARY KEY (invoice_no);
ALTER TABLE dates ADD PRIMARY KEY (invoice_date);
ALTER TABLE valid_customers ADD PRIMARY KEY (customer_id);
ALTER TABLE countries ADD PRIMARY KEY (country);
ALTER TABLE products ADD PRIMARY KEY (stock_code);
ALTER TABLE transaction_types ADD PRIMARY KEY (transaction_type);