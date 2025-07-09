# 🛒 E-commerce Case Study

## 📌 Project Goal  
Analyze transaction data to extract insights into customer purchasing trends and behavior.

---

## 📊 Dataset  
- **Source**: [Kaggle - E-commerce Data](https://www.kaggle.com/datasets/carrie1/ecommerce-data/data)  
- **Original Provider**: UCI Machine Learning Repository  
- **Details**:  
  This dataset includes online retail transactions from 2010 to 2011, primarily for a UK-based retailer.

⚠️ *Due to licensing constraints, the dataset is not stored in this repository.*

To replicate:
1. Download from Kaggle.
2. Export the Excel file as a **UTF-8 CSV**.
3. Move the `.csv` to:  
   `C:\ProgramData\MySQL\MySQL Server 8.0\Uploads`

---

## 🧰 Tools Used
- **Database**: MySQL 8.0
- **Environment**: MySQL Workbench

---

## 🗂️ Database Setup

### 1️⃣ Create the Database
```sql
CREATE DATABASE e_commerce_case_study;
```

### 2️⃣ Create the Table
```sql
CREATE TABLE e_commerce_events (
  invoice_no VARCHAR(20),
  stock_code VARCHAR(20),
  description TEXT,
  quantity INT,
  invoice_date VARCHAR(50),
  unit_price DECIMAL(10,2),
  customer_id INT,
  country VARCHAR(50)
);
```

---

## 📥 Data Import

### Load Data from CSV
```sql
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data.csv'
INTO TABLE e_commerce_events
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(invoice_no, stock_code, description, quantity, invoice_date,
 unit_price, @customer_id, country)
SET customer_id = NULLIF(@customer_id, '');
```
|invoice_no|stock_code|description                       |quantity|unit_price|total_spend|customer_id|country        |invoice_date       |
|----------|----------|----------------------------------|--------|----------|-----------|-----------|---------------|-------------------|
|536365    |85123A    |WHITE HANGING HEART T-LIGHT HOLDER|6       |2.55      |15.30      |17850      |United Kingdom |2010-12-01 08:26:00|
|536365    |71053     |WHITE METAL LANTERN               |6       |3.39      |20.34      |17850      |United Kingdom |2010-12-01 08:26:00|
|536365    |84406B    |CREAM CUPID HEARTS COAT HANGER    |8       |2.75      |22.00      |17850      |United Kingdom |2010-12-01 08:26:00|

### ⚠️ Notes
- `customer_id` is set to `NULL` if empty
- Some `unit_price` values below 0.01 were truncated
- File must be encoded in **UTF-8**

---

## 🧪 Data Audit

### Date Range
```sql
SELECT MIN(invoice_date), MAX(invoice_date)
FROM e_commerce_events;
```
  |MIN(invoice_date)|MAX(invoice_date)|
  |-----------------|-----------------|
|2010-12-01 08:26:00|2011-12-09 12:50:00|


### High-Level Overview
```sql
SELECT 
  COUNT(*) AS total_rows,
  COUNT(DISTINCT invoice_no) AS unique_invoices,
  COUNT(DISTINCT customer_id) AS unique_customers,
  COUNT(DISTINCT stock_code) AS unique_products
FROM e_commerce_events;
```
|total_rows|unique_invoices|unique_customers|unique_products|
|----------|---------------|----------------|---------------|
|541909    |25900          |4372            |3958           |

### Detect Duplicates
```sql
WITH dup_cte AS (
  SELECT COUNT(*) AS dup_count
  FROM e_commerce_events
  GROUP BY invoice_no, stock_code, description, quantity, invoice_date, unit_price, customer_id, country
  HAVING COUNT(*) > 1
)
SELECT SUM(dup_count - 1) AS redundant_rows
FROM dup_cte;
```
|redundant_rows|
|--------------|
|5268          |


### NULL Values
```sql
SELECT *
FROM e_commerce_events
WHERE invoice_no IS NULL 
OR stock_code IS NULL 
OR description IS NULL
OR quantity IS NULL 
OR unit_price IS NULL 
OR customer_id IS NULL
OR country IS NULL 
OR invoice_date IS NULL;
```
|invoice_no|stock_code|description                    |quantity|unit_price|total_spend|customer_id|country        |invoice_date       |
|----------|----------|-------------------------------|--------|----------|-----------|-----------|---------------|-------------------|
|536414    |22139     |                               |56      |0.00      |0.00       |NULL       |United Kingdom |2010-12-01 11:52:00|
|536544    |21773     |DECORATIVE ROSE BATHROOM BOTTLE|1       |2.51      |2.51       |NULL       |United Kingdom |2010-12-01 14:32:00|
|536544    |21774     |DECORATIVE CATS BATHROOM BOTTLE|2       |2.51      |5.02       |NULL       |United Kingdom |2010-12-01 14:32:00|

*Insight:* Only `customer_id` contains NULLs.

### Zero Unit Price
```sql
SELECT *
FROM e_commerce_events
WHERE unit_price = 0;
```
|invoice_no|stock_code|description                    |quantity|unit_price|total_spend|customer_id|country        |invoice_date       |
|----------|----------|-------------------------------|--------|----------|-----------|-----------|---------------|-------------------|
|536414    |22139     |                               |56      |0.00      |0.00       |NULL       |United Kingdom |2010-12-01 11:52:00|
|536545    |21134     |                               |1       |0.00      |0.00       |NULL       |United Kingdom |2010-12-01 14:32:00|
|536546    |22145     |                               |1       |0.00      |0.00       |NULL       |United Kingdom |2010-12-01 14:33:00|

*Insight:* Often paired with NULL `customer_id`; may indicate bundled items.

```sql
SELECT *
FROM e_commerce_events
WHERE unit_price = 0 AND customer_id IS NOT NULL;
```
|invoice_no|stock_code|description                    |quantity|unit_price|total_spend|customer_id|country        |invoice_date       |
|----------|----------|-------------------------------|--------|----------|-----------|-----------|---------------|-------------------|
|537197    |22841     |ROUND CAKE TIN VINTAGE GREEN   |1       |0.00      |0.00       |12647      |Germany        |2010-12-05 14:02:00|
|539263    |22580     |ADVENT CALENDAR GINGHAM SACK   |4       |0.00      |0.00       |16560      |United Kingdom |2010-12-16 14:36:00|
|539722    |22423     |REGENCY CAKESTAND 3 TIER       |10      |0.00      |0.00       |14911      |EIRE           |2010-12-21 13:45:00|

*Insight:* Valid customers with free items — likely promotional.

### High price items
```sql
SELECT *
FROM e_commerce_events
ORDER BY unit_price DESC
LIMIT 200;
```
|invoice_no|stock_code|description                    |quantity|unit_price|total_spend|customer_id|country        |invoice_date       |
|----------|----------|-------------------------------|--------|----------|-----------|-----------|---------------|-------------------|
|C556445   |M         |Manual                         |-1      |38970.00  |-38970.00  |15098      |United Kingdom |2011-06-10 15:31:00|
|C580605   |AMAZONFEE |AMAZON FEE                     |-1      |17836.46  |-17836.46  |NULL       |United Kingdom |2011-12-05 11:36:00|
|C540117   |AMAZONFEE |AMAZON FEE                     |-1      |16888.02  |-16888.02  |NULL       |United Kingdom |2011-01-05 09:55:00|


*Insight:* Highest value items include mainly Manuals and AMAZON fees. They also have negative quantities. Will consider deleting.

### Refunds (Invoices with 'C')
```sql
SELECT * FROM e_commerce_events WHERE invoice_no LIKE 'C%';
```
|invoice_no|stock_code|description                    |quantity|unit_price|total_spend|customer_id|country        |invoice_date       |
|----------|----------|-------------------------------|--------|----------|-----------|-----------|---------------|-------------------|
|C536379   |D         |Discount                       |-1      |27.50     |-27.50     |14527      |United Kingdom |2010-12-01 09:41:00|
|C536383   |35004C    |SET OF 3 COLOURED  FLYING DUCKS|-1      |4.65      |-4.65      |15311      |United Kingdom |2010-12-01 09:49:00|
|C536391   |22556     |PLASTERS IN TIN CIRCUS PARADE  |-12     |1.65      |-19.80     |17548      |United Kingdom |2010-12-01 10:24:00|

*Insight:* Negative `quantity`, likely refunds.

### Negative Quantities Without 'C'
```sql
SELECT * 
FROM e_commerce_events 
WHERE quantity < 0 AND invoice_no NOT LIKE 'C%';
```
|invoice_no|stock_code|description|quantity|unit_price|total_spend|customer_id|country        |invoice_date       |
|----------|----------|-----------|--------|----------|-----------|-----------|---------------|-------------------|
|537032    |21275     |?          |-30     |0.00      |0.00       |NULL       |United Kingdom |2010-12-03 16:50:00|
|537425    |84968F    |check      |-20     |0.00      |0.00       |NULL       |United Kingdom |2010-12-06 15:35:00|
|537426    |84968E    |check      |-35     |0.00      |0.00       |NULL       |United Kingdom |2010-12-06 15:36:00|

*Insight:* Possible damaged goods or stock adjustments.

### Sample Product Checks
```sql
SELECT * FROM e_commerce_events WHERE stock_code = '85175';
SELECT * FROM e_commerce_events WHERE invoice_no = '541993';
SELECT * FROM e_commerce_events WHERE stock_code = '21035';
```
*Insight:* Pricing anomalies and missing `customer_id` suggest outliers.

### Stock Codes For non-itemproducts
```sql
SELECT DISTINCT stock_code
FROM e_commerce_events
WHERE stock_code NOT REGEXP '[0-9]';
```
|stock_code  |
|------------|
|POST        |
|D           |
|M           |
|BANK CHARGES|
|PADS        |
|DOT         |
|CRUK        |

*Insight:* Includes POST(postage), D(discount), M(manual), BANK CHARGES, DOT(dotcom postage), CRUK(cruk commission), and PADS

---

## 🧹 Data Cleaning

### Reformat `invoice_date`
```sql
ALTER TABLE e_commerce_events ADD invoice_dt DATETIME;
UPDATE e_commerce_events
SET invoice_dt = STR_TO_DATE(invoice_date, '%m/%d/%Y %H:%i');
ALTER TABLE e_commerce_events DROP COLUMN invoice_date;
ALTER TABLE e_commerce_events CHANGE invoice_dt invoice_date DATETIME;
```

### Backup Table
```sql
CREATE TABLE e_commerce_events_backup AS
SELECT * FROM e_commerce_events;
```
*Insight:* Backing up table before any major changes.

### Create Surrogate id for rows
```sql
ALTER TABLE e_commerce_events
ADD COLUMN id INT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;
```
*Insight:* Applying surrogate id in order to make eliminating duplicates easier

### Delete Duplicate Rows
```sql
WITH duplicate_ids AS (
  SELECT MIN(id) AS keep_id
  FROM e_commerce_events
  GROUP BY invoice_no, stock_code, description, quantity, invoice_date, unit_price, customer_id, country
)
DELETE FROM e_commerce_events
WHERE id NOT IN (
  SELECT keep_id FROM duplicate_ids
);
```

### Delete rows with NULL customer_id
```sql
DELETE FROM e_commerce_events
WHERE customer_id IS NULL;
```
*Insight:* Unable to attribute to a customer so elimated to remove bad data

### Delete rows with 0.00 unit_price
```sql
DELETE FROM e_commerce_events
WHERE unit_price = 0;
```
*Insight:* As these are additive items they are not necessary for analysis.

### Create Column for Transaction Type
```sql
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
```
*Insight:* Adjusted for clarity

### Remove c from invoice_no
```sql
UPDATE e_commerce_events
SET invoice_no = 
  CASE
    WHEN invoice_no LIKE 'C%' THEN SUBSTRING(invoice_no, 2)
    ELSE invoice_no
  END;
ALTER TABLE e_commerce_events
MODIFY invoice_no INT;
```
*Insight:* Adjusted for clarity

### Trimmed and lowercased description for uniformity
```sql
UPDATE e_commerce_events
SET description = LOWER(TRIM(description));
```

### Splitting date and time
```sql
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
```
*Insight:* Separated for easier analysis.

### Rearange for clarity
```sql
ALTER TABLE e_commerce_events 
MODIFY COLUMN invoice_date DATE AFTER invoice_no;
ALTER TABLE e_commerce_events 
MODIFY COLUMN invoice_time TIME AFTER invoice_date;
ALTER TABLE e_commerce_events 
MODIFY COLUMN customer_id INT AFTER invoice_time;
ALTER TABLE e_commerce_events 
MODIFY COLUMN country VARCHAR(50) AFTER customer_id;
```

### Validating Column types
```sql
DESCRIBE e_commerce_events;
```

*Insight:* All data types are correct for their columns

### High-Level Overview After Cleaning
```sql
SELECT 
  COUNT(*) AS total_rows,
  COUNT(DISTINCT invoice_no) AS unique_invoices,
  COUNT(DISTINCT customer_id) AS unique_customers,
  COUNT(DISTINCT stock_code) AS unique_products
FROM e_commerce_events;
```
|total_rows|unique_invoices|unique_customers                  |unique_products|
|----------|---------------|----------------------------------|---------------|
|401560    |22186          |4371                              |3677           |

### Creating Indexs for main search columns
```sql
CREATE INDEX idx_customer_id ON e_commerce_events(customer_id);
CREATE INDEX idx_invoice_no ON e_commerce_events(invoice_no);
CREATE INDEX idx_stock_code ON e_commerce_events(stock_code);
CREATE INDEX idx_invoice_date ON e_commerce_events(invoice_date);
```
*Insight:* for ease of use when searching

---

## 🔄 Data Manipulation

### Add Total Spend Column
```sql
ALTER TABLE e_commerce_events ADD total_spend DECIMAL(10,2);
UPDATE e_commerce_events
SET total_spend = unit_price * quantity;
ALTER TABLE e_commerce_events 
MODIFY COLUMN total_spend DECIMAL(10,2) AFTER unit_price;
```

### Create table for invoices
```sql
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
```
|invoice_no|invoice_date|invoice_time                      |customer_id|country        |overall_quantity|overall_spend|transaction_types|
|----------|------------|----------------------------------|-----------|---------------|----------------|-------------|-----------------|
|536365    |2010-12-01  |08:26:00                          |17850      |United Kingdom |40              |139.12       |Purchase         |
|536366    |2010-12-01  |08:28:00                          |17850      |United Kingdom |12              |22.20        |Purchase         |
|536367    |2010-12-01  |08:34:00                          |13047      |United Kingdom |83              |278.73       |Purchase         |

### Create table for dates
```sql
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
```
|invoice_date|invoice_count|customer_count|countries                      |overall_quantity|overall_spend|transaction_types                      |
|------------|-------------|--------------|-------------------------------|----------------|-------------|---------------------------------------|
|2010-12-01  |127          |98            |Australia , EIRE , France, Etc |23931           |45867.26     |Manual, Postage, Purchase, Refund      |
|2010-12-02  |160          |117           |EIRE , Germany , United Kingdom|20790           |45656.47     |Bank Charges, Postage, Purchase, Refund|
|2010-12-03  |64           |55            |Belgium , EIRE , France , Etc  |11507           |22553.38     |Manual, Postage, Purchase, Refund      |


### Create table for customers
```sql
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
```
|customer_id|earliest_transaction_date|latest_transaction_date|customer_tenure_days|invoice_count  |countries      |overall_quantity|overall_spend|transaction_types|
|-----------|-------------------------|-----------------------|--------------------|---------------|---------------|----------------|-------------|-----------------|
|12346      |2011-01-18               |2011-01-18             |0                   |2              |United Kingdom |0               |0.00         |Purchase, Refund |
|12347      |2010-12-07               |2011-12-07             |365                 |7              |Iceland        |2458            |4310.00      |Purchase         |
|12348      |2010-12-16               |2011-09-25             |283                 |4              |Finland        |2341            |1797.24      |Postage, Purchase|


*Insight:* Upon inspection, several customers have an overall_spend of 0. This likely indicates full refunds of their purchases or transactions that were reversed. Similarly, customers with an overall_quantity of 0 may represent historical refunds (from purchases predating the dataset) or potential data entry errors. These records do not contribute meaningful value to analysis and may be excluded in later stages.

### Create table for valid customers
```sql
CREATE TABLE valid_customers AS
SELECT *
FROM customers
WHERE overall_spend > 0
AND overall_quantity > 0;
```
|customer_id|earliest_transaction_date|latest_transaction_date|customer_tenure_days|invoice_count  |countries|overall_quantity|overall_spend|transaction_types|
|-----------|-------------------------|-----------------------|--------------------|---------------|---------|----------------|-------------|-----------------|
|12347      |2010-12-07               |2011-12-07             |365                 |7              |Iceland  |2458            |4310.00      |Purchase         |
|12348      |2010-12-16               |2011-09-25             |283                 |4              |Finland  |2341            |1797.24      |Postage, Purchase|
|12349      |2011-11-21               |2011-11-21             |0                   |1              |Italy    |631             |1757.55      |Postage, Purchase|

*Insight:* Good for RFM

### Create table for products
```sql
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
```
|stock_code|description               |earliest_order_date|latest_order_date|overall_quantity|average_price|lowest_price|highest_price|overall_spend|
|----------|--------------------------|-------------------|-----------------|----------------|-------------|------------|-------------|-------------|
|10002     |inflatable political globe|2010-12-01         |2011-04-18       |823             |0.85         |0.85        |0.85         |699.55       |
|10080     |groovy cactus inflatable  |2011-02-27         |2011-11-21       |291             |0.41         |0.39        |0.85         |114.41       |
|10120     |doggy rubber              |2010-12-03         |2011-12-04       |192             |0.21         |0.21        |0.21         |40.32        |

*Insight:* unified description to most common description used in order to unify stock_code

### Create table for countries
```sql
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
```
|country  |earliest_transaction_date|latest_transaction_date|invoice_count|customer_count |overall_quantity|overall_spend|avg_spend_per_customer|transaction_types|
|---------|-------------------------|-----------------------|-------------|---------------|----------------|-------------|----------------------|-----------------|
|Australia|2010-12-01               |2011-11-24             |69           |9              |83335           |137009.77    |15223.31              |Postage & Etc    |
|Austria  |2010-12-15               |2011-12-08             |19           |11             |4827            |10154.32     |923.12                |Postage & Etc    |
|Bahrain  |2011-05-09               |2011-05-19             |2            |2              |260             |548.40       |274.20                |Purchase         |


### Create table for transaction_types
```sql
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
```
|transaction_type|invoice_count|customer_count                    |overall_quantity|overall_spend  |
|----------------|-------------|----------------------------------|----------------|---------------|
|Bank Charges    |11           |10                                |11              |165.00         |
|Dotcom Postage  |16           |1                                 |16              |11906.36       |
|Manual          |253          |197                               |6933            |53419.93       |

### Create PRIMARY KEYs for created tables
```sql
ALTER TABLE invoices ADD PRIMARY KEY (invoice_no);
ALTER TABLE dates ADD PRIMARY KEY (invoice_date);
ALTER TABLE valid_customers ADD PRIMARY KEY (customer_id);
ALTER TABLE countries ADD PRIMARY KEY (country);
ALTER TABLE products ADD PRIMARY KEY (stock_code);
ALTER TABLE transaction_types ADD PRIMARY KEY (transaction_type);
```

---

## 📊 Data Exploration

### Investigate top spenders
```sql
SELECT customer_id,
	customer_tenure_days,
	invoice_count,
  countries,
  overall_quantity,
  overall_spend
FROM e_commerce_case_study.valid_customers 
ORDER BY overall_spend DESC
LIMIT 5;
```
|customer_id|customer_tenure_days|invoice_count|countries      |overall_quantity|overall_spend|
|-----------|--------------------|-------------|---------------|----------------|-------------|
|14646      |353                 |76           |Netherlands    |196143          |279489.02    |
|18102      |367                 |62           |United Kingdom |64122           |256438.49    |
|17450      |359                 |55           |United Kingdom |69009           |187322.17    |
|14911      |372                 |248          |EIRE           |76905           |132458.73    |
|12415      |313                 |26           |Australia      |76946           |123725.45    |

*Insight:* Multiple consistent customers with large overall quantities and overall spending. Potentially wholesellers. 

### Investigate customer_id 14646, 18102, 17350
```sql
SELECT * FROM e_commerce_events WHERE customer_id = 14646;
SELECT * FROM e_commerce_events WHERE customer_id = 18102;
SELECT * FROM e_commerce_events WHERE customer_id = 17450;
```
*Insight:* Many of their transactions have quantities of 100+ of single items which helps to indicate they are indeed wholesellers. Will have to look into differentiating wholesellers from average customers.

---

## 📈 Next Steps
- 🥇 Analyze top-selling products
- 🌍 Assess revenue by country
- 🔁 Track customer retention and frequency
- 📆 Explore monthly and seasonal trends
- Analyze highest spenders, most invoices, invoice batches, highest quantity items

---

## 📄 License
This project is for **educational and portfolio purposes only**.  
Dataset attribution belongs to UCI and the original [Kaggle contributor](https://www.kaggle.com/datasets/carrie1/ecommerce-data).


