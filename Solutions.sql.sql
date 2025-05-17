create database monday_coffee;
use monday_coffee;



CREATE TABLE city
(
	city_id	INT PRIMARY KEY,
	city_name VARCHAR(15),	
	population	BIGINT,
	estimated_rent	FLOAT,
	city_rank INT
);

create table customers
(
  customer_id int primary key,
  customer_name varchar(25),
  city_id int,
  constraint fk_city foreign key (city_id) references city(city_id)
);

CREATE TABLE products
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	Price float
);


CREATE TABLE sales
(
	sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total FLOAT,
	rating INT,
	CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
	CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
);

-- monday coffee -- data analysis
use monday_coffee;
select * from city;
select * from customers;
select * from products;
select * from sales;

-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

select 
     city_name,
     round((population * 0.25) / 100000 , 2) as coffee_consumers_in_millions,
     city_rank
from city
order by 2 desc;





- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

select sum(total) as total_revenue
from sales
where year(sale_date) = 2023 and quarter(sale_date) = 4;



select 
      ci.city_name,
      sum(s.total) as total_revenue
from sales s
join customers  c
on s.customer_id = c.customer_id
join city  ci
on ci.city_id = c.city_id
where year(s.sale_date) = 2023 
      and 
      quarter(s.sale_date) = 4
group by ci.city_name
order by total_revenue desc;



-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

select 
     pd.product_name,
     count(s.sale_id) as total_orders
from products pd
left join sales s
on s.product_id = pd.product_id
group by product_name
order by total_orders desc;


-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?
-- city abd total sale
-- no cx in each these city


select 
    ci.city_name,
    sum(s.total) as total_revenue,
    count(distinct c.customer_id) as total_cust,
    round(
          sum(s.total) / count(distinct c.customer_id),2) as avg_sale_pr_cust

from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
group by city_name 
order by total_revenue  desc;

-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

use monday_coffee;
with  city_table as
(
   select 
   city_name,
   round((population * 0.25)/100000, 2) as coffee_consumer
   from city
),
customers_table
as
(
  select 
  ci.city_name,
  count(distinct c.customer_id) as unique_cx
  from sales as s
  join customers as c
  on c.customer_id = s.customer_id
  join city as ci
  on ci.city_id = c.city_id
  group by 1
  
)
select 
      customers_table.city_name,
      city_table.coffee_consumer as coffee_comsumer_in_millions,
      customers_table.unique_cx
from city_table
join customers_table
on city_table.city_name = customers_table.city_name;




-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
select * 
from 
(select 
    ci.city_name,
    p.product_name,
    count(s.sale_id) as total_orders,
    dense_rank() over(partition by ci.city_name order by count(s.sale_id) desc) as rnk
from sales as s
join products as p
on s.product_id = p.product_id
join customers as c
on c.customer_id = s.customer_id
join city as ci
on ci.city_id = c.city_id
group by ci.city_name, p.product_name
order by ci.city_name, total_orders desc) as t1
where rnk <=  3;




-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

select 
    ci.city_name,
    count(distinct(c.customer_id)) as unique_cx
from city as ci
left join 
customers as c
on c.city_id = ci.city_id
join sales as s
on s.customer_id = c.customer_id
where
  s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by ci.city_name;


-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

-- Conclusions

with city_table
as
(
    select 
     ci.city_name,
     sum(s.total) as total_revenue,
     count(distinct s.customer_id) as total_cx,
     round(
            sum(s.total) / count(distinct s.customer_id),2) as avg_sale_pr_cx
	
    from sales as s
    join customers as c
    on s.customer_id  = c.customer_id
    join city as ci
    on ci.city_id = c.city_id
    group by ci.city_name
    order by sum(s.total) desc
),
city_rent
as
(
 select 
      city_name,
      estimated_rent
from city
)
select 
     cr.city_name,
     cr.estimated_rent,
     ct.total_cx,
     ct.avg_sale_pr_cx,
     round(
           cr.estimated_rent/ ct.total_cx,2) as avg_rent_per_cx
from city_rent as cr
join city_table as ct
on cr.city_name = ct.city_name
order by 4 desc;

-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		MONTH(sale_date) as month,
		YEAR(sale_date) as YEAR,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY ci.city_name, MONTH(sale_date), YEAR(sale_date)
	ORDER BY ci.city_name, MONTH(sale_date), YEAR(sale_date)
),
growth_ratio
AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)/last_month_sale * 100
		, 2
		) as growth_ratio

FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULL	;

-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)/
					COUNT(DISTINCT s.customer_id)
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY ci.city_name
	ORDER BY SUM(s.total) DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent/
									ct.total_cx
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC;


/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.



