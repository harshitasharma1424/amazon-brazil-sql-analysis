SELECT * FROM amazon_brazil.customers;
SELECT * FROM amazon_brazil.order_items;
SELECT * FROM amazon_brazil.orders;
SELECT * FROM amazon_brazil.payments;
SELECT * FROM amazon_brazil.products;
SELECT * FROM amazon_brazil.sellers;
-- AMAZON BRAZIL ANALYSIS
--ANALYSIS I\
--Q1 Average payments by payments types
SELECT payment_type,ROUND(AVG(payment_value)) AS rounded_avg_value 
FROM amazon_brazil.payments GROUP BY payment_type
ORDER BY rounded_avg_value;
--This query shows the credit card is the most widely used options by customers hence we need to tie ups with 
--credit cards comapnies to give rewards schemes to customer and uplift other payment types by giving offers 
--& other scheme to attract potential customers 

--Q2 total_order_percnetage & order_type
SELECT payment_type,ROUND(COUNT(order_id)*100.00/(SELECT COUNT(*) FROM amazon_brazil.payments),1)||'%' AS total_percentage_orders 
FROM amazon_brazil.payments GROUP BY payment_type ORDER BY total_percentage_orders DESC;
--From the query, credit cards percenatge highly dominates followed by boleto

--Q3 product_id & price
SELECT p.product_id,oi.price FROM amazon_brazil.products p 
JOIN amazon_brazil.order_items oi on p.product_id = oi.product_id 
WHERE oi.price BETWEEN 100 AND 500 AND p.product_category_name LIKE '%SMART%'
ORDER BY oi.price DESC;

--Q4 total_sales & month
SELECT EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,ROUND(SUM(oi.price)) AS total_sales 
FROM amazon_brazil.orders o JOIN amazon_brazil.order_items oi on o.order_id= oi.order_id GROUP BY
month ORDER BY total_sales DESC LIMIT 3;

--	Q5 product_category_name & total_revenue
SELECT p.product_category_name, SUM(oi.price)AS total_revenue FROM amazon_brazil.products p 
JOIN amazon_brazil.order_items oi on p.product_id = oi.product_id GROUP BY product_category_name
ORDER BY total_revenue DESC LIMIT 5;

--Q6 payment_type with payment_value std_variation
SELECT payment_type,ROUND(STDDEV(payment_value),2)AS Std_deviation  FROM amazon_brazil.payments  
GROUP BY payment_type ORDER BY Std_deviation;

--Q7 product_id ,product_category_name(missing name & single character)
SELECT product_id,product_category_name FROM amazon_brazil.products
WHERE product_category_name IS NULL OR LENGTH(TRIM(product_category_name))=1;


--ANALYSIS II

--Q1 order_value_segment, payment_type, count
SELECT payment_type,CASE WHEN payment_value <200 THEN 'Low'
WHEN  payment_value BETWEEN 200 AND 1000 THEN 'Medium'
ELSE 'High'
END AS order_value_segment, COUNT(*) AS count FROM amazon_brazil.payments
GROUP BY order_value_segment,payment_type
ORDER BY count DESC;

--Q2 --product_category_name , min, max,avg_price
SELECT p.product_category_name, ROUND(MIN(oi.price),1)AS min_price,ROUND(MAX(oi.price),1)AS max_price,
ROUND(AVG(oi.price),1)AS avg_price FROM amazon_brazil.products p JOIN amazon_brazil.order_items oi on p.product_id = oi.product_id 
GROUP BY product_category_name ORDER BY avg_price;

--Q3 customer_unique_id & total_order
SELECT c.customer_unique_id, COUNT(o.order_id)AS total_orders FROM amazon_brazil.customers c 
JOIN amazon_brazil.orders o on c.customer_id = o.customer_id GROUP BY customer_unique_id
HAVING COUNT(o.order_id)>1 ORDER BY total_orders;

--Q4--custmer_unique_id , customer_type (qnty =1 'new' qnty=2&4 'returning')
WITH customer_order AS(
SELECT c.customer_unique_id, COUNT(o.order_id) AS order_qty FROM amazon_brazil.customers c
JOIN amazon_brazil.orders o on c.customer_id = o.customer_id GROUP BY customer_unique_id
)
SELECT customer_unique_id, 
CASE WHEN order_qty=1 THEN 'New'
     WHEN order_qty BETWEEN 2 AND 4 THEN 'Returning'
     WHEN order_qty>4  THEN 'Loyal'
end as customer_type FROM customer_order 
ORDER BY customer_unique_id;

--Q5--product_category_name & total _revenue by Top 5
SELECT p.product_category_name,SUM(oi.price) AS total_revenue FROM amazon_brazil.products p JOIN amazon_brazil.order_items oi on p.product_id = oi.product_id 
GROUP BY product_category_name ORDER BY total_revenue DESC LIMIT 5;

--ANALYSIS _ III

--Q1 total_sales for each season (summer,autumn, spring,winter) based on order purchase date
SELECT season,SUM(total_sales)AS total_sales
FROM(
SELECT CASE 
WHEN EXTRACT(MONTH from o.order_purchase_timestamp) IN(3,4,5) THEN 'SPRING'
WHEN EXTRACT(MONTH from o.order_purchase_timestamp) IN(6,7,8) THEN 'SUMMER'
WHEN EXTRACT(MONTH from o.order_purchase_timestamp) IN(9,10,11) THEN 'AUTUMN'
ELSE 'WINTER'
end as season, oi.price AS total_sales FROM amazon_brazil.orders o JOIN amazon_brazil.order_items oi
on o.order_id = oi.order_id) as seasonal_data GROUP BY season ORDER BY total_sales DESC;
--From the query SPRING season has maximum sales followed by winter

--Q2 - product_id & total_quantity_sold
WITH my_cte AS (
SELECT product_id, COUNT(*) AS total_quantity_sold
FROM amazon_brazil.order_items
GROUP BY product_id
)
SELECT product_id, total_quantity_sold
FROM my_cte WHERE total_quantity_sold > (
SELECT AVG(total_quantity_sold) FROM my_cte)
ORDER BY total_quantity_sold DESC;

--Q3 month & total revenue 

SELECT EXTRACT(MONTH from o.order_purchase_timestamp) AS month,SUM(oi.price) as total_revenue FROM amazon_brazil.orders o JOIN
amazon_brazil.order_items oi on o.order_id = oi.order_id 
WHERE EXTRACT(YEAR from o.order_purchase_timestamp) ='2018'
AND o.order_status = 'delivered'
GROUP BY EXTRACT(Month from o.order_purchase_timestamp)
ORDER BY total_revenue DESC;

--Q4 - customer_type & count of order

WITH my_cte AS(
SELECT c.customer_unique_id,COUNT(o.order_id) as total_order FROM amazon_brazil.customers c JOIN
amazon_brazil.orders o on c.customer_id =o.customer_id GROUP BY c.customer_unique_id
),
customer_segments AS(
SELECT customer_unique_id ,
CASE WHEN total_order BETWEEN 1 AND 2 THEN 'Occassional'
WHEN total_order BETWEEN 3 AND 5 THEN 'Regular'
WHEN total_order >5 THEN 'Loyal' end as customer_type 
FROM my_cte
)
SELECT customer_type,
COUNT(*) AS count FROM customer_segments
GROUP BY customer_type
ORDER BY count;

--Q5--customer_id,average_order_value & customer_rank
WITH my_cte AS(
SELECT o.customer_id,SUM(oi.price) as order_value FROM amazon_brazil.orders o JOIN
amazon_brazil.order_items oi on o.order_id =oi.order_id GROUP BY customer_id
),
customer_avg AS(
SELECT customer_id,ROUND(AVG(order_value),2) AS avg_order_value
FROM my_cte GROUP BY customer_id
)
SELECT customer_id,avg_order_value,
RANK()OVER(ORDER BY avg_order_value DESC)AS customer_rank 
FROM customer_avg ORDER BY customer_rank limit 20;

--Q6 product_id, sale_month,total_sales
WITH monthly_sales AS (
SELECT  oi.product_id,EXTRACT(MONTH from o.order_purchase_timestamp) AS sale_month,
SUM(oi.price) AS monthly_sales FROM amazon_brazil.orders o
JOIN amazon_brazil.order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.product_id, EXTRACT(MONTH FROM o.order_purchase_timestamp)
)
SELECT product_id, sale_month,
SUM(monthly_sales) OVER (PARTITION BY product_id
ORDER BY sale_month) AS total_sales
FROM monthly_sales
ORDER BY product_id, sale_month;


-- Q7 payment_type, sale_month, monthly_total, monthly_change
WITH monthly_sales AS (
    SELECT 
        p.payment_type,
        EXTRACT(MONTH FROM o.order_purchase_timestamp) AS sale_month,
        SUM(oi.price) AS monthly_total
    FROM amazon_brazil.orders o
    JOIN amazon_brazil.order_items oi 
        ON o.order_id = oi.order_id
    JOIN amazon_brazil.payments p
        ON o.order_id = p.order_id
    WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018
      AND o.order_status = 'delivered'
    GROUP BY p.payment_type, EXTRACT(MONTH FROM o.order_purchase_timestamp)
),
monthly_growth AS (
    SELECT 
        payment_type,
        sale_month,
        monthly_total,
        LAG(monthly_total) OVER (
            PARTITION BY payment_type 
            ORDER BY sale_month
        ) AS previous_month_total
    FROM monthly_sales
)
SELECT 
    payment_type,
    sale_month,
    ROUND(monthly_total, 2) AS monthly_total,
    ROUND(
        ((monthly_total - previous_month_total) / previous_month_total) * 100, 
        2
    ) AS monthly_change_percentage
FROM monthly_growth
ORDER BY payment_type, sale_month;

 


