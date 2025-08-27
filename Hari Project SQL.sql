--1)Customer Performance Analysis
--Top 5 customers by sales
select * from
(
    select 
          Customer_Id,
          Customer_Name = concat(dc.first_name, ' ', dc.last_name),
          Total_Sales = sum(price),
          Rank_Details = dense_rank() over(order by sum(price) desc)
    from gold.fact_sales fs
    join gold.dim_customers dc on dc.customer_key = fs.customer_key
    join gold.dim_products dp on dp.product_key = fs.product_key
    group by customer_id, concat(dc.first_name, ' ', dc.last_name)
) as sub
where Rank_Details <= 5
order by Rank_Details

--Sales by Male_Customers and category
select * from
       (select 
                [Gender]=c.gender,
                [Category]=p.category,
                TotalSales = sum(s.sales_amount)
         from gold.dim_customers as c
         join gold.fact_sales as s on c.customer_key = s.customer_key
         join gold.dim_products as p on p.product_key = s.product_key
         group by p.category,c.gender) male
where gender = 'male'

--Sales by Female_Customers and category
select * from
       (select 
         [Gender]=c.gender,
         [Category]=p.category,
         TotalSales = sum(s.sales_amount)
         from gold.dim_customers as c
         join gold.fact_sales as s on c.customer_key = s.customer_key
         join gold.dim_products as p on p.product_key = s.product_key
         group by p.category,c.gender) female
where gender = 'female'

--Customers with Only One Time Visitors.
select * from 
(
    select
        s.order_date,
        [Customer Name] = concat(c.first_name, '-', c.last_name),
        [Count of Purchase] = count(c.customer_key)
    from gold.dim_customers as c 
    join gold.fact_sales as s on c.customer_key = s.customer_key
    group by concat(c.first_name, '-', c.last_name),s.order_date
) as counts
where [Count of Purchase] = 1

--Quarterly Customer Visit and Sales Analysis:
select 
    [Total Customers] = count(c.customer_id),
    [Totalsales by Quarter] = sum(s.sales_amount),
    [Quarter part] = DATEPART(quarter, s.order_date)
from gold.fact_sales as s
join gold.dim_customers as c on c.customer_key = s.customer_key
group by DATEPART(quarter, s.order_date)
order by [Total Customers] desc

--Frequency of the customer
select * from (
	select 
			CustomerId = dc.customer_id,
			CustomerName = concat(dc.first_name,' ', dc.last_name),
			OrderYear = year(order_date),
			OrdderQuarter = datepart(quarter ,order_date),
			CountPerQuarter = count(datename(quarter ,order_date)),
			CountPerYear = sum( count(datename(quarter ,order_date))) over(partition by year(order_date) , customer_id),
	    	TotalTimes = sum(count(datename(quarter ,order_date))) over(partition by customer_id)
		from gold.fact_sales fs
		join gold.dim_customers dc
		on fs.customer_key = dc.customer_key
		group by dc.customer_id ,concat(dc.first_name,' ', dc.last_name) ,  year(order_date),datepart(quarter ,order_date)
				
	) sub
where TotalTimes >40

--2)Product Performance Analysis
--View for product performance analysis
Create view PerformanceAnalysis as
select 
     Product_Id,
     [Category]=dp.category,
     [SubCategory]=subcategory,
     [ProductName]=Product_Name,
     [Year] = year(order_date),
     TotalQuantity = sum(quantity),
     TotalSalesByProduct = sum(price),
     TotalSalesBySubcategory = sum(sum(price)) over(partition by subcategory),
     TotalSalesByCategory = sum(sum(price)) over(partition by category)
from gold.fact_sales fs
join gold.dim_customers dc on dc.customer_key = fs.customer_key
join gold.dim_products dp on dp.product_key = fs.product_key
group by Product_Id, Product_Name, category, subcategory, year(order_date)

--Final query for Product Performance Analysis
select * from  PerformanceAnalysis

--Query for Product Performance Analysis by category
select 
     [Category],
      [Year],
      TotalSalesByYear = sum(TotalSalesByCategory),
      Rank_of_category = dense_rank() over(partition by category order by sum(TotalSalesByCategory) desc)
from PerformanceAnalysis
group by category, year
order by category, year;

--Query for Product Performance Analysis by SubCategory
select 
      [SubCategory],
       [Year],
      TotalSalesByYear = sum(TotalSalesBySubcategory),
      Rank_of_category = dense_rank() over(partition by subcategory order by sum( TotalSalesBySubcategory) desc)
from PerformanceAnalysis
group by subcategory, year
order by subcategory, year;

--Query for Product Performance Analysis by SubCategory
select 
      [ProductName],
      [Year],
      TotalSalesByYear = format(sum(TotalSalesByProduct), 'N0'),
      Rank_of_category = dense_rank() over(partition by[ProductName] order by sum(TotalSalesByProduct) desc)
from PerformanceAnalysis
group by [ProductName], year
order by [ProductName], year;

--Top sales by year
select 
    TotalSales = sum(s.sales_amount),
    [Order Year]=year(s.order_date),
    [Rank] = RANK() over (order by sum(s.sales_amount) desc)
from gold.fact_sales as s
group by year(s.order_date)

--Total price of all ways of line
select 
		[ProductLine Category]=p.product_line,
		[Total Quantity] = COUNT(s.quantity), 
		[Total Price] = sum(s.price)
from gold.dim_products as p
join gold.fact_sales as s on s.product_key = p.product_key
group by p.product_line;