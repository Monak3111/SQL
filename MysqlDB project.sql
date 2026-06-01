CREATE DATABASE ecommerce_analytics;
USE ecommerce_analytics;

CREATE TABLE customers (
customer_id INT AUTO_INCREMENT PRIMARY KEY,
first_name VARCHAR(50),
last_name VARCHAR(50),
email VARCHAR(100) UNIQUE,
city VARCHAR(50),
country VARCHAR(50),
signup_date DATE
);

CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2),
    cost DECIMAL(10,2)
);

CREATE TABLE inventory (
    inventory_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    stock_quantity INT,
    reorder_level INT,
    FOREIGN KEY(product_id)
    REFERENCES products(product_id)
);

CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    order_status VARCHAR(30),

    FOREIGN KEY(customer_id)
    REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10,2),

    FOREIGN KEY(order_id)
    REFERENCES orders(order_id),

    FOREIGN KEY(product_id)
    REFERENCES products(product_id)
);

create table payments (
payment_id int auto_increment primary key,
order_id int,
payment_date date,
payment_method varchar(50),
amount decimal(10,2),

foreign key(order_id)
references  orders(order_id)
);

CREATE TABLE shipping (
    shipping_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    shipped_date DATE,
    delivery_date DATE,
    shipping_status VARCHAR(50),

    FOREIGN KEY(order_id)
    REFERENCES orders(order_id)
);
CREATE TABLE returns (
    return_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    return_date DATE,
    reason VARCHAR(255),

    FOREIGN KEY(order_id)
    REFERENCES orders(order_id)
);

insert into customers
(first_name, last_name, email, city, country, signup_date)
values
('John','Doe','john@gmail.com','New York','USA','2023-01-10'),
('Emma','Smith','emma@gmail.com','London','UK','2023-02-15'),
('Raj','Kumar','raj@gmail.com','Delhi','India','2023-03-01');


INSERT INTO products
(product_name,category,price,cost)
VALUES
('Laptop','Electronics',1000,700),
('Phone','Electronics',700,450),
('Headphones','Accessories',100,50);

INSERT INTO inventory
(product_id,stock_quantity,reorder_level)
VALUES
(1,50,10),
(2,70,15),
(3,100,20);

INSERT INTO orders
(customer_id,order_date,order_status)
VALUES
(1,'2024-01-10','Completed'),
(2,'2024-01-15','Completed'),
(3,'2024-02-01','Completed');

INSERT INTO order_items
(order_id,product_id,quantity,unit_price)
VALUES
(1,1,1,1000),
(1,3,2,100),
(2,2,1,700),
(3,1,1,1000);



CREATE VIEW sales_summary AS
SELECT
    o.order_id,
    o.order_date,
    p.product_name,
    p.category,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN orders o
ON oi.order_id=o.order_id
JOIN products p
ON oi.product_id=p.product_id;

select
c.customer_id,
concat(c.first_name,' ', c.last_name) customer_name,
count(o.order_id) total_orders,
sum(oi.quantity*oi.unit_price) total_spent
from customers c
join orders o
on c.customer_id=o.customer_id
JOIN order_items oi
ON o.order_id=oi.order_id
GROUP BY c.customer_id;

WITH customer_sales AS
(
SELECT
    c.customer_id,
    CONCAT(c.first_name,' ',c.last_name) customer_name,
    SUM(oi.quantity*oi.unit_price) revenue
FROM customers c
JOIN orders o
ON c.customer_id=o.customer_id
JOIN order_items oi
ON o.order_id=oi.order_id
GROUP BY c.customer_id
)

SELECT *
FROM customer_sales
ORDER BY revenue DESC;

select
product_name,
category,
sum(quantity*unit_price) revenue,

rank() over(
order by sum(quantity*unit_price) desc
) revenue_rank

from order_items oi
join products p
on oi.product_id=p.product_id

group by product_name, category;

delimiter //
create procedure getmonthlyrevenue()
begin

select
year(order_date) year_,
month(order_date) month_,
sum(quantity*unit_price) revenue

from orders o
join order_items oi
on o.order_id=oi.order_id

GROUP BY YEAR(order_date),
MONTH(order_date);

END //

DELIMITER ;

CALL GetMonthlyRevenue();

DELIMITER //

CREATE TRIGGER trg_reduce_inventory
AFTER INSERT ON order_items
FOR EACH ROW

BEGIN

UPDATE inventory
SET stock_quantity =
stock_quantity - NEW.quantity

WHERE product_id = NEW.product_id;

END //

DELIMITER ;


CREATE INDEX idx_order_date
ON orders(order_date);

CREATE INDEX idx_customer
ON orders(customer_id);

CREATE INDEX idx_product
ON order_items(product_id);

SELECT
    DATE_FORMAT(order_date,'%Y-%m') Month,
    SUM(quantity*unit_price) Revenue
FROM orders o
JOIN order_items oi
ON o.order_id=oi.order_id
GROUP BY Month
ORDER BY Month;

SELECT
    product_name,
    SUM(quantity) Units_Sold
FROM order_items oi
JOIN products p
ON oi.product_id=p.product_id
GROUP BY product_name
ORDER BY Units_Sold DESC;



SELECT
    CONCAT(first_name,' ',last_name) Customer,
    SUM(quantity*unit_price) Lifetime_Value
FROM customers c
JOIN orders o
ON c.customer_id=o.customer_id
JOIN order_items oi
ON o.order_id=oi.order_id
GROUP BY Customer
ORDER BY Lifetime_Value DESC;

SELECT
    ROUND(
        COUNT(r.return_id)*100.0 /
        COUNT(DISTINCT o.order_id),2
    ) Return_Rate
FROM orders o
LEFT JOIN returns r
ON o.order_id=r.order_id;

SELECT
    p.product_name,
    i.stock_quantity,
    i.reorder_level
FROM inventory i
JOIN products p
ON i.product_id=p.product_id
WHERE stock_quantity <= reorder_level;





















