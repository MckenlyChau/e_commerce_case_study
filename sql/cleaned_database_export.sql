(
  SELECT 'id', 'invoice_no', 'invoice_date', 'month_number', 'month_name', 'season', 'invoice_time',
         'customer_id', 'customer_type', 'customer_class', 'country', 'region', 'sub_region',
         'stock_code', 'product_level', 'description', 'quantity', 'unit_price', 'usual_price',
         'total_spend', 'transaction_type', 'refund_status'
)
UNION ALL
(
  SELECT 
    id, invoice_no, invoice_date, month_number, month_name, season, invoice_time,
    customer_id, customer_type, customer_class, country, region, sub_region,
    stock_code, product_level, description, quantity, unit_price, usual_price,
    total_spend, transaction_type, refund_status
  FROM transactions
)
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n';

(
  SELECT 'invoice_no', 'invoice_date', 'invoice_time', 'customer_id', 'customer_type', 'country', 
		 'region', 'sub_region', 'overall_quantity', 'overall_spend', 'transaction_types', 'refund_status'
)
UNION ALL
(
  SELECT 
    invoice_no, invoice_date, invoice_time, customer_id, customer_type, country, 
		 region, sub_region, overall_quantity, overall_spend, transaction_types, refund_status 
  FROM invoices
)
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/invoices.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"' 
LINES TERMINATED BY '\n';

(
  SELECT 'customer_id', 'customer_type', 'countries', 'regions', 'sub_regions', 'earliest_purchase_date', 
         'last_purchase_date', 'customer_tenure', 'frequency', 'monetary', 'recency', 'r_score', 'f_score', 'm_score', 
		 'rfm_segment', 'rfm_class', 'estimated_clv'
)
UNION ALL
(
  SELECT 
    customer_id, customer_type, countries, regions, sub_regions, earliest_purchase_date, 
         last_purchase_date, customer_tenure, frequency, monetary, recency, r_score, f_score, m_score, 
		 rfm_segment, rfm_class, estimated_clv
  FROM customers
)
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customers.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"' 
LINES TERMINATED BY '\n';

(
  SELECT 'country', 'region', 'sub_region', 'customer_types', 'earliest_purchase_date', 
         'last_purchase_date', 'country_tenure', 'frequency', 'monetary', 'recency', 'r_score', 'f_score', 'm_score', 
		 'rfm_segment', 'rfm_class', 'estimated_lv'
)
UNION ALL
(
  SELECT 
    country, region, sub_region, customer_types, earliest_purchase_date, 
         last_purchase_date, country_tenure, frequency, monetary, recency, r_score, f_score, m_score, 
		 rfm_segment, rfm_class, estimated_lv
  FROM countries
)
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/countries.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"' 
LINES TERMINATED BY '\n';

(
  SELECT 'region', 'sub_regions', 'countries', 'customer_types', 'earliest_purchase_date', 
         'last_purchase_date', 'region_tenure', 'frequency', 'monetary', 'recency', 'r_score', 'f_score', 'm_score', 
		 'rfm_segment', 'rfm_class', 'estimated_lv'
)
UNION ALL
(
  SELECT 
    region, sub_regions, countries, customer_types, earliest_purchase_date, 
         last_purchase_date, region_tenure, frequency, monetary, recency, r_score, f_score, m_score, 
		 rfm_segment, rfm_class, estimated_lv
  FROM regions
)
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/regions.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"' 
LINES TERMINATED BY '\n';

(
  SELECT 'sub_region', 'region', 'countries', 'customer_types', 'earliest_purchase_date', 
         'last_purchase_date', 'sub_region_tenure', 'frequency', 'monetary', 'recency', 'r_score', 'f_score', 'm_score', 
		 'rfm_segment', 'rfm_class', 'estimated_lv'
)
UNION ALL
(
  SELECT 
    sub_region, region, countries, customer_types, earliest_purchase_date, 
         last_purchase_date, sub_region_tenure, frequency, monetary, recency, r_score, f_score, m_score, 
		 rfm_segment, rfm_class, estimated_lv
  FROM sub_regions
)
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sub_regions.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"' 
LINES TERMINATED BY '\n';

(
  SELECT 'invoice_date', 'frequency', 'monetary', 'm_class'
)
UNION ALL
(
  SELECT 
    invoice_date, frequency, monetary, m_class
  FROM dates
)
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dates.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

(
  SELECT 'month_number', 'month_name', 'frequency', 'monetary', 'm_class'
)
UNION ALL
(
  SELECT 
    month_number, month_name, frequency, monetary, m_class
  FROM months
)
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/months.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"' 
LINES TERMINATED BY '\n';

(
  SELECT 'season', 'frequency', 'monetary'
)
UNION ALL
(
  SELECT 
    season, frequency, monetary
  FROM seasons
)
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/seasons.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

(
  SELECT 'stock_code', 'description', 'top_month', 'top_season', 'earliest_purchase_date', 
         'last_purchase_date', 'product_tenure', 'overall_quantity', 'average_price', 'lowest_price',
         'highest_price', 'usual_price', 'product_level', 'frequency', 'monetary', 'recency', 'r_score', 'f_score', 'm_score', 
		 'rfm_segment', 'rfm_class', 'estimated_value'
)
UNION ALL
(
  SELECT 
    stock_code, description, top_month, top_season, earliest_purchase_date, 
         last_purchase_date, product_tenure, overall_quantity, average_price, lowest_price,
         highest_price, usual_price, product_level, frequency, monetary, recency, r_score, f_score, m_score, 
		 rfm_segment, rfm_class, estimated_value
  FROM products
)
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"' 
LINES TERMINATED BY '\n';