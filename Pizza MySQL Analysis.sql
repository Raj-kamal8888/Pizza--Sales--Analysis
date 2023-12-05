use  pizza_data;

select * from pizza_sales;
select * from orders;
select * from pizza;

-- KPI's REQUIREMENT

-- Total Revenue

select round(sum(total_price),0) as Total_Revenue from pizza_sales;

-- Total orders

SELECT COUNT( distinct order_id) AS total_orders FROM orders;

-- Average Order value

select  round(sum(total_price) /count(distinct order_id),2) as  Avg_Order_Value from pizza_sales;

-- Total Pizzas Sold

select sum(quantity) as Total_Pizzas_Sold from pizza_sales;

-- Average Pizzas per order

select round(sum(quantity) / count(distinct order_id),2) as Avg_Pizzas_per_Order from pizza_sales;

-- SECTOR WISE ANALYSIS

-- ------------------------------------------ SALES PERFORMANCE ANALYSIS -----------------------------------------------------


-- What is the average unit price and revenue of pizza across different categories?

select * from pizza_sales;
select * from orders;

select p.pizza_category , round(avg(p.unit_price),2) as avg_unit_price,
round(sum((p.unit_price * ps.quantity)),0) as Total_sales
from pizza p inner join pizza_sales ps on ps.pizza_id = p.pizza_id
group by p.pizza_category 
order by Total_sales desc;

-- What is the average unit price and revenue of pizza across different sizes?

select p.pizza_size,
round(avg(ps.unit_price),2) as Avg_Unit_Price,
round(sum(total_price),0) as Total_Revenue
from pizza p 
inner join pizza_sales ps on ps.pizza_id = p.pizza_id
group by p.pizza_size
order by Total_Revenue desc;


-- What is the average unit price and revenue of most sold 3 pizzas?

select p.pizza_name,
round(avg(ps.unit_price),2) as avg_unit_price,
sum(ps.quantity) as Total_Pizza_Sold
from pizza p 
inner join pizza_sales ps on p.pizza_id = ps.pizza_id
group by p.pizza_name
order by Total_Pizza_Sold desc 
limit 3;

-- What is the average unit price and Total Orders of most Ordered top 3 pizzas

select p.pizza_name,
round(avg(ps.unit_price),2) as avg_unit_price,
count(distinct ps.order_id) as Total_Orders
from pizza p 
inner join pizza_sales ps on p.pizza_id = ps.pizza_id
group by p.pizza_name
order by Total_Orders desc 
limit 3;


-- calculate the percentage contribution of each pizza category to the total revenue 

select pizza_category,
concat(round( (sum(ps.total_price)  / (select sum(total_price) from pizza_sales ) ) * 100,2),'%')
as Revenue_contribution
from  pizza p inner join pizza_sales ps on p.pizza_id = ps.pizza_id
group by pizza_category;

-- ------------------------------------------ SEASONAL ANALYSIS -----------------------------------------------------

-- Which days of the week having the highest number of orders

select Day_Name, count(distinct order_id) as Total_Orders from orders 
group by Day_Name
order by Total_Orders desc
limit 1;

-- Which month has highest Orders?

select Month_Name,count(distinct order_id) as Total_orders from orders
group by Month_Name
order by Total_orders desc
limit 1;


-- which season has highest orders

select 
case 
     when month(order_date) in (12,1,2) then 'Winter'
     when month(order_date) in (9,10,11) then 'Fall'
     when month(order_date) in (6,7,8) then 'Summer'
     when month(order_date) in (3,4,5) then 'Spring'
     end as season,
count(distinct ps.order_id) as Total_Orders
from orders o inner join pizza_sales ps on ps.order_id = o.order_id
group by season;


-- ------------------------------------------ CUSTOMER BEHAVIOR ANALYSIS ---------------------------------------------------


-- Top 5 favourite pizza of customers (most ordered pizza)?

select p.pizza_name ,
count(distinct ps.order_id) as Total_Orders
from pizza p inner join
pizza_sales ps on ps.pizza_id = p.pizza_id
group by p.pizza_name 
order by Total_Orders desc
limit 5;

-- Which pizza size is preferred by cutomers?

select pizza_size,
count(distinct ps.order_id) as Total_Orders
from pizza p inner join pizza_sales ps on ps.pizza_id = p.pizza_id
group by pizza_size
order by Total_Orders desc;

-- which pizza category is preferred by customers?

select pizza_category,
count(distinct ps.order_id) as Total_Orders
from pizza p inner join pizza_sales ps on ps.pizza_id = p.pizza_id
group by pizza_category
order by Total_Orders desc;

-- --------------------------------------------- PIZZA ANALYSIS ---------------------------------------------------

-- pizza with least price
select pizza_name as lowest_priced_pizza, unit_price
from pizza
order by unit_price
limit 1;

-- pizza with highest price
select pizza_name  as highest_priced_pizza, unit_price
from pizza
order by unit_price desc
limit 1;


-- number of pizzas per category

select pizza_category , count(pizza_id) as Total_Pizzas from pizza
group by pizza_category 
order by Total_Pizzas desc;

-- Number of pizzas per pizza_size

select pizza_size,count(pizza_name) as count
from pizza
group by pizza_size
order by count desc;

-- --------------------------------------------- Store Procedures ---------------------------------------------------



-- create store procedure which will take Month number as input and gives the 
-- Total Sales, Total Orders, Most Orderd Pizza , Pizza Size , Pizza Category


delimiter $

create procedure Sales_Analysis_by_Month ( Month_Num int)
begin
select monthname(o.order_date) as Month,
round(sum(ps.total_price) / 1000 ,3) as Total_sales_in_Thousands,
count(distinct o.order_id) as Total_Orders,

	( 
		select p.pizza_name from pizza p inner join 
		pizza_sales ps on ps.pizza_id = p.pizza_id
		inner join orders o on o.order_id = ps.order_id
		where month(order_date) = Month_Num
		group by p.pizza_name
		order by count(distinct ps.order_id) desc
		limit 1

     )  as  Most_Ordered_Pizza ,
     
	 (
		select p.pizza_size from pizza p inner join 
		pizza_sales ps on ps.pizza_id = p.pizza_id
		inner join orders o on o.order_id = ps.order_id
		where month(order_date) = Month_Num
		group by p.pizza_size
		order by count(distinct ps.order_id) desc
		limit 1
	 ) as Most_Orderd_Pizza_size,
     
	(
	select p.pizza_category from pizza p inner join 
	pizza_sales ps on ps.pizza_id = p.pizza_id
	inner join orders o on o.order_id = ps.order_id
	where month(order_date) = Month_Num
	group by p.pizza_category
	order by count(distinct ps.order_id) desc
	limit 1
	) as Most_Orderd_Pizza_Category
from orders o inner join pizza_sales ps on ps.order_item_id = o.order_item_id
where month(o.order_date) = Month_Num
group by monthname(o.order_date);

end $

delimiter ;

call Sales_Analysis_by_Month (7);


-- create store procedure which will take pizza name as input as gives the
-- Avg Unit Price, Total Orders , Total Revenue Ganerate by the pizza
drop procedure Sale_Analysis_By_Pizza

delimiter $
create procedure Sale_Analysis_By_Pizza ( pizzaname varchar(200) )
begin
select pizza_name,
count(distinct ps.order_id) as Total_Orders,
round(sum( ps.total_price )/ 1000,3) as Total_Revenue
from pizza p
inner join pizza_sales ps on ps.pizza_id = p.pizza_id
where pizza_name = pizzaname
group by pizza_name
order by Total_Revenue;
end $
delimiter ;

call Sale_Analysis_By_Pizza ('The Thai Chicken Pizza'); 
