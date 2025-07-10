-- Convert Date Formats
-- -- Add Column For Temp Date Column
ALTER TABLE e_commerce_events ADD invoice_dt DATETIME;
-- -- Set Temp Column
UPDATE e_commerce_events
SET invoice_dt = STR_TO_DATE(invoice_date, '%m/%d/%Y %H:%i');
-- -- Drop Old Column
ALTER TABLE e_commerce_events DROP COLUMN invoice_date;
-- -- Rename New Column
ALTER TABLE e_commerce_events CHANGE invoice_dt invoice_date DATETIME;

-- Create Backup Before Modifications
CREATE TABLE e_commerce_events_backup AS
SELECT * FROM e_commerce_events;

-- Add Surrogate Row Identifier
ALTER TABLE e_commerce_events
ADD COLUMN id INT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;

-- Remove Duplicate Records
WITH duplicate_ids AS (
  SELECT MIN(id) AS keep_id
  FROM e_commerce_events
  GROUP BY invoice_no, stock_code, description, quantity, invoice_date, unit_price, customer_id, country
)
DELETE FROM e_commerce_events
WHERE id NOT IN (
  SELECT keep_id FROM duplicate_ids
);

-- Remove Rows Without Customer ID
DELETE FROM e_commerce_events
WHERE customer_id IS NULL;

-- Remove Free or Promotional Item
DELETE FROM e_commerce_events
WHERE unit_price = 0;

-- Categorize Transaction Type
-- -- Add Column For Transaction Type
ALTER TABLE e_commerce_events ADD transaction_type VARCHAR(20);
-- -- Set Column For Transaction Type
UPDATE e_commerce_events
SET transaction_type = 
  CASE
    WHEN invoice_no LIKE 'C%' THEN 'Refund'
    WHEN stock_code = 'POST' THEN 'Postage'
    WHEN stock_code = 'D' THEN 'Discount'
    WHEN stock_code = 'M' THEN 'Manual'
    WHEN stock_code = 'BANK CHARGES' THEN 'Bank Charges'
    WHEN stock_code = 'DOT' THEN 'Dotcom Postage'
    WHEN stock_code = 'CRUK' THEN 'CRUK Commission'
    WHEN stock_code = 'PADS' THEN 'Pads'
    ELSE 'Purchase'
  END;
-- -- Remove Stock Codes That Were Moved To New Column
UPDATE e_commerce_events
SET stock_code = NULL
WHERE stock_code IN ('POST', 'D', 'M', 'BANK CHARGES', 'DOT', 'CRUK', 'PADS');
  
-- Clean Invoice Numbers
-- -- Remove 'C' From Invoice Number
UPDATE e_commerce_events
SET invoice_no = 
  CASE
    WHEN invoice_no LIKE 'C%' THEN SUBSTRING(invoice_no, 2)
    ELSE invoice_no
  END;
-- -- Change Invoice Number To Integer Data Type
ALTER TABLE e_commerce_events
MODIFY invoice_no INT;

-- Normalize Product Descriptions
UPDATE e_commerce_events
SET description = LOWER(TRIM(description));

-- Separate Date And Time Fields
-- -- ADD Columns For Date and Time
ALTER TABLE e_commerce_events
ADD COLUMN invoice_date_only DATE,
ADD COLUMN invoice_time_only TIME;
-- -- Set Date And Time For New Columns From Invoice Date
UPDATE e_commerce_events
SET
  invoice_date_only = DATE(invoice_date),
  invoice_time_only = TIME(invoice_date);
-- -- Drop Old Column
ALTER TABLE e_commerce_events
DROP COLUMN invoice_date;
-- -- Rename New Columns
ALTER TABLE e_commerce_events
CHANGE invoice_date_only invoice_date DATE,
CHANGE invoice_time_only invoice_time TIME;

-- Column Order Cleanup
-- -- Move Invoice Date After Invoice Number
ALTER TABLE e_commerce_events 
MODIFY COLUMN invoice_date DATE AFTER invoice_no;
-- -- Move Invoice Time After Invoice Date
ALTER TABLE e_commerce_events 
MODIFY COLUMN invoice_time TIME AFTER invoice_date;
-- -- Move Customer ID After Invoice Time
ALTER TABLE e_commerce_events 
MODIFY COLUMN customer_id INT AFTER invoice_time;
-- -- Move Customer After Customer ID
ALTER TABLE e_commerce_events 
MODIFY COLUMN country VARCHAR(50) AFTER customer_id;

-- Confirm Column Data Types
DESCRIBE e_commerce_events;

-- High-Level Metrics After Cleaning
SELECT 
  COUNT(*) AS total_rows,
  COUNT(DISTINCT invoice_no) AS unique_invoices,
  COUNT(DISTINCT customer_id) AS unique_customers,
  COUNT(DISTINCT stock_code) AS unique_products
FROM e_commerce_events;

-- Add Indexes For Query Optimization
-- -- Index Customer ID
CREATE INDEX idx_customer_id ON e_commerce_events(customer_id);
-- -- Index Invoice Number
CREATE INDEX idx_invoice_no ON e_commerce_events(invoice_no);
-- -- Index Stock Code
CREATE INDEX idx_stock_code ON e_commerce_events(stock_code);
-- -- Index Invoice Date
CREATE INDEX idx_invoice_date ON e_commerce_events(invoice_date);
