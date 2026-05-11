--1. GENERAL DATA SUMMARY

--number of orders
select
	count(distinct bo.order_id) as orders_number
from
	blinkit.blinkit_orders bo;

--number of customers
select
	count(distinct bc.customer_id) as number_of_customers
from
	blinkit.blinkit_customers bc;

--data period
select
	min(bo.order_date) as period_start,
	max(bo.order_date) as period_end,
	date_part('day', max(order_date) - min(order_date)) as period_days
from
	blinkit.blinkit_orders bo; 

--total revenue
select
	sum(bo.order_total) as total_revenue
from
	blinkit.blinkit_orders bo;

--AOV
select
	round(avg(bo.order_total)::numeric, 2) as AOV
from
	blinkit.blinkit_orders bo;

--repeat customer rate
select
	round((SUM(case when order_count > 1 then 1 else 0 end) * 1.0
    / COUNT(*)), 2) as repeat_customer_rate
from
	(
	select
		bo.customer_id,
		COUNT(bo.order_id) as order_count
	from
		blinkit.blinkit_orders bo
	group by
		customer_id
) t;


--top-5 product categories
select
	bp.category,
	round(sum(boi.unit_price * boi.quantity)::numeric, 2) as total_revenue,
	count(distinct bo.order_id) as number_of_orders,
	count(distinct bp.product_id) as unique_products,
	round(avg(bp.price)::numeric, 2) as average_price
from
	blinkit.blinkit_products bp
left join blinkit.blinkit_order_items boi
on
	bp.product_id = boi.product_id
join blinkit.blinkit_orders bo on
	boi.order_id = bo.order_id
group by
	bp.category
order by
	total_revenue desc
limit 5;

--top-5 products
select
	bp.product_name,
	bp.price,
	round(sum(boi.unit_price * boi.quantity)::numeric, 0) as total_revenue,
	sum(boi.quantity) as quantity_sold
from
	blinkit.blinkit_products bp
left join blinkit.blinkit_order_items boi
on
	bp.product_id = boi.product_id
join blinkit.blinkit_orders bo on
	boi.order_id = bo.order_id
group by
	product_name,
	bp.price
order by
	total_revenue desc
limit 5;
	
--number of categories, number of products
select
	count(distinct bp.category) as categories_total,
	count(distinct bp.product_id) as products_total
from
	blinkit.blinkit_products bp;

--2. PERFORMANCE OVER TIME

--revenue by years
select
	EXTRACT(YEAR FROM bo.order_date) as sale_year,
	sum(bo.order_total) as total_revenue
from
	blinkit.blinkit_orders bo
GROUP BY sale_year
ORDER BY sale_year;

--revenue by months
select
	TO_CHAR(bo.order_date, 'Mon') || '-' || EXTRACT(YEAR FROM bo.order_date) as sale_month,
	sum(bo.order_total) as total_revenue
from
	blinkit.blinkit_orders bo
GROUP BY sale_month, DATE_TRUNC('month', bo.order_date)
ORDER BY DATE_TRUNC('month', bo.order_date);

--yearly new registrated customers
select
	extract(year from bc.registration_date) as year_reg,
	count(bc.customer_id) as new_clients
from
	blinkit.blinkit_customers bc
group by
	year_reg,
	DATE_TRUNC('year', bc.registration_date)
order by
	DATE_TRUNC('year', bc.registration_date);

--3. ANALYSIS OF MARKETING CAMPAIGNS

--marketing campaign performance
select
	bmp.campaign_name,
	round(sum(bmp.spend)) as total_spend,
	round(sum(bmp.revenue_generated)) as total_revenue,
	round(sum(bmp.revenue_generated - bmp.spend)) as total_profit,
	round(avg(bmp.roas)::numeric, 2) as avg_roas,
	round(sum(bmp.clicks) * 1.0 / sum(bmp.impressions), 3) as ctr,
	round(sum(bmp.conversions) * 1.0 / sum(bmp.clicks), 3) as conversion_rate
from
	blinkit.blinkit_marketing_performance bmp
group by
	bmp.campaign_name
order by
	total_profit desc;

--target_audience_performance
select
	bmp.target_audience,
	round(sum(bmp.spend)) as total_spend,
	round(sum(bmp.revenue_generated)) as total_revenue,
	round(sum(bmp.revenue_generated - bmp.spend)) as total_profit,
	round(avg(bmp.roas)::numeric, 2) as avg_roas,
	round(sum(bmp.clicks) * 1.0 / sum(bmp.impressions), 3) as ctr,
	round(sum(bmp.conversions) * 1.0 / sum(bmp.clicks), 3) as conversion_rate
from
	blinkit.blinkit_marketing_performance bmp
group by
	bmp.target_audience
order by
	total_profit desc;


--4. DELIVERY PERFORMANCE

--number of orders by delivery status
select
	bdp.delivery_status,
	count(bdp.order_id) as number_of_orders,
	round(avg(bdp.distance_km)::numeric, 2) as average_distance
from
	blinkit.blinkit_delivery_performance bdp
group by
	bdp.delivery_status; 

--average difference between promised time and actual time
select
	round(avg(bdp.delivery_time_minutes)::numeric, 1) as avg_delivery_minutes
from
	blinkit.blinkit_delivery_performance bdp;

--min, max, avg delivery time
select
	min(bo.actual_delivery_time - bo.order_date) as shortest_delivery,
	max(bo.actual_delivery_time - bo.order_date) as longest_delivery,
	date_trunc('second', (avg(bo.actual_delivery_time - bo.order_date))) as avg_delivery_time
from
	blinkit.blinkit_orders bo;

--delayed orders
select
	count(case when delivery_status != 'On Time' then 1 end) as delayed_orders,
	count(case when delivery_status != 'On Time' then 1 end) * 1.0
	/ count(*) as delayed_ratio
from
	blinkit.blinkit_delivery_performance;


--5. INVENTORY PERFORMANCE

--damage_rate by products
select
	product_name,
	brand,
	stock_received,
	damaged_stock,
	round(((damaged_stock * 1.0) / stock_received) * 100, 2) as damage_rate
from
	(
	select
		bp.product_name ,
		bp.brand ,
		sum(bi.stock_received) as stock_received,
		sum(bi.damaged_stock) as damaged_stock
	from
		blinkit.blinkit_inventory bi
	left join blinkit.blinkit_products bp on
		bi.product_id = bp.product_id
	group by
		bi.product_id,
		bp.product_name,
		bp.brand 
) t
order by
	damage_rate desc;

--damage rate by date
select
	stock_date,
	stock_received,
	damaged_stock,
	round(((damaged_stock * 1.0) / stock_received) * 100, 2) as damage_rate
from
	(
	select
		bi."date" as stock_date,
		sum(bi.stock_received) as stock_received,
		sum(bi.damaged_stock) as damaged_stock
	from
		blinkit.blinkit_inventory bi
	group by
		bi."date") t
order by
	stock_date;

--general damage rate
select
	stock_received,
	damaged_stock,
	round(((damaged_stock * 1.0) / stock_received) * 100, 2) as damage_rate
from
	(
	select
		sum(bi.stock_received) as stock_received,
		sum(bi.damaged_stock) as damaged_stock
	from
		blinkit.blinkit_inventory bi ) t;
		
--shelf life days by category		
select
	bp.category,
	bp.shelf_life_days,
	count(distinct bp.product_id ) as number_of_products
from
	blinkit.blinkit_products bp
group by
	bp.shelf_life_days,
	bp.category
order by shelf_life_days;

























