-- Reformat `invoice_date`
ALTER TABLE e_commerce_events ADD invoice_dt DATETIME;
UPDATE e_commerce_events
SET invoice_dt = STR_TO_DATE(invoice_date, '%m/%d/%Y %H:%i');
ALTER TABLE e_commerce_events DROP COLUMN invoice_date;
ALTER TABLE e_commerce_events CHANGE invoice_dt invoice_date DATETIME;

-- Backup Table
CREATE TABLE e_commerce_events_backup AS
SELECT * FROM e_commerce_events;

-- Create Surrogate id for rows
ALTER TABLE e_commerce_events
ADD COLUMN id INT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;

-- Delete Duplicate Rows
WITH duplicate_ids AS (
  SELECT MIN(id) AS keep_id
  FROM e_commerce_events
  GROUP BY invoice_no, stock_code, description, quantity, invoice_date, unit_price, customer_id, country
)
DELETE FROM e_commerce_events
WHERE id NOT IN (
  SELECT keep_id FROM duplicate_ids
);

-- Delete rows with NULL customer_id
DELETE FROM e_commerce_events
WHERE customer_id IS NULL;

-- Delete rows with 0.00 unit_price
DELETE FROM e_commerce_events
WHERE unit_price = 0;

-- Create Column for Transaction Type
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
UPDATE e_commerce_events
SET stock_code = NULL
WHERE stock_code IN ('POST', 'D', 'M', 'BANK CHARGES', 'DOT', 'CRUK', 'PADS');
  
-- Remove c from invoice_id
UPDATE e_commerce_events
SET invoice_no = 
  CASE
    WHEN invoice_no LIKE 'C%' THEN SUBSTRING(invoice_no, 2)
    ELSE invoice_no
  END;
ALTER TABLE e_commerce_events
MODIFY invoice_no INT;

-- Trimmed and lowercased description for uniformity
UPDATE e_commerce_events
SET description = LOWER(TRIM(description));

-- Splitting date and time
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

-- Rearange for clarity
ALTER TABLE e_commerce_events 
MODIFY COLUMN invoice_date DATE AFTER invoice_no;
ALTER TABLE e_commerce_events 
MODIFY COLUMN invoice_time TIME AFTER invoice_date;
ALTER TABLE e_commerce_events 
MODIFY COLUMN customer_id INT AFTER invoice_time;
ALTER TABLE e_commerce_events 
MODIFY COLUMN country VARCHAR(50) AFTER customer_id;

-- Validating Column types
DESCRIBE e_commerce_events;

-- High-Level Overview After Cleaning
SELECT 
  COUNT(*) AS total_rows,
  COUNT(DISTINCT invoice_no) AS unique_invoices,
  COUNT(DISTINCT customer_id) AS unique_customers,
  COUNT(DISTINCT stock_code) AS unique_products
FROM e_commerce_events;

-- Creating Indexs for main search columns
CREATE INDEX idx_customer_id ON e_commerce_events(customer_id);
CREATE INDEX idx_invoice_no ON e_commerce_events(invoice_no);
CREATE INDEX idx_stock_code ON e_commerce_events(stock_code);
CREATE INDEX idx_invoice_date ON e_commerce_events(invoice_date);
