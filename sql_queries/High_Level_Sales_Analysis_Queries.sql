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

-- SECTION A: HIGH LEVEL SALES ANALYSIS
-- ============================================================================
-- This section provides overall sales metrics across all products

-- ----------------------------------------------------------------------------
-- Question 1: What was the total quantity sold for all products?
-- ----------------------------------------------------------------------------

-- SQL Code:
select
      sum(qty) as total_quantity_sold
from balanced_tree.sales;	  

-- Business Value : Showcase total Quantity Moved or sold useful for inventory planning.

-- ----------------------------------------------------------------------------
-- Question 2: What is the total generated revenue for all products 
--             before discounts?
-- ----------------------------------------------------------------------------

-- SQL Code:
select
      round(sum(qty * price)::numeric / 1000000 , 2) as total_revenue_before_discount
from balanced_tree.sales;	  

-- Business Value: Which Showcase Gross Revenue (in Millions USD) Before any Discount Impact.

-- ----------------------------------------------------------------------------
-- Question 3: What was the total discount amount for all products?
-- ----------------------------------------------------------------------------

-- SQL Code:
select 
      round(sum((qty * price * discount):: numeric / 100 ) / 1000, 2) as total_discount_amount
from balanced_tree.sales;	

-- Business Value: Which Showcase the cost of discount promotions (in Thousand USD) to the business.

-- Final High Level Sales Analysis Combined Report Query:

-- SQL Code:
select
      'Total Quantity Sold' as Metric_List,
	  sum(qty) as Metric_Value
from balanced_tree.sales
union
select
      'Gross Revenue(Revenue Before Discount in Millions USD)' as Metric_List,
	  round(sum(qty * price)::numeric / 1000000 , 2) AS Metric_Value
from balanced_tree.sales	  
union
select
     'Total Discount (in Thousand USD)' as Metric_List,
	  round(sum((qty * price * discount):: numeric / 100 ) / 1000, 2) as Metric_Value
from balanced_tree.sales
union
select
      'Net Revenue (in Millions USD)' as Metric_List,
	  round(sum(qty * price * (1- discount::numeric / 100)) / 1000000 , 2) as Metric_Value
from balanced_tree.sales;	  

-- ============================================================================
-- END OF SQL  