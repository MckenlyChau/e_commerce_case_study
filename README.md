# 🛒 E-commerce Case Study

## Contents

- [📌 Project Goal](#-project-goal)
- [📊 Dataset](#-dataset)
- [🧰 Tools Used](#-tools-used)
- [🗂️ Database Setup](#-database-setup)
- [📥 Data Import](#-data-import)
- [🧪 Data Audit](#-data-audit)
- [🧹 Data Cleaning](#-data-cleaning)
- [🔄 Data Manipulation](#-data-manipulation)
- [📊 Data Exploration](#-data-exploration)
- [🧠 Data Enrichment](#-data-enrichment)
- [📈 Data Analysis](#-data-analysis)
- [📈 Data Visuals](#-data-visuals)
- [📄 License](#-license)

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
### Contents

- [📅 Date Range](#-date-range)
- [📊 High-Level Overview](#-high-level-overview)
- [🔁 Detect Duplicates](#-detect-duplicates)
- [⚠️ NULL Value Checks](#️-null-value-checks)
- [💸 Zero Unit Price](#-zero-unit-price)
- [💰 High-Value Items](#-high-value-items)
- [🔄 Refund Invoices (Start with "C")](#-refund-invoices-start-with-c)
- [🔻 Negative Quantities Without ‘C’ Invoices](#-negative-quantities-without-c-invoices)
- [🧪 Sample Checks](#-sample-checks)
- [🔣 Non-Item Stock Codes](#-non-item-stock-codes)

### 📅 Date Range
```sql
SELECT MIN(invoice_date), MAX(invoice_date)
FROM e_commerce_events;
```
|MIN(invoice_date)  |MAX(invoice_date)  |
|-------------------|-------------------|
|2010-12-01 08:26:00|2011-12-09 12:50:00|


### 📊 High-Level Overview
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

### 🔁 Detect Duplicates
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


### ⚠️ NULL Value Checks
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

**Insight:** Only `customer_id` contains NULLs.

### 💸 Zero Unit Price
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

**Insight:** Often paired with NULL `customer_id`; may indicate bundled items.

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

**Insight:** Valid customers with free items — likely promotional.

### 💰 High-Value Items
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


***Insight:** Highest value items include mainly Manuals and AMAZON fees. They also have negative quantities. Will consider deleting.

### 🔄 Refund Invoices (Start with "C")
```sql
SELECT * FROM e_commerce_events WHERE invoice_no LIKE 'C%';
```
|invoice_no|stock_code|description                    |quantity|unit_price|total_spend|customer_id|country        |invoice_date       |
|----------|----------|-------------------------------|--------|----------|-----------|-----------|---------------|-------------------|
|C536379   |D         |Discount                       |-1      |27.50     |-27.50     |14527      |United Kingdom |2010-12-01 09:41:00|
|C536383   |35004C    |SET OF 3 COLOURED  FLYING DUCKS|-1      |4.65      |-4.65      |15311      |United Kingdom |2010-12-01 09:49:00|
|C536391   |22556     |PLASTERS IN TIN CIRCUS PARADE  |-12     |1.65      |-19.80     |17548      |United Kingdom |2010-12-01 10:24:00|

**Insight:** Negative `quantity`, likely refunds.

### 🔻 Negative Quantities Without ‘C’ Invoices
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

***Insight:** Possible damaged goods or stock adjustments.

### 🧪 Sample Checks
```sql
SELECT * FROM e_commerce_events WHERE stock_code = '85175';
SELECT * FROM e_commerce_events WHERE invoice_no = '541993';
SELECT * FROM e_commerce_events WHERE stock_code = '21035';
```
**Insight:** Pricing anomalies and missing `customer_id` suggest outliers.

### 🔣 Non-Item Stock Codes
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

***Insight:** Includes POST(postage), D(discount), M(manual), BANK CHARGES, DOT(dotcom postage), CRUK(cruk commission), and PADS

---

## 🧹 Data Cleaning

### Contents

- [🕒 Convert Date Formats](#-convert-date-formats)
- [💾 Create Backup Before Modifications](#-create-backup-before-modifications)
- [🆔 Add Surrogate Row Identifier](#-add-surrogate-row-identifier)
- [🗑️ Remove Duplicate Records](#️-remove-duplicate-records)
- [🚫 Remove Rows Without Customer ID](#-remove-rows-without-customer-id)
- [🚫 Remove Free or Promotional Item](#-remove-free-or-promotional-item)
- [🔄 Categorize Transaction Type](#-categorize-transaction-type)
- [🔧 Clean Invoice Numbers](#-clean-invoice-numbers)
- [✂️ Normalize Product Descriptions](#️-normalize-product-descriptions)
- [⏱️ Separate Date and Time Fields](#️-separate-date-and-time-fields)
- [🧹 Column Order Cleanup](#-column-order-cleanup)
- [✅ Confirm Column Data Types](#-confirm-column-data-types)
- [🧾 High-Level Metrics After Cleaning](#-high-level-metrics-after-cleaning)
- [🚀 Add Indexes for Query Optimization](#-add-indexes-for-query-optimization)

### 🕒 Convert Date Formats
```sql
ALTER TABLE e_commerce_events ADD invoice_dt DATETIME;
UPDATE e_commerce_events
SET invoice_dt = STR_TO_DATE(invoice_date, '%m/%d/%Y %H:%i');
ALTER TABLE e_commerce_events DROP COLUMN invoice_date;
ALTER TABLE e_commerce_events CHANGE invoice_dt invoice_date DATETIME;
```

### 💾 Create Backup Before Modifications
```sql
CREATE TABLE e_commerce_events_backup AS
SELECT * FROM e_commerce_events;
```
***Insight:** Backing up table before any major changes.

### 🆔 Add Surrogate Row Identifier
```sql
ALTER TABLE e_commerce_events
ADD COLUMN id INT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;
```
***Insight:** Applying surrogate id in order to make eliminating duplicates easier

### 🗑️ Remove Duplicate Records
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

### 🚫 Remove Rows Without Customer ID
```sql
DELETE FROM e_commerce_events
WHERE customer_id IS NULL;
```
***Insight:** Unable to attribute to a customer so elimated to remove bad data

### 🚫 Remove Free or Promotional Item
```sql
DELETE FROM e_commerce_events
WHERE unit_price = 0;
```
***Insight:** As these are additive items they are not necessary for analysis.

### 🔄 Categorize Transaction Type
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
***Insight:** Adjusted for clarity

### 🔧 Clean Invoice Numbers
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
***Insight:** Adjusted for clarity

### ✂️ Normalize Product Descriptions
```sql
UPDATE e_commerce_events
SET description = LOWER(TRIM(description));
```

### ⏱️ Separate Date and Time Fields
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
***Insight:** Separated for easier analysis.

### 🧹 Column Order Cleanup
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

### ✅ Confirm Column Data Types
```sql
DESCRIBE e_commerce_events;
```

**Insight:** All data types are correct for their columns

### 🧾 High-Level Metrics After Cleaning
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

### 🚀 Add Indexes for Query Optimization
```sql
CREATE INDEX idx_customer_id ON e_commerce_events(customer_id);
CREATE INDEX idx_invoice_no ON e_commerce_events(invoice_no);
CREATE INDEX idx_stock_code ON e_commerce_events(stock_code);
CREATE INDEX idx_invoice_date ON e_commerce_events(invoice_date);
```
**Insight:** for ease of use when searching

---

## 🔄 Data Manipulation

### Contents

- [➕ Calculate and Add Total Spend](#-calculate-and-add-total-spend)
- [🧾 Invoice Summary Table](#-invoice-summary-table)
- [📆 Daily Performance Overview](#-daily-performance-overview)
- [👥 Customer Activity Summary](#-customer-activity-summary)
- [✅ Active Customers Non-Zero Spend](#-active-customers-non-zero-spend)
- [📦 Product Master Table](#-product-master-table)
- [🌍 Country-Level Aggregates](#-country-level-aggregates)
- [🔄 Transaction Type Breakdown](#-transaction-type-breakdown)
- [🔑 Add Primary Keys to Summary Tables](#-add-primary-keys-to-summary-tables)

### ➕ Calculate and Add Total Spend
```sql
ALTER TABLE e_commerce_events ADD total_spend DECIMAL(10,2);
UPDATE e_commerce_events
SET total_spend = unit_price * quantity;
ALTER TABLE e_commerce_events 
MODIFY COLUMN total_spend DECIMAL(10,2) AFTER unit_price;
```

### 🧾 Invoice Summary Table
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

### 📆 Daily Performance Overview
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


###	👥 Customer Activity Summary
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

**Insight:** Several customers have an overall_spend of 0, which likely indicates full refunds or fully reversed transactions. Similarly, an overall_quantity of 0 may reflect historical refunds or data entry anomalies. Since these records do not provide meaningful analytical value, they may be excluded in later stages of the analysis.

### ✅ Active Customers Non-Zero Spend
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

**Insight:** This cleaned subset of customers is well-suited for RFM (Recency, Frequency, Monetary) analysis, as it ensures all included records reflect meaningful purchasing behavior.

### 📦 Product Master Table
```sql
CREATE TABLE products AS
WITH mode_cte AS (
  SELECT stock_code, unit_price AS usual_price,
         ROW_NUMBER() OVER (PARTITION BY stock_code ORDER BY COUNT(*) DESC) AS rn
  FROM e_commerce_events
  GROUP BY stock_code, unit_price
),
top_descriptions AS (
  SELECT stock_code, description
  FROM (
    SELECT stock_code, description,
           ROW_NUMBER() OVER (PARTITION BY stock_code ORDER BY COUNT(*) DESC) AS rn
    FROM e_commerce_events
    GROUP BY stock_code, description
  ) ranked
  WHERE rn = 1
),
mode_filtered AS (
  SELECT stock_code, usual_price
  FROM mode_cte
  WHERE rn = 1
)
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
```
|stock_code|description               |earliest_order_date|latest_order_date|overall_quantity|average_price|lowest_price|highest_price|usual_price|overall_spend|
|----------|--------------------------|-------------------|-----------------|----------------|-------------|------------|-------------|-----------|-------------|
|10002     |inflatable political globe|2010-12-01         |2011-04-18       |823             |0.85         |0.85        |0.85         |0.85       |699.55       |
|10080     |groovy cactus inflatable  |2011-02-27         |2011-11-21       |291             |0.41         |0.39        |0.85         |0.39       |114.41       |
|10120     |doggy rubber              |2010-12-03         |2011-12-04       |192             |0.21         |0.21        |0.21         |0.21       |40.32        |

***Insight:** Standardized product descriptions by assigning the most frequently used description per `stock_code`, ensuring consistency across records for accurate aggregation and analysis.

### 🌍 Country-Level Aggregates
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


### 🔄 Transaction Type Breakdown
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

### 🔑 Add Primary Keys to Summary Tables
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

### Contents

- [👥 EX-Customers](#-ex-customers)
- [📦 EX-Products](#-ex-products)
- [🧾 EX-Invoices](#-ex-invoices)
- [🌍 EX-Country](#-ex-country)
- [📅 EX-Dates](#-ex-dates)


### 👥 EX-Customers

#### Contents

- [💰 Top Customer Spenders](#-top-customer-spenders)
- [🔍 Sample Top Customers](#-sample-top-customers)

#### 💰 Top Customer Spenders
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

**Insight:** Several customers consistently exhibit high order volumes and total spending, indicating potential wholesale buyers or bulk purchasers.

### 🔍 Sample Top Customers
```sql
SELECT * FROM e_commerce_events WHERE customer_id = 14646;
SELECT * FROM e_commerce_events WHERE customer_id = 18102;
SELECT * FROM e_commerce_events WHERE customer_id = 17450;
```
**Insight:** Many of their transactions involve purchasing 100+ units of individual items, reinforcing the likelihood that they are wholesale customers. Further analysis is needed to distinguish wholesalers from regular retail buyers.

### 📦 EX-Products

#### Contents

- [🏆 Top Products by Revenue](#-top-products-by-revenue)
- [📦 Top Products by Volume](#-top-products-by-volume)

#### 🏆 Top Products by Revenue
```sql
SELECT stock_code,
	description,
    overall_quantity,
    average_price,
    lowest_price,
    highest_price,
    usual_price,
    overall_spend
FROM products
ORDER BY overall_spend DESC;
```
|stock_code|description                       |overall_quantity|average_price|lowest_price|highest_price|usual_price|overall_spend|
|----------|----------------------------------|----------------|-------------|------------|-------------|-----------|-------------|
|22423     |regency cakestand 3 tier          |11519           |12.44        |4.00        |24.96        |12.75      |132567.70    |
|85123A    |white hanging heart t-light holder|34185           |2.89         |2.40        |5.79         |2.95       |93923.15     |
|85099B    |jumbo bag red retrospot           |44963           |2.01         |1.65        |4.13         |2.08       |83056.52     |

**Insight:** The Regency Cakestand ranks among the top items by `overall_spend`, despite having a lower quantity sold compared to others. This suggests it is a high-value item. Categorizing products into high-end and low-end segments based on `usual_price` may provide more meaningful insights during analysis.

### 📦 Top Products by Volume
```sql
SELECT stock_code,
	description,
    overall_quantity,
    average_price,
    lowest_price,
    highest_price,
    usual_price,
    overall_spend
FROM products
ORDER BY overall_quantity DESC;
```
|stock_code|description                      |overall_quantity|average_price|lowest_price|highest_price|usual_price|overall_spend|
|----------|---------------------------------|----------------|-------------|------------|-------------|-----------|-------------|
|84077     |world war 2 gliders asstd designs|53119           |0.29         |0.11        |0.63         |0.29       |13304.49     |
|22197     |popcorn holder                   |48689           |0.84         |0.72        |1.63         |0.85       |36840.33     |
|85099B    |jumbo bag red retrospot          |44963           |2.01         |1.65        |4.13         |2.08       |83056.52     |

**Insight:** Most high-volume products are priced below $1, with only a few exceptions. This reinforces the value of segmenting items into low-end and high-end categories based on `usual_price` for more precise product-level analysis.

### 🧾 EX-Invoices

#### Contents

- [📊 Largest Orders by Quantity](#-largest-orders-by-quantitys)
- [↩️ Largest Refunds by Quantity](#️-largest-refunds-by-quantity)

#### 📊 Largest Orders by Quantitys
```sql
SELECT * 
FROM invoices
ORDER BY overall_quantity DESC;
```
|invoice_no|invoice_date              |invoice_time|customer_id|country        |overall_quantity|overall_spend|transaction_types|
|----------|--------------------------|------------|-----------|---------------|----------------|-------------|-----------------|
|581483    |2011-12-09                |09:15:00    |16446      |United Kingdom |80995           |168469.60    |Purchase         |
|541431    |2011-01-18                |10:01:00    |12346      |United Kingdom |74215           |77183.60     |Purchase         |
|556917    |2011-06-15                |13:37:00    |12415      |Australia      |15049           |22775.93     |Purchase         |

#### ↩️ Largest Refunds by Quantity
```sql
SELECT * 
FROM invoices
ORDER BY overall_quantity;
```
|invoice_no|invoice_date              |invoice_time|customer_id|country        |overall_quantity|overall_spend|transaction_types|
|----------|--------------------------|------------|-----------|---------------|----------------|-------------|-----------------|
|581484    |2011-12-09                |09:27:00    |16446      |United Kingdom |-80995          |-168469.60   |Refund           |
|541433    |2011-01-18                |10:17:00    |12346      |United Kingdom |-74215          |-77183.60    |Refund           |
|536757    |2010-12-02                |14:23:00    |15838      |United Kingdom |-9360           |-280.80      |Refund           |

**Insight:** This is the inverse of large orders by sorting in ascending quantity. Numerous large invoices appear to be refunded shortly after the original purchase. It would be beneficial to identify and label fully refunded orders to improve accuracy in customer and revenue analysis.

### 🌍 EX-Country

#### Contents

- [🌍 Top Countries by Invoices](#-top-countries-by-invoices)
- [👥 Top Countries by Customers](#-top-countries-by-customers)
- [📦 Top Countries by Units Sold](#-top-countries-by-units-sold)
- [💸 Top Countries by Total Spend](#-top-countries-by-total-spend)
- [🧾 Top Countries by Avg. Spend per Customer](#-top-countries-by-avg-spend-per-customer)

#### 🌍 Top Countries by Invoices
```sql
SELECT country,
	invoice_count,
    customer_count,
    overall_quantity,
    overall_spend,
    avg_spend_per_customer
FROM countries
ORDER BY invoice_count DESC;
```
|country        |invoice_count             |customer_count|overall_quantity|overall_spend|avg_spend_per_customer|
|---------------|--------------------------|--------------|----------------|-------------|----------------------|
|United Kingdom |19854                     |3949          |3982134         |6747156.15   |1708.57               |
|Germany        |603                       |95            |117339          |221509.47    |2331.68               |
|France         |458                       |87            |109805          |196626.05    |2260.07               |

#### 👥 Top Countries by Customers
```sql
SELECT country,
	invoice_count,
    customer_count,
    overall_quantity,
    overall_spend,
    avg_spend_per_customer
FROM countries
ORDER BY customer_count DESC;
```
|country        |invoice_count             |customer_count|overall_quantity|overall_spend|avg_spend_per_customer|
|---------------|--------------------------|--------------|----------------|-------------|----------------------|
|United Kingdom |19854                     |3949          |3982134         |6747156.15   |1708.57               |
|Germany        |603                       |95            |117339          |221509.47    |2331.68               |
|France         |458                       |87            |109805          |196626.05    |2260.07               |

#### 📦 Top Countries by Units Sold
```sql
SELECT country,
	invoice_count,
    customer_count,
    overall_quantity,
    overall_spend,
    avg_spend_per_customer
FROM countries
ORDER BY overall_quantity DESC;
```
|country        |invoice_count             |customer_count|overall_quantity|overall_spend|avg_spend_per_customer|
|---------------|--------------------------|--------------|----------------|-------------|----------------------|
|United Kingdom |19854                     |3949          |3982134         |6747156.15   |1708.57               |
|Netherlands    |100                       |9             |199552          |284661.54    |31629.06              |
|EIRE           |319                       |3             |135937          |250001.78    |83333.93              |

#### 💸 Top Countries by Total Spend
```sql
SELECT country,
	invoice_count,
    customer_count,
    overall_quantity,
    overall_spend,
    avg_spend_per_customer
FROM countries
ORDER BY overall_spend DESC;
```
|country        |invoice_count             |customer_count|overall_quantity|overall_spend|avg_spend_per_customer|
|---------------|--------------------------|--------------|----------------|-------------|----------------------|
|United Kingdom |19854                     |3949          |3982134         |6747156.15   |1708.57               |
|Netherlands    |100                       |9             |199552          |284661.54    |31629.06              |
|EIRE           |319                       |3             |135937          |250001.78    |83333.93              |

#### 🧾 Top Countries by Avg. Spend per Customer
```sql
SELECT country,
	invoice_count,
    customer_count,
    overall_quantity,
    overall_spend,
    avg_spend_per_customer
FROM countries
ORDER BY avg_spend_per_customer DESC;
```
|country     |invoice_count             |customer_count|overall_quantity|overall_spend|avg_spend_per_customer|
|------------|--------------------------|--------------|----------------|-------------|----------------------|
|EIRE        |319                       |3             |135937          |250001.78    |83333.93              |
|Netherlands |100                       |9             |199552          |284661.54    |31629.06              |
|Australia   |69                        |9             |83335           |137009.77    |15223.31              |

**Insight:** Orders from the United Kingdom significantly surpass other countries in both quantity and total spend, which aligns with the dataset’s UK origin. Countries with fewer customers often exhibit a higher average spend per customer, suggesting that international sales may have been limited to wholesale buyers operating in their own domestic markets. It may be valuable to distinguish between domestic and international transactions for clearer segmentation.

### 📅 EX-Dates

#### Contents

- [🗓️ Dates with Most Invoices](#️-dates-with-most-invoices)
- [👤 Dates with Most Customers](#-dates-with-most-customers)
- [📈 Dates with Highest Sales Volume](#-dates-with-highest-sales-volume)
- [💳 Dates with Highest Revenue](#-dates-with-highest-revenue)

#### 🗓️ Dates with Most Invoices
```sql
SELECT invoice_date,
invoice_count,
customer_count,
overall_quantity,
overall_spend
FROM e_commerce_case_study.dates
ORDER BY invoice_count DESC;
```
|invoice_date|invoice_count             |customer_count|overall_quantity|overall_spend|
|------------|--------------------------|--------------|----------------|-------------|
|2011-10-06  |180                       |154           |30848           |52673.62     |
|2011-12-01  |164                       |149           |24582           |43634.37     |
|2011-11-10  |161                       |139           |37780           |68321.01     |

#### 👤 Dates with Most Customers
```sql
SELECT invoice_date,
invoice_count,
customer_count,
overall_quantity,
overall_spend
FROM e_commerce_case_study.dates
ORDER BY customer_count DESC;
```
|invoice_date|invoice_count             |customer_count|overall_quantity|overall_spend|
|------------|--------------------------|--------------|----------------|-------------|
|2011-10-06  |180                       |154           |30848           |52673.62     |
|2011-12-01  |164                       |149           |24582           |43634.37     |
|2011-11-10  |161                       |139           |37780           |68321.01     |

#### 📈 Dates with Highest Sales Volume
```sql
SELECT invoice_date,
invoice_count,
customer_count,
overall_quantity,
overall_spend
FROM e_commerce_case_study.dates
ORDER BY overall_quantity DESC;
```
|invoice_date|invoice_count             |customer_count|overall_quantity|overall_spend|
|------------|--------------------------|--------------|----------------|-------------|
|2011-10-05  |99                        |82            |45677           |73626.37     |
|2011-09-20  |71                        |56            |42583           |103327.13    |
|2011-12-07  |117                       |101           |40903           |68867.66     |

#### 💳 Dates with Highest Revenue
```sql
SELECT invoice_date,
invoice_count,
customer_count,
overall_quantity,
overall_spend
FROM e_commerce_case_study.dates
ORDER BY overall_spend DESC;
```
|invoice_date|invoice_count             |customer_count|overall_quantity|overall_spend|
|------------|--------------------------|--------------|----------------|-------------|
|2011-09-20  |71                        |56            |42583           |103327.13    |
|2011-10-05  |99                        |82            |45677           |73626.37     |
|2011-11-23  |148                       |114           |38035           |70099.27     |

**Insight:** The highest overall quantity and total spend are concentrated in the latter half of the year, indicating a potential seasonal trend. This pattern suggests increased purchasing activity during certain months, likely related to holidays or year-end demand. Further analysis by month and season will help validate and understand these trends.


## 📈 Next Steps
- 🥇 Analyze top-selling products Y
- 🌍 Assess revenue by country Y
- 🔁 Track customer retention and frequency
- 📆 Explore monthly and seasonal trends
- Analyze highest spenders, most invoices, invoice batches, highest quantity items

---

## 🧠 Data Enrichment

### Contents

- [👥 EN-Customers](#-en-customers)
- [📦 EN-Product](#-en-product)
- [🗓️ EN-Dates](#️-en-dates)

### 👥 EN-Customers

### Contents

- [🧠 Customer Segmentation by Type](#-customer-segmentation-by-type)
- [📈 Customer Segmentation by Engagement](#-customer-segmentation-by-engagement)

#### 🧠 Customer Segmentation by Type
```sql
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
```
**Insight:** Customers with an overall quantity exceeding 5,000, an average of more than 100 items per invoice, and total spending above 10,000 strongly indicate wholesale purchasing behavior. Meanwhile, those with over 2,000 items, an average above 50 per invoice, and spending above 1,000 suggest micro-wholesale activity. These thresholds help distinguish wholesalers from regular retail customers by identifying consistent patterns in purchase volume and value.

### 📈 Customer Segmentation by Engagement
```sql
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
```
**Insight:** Customers are categorized into engagement levels based on the number of days between their first and last transactions `customer_tenure_days` and their total number of invoices `invoice_count`. This segmentation helps classify them as One-Time, Short-Term, Medium-Term, Recurrent, or Occasional customers, providing a clearer understanding of purchasing behavior and loyalty.

### 📦 EN-Product

### Contents

- [💰 Product Tier Assignment by Price](#-product-tier-assignment-by-price)

#### 💰 Product Tier Assignment by Price
```sql
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
```
**Insight:** Products are categorized into tiers—Premium, High, Mid, Standard, and Low—based on their `usual_price` to reflect relative pricing levels and support more granular product analysis.

### 🗓️ EN-Dates

### Contents

- [📅 Add Month and Month Number](#-add-month-and-month-number)
- [📊 Monthly Trends Summary Table](#-monthly-trends-summary-table)

#### 📅 Add Month and Month Number
```sql
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
```
**Insight:** Added month_number and month_name columns to enhance time-based analysis and enable proper chronological sorting in monthly reports.

#### 📊 Monthly Trends Summary Table
```sql
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
```
|month_number|month_name                |invoice_count|customer_count|overall_quantity|overall_spend|
|------------|--------------------------|-------------|--------------|----------------|-------------|
|1           |Jan                       |1236         |1116          |268706          |473731.90    |
|2           |Feb                       |1201         |1079          |262227          |435534.07    |
|3           |Mar                       |1619         |1434          |343054          |578576.21    |

**Insight:** A dedicated months table was created to facilitate clearer analysis of monthly trends in customer activity, order volume, and revenue. This helps uncover seasonality and performance patterns across the year.


## Next Steps
- Seperate Wholesellers from customers. DONE
- Create categories for high end and low end items. DONE
- Label refunded orders 
- Seperate domestic and international transactions
- label dates by month and seasons DONE

---

## 📈 Data Analysis

---

## 📈 Data Visuals

---

## 📄 License
This project is for **educational and portfolio purposes only**.  
Dataset attribution belongs to UCI and the original [Kaggle contributor](https://www.kaggle.com/datasets/carrie1/ecommerce-data).


