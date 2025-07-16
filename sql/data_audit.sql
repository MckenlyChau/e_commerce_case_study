-- Date Range
SELECT MIN(invoice_date), MAX(invoice_date)
FROM e_commerce_events;

-- High-Level Overview
SELECT 
  COUNT(*) AS total_rows,
  COUNT(DISTINCT invoice_no) AS unique_invoices,
  COUNT(DISTINCT customer_id) AS unique_customers,
  COUNT(DISTINCT stock_code) AS unique_products
FROM e_commerce_events;

-- Detect Duplicates
WITH dup_cte AS (
  SELECT COUNT(*) AS dup_count
  FROM e_commerce_events
  GROUP BY invoice_no, stock_code, description, quantity, invoice_date, unit_price, customer_id, country
  HAVING COUNT(*) > 1
) -- CTE to Count Duplicates
SELECT SUM(dup_count - 1) AS redundant_rows
FROM dup_cte;

-- NULL Value Checks
Select *
FROM e_commerce_events
WHERE invoice_no IS NULL
OR stock_code IS NULL
OR description IS NULL
OR quantity IS NULL
OR unit_price IS NULL
OR customer_id IS NULL
OR country IS NULL
OR invoice_date IS NULL;

-- Zero Unit Price
SELECT *
FROM e_commerce_events
WHERE unit_price = 0;

-- Zero Unit Price Without NULL Customer
SELECT *
FROM e_commerce_events
WHERE unit_price = 0
AND customer_id IS NOT NULL;

-- High-Value Items
SELECT *
FROM e_commerce_events
ORDER BY unit_price DESC
LIMIT 200;

-- Refund Invoices (Start with "C")
SELECT * 
FROM e_commerce_events 
WHERE invoice_no LIKE 'c%';

-- Negative Quantities Without ‘C’ Invoices
SELECT * 
FROM e_commerce_events 
WHERE quantity < 0
AND invoice_no NOT LIKE 'c%';

-- Sample Investigation of stock_code 85175
SELECT * 
FROM e_commerce_events 
WHERE stock_code = 85175;

-- Sample Investigation of invoice_no 541993
SELECT * 
FROM e_commerce_events 
WHERE invoice_no = 541993;

-- Sample Investigation of stock_code 21035
SELECT * 
FROM e_commerce_events 
WHERE stock_code = 21035;

-- Non-Item Stock Codes
SELECT DISTINCT stock_code
FROM e_commerce_events
WHERE stock_code NOT REGEXP '[0-9]';