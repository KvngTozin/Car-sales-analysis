select * from sales_data_sample$

-- create duplicate table
select *
into sales2
from sales_data_sample$

select * 
from sales2

-- check for duplicates

with dups as
(
select 
	*,
	ROW_NUMBER() over(partition by ordernumber, quantityordered,priceeach, orderlinenumber, sales, orderdate,
	status, qtr_id, month_id, year_id, productline, msrp, productcode,customername, phone, addressline1,
	addressline2, city, state, postalcode, country, territory, contactlastname, contactfirstname, dealsize
	order by ordernumber)
	as row_num
from sales2
)
select *
from dups 
where row_num > 1

-- handle null values
-- see if it can be populated first

select 
	customername,
	addressline2,
	state,
	postalcode,
	country
from sales2

-- since it cannot we replace addressline2 and state  with unknown

update sales2
set ADDRESSLINE2 = coalesce(ADDRESSLINE2, 'unknown') 

update sales2
set STATE = coalesce(STATE, 'unknown')

--cleaning phone column
-- have to know first what country we are dealing with so we can adjust the postal codes on the number
select 
	distinct country
from sales2;

select 
	phone
from sales2;

update sales2
set Phone = REPLACE(REPLACE(REPLACE(REPLACE(Phone, ' ', ''), '(', ''), ')', ''), '.', '')
where Phone is not null;

update sales2
set Phone = 
    CASE 
        WHEN LEFT(Phone,1) = '+' THEN Phone  -- Already has country code
        WHEN Country = 'USA' THEN '+1' + Phone
        WHEN Country = 'Canada' THEN '+1' + Phone
        WHEN Country = 'UK' THEN '+44' + Phone
        WHEN Country = 'France' THEN '+33' + Phone
        WHEN Country = 'Germany' THEN '+49' + Phone
        WHEN Country = 'Italy' THEN '+39' + Phone
        WHEN Country = 'Sweden' THEN '+46' + Phone
        WHEN Country = 'Norway' THEN '+47' + Phone
        WHEN Country = 'Finland' THEN '+358' + Phone
        WHEN Country = 'Switzerland' THEN '+41' + Phone
        WHEN Country = 'Austria' THEN '+43' + Phone
        WHEN Country = 'Belgium' THEN '+32' + Phone
        WHEN Country = 'Philippines' THEN '+63' + Phone
        WHEN Country = 'Japan' THEN '+81' + Phone
        WHEN Country = 'Spain' THEN '+34' + Phone
        WHEN Country = 'Denmark' THEN '+45' + Phone
        WHEN Country = 'Australia' THEN '+61' + Phone
        WHEN Country = 'Ireland' THEN '+353' + Phone
        WHEN Country = 'Singapore' THEN '+65' + Phone
        ELSE Phone  
    END
where Phone is not null;

select * from sales2
-- convert the orderdate column to a proper date

alter table sales2
alter column orderdate date

--use car_sales go

-- find the top 10 customers by sales
select top 10
    customername,
    contactfirstname + ' ' + contactlastname as contactname,
    sum(sales) as total_sales
from sales2
group by customername, contactfirstname, contactlastname
order by total_sales desc;

-- find the sales trend over time
select
    orderdate,
    sum(sales) as total_sales
from sales2
group by ORDERDATE
order by ORDERDATE asc

-- find top 5 products that generates most sales
select top 5
    productline as products,
    sum(sales) as total_sales
from sales2
group by PRODUCTLINE
order by total_sales desc

-- sales by region
select 
    country,
    sum(sales) as total_sales
from sales2
group by country

--kpis
-- total sales
select
    sum(sales) as total_sales
from sales2

-- total orders
select 
    count(distinct ordernumber) as total_orders
from sales2

--total customers
select 
    count(distinct CUSTOMERNAME) as total_customers
from sales2

--preparing query for tableu
--join all query to create 1 
select
    customername,
    productline,
    country,
    contactfirstname + ' ' + contactlastname as contactname,
    year(orderdate) as order_year,
    month(orderdate) as order_month,
    sum(sales) as total_sales,
    sum(quantityordered) as total_quantity,
    ORDERNUMBER
from sales2
group by
    customername,
    CONTACTFIRSTNAME,
    CONTACTLASTNAME,
    productline,
    country,
    year(orderdate),
    month(orderdate),
    ordernumber;
   
