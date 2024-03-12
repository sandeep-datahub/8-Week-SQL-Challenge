--Table creation
USE [Dannys Diner];

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 
CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

/* --------------------
   CASE STUDY QUESTIONS
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(price) AS total_amount_spent
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT (DISTINCT order_date)
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH CTE AS (
SELECT s.customer_id, m.product_name,
ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) rn
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
)
SELECT customer_id, product_name FROM cte WHERE rn = 1

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT * FROM sales;
SELECT * FROM menu;
SELECT * FROM members;
product_name, count of occurences overall
select * from sales,menu

select TOP 1 m.product_name, COUNT(m.product_name)
from sales s
join menu m
ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY COUNT(m.product_name) DESC

-- 5. Which item was the most popular for each customer?
WITH item_count as (
	SELECT s.customer_id, m.product_name,
	COUNT(*) as order_count
	FROM sales s
	JOIN menu m
	ON s.product_id = m.product_id
	GROUP BY s.customer_id, m.product_name
),
ranking as (
	SELECT *,
	DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_count DESC) as rn
	FROM item_count
)
SELECT customer_id, product_name
FROM ranking
WHERE rn = 1

-- 6. Which item was purchased first by the customer after they became a member?
WITH orders AS(
SELECT s.customer_id, s.order_date, m.product_name, mb.join_date,
ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY order_date) as rn
FROM menu m
JOIN sales s
ON s.product_id = m.product_id
JOIN members mb
ON s.customer_id = mb.customer_id
WHERE s.order_date > mb.join_date
)
SELECT customer_id, product_name, order_date, join_date
FROM orders
WHERE rn = 1

-- 7. Which item was purchased just before the customer became a member?
WITH orders AS(
SELECT s.customer_id, s.order_date, m.product_name, mb.join_date,
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date DESC) as rn
FROM menu m
JOIN sales s
ON s.product_id = m.product_id
JOIN members mb
ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
)
SELECT customer_id, product_name, order_date, join_date
FROM orders
WHERE rn = 1

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(m.product_id) as total_items_ordered, SUM(price) as total_amount_spent
FROM menu m
JOIN sales s
ON m.product_id = s.product_id
JOIN members mb
ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id, m.product_name, m.price, 
CASE
    WHEN m.product_name = 'sushi' THEN m.price*10*2
    ELSE m.price*10
END as points
FROM sales s
JOIN menu m
ON s.product_id = m.product_id

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi
--- how many points do customer A and B have at the end of January?

select * from sales

WITH cte as (
SELECT s.customer_id, m.product_name, m.price, order_date, join_date,
CASE
    WHEN s.order_date BETWEEN mb.join_date AND DATEADD(day, 7, mb.join_date) THEN m.price*10*2
	WHEN m.product_name = 'sushi' THEN m.price*10*2
    ELSE m.price*10
END as points
FROM menu m
JOIN sales s
ON s.product_id = m.product_id
JOIN members mb
ON s.customer_id = mb.customer_id
WHERE order_date < '2021-02-01'
)
SELECT customer_id, SUM(points) as total_points FROM cte
GROUP BY customer_id


-- BONUS Questions
-- Q.11: Determine the name and price of the product ordered by each customer on all order dates & find out whether the customer 
-- was a member on the order date or not

SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE
	WHEN mb.join_date <= s.order_date THEN 'Y'
	ELSE 'N'
END AS member
FROM menu m
JOIN sales s
ON s.product_id = m.product_id
LEFT JOIN members mb
ON mb.customer_id = s.customer_id

-- Bonus Q.12: Rank the previous output from Q.11 based on the order_date for each customer. Display NULL if customer was not a 
-- member when dish was ordered.

WITH cte AS (
	SELECT s.customer_id, s.order_date, m.product_name, m.price,
	CASE
		WHEN mb.join_date <= s.order_date THEN 'Y'
		ELSE 'N'
	END AS member_status
	FROM menu m
	JOIN sales s
	ON s.product_id = m.product_id
	LEFT JOIN members mb
	ON mb.customer_id = s.customer_id
)
SELECT *, 
CASE
	WHEN cte.member_status = 'Y' THEN RANK() OVER(PARTITION BY cte.customer_id, cte.member_status ORDER BY cte.order_date)
	ELSE NULL
END AS ranking
FROM cte
