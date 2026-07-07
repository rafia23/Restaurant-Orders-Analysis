USE restaurant_db;

-- **Menu Analysis**
-- Find the no. of items in the menu
SELECT COUNT(menu_item_id) AS Number_of_items FROM menu_items;


-- What are the least and most expensive item on the menu?
SELECT item_name, price,
CASE 
WHEN price = (SELECT MIN(price) FROM menu_items) THEN "Least Expensive"
WHEN price = (SELECT MAX(price) FROM menu_items) THEN "Most Expensive"
END AS price_type
FROM menu_items
WHERE price = (SELECT MIN(price) FROM menu_items)
OR price = (SELECT MAX(price) FROM menu_items);


-- How many dishes are in each category?
SELECT category, COUNT(menu_item_id) as total_no_of_dishes
FROM menu_items
GROUP BY category;

-- What is the average dish price within each category?
SELECT category, ROUND(AVG(price),2) as avg_price
FROM menu_items
GROUP BY category;

-- What are the 10 most expensive menu items?
SELECT item_name, category, price
FROM menu_items
ORDER BY price DESC
LIMIT 10;

-- **Order Analysis**

-- Date range of the table
SELECT MIN(order_date) AS start_date, MAX(order_date) AS end_date FROM order_details;

-- Total no. of orders
SELECT COUNT(distinct order_id) AS total_orders FROM order_details;

-- How many items were ordered in total?
SELECT COUNT(item_id) AS total_ordered_item FROM order_details;

-- What were the top 10 orders with the most number of items?
SELECT order_id, COUNT(item_id) AS num_items FROM order_details
GROUP BY order_id
ORDER BY num_items DESC
LIMIT 10;

-- What is the average number of items per order?
WITH item_no_per_order AS 
(SELECT order_id, COUNT(item_id) AS count_item
FROM order_details
GROUP BY order_id)

SELECT ROUND(AVG(count_item),2) AS avg_item_per_order
FROM item_no_per_order;

-- Which menu items never received an order?  
SELECT m.item_name
FROM menu_items m LEFT JOIN order_details o ON m.menu_item_id = o.item_id
WHERE o.item_id IS NULL;

-- **Revenue & Sales Performance**

-- Which categories generated the highest total revenue?
SELECT m.category, SUM(price) AS total_revenue
FROM menu_items m JOIN order_details o ON m.menu_item_id = o.item_id
GROUP BY m.category
ORDER BY total_revenue DESC;

-- Which category contributes most revenue? (Revenue contribution %)
SELECT category, 
ROUND(SUM(price) * 100 / SUM(SUM(price)) OVER (),2) AS revenue_percentage
FROM menu_items m JOIN order_details o ON m.menu_item_id = o.item_id
GROUP BY category
ORDER BY revenue_percentage DESC;

-- What were the top 5 menu items that generated the highest revenue?
SELECT item_name, SUM(price) AS total_revenue
FROM menu_items m JOIN order_details o ON m.menu_item_id = o.item_id
GROUP BY item_name
ORDER BY total_revenue DESC
LIMIT 5;

-- What were the top 5 orders that spent the most money?
SELECT SUM(price) AS total_spend, order_id
FROM menu_items m JOIN order_details o ON m.menu_item_id = o.item_id
GROUP BY order_id
ORDER BY SUM(price) DESC
LIMIT 5; 

-- View the details of the top 5 highest spend order. 
WITH top5_orders AS 
(SELECT order_id, SUM(price) AS total_spend 
FROM menu_items m JOIN order_details o ON m.menu_item_id = o.item_id
GROUP BY order_id
ORDER BY SUM(price) DESC
LIMIT 5)

SELECT * FROM menu_items m JOIN order_details o ON m.menu_item_id = o.item_id
JOIN top5_orders t ON o.order_id = t.order_id
ORDER BY t.total_spend DESC, o.order_id; -- to order by highest spend

-- Rank menu items by revenue within each category. 
WITH revenue AS(
SELECT m.category, m.item_name, SUM(m.price) AS total_revenue
FROM menu_items m JOIN order_details o ON m.menu_item_id = o.item_id
GROUP BY m.category, m.item_name
)
SELECT revenue.category, revenue.item_name, revenue.total_revenue,
RANK() OVER(PARTITION BY revenue.category ORDER BY revenue.total_revenue DESC) as rank_by_revenue
FROM revenue;

-- **Customer Purchasing Patterns**

-- Which menu items are most frequently ordered together? (Market Basket Analysis)
SELECT m1.item_name AS item1, m2.item_name AS item2, COUNT(*) AS no_of_times_ordered_together
FROM order_details o1 JOIN order_details o2 ON o1.order_id = o2.order_id AND o1.item_id > o2.item_id
JOIN menu_items m1 ON m1.menu_item_id = o1.item_id
JOIN menu_items m2 ON m2.menu_item_id = o2.item_id
GROUP BY m1.item_name, m2.item_name
ORDER BY no_of_times_ordered_together DESC;

-- What is the average order value? 
WITH total_order_value AS (
SELECT o.order_id, SUM(m.price) AS total_price
FROM menu_items m JOIN order_details o ON m.menu_item_id = o.item_id
GROUP BY o.order_id)

SELECT ROUND(AVG(total_price),2) AS avg_order_value
FROM total_order_value;

-- Top 5 most frequently ordered menu items
SELECT item_name, category, COUNT(order_details_id) AS num_orders
FROM menu_items m JOIN order_details o ON m.menu_item_id = o.item_id
GROUP BY item_name, category
ORDER BY COUNT(order_details_id) DESC
LIMIT 5;


-- Time-based Revenue Analysis
-- Which hour receives the most orders? 
SELECT COUNT(DISTINCT order_id) AS no_of_orders, EXTRACT(HOUR FROM order_time) AS hour_of_day
FROM order_details
GROUP BY EXTRACT(HOUR FROM order_time)
ORDER BY COUNT(DISTINCT order_id) DESC;

-- Which hour generates the most revenue
SELECT SUM(m.price) AS revenue, EXTRACT(HOUR FROM o.order_time) AS hour_of_day
FROM menu_items m JOIN order_details o ON m.menu_item_id = o.item_id
GROUP BY EXTRACT(HOUR FROM o.order_time)
ORDER BY SUM(m.price) DESC;
