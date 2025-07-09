-- Create Database
CREATE DATABASE e_commerce_case_study;

-- Set DATABASE
USE e_commerce_case_study;

-- Create Table
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

-- Importing Data
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data.csv'
INTO TABLE e_commerce_events
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS(
  invoice_no, stock_code, description, quantity, invoice_date,
  unit_price, @customer_id, country
)
SET customer_id = NULLIF(@customer_id, '');

--
    