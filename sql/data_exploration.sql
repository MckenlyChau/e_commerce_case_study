-- Investigate top spenders
SELECT customer_id,
	customer_tenure_days,
	invoice_count,
    countries,
    overall_quantity,
    overall_spend
FROM e_commerce_case_study.valid_customers 
ORDER BY overall_spend DESC
LIMIT 5;

-- investigate customer_id 14646
SELECT * FROM e_commerce_events WHERE customer_id = 14646;
-- investigate customer_id 18102
SELECT * FROM e_commerce_events WHERE customer_id = 18102;
-- investigate customer_id 17350
SELECT * FROM e_commerce_events WHERE customer_id = 17450;