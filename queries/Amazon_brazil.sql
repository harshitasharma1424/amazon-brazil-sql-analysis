-- AMAZON BRAZIL E-COMMERCE ANALYSIS
-- Tool: PostgreSQL

-- Preview Tables
SELECT * FROM amazon_brazil.customers;
SELECT * FROM amazon_brazil.order_items;
SELECT * FROM amazon_brazil.orders;
SELECT * FROM amazon_brazil.payments;
SELECT * FROM amazon_brazil.products;
SELECT * FROM amazon_brazil.sellers;

-- =========================================================
-- ANALYSIS I
-- =========================================================

-- Q1: Average payment value by payment type
SELECT 
    payment_type,
    ROUND(AVG(payment_value)) AS rounded_avg_payment
FROM amazon_brazil.payments
GROUP BY payment_type
ORDER BY rounded_avg_payment;


-- Q2: Percentage distribution of orders by payment type
SELECT 
    payment_type,
    ROUND(COUNT(order_id) * 100.0 / (SELECT COUNT(*) FROM amazon_brazil.payments), 1) AS percentage_orders
FROM amazon_brazil.payments
GROUP BY payment_type
ORDER BY percentage_orders DESC;


-- Q3: Products priced between 100 and 500 BRL containing 'Smart' in category/name
SELECT 
    p.product_id,
    p.product_category_name,
    oi.price
FROM amazon_brazil.products p
JOIN amazon_brazil.order_items oi 
    ON p.product_id = oi.product_id
WHERE oi.price BETWEEN 100 AND 500
  AND p.product_category_name ILIKE '%smart%'
ORDER BY oi.price DESC;


-- Q4: Top 3 months with highest total sales
SELECT 
    EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,
    ROUND(SUM(oi.price)) AS total_sales
FROM amazon_brazil.orders o
JOIN amazon_brazil.order_items oi 
    ON o.order_id = oi.order_id
GROUP BY EXTRACT(MONTH FROM o.order_purchase_timestamp)
ORDER BY total_sales DESC
LIMIT 3;


-- Q5: Product categories with price difference greater than 500 BRL
SELECT 
    p.product_category_name,
    ROUND(MAX(oi.price) - MIN(oi.price), 2) AS price_difference
FROM amazon_brazil.products p
JOIN amazon_brazil.order_items oi 
    ON p.product_id = oi.product_id
GROUP BY p.product_category_name
HAVING MAX(oi.price) - MIN(oi.price) > 500
ORDER BY price_difference DESC;


-- Q6: Payment types with least variation in transaction amounts
SELECT 
    payment_type,
    ROUND(STDDEV(payment_value), 2) AS std_deviation
FROM amazon_brazil.payments
GROUP BY payment_type
ORDER BY std_deviation;


-- Q7: Products with missing or single-character category names
SELECT 
    product_id,
    product_category_name
FROM amazon_brazil.products
WHERE product_category_name IS NULL 
   OR LENGTH(TRIM(product_category_name)) = 1;


-- =========================================================
-- ANALYSIS II
-- =========================================================

-- Q1: Payment type count by order value segment
SELECT 
    CASE 
        WHEN payment_value < 200 THEN 'Low'
        WHEN payment_value BETWEEN 200 AND 1000 THEN 'Medium'
        ELSE 'High'
    END AS order_value_segment,
    payment_type,
    COUNT(*) AS count
FROM amazon_brazil.payments
GROUP BY order_value_segment, payment_type
ORDER BY count DESC;


-- Q2: Min, max, and average price by product category
SELECT 
    p.product_category_name,
    ROUND(MIN(oi.price), 2) AS min_price,
    ROUND(MAX(oi.price), 2) AS max_price,
    ROUND(AVG(oi.price), 2) AS avg_price
FROM amazon_brazil.products p
JOIN amazon_brazil.order_items oi 
    ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY avg_price DESC;


-- Q3: Customers with more than one order
SELECT 
    c.customer_unique_id,
    COUNT(o.order_id) AS total_orders
FROM amazon_brazil.customers c
JOIN amazon_brazil.orders o 
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING COUNT(o.order_id) > 1
ORDER BY total_orders DESC;


-- Q4: Customer segmentation by purchase frequency
WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(o.order_id) AS order_qty
    FROM amazon_brazil.customers c
    JOIN amazon_brazil.orders o 
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT 
    customer_unique_id,
    CASE 
        WHEN order_qty = 1 THEN 'New'
        WHEN order_qty BETWEEN 2 AND 4 THEN 'Returning'
        WHEN order_qty > 4 THEN 'Loyal'
    END AS customer_type
FROM customer_orders
ORDER BY customer_unique_id;


-- Q5: Top 5 product categories by total revenue
SELECT 
    p.product_category_name,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM amazon_brazil.products p
JOIN amazon_brazil.order_items oi 
    ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC
LIMIT 5;


-- =========================================================
-- ANALYSIS III
-- =========================================================

-- Q1: Total sales by season
SELECT 
    season,
    ROUND(SUM(total_sales), 2) AS total_sales
FROM (
    SELECT 
        CASE 
            WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (3, 4, 5) THEN 'Spring'
            WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (6, 7, 8) THEN 'Summer'
            WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (9, 10, 11) THEN 'Autumn'
            ELSE 'Winter'
        END AS season,
        oi.price AS total_sales
    FROM amazon_brazil.orders o
    JOIN amazon_brazil.order_items oi 
        ON o.order_id = oi.order_id
) AS seasonal_data
GROUP BY season
ORDER BY total_sales DESC;


-- Q2: Products with sales volume above overall average
WITH product_quantity AS (
    SELECT 
        product_id,
        COUNT(*) AS total_quantity_sold
    FROM amazon_brazil.order_items
    GROUP BY product_id
)
SELECT 
    product_id,
    total_quantity_sold
FROM product_quantity
WHERE total_quantity_sold > (
    SELECT AVG(total_quantity_sold)
    FROM product_quantity
)
ORDER BY total_quantity_sold DESC;


-- Q3: Monthly revenue trends for year 2018
SELECT 
    EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM amazon_brazil.orders o
JOIN amazon_brazil.order_items oi 
    ON o.order_id = oi.order_id
WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018
  AND o.order_status = 'delivered'
GROUP BY EXTRACT(MONTH FROM o.order_purchase_timestamp)
ORDER BY month;


-- Q4: Customer loyalty segmentation count
WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(o.order_id) AS total_orders
    FROM amazon_brazil.customers c
    JOIN amazon_brazil.orders o 
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
),
customer_segments AS (
    SELECT 
        customer_unique_id,
        CASE 
            WHEN total_orders BETWEEN 1 AND 2 THEN 'Occasional'
            WHEN total_orders BETWEEN 3 AND 5 THEN 'Regular'
            WHEN total_orders > 5 THEN 'Loyal'
        END AS customer_type
    FROM customer_orders
)
SELECT 
    customer_type,
    COUNT(*) AS customer_count
FROM customer_segments
GROUP BY customer_type
ORDER BY customer_count DESC;


-- Q5: Top 20 high-value customers by average order value
WITH customer_order_value AS (
    SELECT 
        o.customer_id,
        o.order_id,
        SUM(oi.price) AS order_value
    FROM amazon_brazil.orders o
    JOIN amazon_brazil.order_items oi 
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id, o.order_id
),
customer_avg AS (
    SELECT 
        customer_id,
        ROUND(AVG(order_value), 2) AS avg_order_value
    FROM customer_order_value
    GROUP BY customer_id
)
SELECT 
    customer_id,
    avg_order_value,
    RANK() OVER (ORDER BY avg_order_value DESC) AS customer_rank
FROM customer_avg
ORDER BY customer_rank
LIMIT 20;


-- Q6: Monthly cumulative sales by product
WITH monthly_sales AS (
    SELECT  
        oi.product_id,
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS sale_month,
        SUM(oi.price) AS monthly_sales
    FROM amazon_brazil.orders o
    JOIN amazon_brazil.order_items oi 
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.product_id, DATE_TRUNC('month', o.order_purchase_timestamp)
)
SELECT 
    product_id,
    sale_month,
    ROUND(
        SUM(monthly_sales) OVER (
            PARTITION BY product_id
            ORDER BY sale_month
        ), 2
    ) AS cumulative_sales
FROM monthly_sales
ORDER BY product_id, sale_month;


-- Q7: Month-over-month sales growth by payment type for 2018
WITH monthly_sales AS (
    SELECT 
        p.payment_type,
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS sale_month,
        SUM(oi.price) AS monthly_total
    FROM amazon_brazil.orders o
    JOIN amazon_brazil.order_items oi 
        ON o.order_id = oi.order_id
    JOIN amazon_brazil.payments p
        ON o.order_id = p.order_id
    WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018
      AND o.order_status = 'delivered'
    GROUP BY p.payment_type, DATE_TRUNC('month', o.order_purchase_timestamp)
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
        ((monthly_total - previous_month_total) / NULLIF(previous_month_total, 0)) * 100, 
        2
    ) AS monthly_change_percentage
FROM monthly_growth
ORDER BY payment_type, sale_month;
