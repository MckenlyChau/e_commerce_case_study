-- Add column for customer_types
ALTER TABLE valid_customers
ADD COLUMN customer_type VARCHAR(20);

UPDATE valid_customers
SET customer_type = 
  CASE
    WHEN overall_quantity > 5000
         AND (overall_quantity / invoice_count) > 100
         AND overall_spend > 10000 THEN 'Wholesaler'
	WHEN overall_quantity > 2000
         AND (overall_quantity / invoice_count) > 50
         AND overall_spend > 1000 THEN 'Micro-Wholesaler'
    ELSE 'Retail'
  END;
  
-- Add Column for Customer Level
ALTER TABLE valid_customers
ADD COLUMN customer_level VARCHAR(20);

UPDATE valid_customers
SET customer_level = 
  CASE
  WHEN invoice_count = 1 THEN 'One-Time'
  WHEN invoice_count < 3 AND customer_tenure_days < 30 THEN 'Short-Term'
  WHEN invoice_count >= 3 AND customer_tenure_days < 90 THEN 'Medium-Term'
  WHEN invoice_count >= 5 AND customer_tenure_days >= 90 THEN 'Recurrent'
  ELSE 'Occasional'
END;

-- Add Column for Product level
ALTER TABLE products
ADD COLUMN product_level VARCHAR(20);

UPDATE products
SET product_level = 
  CASE
    WHEN usual_price > 100 THEN 'Premium'
    WHEN usual_price > 50 THEN 'High'
    WHEN usual_price > 10 THEN 'Mid'
    WHEN usual_price > 1 THEN 'Standard'
    ELSE 'Low'
  END;
  
-- Add columns for month_name and month_number
ALTER TABLE dates
ADD COLUMN month_number TINYINT,
ADD COLUMN month_name VARCHAR(10);

UPDATE dates
SET 
  month_number = MONTH(invoice_date),
  month_name = DATE_FORMAT(invoice_date, '%b');
  
  ALTER TABLE dates
MODIFY COLUMN month_number TINYINT AFTER invoice_date,
MODIFY COLUMN month_name VARCHAR(10) AFTER month_number;

-- Create Table for Months
CREATE TABLE months AS
SELECT 
  month_number,
  month_name,
  SUM(invoice_count) AS invoice_count,
  SUM(customer_count) AS customer_count,
  SUM(overall_quantity) AS overall_quantity,
  SUM(overall_spend) AS overall_spend
FROM dates
GROUP BY month_number, month_name
ORDER BY month_number;

