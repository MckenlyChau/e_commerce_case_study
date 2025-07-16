-- Convert invoice_date from string to DATETIME
ALTER TABLE e_commerce_events ADD invoice_dt DATETIME;
UPDATE e_commerce_events
SET invoice_dt = STR_TO_DATE(invoice_date, '%m/%d/%Y %H:%i');
ALTER TABLE e_commerce_events DROP COLUMN invoice_date;
ALTER TABLE e_commerce_events CHANGE invoice_dt invoice_date DATETIME; 

-- Backup table before cleaning
CREATE TABLE e_commerce_events_backup AS
SELECT * FROM e_commerce_events;

-- Add surrogate key (row ID)
ALTER TABLE e_commerce_events
ADD COLUMN id INT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;

-- Remove duplicate records
WITH duplicate_ids AS (
  SELECT MIN(id) AS keep_id
  FROM e_commerce_events
  GROUP BY invoice_no, stock_code, description, quantity, invoice_date, unit_price, customer_id, country
)
DELETE FROM e_commerce_events
WHERE id NOT IN (
  SELECT keep_id FROM duplicate_ids
);

-- Remove rows with missing customer ID
DELETE FROM e_commerce_events
WHERE customer_id IS NULL;

-- Remove free or promotional items (unit_price = 0)
DELETE FROM e_commerce_events
WHERE unit_price = 0;

-- Classify transaction types
ALTER TABLE e_commerce_events ADD transaction_type VARCHAR(20);
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

-- Clean stock_code for non-item transactions
UPDATE e_commerce_events
SET stock_code = NULL
WHERE stock_code IN ('POST', 'D', 'M', 'BANK CHARGES', 'DOT', 'CRUK', 'PADS');
  
-- Normalize invoice numbers (remove 'C' prefix)
UPDATE e_commerce_events
SET invoice_no = 
  CASE
    WHEN invoice_no LIKE 'C%' THEN SUBSTRING(invoice_no, 2)
    ELSE invoice_no
  END; 
ALTER TABLE e_commerce_events
MODIFY invoice_no INT;

-- Normalize product descriptions (lowercase & trimmed)
UPDATE e_commerce_events
SET description = LOWER(TRIM(description));

-- Separate invoice_date into date and time components
ALTER TABLE e_commerce_events
ADD COLUMN invoice_date_only DATE,
ADD COLUMN invoice_time_only TIME; 
UPDATE e_commerce_events
SET
  invoice_date_only = DATE(invoice_date),
  invoice_time_only = TIME(invoice_date);
ALTER TABLE e_commerce_events
DROP COLUMN invoice_date;
ALTER TABLE e_commerce_events
CHANGE invoice_date_only invoice_date DATE,
CHANGE invoice_time_only invoice_time TIME; 

-- Reorder columns for readability
ALTER TABLE e_commerce_events 
MODIFY COLUMN invoice_date DATE AFTER invoice_no;
ALTER TABLE e_commerce_events 
MODIFY COLUMN invoice_time TIME AFTER invoice_date;
ALTER TABLE e_commerce_events 
MODIFY COLUMN customer_id INT AFTER invoice_time;
ALTER TABLE e_commerce_events 
MODIFY COLUMN country VARCHAR(50) AFTER customer_id;

-- Confirm data types after transformations
DESCRIBE e_commerce_events;

-- Validate cleaned data with key metricg
SELECT 
  COUNT(*) AS total_rows,
  COUNT(DISTINCT invoice_no) AS unique_invoices,
  COUNT(DISTINCT customer_id) AS unique_customers,
  COUNT(DISTINCT stock_code) AS unique_products
FROM e_commerce_events;

-- Add indexes to optimize query performance
CREATE INDEX idx_customer_id ON e_commerce_events(customer_id);
CREATE INDEX idx_invoice_no ON e_commerce_events(invoice_no); 
CREATE INDEX idx_stock_code ON e_commerce_events(stock_code);
CREATE INDEX idx_invoice_date ON e_commerce_events(invoice_date); 
