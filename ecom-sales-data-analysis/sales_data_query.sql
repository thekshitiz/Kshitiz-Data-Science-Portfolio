
SELECT * FROM orders
LIMIT 10;


-- 1. Sales from top 20 products
-- This query finds the top 20 products based on the total sales value.
-- We calculate the total sales for each product by multiplying the price with the quantity.
-- The LIMIT clause restricts the result to the top 20 products.

SELECT product_id, SUM(price * quantity) AS total_sales
FROM orders
GROUP BY product_id
ORDER BY total_sales DESC
LIMIT 20;

-- 2. Top 20 products in each month
-- This query retrieves the top 20 products sold in each month.
-- We use ROW_NUMBER() to rank products within each month and filter to only get the top 20.

WITH ranked_products AS (
    SELECT EXTRACT(YEAR FROM order_date) AS year,
           EXTRACT(MONTH FROM order_date) AS month,
           product_id,
           SUM(price * quantity) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date) 
                              ORDER BY SUM(price * quantity) DESC) AS rank
    FROM orders
    GROUP BY year, month, product_id
)
SELECT year, month, product_id, total_sales
FROM ranked_products
WHERE rank <= 20
ORDER BY year, month, total_sales DESC;



-- 3. Top 1% and 5% product sales in each month
-- This query retrieves the top 1% and 5% product sales in each month.
-- We first calculate the total sales per product for each month.
-- Then, we filter the products whose sales exceed the 1st and 5th percentiles for that month.

WITH sales_per_month AS (
    SELECT EXTRACT(YEAR FROM order_date) AS year,
           EXTRACT(MONTH FROM order_date) AS month,
           product_id,
           SUM(price * quantity) AS total_sales
    FROM orders
    GROUP BY year, month, product_id
)
-- Top 1% products in each month
SELECT year, month, product_id, total_sales
FROM sales_per_month
WHERE total_sales > (
    SELECT PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY total_sales)
    FROM sales_per_month AS sm
    WHERE sm.year = sales_per_month.year AND sm.month = sales_per_month.month
)
ORDER BY year, month, total_sales DESC;

-- Top 5% products: change the percentile to 0.05 in the subquery.


-- 4. Top product sales in each category
-- This query retrieves the product with the highest sales in each category.
-- We join the 'orders' table with 'products' (assumed to have the 'category' column).
-- The sales for each product are calculated by multiplying the price with the quantity.
-- We use GROUP BY to get the sales per product within each category and order by sales in descending order.

SELECT category, 
       product_id, 
       SUM(price * quantity) AS total_sales
FROM orders
GROUP BY category, product_id
ORDER BY category, total_sales DESC;


-- 4. Top product sales in each category (only the top product per category)
-- This query retrieves the top-selling product in each category.
-- We use ROW_NUMBER() to rank products within each category based on total sales.

WITH ranked_products AS (
    SELECT category,
           product_id,
           SUM(price * quantity) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY SUM(price * quantity) DESC) AS rank
    FROM orders
    GROUP BY category, product_id
)
SELECT category, product_id, total_sales
FROM ranked_products
WHERE rank = 1
ORDER BY category;

