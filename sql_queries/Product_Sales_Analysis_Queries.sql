/*
================================================================================
CASE STUDY #7: BALANCED TREE CLOTHING CO.
SQL Solutions Document
================================================================================

Author: BISWAJIT SASMAL
Date: December 2025
Database: PostgreSQL
Schema: balanced_tree

BUSINESS CONTEXT:
Balanced Tree Clothing Company is analyzing their sales performance to generate
financial reports for the merchandising team. This document contains SQL queries
that answer key business questions about sales, transactions, and products.

DATASET OVERVIEW:
- product_details: Product catalog with pricing and category information
- sales: Transaction-level sales data with discounts and member information
- product_hierarchy: Product categorization structure
- product_prices: Product pricing reference table
================================================================================
*/
-- ============================================================================
-- SECTION C: PRODUCT ANALYSIS
-- ============================================================================
-- This section analyzes product performance and category insights

-- ----------------------------------------------------------------------------
-- Question 1: What are the top 3 products by total revenue before discount?
-- ----------------------------------------------------------------------------

--SQL Code:
select
      p.product_name,
	  round(sum(s.qty * s.price )::numeric / 1000 ) as revenue_before_discount_thousand_usd
from balanced_tree.product_details as p
left join balanced_tree.sales as s on p.product_id = s.prod_id
group by p.product_name
order by revenue_before_discount_thousand_usd desc
limit 3 ;

-- Business Value : Shows Which Products drive Most Sales.

-- ----------------------------------------------------------------------------
-- Question 2: What is the total quantity, revenue and discount 
--             for each segment?
-- ----------------------------------------------------------------------------

-- SQL Code:
select
     p.segment_name,
	 sum(s.qty) as total_quantity_sold,
	 round(sum(s.qty * s.price * (1 - s.discount ::numeric / 100)) / 1000 , 2) as net_revenue_thousand_usd,
	 round(sum((s.qty * s.price * s.discount :: numeric )/ 100) / 1000 , 2) as total_discount_thousand_usd
from balanced_tree.product_details as p
left join balanced_tree.sales as s on p.product_id = s.prod_id
group by p.segment_name
order by net_revenue_thousand_usd desc ;

-- Business Value : Shows Which Product Segment Perform Best.

-- ----------------------------------------------------------------------------
-- Question 3: What is the top selling product for each segment?
-- ----------------------------------------------------------------------------

-- SQL Code:

select
      segment_name,
	  product_name as top_selling_product,
	  total_quantity_sold
from (select
		      p.segment_name,
			  p.product_name,
			  sum(s.qty) as total_quantity_sold,
			  dense_rank() over(partition by p.segment_name order by sum(s.qty) desc) as selling_rank
	  from balanced_tree.product_details as p
	  left join balanced_tree.sales as s on p.product_id = s.prod_id
	   group by p.segment_name , p.product_name) as t
where selling_rank = 1 ;	   

-- Business Value : Hepls us to Indentify Star Products Within Each Segment


-- ----------------------------------------------------------------------------
-- Question 4: What is the total quantity, revenue and discount 
--             for each category?
-- ----------------------------------------------------------------------------

-- SQL Code:
select
     p.category_name,
	 sum(s.qty) as total_quantity_sold,
	 round(sum(s.qty * s.price *(1 - s.discount :: numeric / 100 )) / 1000,2) as net_revenue_in_thousand_usd,
	 round(sum((s.qty * s.price * s.discount :: numeric )/ 100) / 1000 , 2) as total_discount_in_thousand_usd
from balanced_tree.product_details as p
left join balanced_tree.sales as s on p.product_id = s.prod_id
group by p.category_name
order by net_revenue_in_thousand_usd desc ;

--Business Value : Help us View High -Level Performance of each category.

-- ----------------------------------------------------------------------------
-- Question 5: What is the top selling product for each category?
-- ----------------------------------------------------------------------------

-- SQL Code:
select
      category_name,
	  product_name as top_selling_product,
	  total_quantity_sold
from (select
		      p.category_name,
			  p.product_name,
			  sum(s.qty) as total_quantity_sold,
			  dense_rank() over(partition by p.category_name order by sum(s.qty) desc) as selling_rank
	  from balanced_tree.product_details as p
	  left join balanced_tree.sales as s on p.product_id = s.prod_id
	  group by p.category_name , p.product_name) as t
where selling_rank = 1 ;

-- Business Value : Identify Star Products in Mens and Womens Lines.

-- ----------------------------------------------------------------------------
-- Question 6: What is the percentage split of revenue by product 
--             for each segment?
-- ----------------------------------------------------------------------------

-- SQL Code:

select
    segment_name,
	product_name,
	round(net_revenue ::numeric / 1000 , 2) as net_revenue_in_thousand_usd,
	round(net_revenue:: numeric * 100 / sum(net_revenue) over(partition by segment_name) , 2) as revenue_pct 
from (select
		     p.segment_name,
			 p.product_name,
			 round(sum(s.qty * s.price * (1 - s.discount::numeric / 100)) , 2) as net_revenue
		from balanced_tree.product_details as p 
		left join balanced_tree.sales as s on p.product_id = s.prod_id
		group by p.segment_name, p.product_name ) as t
order by segment_name asc , net_revenue_in_thousand_usd desc ;

-- Business Value : Help us Indentify Which Products Dominate in terms of revenue in each segment.

-- ----------------------------------------------------------------------------
-- Question 7: What is the percentage split of revenue by segment 
--             for each category?
-- ----------------------------------------------------------------------------

-- SQL Code:
select
    category_name,
	segment_name,
	round(net_revenue:: numeric / 1000) as net_revenue_in_thousand_usd,
	round(net_revenue:: numeric * 100 / sum(net_revenue) over(partition by category_name) , 2) as revenue_pct 
from (select
		     p.category_name,
			 p.segment_name,
			 round(sum(s.qty * s.price * (1 - discount ::numeric / 100)),2) as net_revenue
		from balanced_tree.product_details as p 
		left join balanced_tree.sales as s on p.product_id = s.prod_id
		group by p.category_name, p.segment_name ) as t
order by  category_name asc , segment_name asc , net_revenue_in_thousand_usd desc ;

-- Business Value : Help us to identify which segments dominate in mens and womens sales.

-- ----------------------------------------------------------------------------
-- Question 8: What is the percentage split of total revenue by category?
-- ----------------------------------------------------------------------------

-- SQL Code:

select
     category_name,
	 round(net_revenue ::numeric / 1000) as net_revenue_in_thousand_usd,
	 round(net_revenue :: numeric * 100 / sum(net_revenue) over(),2) as revenue_pct 
from (select
		     category_name,
			 round(sum(s.qty * s.price * (1 - discount :: numeric / 100)),2) as net_revenue
	 from balanced_tree.product_details as p 
	 left join balanced_tree.sales as s on p.product_id = s.prod_id
	 group by category_name) as t
order by net_revenue_in_thousand_usd desc ; 

-- Business Value : Shows us high -level view of revenue split by Gender category
-- ----------------------------------------------------------------------------
-- Question 9: What is the total transaction "penetration" for each product?
-- ----------------------------------------------------------------------------

-- SQL Code:
select
     product_name,
	 round(total_unique_transactions:: numeric * 100 / (select count(distinct txn_id) from balanced_tree.sales) , 2) as penetration_pct 
from (select
		     p.product_name,
			 count(distinct s.txn_id) as total_unique_transactions
		from balanced_tree.product_details as p 
		left join balanced_tree.sales as s on p.product_id = s.prod_id
		group by p.product_name) as t
order by penetration_pct desc ; 

-- Business Value : Which help us to identify which product is frequently occur in each transaction


-- ----------------------------------------------------------------------------
-- Question 10: What is the most common combination of at least 1 quantity 
--              of any 3 products in a single transaction?
-- ----------------------------------------------------------------------------

-- SQL Code:
select
	 p1.product_name || ' | ' || p2.product_name || ' | ' || p3.product_name as product_combo,
	 combination_count
from (select
		     s1.prod_id as first_product,
			 s2.prod_id  as second_product,
			 s3.prod_id as third_product,
			 count(s1.txn_id) as combination_count
	 from balanced_tree.sales as s1
	 join balanced_tree.sales as s2 on s1.txn_id = s2.txn_id  and s1.prod_id < s2.prod_id
	 join balanced_tree.sales as s3 on s2.txn_id = s3.txn_id and s2.prod_id < s3.prod_id
	 group by s1.prod_id, s2.prod_id , s3.prod_id) as t
join balanced_tree.product_details as p1 on t.first_product = p1.product_id
join balanced_tree.product_details as p2 on t.second_product = p2.product_id
join balanced_tree.product_details as p3 on t.third_product = p3.product_id
order by combination_count desc
limit 1 ;

-- Business Value : Indetifies bundling opportunities and natural product affinity
-- ===============================================================================
-- END SQL