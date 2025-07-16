-- Customer Segmentation By Type
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
  
-- Customer Segmentation By Engagement
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

-- Add CLV columns to valid_customers
ALTER TABLE valid_customers
ADD COLUMN customer_lifetime_value DECIMAL(10, 2),
ADD COLUMN estimated_clv DECIMAL(10, 2);

-- Historical CLV: Total spend per customer
UPDATE valid_customers
SET customer_lifetime_value = overall_spend;

-- Estimated CLV using customer_type and customer_level
UPDATE valid_customers
SET estimated_clv = 
  (overall_spend / NULLIF(invoice_count, 0)) *                           -- Average Order Value
  (invoice_count / NULLIF(GREATEST(customer_tenure_days, 1), 0)) *       -- Purchase frequency
  CASE 
    WHEN customer_level = 'One-Time' THEN 0				-- No lifetime value
    WHEN customer_type = 'Wholesaler' THEN 730
    WHEN customer_type = 'Micro-Wholesaler' THEN 365
    WHEN customer_level = 'Short-Term' THEN 60			-- customer_level used for segmenting Retail customers
    WHEN customer_level = 'Medium-Term' THEN 120
    WHEN customer_level = 'Occasional' THEN 180
    WHEN customer_level = 'Recurrent' THEN 365
    ELSE 180  -- Default fallback
  END; 

-- Product Tier Assignment by Price
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
  
-- Add Month and Month Number
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

-- Monthly Trends Summary Table
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
ALTER TABLE months ADD PRIMARY KEY (month_number);

-- Refund Summary Table
CREATE TABLE refunds AS
WITH purchase_cte AS (
  SELECT *
  FROM invoices
  WHERE transaction_types LIKE '%Purchase%'
), -- Filter purchase transactions
refund_cte AS (
  SELECT *
  FROM invoices
  WHERE transaction_types LIKE '%Refund%'
), -- Filter refund transactions
matched_cte AS (
  SELECT 
    p.invoice_no AS purchase_invoice,
    r.invoice_no AS refund_invoice,
    p.customer_id,
    p.country,
    p.invoice_date AS purchase_date,
    r.invoice_date AS refund_date,
    DATEDIFF(r.invoice_date, p.invoice_date) AS days_between,
    p.overall_quantity AS purchase_quantity,
    r.overall_quantity AS refund_quantity,
    p.overall_spend AS purchase_spend,
    r.overall_spend AS refund_spend,
    CASE 
      WHEN ABS(p.overall_quantity) = ABS(r.overall_quantity) 
           AND ABS(p.overall_spend) = ABS(r.overall_spend) THEN 'Full'
      ELSE 'Partial'
    END AS refund_type, -- Refund classification: Full vs Partial
    ROW_NUMBER() OVER (
      PARTITION BY p.invoice_no
      ORDER BY DATEDIFF(r.invoice_date, p.invoice_date)
    ) AS refund_rank -- Select closest matching refund per purchase
  FROM purchase_cte p
  JOIN refund_cte r
    ON p.customer_id = r.customer_id
    AND p.country = r.country
    AND DATEDIFF(r.invoice_date, p.invoice_date) BETWEEN 0 AND 14 -- Allow refund window of 14 days
    AND (
		(p.overall_quantity < 50 AND 
		ABS(p.overall_quantity - ABS(r.overall_quantity)) / p.overall_quantity <= 0.50)
		OR
		(p.overall_quantity >= 50 AND 
		ABS(p.overall_quantity - ABS(r.overall_quantity)) / p.overall_quantity <= 0.15)
	) -- Apply 50% tolerance for small orders (under 50 units), 15% otherwise
    AND (
		(p.overall_spend < 50 AND 
		ABS(p.overall_spend - ABS(r.overall_spend)) / p.overall_spend <= 0.50)
		OR
		(p.overall_spend >= 50 AND 
		ABS(p.overall_spend - ABS(r.overall_spend)) / p.overall_spend <= 0.15)
	) -- Apply 50% tolerance for low-spend orders (under $50), 15% otherwise
    AND ABS(r.overall_quantity) <= ABS(p.overall_quantity) -- Ensure refund is not larger than original purchase
    AND ABS(r.overall_spend) <= ABS(p.overall_spend) -- Ensure refund is not larger than original purchase
    AND p.invoice_date < r.invoice_date -- Prevent future-dated purchases
    AND p.overall_quantity > 0 -- Exclude invalid or incomplete purchases
    AND p.overall_spend > 0 -- Exclude invalid or incomplete purchases
) -- Match refunds to purchases based on customer, country, time window, and value proximity
-- Final selection of most relevant refund per purchase
SELECT purchase_invoice,
	refund_invoice,
    customer_id,
    country,
    purchase_date,
    refund_date,
    days_between,
    purchase_quantity,
    ABS(refund_quantity) AS refund_quantity, -- Normalize values for interpretation
    purchase_spend,
    ABS(refund_spend) AS refund_spend, -- Normalize values for interpretation
    refund_type
FROM matched_cte
WHERE refund_rank = 1 -- Keep best-matched refund per purchase
ORDER BY purchase_invoice;
ALTER TABLE refunds ADD PRIMARY KEY (purchase_invoice);

-- Historic Refunds Table: Refund invoices that do not match any known purchase
CREATE TABLE historic_refunds AS
SELECT 
  i.invoice_no,
  i.invoice_date,
  i.invoice_time,
  i.customer_id,
  i.country,
  i.overall_quantity,
  i.overall_spend
FROM invoices i
LEFT JOIN refunds r
  ON i.invoice_no = r.refund_invoice
WHERE r.refund_invoice IS NULL
  AND i.transaction_types LIKE '%Refund%';
ALTER TABLE historic_refunds ADD PRIMARY KEY (invoice_no);
  
  -- Enriched Invoices Table
CREATE TABLE enriched_invoices AS
SELECT 
    i.invoice_no,
    i.invoice_date,
    i.invoice_time,
    i.customer_id,
    v.customer_type,
    i.country,
    i.overall_quantity,
    i.overall_spend,
    i.transaction_types,
    CASE 
        WHEN r.refund_type = 'Full' THEN 'Full Refund'
        WHEN r.refund_type = 'Partial' THEN 'Partial Refund'
        WHEN r2.refund_type = 'Full' THEN 'Full Refund'
        WHEN r2.refund_type = 'Partial' THEN 'Partial Refund'
        WHEN h.invoice_no IS NOT NULL THEN 'Historic Refund'
        ELSE 'Not Refunded'
    END AS refund_status
FROM invoices i
LEFT JOIN refunds r ON i.invoice_no = r.purchase_invoice
LEFT JOIN refunds r2 ON i.invoice_no = r2.refund_invoice
LEFT JOIN historic_refunds h ON i.invoice_no = h.invoice_no
LEFT JOIN valid_customers v ON i.customer_id = v.customer_id
ORDER BY i.invoice_no;
ALTER TABLE enriched_invoices ADD PRIMARY KEY (invoice_no);

-- UNSD classification Table
CREATE TABLE unsd_classifications (
    region_code INT,
    region_name VARCHAR(20),
    sub_region_code INT,
    sub_region_name VARCHAR(40),
    country VARCHAR(30)
    );
    
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/unsd.csv'
INTO TABLE unsd_classifications
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS(
  region_code, region_name, sub_region_code, sub_region_name, country
);

-- Enriched Countries Table
CREATE TABLE enriched_countries AS
	SELECT
    c.country AS country_name,
    u.region_name,
    u.sub_region_name,
    c.earliest_transaction_date,
    c.latest_transaction_date,
    c.invoice_count,
    c.customer_count,
    c.overall_quantity,
    c.overall_spend,
    c.avg_spend_per_customer,
    c.transaction_types
    FROM countries c
    LEFT JOIN unsd_classifications u
    ON c.country = u.country;
ALTER TABLE enriched_countries ADD PRIMARY KEY (country_name);

-- Region Summary Table
CREATE TABLE regions AS 
SELECT 
  CASE 
    WHEN enriched_countries.region_name IS NOT NULL THEN enriched_countries.region_name
    ELSE 'Unspecified'
  END AS region_name,
  GROUP_CONCAT(DISTINCT country_name ORDER BY country_name SEPARATOR ', ') AS countries,
  MIN(earliest_transaction_date) AS earliest_transaction_date,
  MAX(latest_transaction_date) AS latest_transaction_date,
  SUM(invoice_count) AS invoice_count,
  SUM(customer_count) AS customer_count,
  SUM(overall_quantity) AS overall_quantity,
  ROUND(SUM(overall_spend) / NULLIF(SUM(customer_count), 0), 2) AS avg_spend_per_customer
FROM enriched_countries
GROUP BY enriched_countries.region_name;
ALTER TABLE regions ADD PRIMARY KEY (region_name);

-- Sub-Region Summary Table
CREATE TABLE sub_regions AS 
SELECT 
  CASE 
    WHEN enriched_countries.sub_region_name IS NOT NULL THEN enriched_countries.sub_region_name
    ELSE 'Unspecified'
  END AS sub_region_name,
  GROUP_CONCAT(DISTINCT country_name ORDER BY country_name SEPARATOR ', ') AS countries,
  MIN(earliest_transaction_date) AS earliest_transaction_date,
  MAX(latest_transaction_date) AS latest_transaction_date,
  SUM(invoice_count) AS invoice_count,
  SUM(customer_count) AS customer_count,
  SUM(overall_quantity) AS overall_quantity,
  ROUND(SUM(overall_spend) / NULLIF(SUM(customer_count), 0), 2) AS avg_spend_per_customer
FROM enriched_countries
GROUP BY enriched_countries.sub_region_name;
ALTER TABLE sub_regions ADD PRIMARY KEY (sub_region_name);

-- Enrich Valid Customers with Region Data
ALTER TABLE valid_customers
ADD COLUMN regions VARCHAR(100),
ADD COLUMN sub_regions VARCHAR(100);

WITH customer_regions AS (
  SELECT 
    i.customer_id,
    GROUP_CONCAT(DISTINCT ec.region_name ORDER BY ec.region_name SEPARATOR ', ') AS raw_regions,
    GROUP_CONCAT(DISTINCT ec.sub_region_name ORDER BY ec.sub_region_name SEPARATOR ', ') AS raw_sub_regions
  FROM invoices i
  LEFT JOIN enriched_countries ec ON i.country = ec.country_name
  GROUP BY i.customer_id
)
UPDATE valid_customers vc
JOIN (
  SELECT 
    customer_id,
    COALESCE(NULLIF(raw_regions, ''), 'Unspecified') AS regions,
    COALESCE(NULLIF(raw_sub_regions, ''), 'Unspecified') AS sub_regions
  FROM customer_regions
) cr ON vc.customer_id = cr.customer_id
SET 
  vc.regions = cr.regions,
  vc.sub_regions = cr.sub_regions;
ALTER TABLE valid_customers
MODIFY COLUMN regions VARCHAR(100) AFTER countries,
MODIFY COLUMN sub_regions VARCHAR(100) AFTER regions;

-- Enrich Invoices Table with Region Data
ALTER TABLE enriched_invoices
ADD COLUMN region VARCHAR(20),
ADD COLUMN sub_region VARCHAR(40);

UPDATE enriched_invoices ei
JOIN enriched_countries ec
ON ei.country = ec.country_name
SET 
  ei.region = ec.region_name,
  ei.sub_region = ec.sub_region_name;
ALTER TABLE enriched_invoices
MODIFY COLUMN region VARCHAR(20) AFTER country,
MODIFY COLUMN sub_region VARCHAR(40) AFTER region;
UPDATE enriched_invoices
  SET region = CASE WHEN region IS NOT NULL THEN region
  ELSE 'Unspecified' END,
  sub_region = CASE WHEN sub_region IS NOT NULL THEN sub_region
  ELSE 'Unspecified' END;

-- Seasonal Data Columns
ALTER TABLE dates
ADD COLUMN season VARCHAR(10);
UPDATE dates
SET season = CASE
	WHEN month_number IN (3,4,5) THEN 'Spring'
    WHEN month_number IN (6,7,8) THEN 'Summer'
    WHEN month_number IN (9,10,11) THEN 'Autumn'
    WHEN month_number IN (12,1,2) THEN 'Winter'
    END;
ALTER TABLE dates
MODIFY COLUMN season VARCHAR(10) AFTER month_name;

ALTER TABLE months
ADD COLUMN season VARCHAR(10);
UPDATE months
SET season = CASE
	WHEN month_number IN (3,4,5) THEN 'Spring'
    WHEN month_number IN (6,7,8) THEN 'Summer'
    WHEN month_number IN (9,10,11) THEN 'Autumn'
    WHEN month_number IN (12,1,2) THEN 'Winter'
    END;
ALTER TABLE months
MODIFY COLUMN season VARCHAR(10) AFTER month_name;

-- Seasonal Summary Table
CREATE TABLE seasons AS
SELECT 
  season,
  CASE 
    WHEN season = 'Spring' THEN 'Mar - May'
    WHEN season = 'Summer' THEN 'Jun - Aug'
    WHEN season = 'Autumn' THEN 'Sep - Nov'
    WHEN season = 'Winter' THEN 'Dec - Feb'
  END AS season_range,
  SUM(invoice_count) AS invoice_count,
  SUM(customer_count) AS customer_count,
  SUM(overall_quantity) AS overall_quantity,
  SUM(overall_spend) AS overall_spend
FROM months
GROUP BY season
ORDER BY 
  CASE 
    WHEN season = 'Spring' THEN 1
    WHEN season = 'Summer' THEN 2
    WHEN season = 'Autumn' THEN 3
    WHEN season = 'Winter' THEN 4
  END;
ALTER TABLE seasons ADD PRIMARY KEY (season);

-- RFM Model Table
CREATE TABLE rfm AS
SELECT 
  ei.customer_id,
  ei.customer_type,
  GROUP_CONCAT(DISTINCT ei.country ORDER BY ei.country SEPARATOR ', ') AS countries,
  GROUP_CONCAT(DISTINCT ei.region ORDER BY ei.region SEPARATOR ', ') AS regions,
  GROUP_CONCAT(DISTINCT ei.sub_region ORDER BY ei.sub_region SEPARATOR ', ') AS sub_regions,
  MIN(ei.invoice_date) AS earliest_purchase_date,
  MAX(ei.invoice_date) AS last_purchase_date,
  DATEDIFF(MAX(ei.invoice_date), MIN(ei.invoice_date)) AS customer_tenure,
  COUNT(DISTINCT ei.invoice_no) AS frequency,
  SUM(ei.overall_spend) AS monetary,
  DATEDIFF(
    (SELECT MAX(invoice_date) FROM enriched_invoices),
    MAX(ei.invoice_date)
  ) AS recency
FROM enriched_invoices ei
WHERE ei.customer_type IS NOT NULL -- Remove customers not included in Valid Customers
AND ei.refund_status != 'Full Refund'
GROUP BY 
  ei.customer_id,
  ei.customer_type
ORDER BY ei.customer_id;

ALTER TABLE rfm
ADD COLUMN r_score INT,
ADD COLUMN f_score INT,
ADD COLUMN m_score INT,
ADD COLUMN rfm_segment VARCHAR(3),
ADD COLUMN rfm_class VARCHAR(20),
ADD COLUMN estimated_clv INT;

-- Use a CTE to rank customers for each metric
WITH scored AS (
  SELECT 
    customer_id,
    NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
  FROM rfm
)
UPDATE rfm
JOIN scored USING (customer_id)
SET 
  rfm.r_score = scored.r_score,
  rfm.f_score = scored.f_score,
  rfm.m_score = scored.m_score;
  
UPDATE rfm
SET rfm_segment = CONCAT(r_score, f_score, m_score);

UPDATE rfm
SET rfm_class = CASE
  WHEN DATEDIFF(
    (SELECT MAX(invoice_date) FROM enriched_invoices),
    earliest_purchase_date) < 31 THEN 'New' -- Customers who made their first purchase within 30 days of final date recorded as New.
  WHEN rfm_segment = '555' THEN 'Champion'
  WHEN r_score >= 4 AND f_score >= 4 THEN 'Loyal'
  WHEN r_score >= 3 AND f_score <= 2 THEN 'At Risk'
  WHEN r_score <= 2 AND f_score <= 2 THEN 'Churned'
  ELSE 'Other'
END;

-- Estimate Lifetime Value with Non-Refunded orders and RFM class indicator
UPDATE rfm
SET estimated_clv = ROUND(
  (monetary / NULLIF(frequency, 0)) *                           -- Average Order Value
  (frequency / NULLIF(GREATEST(customer_tenure, 1), 0)) *           -- Purchase frequency
  CASE 
	WHEN customer_tenure = 0 THEN 0
    WHEN rfm_class = 'Churned' THEN 0
    WHEN rfm_class = 'Champion' THEN 730
    WHEN rfm_class = 'Loyal' THEN 365
    WHEN rfm_class = 'At Risk' THEN 180
    WHEN rfm_class = 'Other' THEN 90
    ELSE 60
  END
, 2);

-- Country Level RFM Model Table
CREATE TABLE country_rfm AS
SELECT 
  ei.country,
  ei.region,
  ei.sub_region,
  GROUP_CONCAT(DISTINCT ei.customer_type ORDER BY ei.customer_type SEPARATOR ', ') AS customer_types,
  MIN(ei.invoice_date) AS earliest_purchase_date,
  MAX(ei.invoice_date) AS last_purchase_date,
  DATEDIFF(MAX(ei.invoice_date), MIN(ei.invoice_date)) AS country_tenure,
  COUNT(DISTINCT ei.invoice_no) AS frequency,
  SUM(ei.overall_spend) AS monetary,
  DATEDIFF(
    (SELECT MAX(invoice_date) FROM enriched_invoices),
    MAX(ei.invoice_date)
  ) AS recency
FROM enriched_invoices ei
WHERE ei.customer_type IS NOT NULL -- Remove customers not included in Valid Customers
AND ei.refund_status != 'Full Refund'
GROUP BY 
  ei.country,
  ei.region,
  ei.sub_region
ORDER BY ei.country;

ALTER TABLE country_rfm
ADD COLUMN r_score INT,
ADD COLUMN f_score INT,
ADD COLUMN m_score INT,
ADD COLUMN rfm_segment VARCHAR(3),
ADD COLUMN rfm_class VARCHAR(20),
ADD COLUMN estimated_lv INT;

-- Use a CTE to rank for each metric
WITH scored AS (
  SELECT 
    country,
    NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
  FROM country_rfm
)
UPDATE country_rfm
JOIN scored USING (country)
SET 
  country_rfm.r_score = scored.r_score,
  country_rfm.f_score = scored.f_score,
  country_rfm.m_score = scored.m_score;
  
UPDATE country_rfm
SET rfm_segment = CONCAT(r_score, f_score, m_score);

UPDATE country_rfm
SET rfm_class = CASE
  WHEN DATEDIFF(
    (SELECT MAX(invoice_date) FROM enriched_invoices),
    earliest_purchase_date) < 31 THEN 'New' 
  WHEN rfm_segment = '555' THEN 'Champion'
  WHEN r_score >= 4 AND f_score >= 4 THEN 'Loyal'
  WHEN r_score >= 3 AND f_score <= 2 THEN 'At Risk'
  WHEN r_score <= 2 AND f_score <= 2 THEN 'Churned'
  ELSE 'Other'
END;

-- Estimate Lifetime Value with Non-Refunded orders and RFM class indicator
UPDATE country_rfm
SET estimated_lv = ROUND(
  (monetary / NULLIF(frequency, 0)) *                           -- Average Order Value
  (frequency / NULLIF(GREATEST(country_tenure, 1), 0)) *           -- Purchase frequency
  CASE 
	WHEN country_tenure = 0 THEN 0
    WHEN rfm_class = 'Churned' THEN 0
    WHEN rfm_class = 'Champion' THEN 730
    WHEN rfm_class = 'Loyal' THEN 365
    WHEN rfm_class = 'At Risk' THEN 180
    WHEN rfm_class = 'Other' THEN 90
    ELSE 60
  END
, 2);

-- Region Level RFM Model Table
CREATE TABLE region_rfm AS
SELECT 
  ei.region,
  GROUP_CONCAT(DISTINCT ei.sub_region ORDER BY ei.sub_region SEPARATOR ', ') AS sub_regions,
  GROUP_CONCAT(DISTINCT ei.country ORDER BY ei.country SEPARATOR ', ') AS countries,
  GROUP_CONCAT(DISTINCT ei.customer_type ORDER BY ei.customer_type SEPARATOR ', ') AS customer_types,
  MIN(ei.invoice_date) AS earliest_purchase_date,
  MAX(ei.invoice_date) AS last_purchase_date,
  DATEDIFF(MAX(ei.invoice_date), MIN(ei.invoice_date)) AS region_tenure,
  COUNT(DISTINCT ei.invoice_no) AS frequency,
  SUM(ei.overall_spend) AS monetary,
  DATEDIFF(
    (SELECT MAX(invoice_date) FROM enriched_invoices),
    MAX(ei.invoice_date)
  ) AS recency
FROM enriched_invoices ei
WHERE ei.customer_type IS NOT NULL -- Remove customers not included in Valid Customers
AND ei.refund_status != 'Full Refund'
GROUP BY 
  ei.region
ORDER BY ei.region;

ALTER TABLE region_rfm
ADD COLUMN r_score INT,
ADD COLUMN f_score INT,
ADD COLUMN m_score INT,
ADD COLUMN rfm_segment VARCHAR(3),
ADD COLUMN rfm_class VARCHAR(20),
ADD COLUMN estimated_lv INT;

-- Use a CTE to rank for each metric
WITH scored AS (
  SELECT 
    region,
    NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
  FROM region_rfm
)
UPDATE region_rfm
JOIN scored USING (region)
SET 
  region_rfm.r_score = scored.r_score,
  region_rfm.f_score = scored.f_score,
  region_rfm.m_score = scored.m_score;
  
UPDATE region_rfm
SET rfm_segment = CONCAT(r_score, f_score, m_score);

UPDATE region_rfm
SET rfm_class = CASE
  WHEN DATEDIFF(
    (SELECT MAX(invoice_date) FROM enriched_invoices),
    earliest_purchase_date) < 31 THEN 'New' 
  WHEN rfm_segment = '555' THEN 'Champion'
  WHEN r_score >= 4 AND f_score >= 4 THEN 'Loyal'
  WHEN r_score >= 3 AND f_score <= 2 THEN 'At Risk'
  WHEN r_score <= 2 AND f_score <= 2 THEN 'Churned'
  ELSE 'Other'
END;

-- Estimate Lifetime Value with Non-Refunded orders and RFM class indicator
UPDATE region_rfm
SET estimated_lv = ROUND(
  (monetary / NULLIF(frequency, 0)) *                           -- Average Order Value
  (frequency / NULLIF(GREATEST(region_tenure, 1), 0)) *           -- Purchase frequency
  CASE 
	WHEN region_tenure = 0 THEN 0
    WHEN rfm_class = 'Churned' THEN 0
    WHEN rfm_class = 'Champion' THEN 730
    WHEN rfm_class = 'Loyal' THEN 365
    WHEN rfm_class = 'At Risk' THEN 180
    WHEN rfm_class = 'Other' THEN 90
    ELSE 60
  END
, 2);

-- Sub-Region Level RFM Model Table
CREATE TABLE sub_region_rfm AS
SELECT 
  ei.sub_region,
  ei.region,
  GROUP_CONCAT(DISTINCT ei.country ORDER BY ei.country SEPARATOR ', ') AS countries,
  GROUP_CONCAT(DISTINCT ei.customer_type ORDER BY ei.customer_type SEPARATOR ', ') AS customer_types,
  MIN(ei.invoice_date) AS earliest_purchase_date,
  MAX(ei.invoice_date) AS last_purchase_date,
  DATEDIFF(MAX(ei.invoice_date), MIN(ei.invoice_date)) AS sub_region_tenure,
  COUNT(DISTINCT ei.invoice_no) AS frequency,
  SUM(ei.overall_spend) AS monetary,
  DATEDIFF(
    (SELECT MAX(invoice_date) FROM enriched_invoices),
    MAX(ei.invoice_date)
  ) AS recency
FROM enriched_invoices ei
WHERE ei.customer_type IS NOT NULL -- Remove customers not included in Valid Customers
AND ei.refund_status != 'Full Refund'
GROUP BY ei.sub_region,
	ei.region
ORDER BY ei.sub_region;

ALTER TABLE sub_region_rfm
ADD COLUMN r_score INT,
ADD COLUMN f_score INT,
ADD COLUMN m_score INT,
ADD COLUMN rfm_segment VARCHAR(3),
ADD COLUMN rfm_class VARCHAR(20),
ADD COLUMN estimated_lv INT;

-- Use a CTE to rank for each metric
WITH scored AS (
  SELECT 
    sub_region,
    NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
  FROM sub_region_rfm
)
UPDATE sub_region_rfm
JOIN scored USING (sub_region)
SET 
  sub_region_rfm.r_score = scored.r_score,
  sub_region_rfm.f_score = scored.f_score,
  sub_region_rfm.m_score = scored.m_score;
  
UPDATE sub_region_rfm
SET rfm_segment = CONCAT(r_score, f_score, m_score);

UPDATE sub_region_rfm
SET rfm_class = CASE
  WHEN DATEDIFF(
    (SELECT MAX(invoice_date) FROM enriched_invoices),
    earliest_purchase_date) < 31 THEN 'New' 
  WHEN rfm_segment = '555' THEN 'Champion'
  WHEN r_score >= 4 AND f_score >= 4 THEN 'Loyal'
  WHEN r_score >= 3 AND f_score <= 2 THEN 'At Risk'
  WHEN r_score <= 2 AND f_score <= 2 THEN 'Churned'
  ELSE 'Other'
END;

-- Estimate Lifetime Value with Non-Refunded orders and RFM class indicator
UPDATE sub_region_rfm
SET estimated_lv = ROUND(
  (monetary / NULLIF(frequency, 0)) *                           -- Average Order Value
  (frequency / NULLIF(GREATEST(sub_region_tenure, 1), 0)) *           -- Purchase frequency
  CASE 
	WHEN sub_region_tenure = 0 THEN 0
    WHEN rfm_class = 'Churned' THEN 0
    WHEN rfm_class = 'Champion' THEN 730
    WHEN rfm_class = 'Loyal' THEN 365
    WHEN rfm_class = 'At Risk' THEN 180
    WHEN rfm_class = 'Other' THEN 90
    ELSE 60
  END
, 2);

-- Daily FM Model Table
CREATE TABLE daily_fm AS
SELECT 
  ei.invoice_date,
  COUNT(DISTINCT ei.invoice_no) AS frequency,
  SUM(ei.overall_spend) AS monetary
FROM enriched_invoices ei
WHERE ei.customer_type IS NOT NULL  -- Exclude invalid customers
  AND ei.refund_status != 'Full Refund'
GROUP BY ei.invoice_date
ORDER BY ei.invoice_date;

-- Add monetization class column
ALTER TABLE daily_fm
ADD COLUMN m_class VARCHAR(20);

-- Score each day into High, Medium, or Low based on monetary value
WITH scored AS (
  SELECT 
    invoice_date,
    NTILE(3) OVER (ORDER BY monetary DESC) AS m_score
  FROM daily_fm
)
UPDATE daily_fm
JOIN scored USING (invoice_date)
SET m_class = 
  CASE 
    WHEN m_score = 1 THEN 'High'
    WHEN m_score = 2 THEN 'Medium'
    WHEN m_score = 3 THEN 'Low'
  END;

-- Monthly FM Model Table
CREATE TABLE monthly_fm AS
SELECT 
  d.month_number,
  d.month_name,
  COUNT(DISTINCT ei.invoice_no) AS frequency,
  SUM(ei.overall_spend) AS monetary
FROM enriched_invoices ei
LEFT JOIN dates d
ON ei.invoice_date = d.invoice_date
WHERE ei.customer_type IS NOT NULL -- Remove customers not included in Valid Customers
AND ei.refund_status != 'Full Refund'
GROUP BY d.month_number,
	d.month_name
ORDER BY d.month_number;

ALTER TABLE monthly_fm
ADD COLUMN m_class VARCHAR(20);

WITH scored AS (
  SELECT 
    month_number,
    NTILE(3) OVER (ORDER BY monetary DESC) AS m_score
  FROM monthly_fm
)
UPDATE monthly_fm
JOIN scored USING (month_number)
SET m_class = 
  CASE WHEN scored.m_score = 1 THEN 'High'
  WHEN scored.m_score = 2 THEN 'Medium'
  WHEN scored.m_score = 3 THEN 'Low'
  END;

-- Seasonal FM Model Table
CREATE TABLE seasonal_fm AS
SELECT 
  d.season,
  COUNT(DISTINCT ei.invoice_no) AS frequency,
  SUM(ei.overall_spend) AS monetary
FROM enriched_invoices ei
LEFT JOIN dates d
ON ei.invoice_date = d.invoice_date
WHERE ei.customer_type IS NOT NULL -- Remove customers not included in Valid Customers
AND ei.refund_status != 'Full Refund'
GROUP BY d.season;

-- Enriched Transactions
CREATE TABLE enriched_transactions AS
  SELECT 
    ee.invoice_no,
    ee.invoice_date,
    d.month_number,
    d.month_name,
    d.season,
    ee.invoice_time,
    ee.customer_id,
    rfm.customer_type,
    rfm.rfm_class AS customer_class,
    ee.country,
    CASE WHEN ec.region_name IS NOT NULL THEN ec.region_name ELSE 'Unspecified' END AS region,
    CASE WHEN ec.sub_region_name IS NOT NULL THEN ec.sub_region_name ELSE 'Unspecified' END AS sub_region,
    ee.stock_code,
    p.product_level,
    ee.description,
    ee.quantity,
    ee.unit_price,
    p.usual_price,
    ee.total_spend,
    ee.transaction_type,
    ei.refund_status
  FROM e_commerce_events ee
  JOIN dates d ON ee.invoice_date = d.invoice_date
  INNER JOIN rfm ON ee.customer_id = rfm.customer_id -- Only include transactions for Customers in RFM
  JOIN enriched_countries ec ON ee.country = ec.country_name
  JOIN products p ON ee.stock_code = p.stock_code
  JOIN enriched_invoices ei ON ee.invoice_no = ei.invoice_no;
-- Add surrogate key (row ID)
ALTER TABLE enriched_transactions
ADD COLUMN id INT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;

-- Product Level RFM Table
CREATE TABLE product_rfm AS
WITH season_cte AS (
  -- Rank seasons by frequency per product
  SELECT 
    stock_code, 
    season, 
    COUNT(*) AS season_count,
    ROW_NUMBER() OVER (PARTITION BY stock_code ORDER BY COUNT(*) DESC) AS rn
  FROM enriched_transactions
  GROUP BY stock_code, season
),
season_final AS (
  -- Keep top season per product
  SELECT 
    stock_code, 
    season AS top_season
  FROM season_cte
  WHERE rn = 1
),
month_cte AS (
  -- Rank months by frequency per product
  SELECT 
    stock_code, 
    month_name, 
    COUNT(*) AS month_count,
    ROW_NUMBER() OVER (PARTITION BY stock_code ORDER BY COUNT(*) DESC) AS rn
  FROM enriched_transactions
  GROUP BY stock_code, month_name
),
month_final AS (
  -- Keep top month per product
  SELECT 
    stock_code, 
    month_name AS top_month
  FROM month_cte
  WHERE rn = 1
),
desc_cte AS (
  -- Find most common description per stock code
  SELECT 
    stock_code,
    description,
    ROW_NUMBER() OVER (PARTITION BY stock_code ORDER BY COUNT(*) DESC) AS rn
  FROM enriched_transactions
  GROUP BY stock_code, description
),
desc_final AS (
  SELECT 
    stock_code,
    description AS common_description
  FROM desc_cte
  WHERE rn = 1
)

-- Final Product RFM table with seasonality and performance metrics
SELECT
  et.stock_code,
  df.common_description AS description,
  mf.top_month,
  sf.top_season,
  MIN(et.invoice_date) AS earliest_purchase_date,
  MAX(et.invoice_date) AS last_purchase_date,
  DATEDIFF(MAX(et.invoice_date), MIN(et.invoice_date)) AS product_tenure,
  SUM(et.quantity) AS overall_quantity,
  ROUND(AVG(et.unit_price), 2) AS average_price,
  MIN(et.unit_price) AS lowest_price,
  MAX(et.unit_price) AS highest_price,
  et.usual_price,
  et.product_level,
  COUNT(DISTINCT et.invoice_no) AS frequency,
  SUM(et.total_spend) AS monetary,
  DATEDIFF(
    (SELECT MAX(invoice_date) FROM enriched_transactions),
    MAX(et.invoice_date)
  ) AS recency
FROM enriched_transactions et
JOIN season_final sf ON et.stock_code = sf.stock_code
JOIN month_final mf ON et.stock_code = mf.stock_code
JOIN desc_final df ON et.stock_code = df.stock_code
WHERE et.refund_status != 'Full Refund'
GROUP BY 
  et.stock_code, 
  df.common_description, 
  mf.top_month, 
  sf.top_season, 
  et.usual_price,
  et.product_level;

-- Add RFM Columns to Product RFM Table
ALTER TABLE product_rfm
ADD COLUMN r_score INT,
ADD COLUMN f_score INT,
ADD COLUMN m_score INT,
ADD COLUMN rfm_segment VARCHAR(3),
ADD COLUMN rfm_class VARCHAR(20),
ADD COLUMN estimated_value DECIMAL(10,2);

-- Assign RFM Scores using NTILE (lower recency = better, higher frequency/spend = better)
WITH scored AS (
  SELECT 
    stock_code,
    NTILE(5) OVER (ORDER BY recency ASC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency DESC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary DESC) AS m_score
  FROM product_rfm
)
UPDATE product_rfm pr
JOIN scored s ON pr.stock_code = s.stock_code
SET 
  pr.r_score = s.r_score,
  pr.f_score = s.f_score,
  pr.m_score = s.m_score;

-- Create Segment Code (e.g. 555, 343)
UPDATE product_rfm
SET rfm_segment = CONCAT(r_score, f_score, m_score);

-- Classify RFM Segment
UPDATE product_rfm
SET rfm_class = CASE
  WHEN rfm_segment = '555' THEN 'Top Seller'
  WHEN r_score >= 4 AND f_score >= 4 THEN 'Consistent Performer'
  WHEN r_score <= 2 AND f_score >= 4 THEN 'Old Favorite'
  WHEN r_score >= 4 AND f_score <= 2 THEN 'New Trending'
  WHEN r_score <= 2 AND f_score <= 2 THEN 'Low Performer'
  ELSE 'Average'
END;

-- Estimate Value based on activity and price (e.g. potential revenue)
UPDATE product_rfm
SET estimated_value = ROUND(
  (monetary / NULLIF(frequency, 0)) *                          -- AOV
  (frequency / NULLIF(GREATEST(product_tenure, 1), 0)) *       -- Frequency rate
  CASE 
    WHEN product_tenure = 0 THEN 0
    WHEN rfm_class = 'Top Seller' THEN 730
    WHEN rfm_class = 'Consistent Performer' THEN 365
    WHEN rfm_class = 'New Trending' THEN 180
    WHEN rfm_class = 'Old Favorite' THEN 90
    WHEN rfm_class = 'Low Performer' THEN 30
    ELSE 60
  END
, 2);

-- Find values with trailing spaces or carriage returns
SELECT DISTINCT country
FROM enriched_invoices
WHERE country LIKE '% ' OR country LIKE '%\r' OR country LIKE '%\n';
SELECT DISTINCT region_name
FROM enriched_countries
WHERE region_name LIKE '% ' OR region_name LIKE '%\r' OR region_name LIKE '%\n';
SELECT DISTINCT sub_region_name
FROM enriched_countries
WHERE sub_region_name LIKE '% ' OR sub_region_name LIKE '%\r' OR sub_region_name LIKE '%\n';

-- Trim spaces and remove carriage returns/newlines
UPDATE enriched_invoices
SET country = REPLACE(REPLACE(TRIM(country), '\r', ''), '\n', '');
UPDATE enriched_transactions
SET country = REPLACE(REPLACE(TRIM(country), '\r', ''), '\n', '');
UPDATE rfm
SET countries = REPLACE(REPLACE(TRIM(countries), '\r', ''), '\n', '');
UPDATE country_rfm
SET country = REPLACE(REPLACE(TRIM(country), '\r', ''), '\n', '');
UPDATE region_rfm
SET countries = REPLACE(REPLACE(TRIM(countries), '\r', ''), '\n', '');
UPDATE sub_region_rfm
SET countries = REPLACE(REPLACE(TRIM(countries), '\r', ''), '\n', '');
-- 

  