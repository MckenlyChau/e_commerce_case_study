-- Cleaned Database
CREATE DATABASE cleaned_e_commerce;
USE cleaned_e_commerce;

-- Transfer Tables
CREATE TABLE transactions
SELECT * FROM e_commerce_case_study.enriched_transactions WHERE customer_type IS NOT NULL AND refund_status != 'Full Refund'; -- Include only invoices in the RFM 

CREATE TABLE invoices
SELECT * FROM e_commerce_case_study.enriched_invoices WHERE customer_type IS NOT NULL AND refund_status != 'Full Refund'; -- Include only invoices in the RFM 

CREATE TABLE customers
SELECT * FROM e_commerce_case_study.rfm;

CREATE TABLE countries
SELECT * FROM e_commerce_case_study.country_rfm;

CREATE TABLE regions
SELECT * FROM e_commerce_case_study.region_rfm;

CREATE TABLE sub_regions
SELECT * FROM e_commerce_case_study.sub_region_rfm;

CREATE TABLE dates
SELECT * FROM e_commerce_case_study.daily_fm;

CREATE TABLE months
SELECT * FROM e_commerce_case_study.monthly_fm;

CREATE TABLE seasons
SELECT * FROM e_commerce_case_study.seasonal_fm;

CREATE TABLE products
SELECT * FROM e_commerce_case_study.product_rfm;

-- Primary Keys for Tables
ALTER TABLE transactions ADD PRIMARY KEY (id);
ALTER TABLE invoices ADD PRIMARY KEY (invoice_no);
ALTER TABLE customers ADD PRIMARY KEY (customer_id);
ALTER TABLE countries ADD PRIMARY KEY (country);
ALTER TABLE regions ADD PRIMARY KEY (region);
ALTER TABLE sub_regions ADD PRIMARY KEY (sub_region);
ALTER TABLE dates ADD PRIMARY KEY (invoice_date);
ALTER TABLE months ADD PRIMARY KEY (month_number);
ALTER TABLE seasons ADD PRIMARY KEY (season);
ALTER TABLE products ADD PRIMARY KEY (stock_code);

-- Foreign Keys for Tables
ALTER TABLE transactions
ADD CONSTRAINT tra_to_inv FOREIGN KEY (invoice_no) REFERENCES invoices(invoice_no),
ADD CONSTRAINT tra_to_cus FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
ADD CONSTRAINT tra_to_cou FOREIGN KEY (country) REFERENCES countries(country),
ADD CONSTRAINT tra_to_reg FOREIGN KEY (region) REFERENCES regions(region),
ADD CONSTRAINT tra_to_sub FOREIGN KEY (sub_region) REFERENCES sub_regions(sub_region),
ADD CONSTRAINT tra_to_dat FOREIGN KEY (invoice_date) REFERENCES dates(invoice_date),
ADD CONSTRAINT tra_to_mon FOREIGN KEY (month_number) REFERENCES months(month_number),
ADD CONSTRAINT tra_to_sea FOREIGN KEY (season) REFERENCES seasons(season),
ADD CONSTRAINT tra_to_pro FOREIGN KEY (stock_code) REFERENCES products(stock_code);

ALTER TABLE invoices
ADD CONSTRAINT inv_to_cus FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
ADD CONSTRAINT inv_to_cou FOREIGN KEY (country) REFERENCES countries(country),
ADD CONSTRAINT inv_to_reg FOREIGN KEY (region) REFERENCES regions(region),
ADD CONSTRAINT inv_to_sub FOREIGN KEY (sub_region) REFERENCES sub_regions(sub_region);

ALTER TABLE countries
ADD CONSTRAINT cou_to_reg FOREIGN KEY (region) REFERENCES regions(region),
ADD CONSTRAINT cou_to_sub FOREIGN KEY (sub_region) REFERENCES sub_regions(sub_region);

ALTER TABLE sub_regions
ADD CONSTRAINT sub_to_reg FOREIGN KEY (region) REFERENCES regions(region);