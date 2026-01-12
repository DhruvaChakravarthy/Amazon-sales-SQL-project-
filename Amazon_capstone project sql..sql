


#### SQL CAPSTONE PROJECT ####

use amazon_sales_db;

SET SQL_SAFE_UPDATES = 0;

-- create table & insert data--
CREATE TABLE IF NOT EXISTS sales (
    invoice_id VARCHAR(30) PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(10) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    quantity INT NOT NULL,
    tax_5_percent FLOAT(6, 4) NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    date DATE NOT NULL,
    time TIME NOT NULL,
    payment_method VARCHAR(20) NOT NULL,
    cogs DECIMAL(10, 2) NOT NULL,
    gross_margin_percentage FLOAT(11, 9) NOT NULL,
    gross_income DECIMAL(10, 2) NOT NULL,
    rating FLOAT(2, 1) NOT NULL
);

-- Successfully imported data from csv.
-- verify data loaded successfully
select count(*) as total_records from sales;

-- check for NULL values:
SELECT 
    SUM(invoice_id IS NULL) AS null_invoice_id,
    SUM(branch IS NULL) AS null_branch,
    SUM(city IS NULL) AS null_city,
    SUM(customer_type IS NULL) AS null_customer_type,
    SUM(gender IS NULL) AS null_gender,
    SUM(product_line IS NULL) AS null_product_line,
    SUM(unit_price IS NULL) AS null_unit_price,
    SUM(quantity IS NULL) AS null_quantity,
    SUM(tax_5_percent IS NULL) AS null_tax,
    SUM(total IS NULL) AS null_total,
    SUM(date IS NULL) AS null_date,
    SUM(time IS NULL) AS null_time,
    SUM(payment_method IS NULL) AS null_payment_method,
    SUM(cogs IS NULL) AS null_cogs,
    SUM(gross_margin_percentage IS NULL) AS null_gross_margin,
    SUM(gross_income IS NULL) AS null_gross_income,
    SUM(rating IS NULL) AS null_rating
FROM sales;

# 2.1 add timeofday column
alter table sales add column timeofday varchar(20);

-- populate timeofday based on transactiontime
update sales 
set timeofday = case
when hour(time) >= 6 and hour(time) < 12 then 'Morning'
when hour(time) >=12 and hour(time) <18 then 'Afternoon'
else 'Evening'
end;

-- verifying the update
select distinct timeofday from sales;

# 2.2:Add dayname column.

alter table sales add column dayname varchar(20);

-- populate dayname col woth full day names.
update sales 
set dayname= dayname(date);

-- verifying the update 
select  dayname from sales;

# 2.3: add Monthname column
alter table sales add column monthname varchar(10);

-- populate monthname col with full month names.
update sales 
set monthname= monthname(date);

-- verifying the update
select monthname from sales;

### EXPLORATORY DATA ANALYSIS : Business Questions

-- 1.Count of distinct citites of dataset
select count(distinct city) as distinct_cities from sales;

-- 2.For Each Brand, what is the correspoding city?
select distinct 
branch , city from sales 
order by branch;

-- 3.Count of Distinct Product line in the dataset.
select count(distinct product_line) as distinct_product_line 
from sales;

-- 4.Which payment method occurs most frequently?
select payment_method,
count(*) as frequency from sales
group by payment_method 
order by frequency desc limit 1; 

-- 5.Which product line has Highest sales? (by revenue)
select product_line,
sum(quantity) as total_quantity_sold, sum(total) as total_revenue from sales 
group by product_line
order by total_revenue desc limit 1;

-- 6.How much revenue is generated each  month?
select monthname,
month(date) as month_num,
sum(total) as monthly_revenue from sales
group by monthname, month(date) 
order by monthname, month(date);

-- 7.In which month did the cost of goods sold (COGS) reach its peak?
select monthname, 
month(date) as month_num,
sum(cogs) as total_cogs from sales
group by monthname, month(date)
order by total_cogs desc limit 1;

-- 8.Which Product Line generated the highest revenue?
select product_line,
sum(total) as total_revenue from sales 
group by product_line 
order by total_revenue desc limit 1;

-- 9.In which city was the highest revenue recorded?
select city,
sum(total) as total_revenue from sales 
group by city 
order by total_revenue desc limit 1 ;

-- 10.Which Product Line incurred the highest value added tax (VAT) ?
select product_line,
sum(tax_5_percent) as total_tax from sales 
group by product_line 
order by total_tax desc limit 1;

-- 11.For each product line, indicate "good" if sales are above average,otherwise Bad.
with product_sales as (
    select
        product_line,
        sum(total) as total_sales
    from sales
    group by product_line
),
average_sales as (
    select avg(total_sales) as avg_sales
    from product_sales
)
select
    ps.product_line,
    ps.total_sales,
    case
        when ps.total_sales > (select avg_sales from average_sales) then 'Good'
        else 'Bad'
    end as performance
from product_sales ps
order by ps.total_sales desc;

-- 12.Identify the branch that exceeded the average nof.products sold
with branch_quantities as (
    select 
        branch,
        sum(quantity) as total_quantity
    from sales
    group by branch
),
average_quantity as (
    select  avg(total_quantity) as avg_quantity
    from branch_quantities
)
select  
    bq.branch,
    bq.total_quantity
from branch_quantities bq
where bq.total_quantity > (select  avg_quantity from average_quantity)
order by bq.total_quantity desc;

-- 13.Which Product line is most frequently associated with each gender?
with gender_product_counts as (
select gender, product_line, count(*) as frequency,
row_number() over (partition by gender order by count(*) desc) as rn from sales 
group by gender, product_line)
select gender, product_line,frequency from gender_product_counts 
where rn = 1 
order by gender;

-- 14.Calculate the average rating for each product line 
select product_line,
round(avg(rating),2) as avg_rating,
count(*) as number_of_transactions from sales
group by product_line 
order by avg_rating desc;

-- 15.Count the sales occurences for each time of day on every weekday.
select dayname,timeofday ,count(*) as sales_count from sales 
group by dayname,timeofday
order by 
 field(dayname, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'),
 field(timeofday, 'Morning', 'Afternoon', 'Evening');
 
 -- 16.Identify the customer type contributing the highest revenue.
 select customer_type, sum(total) as total_revenue,
 count(*) as number_of_transactions from sales 
 group by customer_type 
 order by total_revenue desc limit 1;
 
 -- 17.determine the city eith highest VAT percentage.
 select city,
 round((sum(tax_5_percent)/sum(cogs)) *100,2) as vat_percentage from sales
 group by city
 order by vat_percentage desc limit 1;
 
 -- 18.Identify the customer type with highest VAT payments.
 select customer_type, 
 sum(tax_5_percent) as total_vat from sales
 group by customer_type 
 order by total_vat desc limit 1;
 
 -- 19.Count Distinct customer types in the dataset.
 select 
 count(distinct customer_type ) as distinct_customer_type
 from sales;
 
 -- 20.count of distinct payment methods in the dataset.
 select count(distinct payment_method) as distinct_payment_methods 
 from sales;
 
 -- 21.which customer type occurs most frequently?
 select customer_type, count(*) as frequency from sales 
 group by customer_type 
 order by frequency desc limit 1 ;
 
 -- 22.Customer type with highest purchase frequency
 select customer_type, count(*) as purchase_count from sales 
 group by customer_type
 order by purchase_count desc limit 1;
 
 -- 23.Determine the predominant gender among customers
 select gender, count(*) as customer_count,
 round((count(*)/(select count(*) from sales)) * 100,2) as percentage from sales
 group by gender
 order by customer_count desc limit 1;

-- 24.Examine the distribution of genders within each branch.
select branch,gender,count(*) as customer_count from sales 
group by branch,gender
order by branch, gender;

-- 25. Identify the timeofday when customers provide the most ratings.
select timeofday,count(*) as rating_count,
round(avg(rating),2) as avg_rating from sales
group by timeofday
order by rating_count desc;

-- 26.Determine the timeofday wit highest customer ratings for each brand.
 with branch_time_ratings as (
 select branch, timeofday,
 round(avg(rating),2) as avg_rating,
 row_number() over (partition by branch order by avg(rating) desc) as rn from sales 
 group by branch, timeofday)
 select branch,timeofday,avg_rating from branch_time_ratings
 where rn = 1 
 order by branch;
 
 
 -- 27.Identify the dayofweek with highest average ratings.
 select dayname,
 round(avg(rating),2) as avg_rating,
 count(*) as transaction_count from sales 
 group by dayname 
 order by avg_rating desc limit 1;
 
 -- 28.Determine the day of week with highest average ratings for each branch.
 with branch_day_ratings as (
 select branch,
 dayname,
 round(avg(rating),2) as avg_rating,
 row_number() over (partition by branch order by avg(rating) desc) as rn from sales
 group by branch, dayname )
 select branch, dayname, avg_rating from branch_day_ratings
 where rn = 1 
 order by branch;
 

