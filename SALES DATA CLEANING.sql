-- Inspecting Data

select *
from sales_data_sample

-- Checking unique values

select distinct status from sales_data_sample --Nice one to plot

select distinct year_id from sales_data_sample

select distinct PRODUCTLINE from sales_data_sample --Nice one to plot

select distinct COUNTRY from sales_data_sample --Nice one to plot

select distinct DEALSIZE from sales_data_sample --Nice one to plot

select distinct TERRITORY from sales_data_sample --Nice one to plot

select distinct MONTH_ID from sales_data_sample -- The company only operated for half the year
where year_id = 2005


-- ANALYSIS
-- Start by grouping salwes by production

select PRODUCTLINE, SUM(sales) Revenue
from sales_data_sample
group by PRODUCTLINE
order by 2 desc

select YEAR_ID, SUM(sales) Revenue
from sales_data_sample
group by YEAR_ID
order by 2 desc

select DEALSIZE, SUM(sales) Revenue
from sales_data_sample
group by DEALSIZE
order by 2 desc

-- What was the best month for sales in a specific year? How much was earned that month?
-- Change year to see the rest

select MONTH_ID, SUM(sales) Revenue, COUNT(ORDERNUMBER) Frequency
from sales_data_sample
where YEAR_ID = 2004 
group by MONTH_ID
order by 2 desc

-- November seems to be the best month for revenue, what product do they sell in November?

select MONTH_ID, PRODUCTLINE, SUM(sales) Revenue, COUNT(ORDERNUMBER) Frequency
from sales_data_sample
where YEAR_ID = 2003 AND MONTH_ID = 11
group by MONTH_ID, PRODUCTLINE
order by 3 desc

-- Who is our best customer? This could be best answered with RFM

DROP TABLE IF EXISTS #rfm
;with rfm as
(
	select
		CUSTOMERNAME,
		SUM(sales) MonetaryValue,
		AVG(sales) AvgMonetaryValue,
		COUNT(ORDERNUMBER) Frequency,
		MAX(ORDERDATE) last_order_date,
		(select MAX(ORDERDATE) from sales_data_sample) max_order_date,
		DATEDIFF(MAX(ORDERDATE), (select MAX(ORDERDATE) from sales_data_sample)) Recency
	from sales_data_sample
	group by CUSTOMERNAME
),

rfm_calc as
(
	select r. *,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency desc) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue desc) rfm_monetary
	from rfm r
)

select 
	c, *, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) rfm_cell_string
into #rfm
from rfm_calc c

-- How to analyse and categorise your customers. Do customers who spend large amounts shop less frequently? Which customers are we losing and which ones are loyal?


select CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary
case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm

-- What products are sold together?
--select * from sales_data_sample where ORDERNUMBER =  10411

select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from sales_data_sample p
	where ORDERNUMBER in 
		(
			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				from sales_data_sample
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))

		, 1, 1, '') ProductCodes --Converted results to a string

from sales_data_sample s
order by 2 desc





