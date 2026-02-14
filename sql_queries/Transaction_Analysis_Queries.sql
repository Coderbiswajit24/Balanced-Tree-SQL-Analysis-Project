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
-- SECTION B: TRANSACTION ANALYSIS
-- ============================================================================
-- This section analyzes transaction patterns and customer behavior

-- ----------------------------------------------------------------------------
-- Question 1: How many unique transactions were there?
-- ----------------------------------------------------------------------------

-- SQL Code:
select
      count(distinct txn_id) as total_unique_transactions
from balanced_tree.sales;

-- Business Values : Which Showcase the Key Metric for Business Activity Volume for three months between 1st January 2021 to 30th March 2021 .

-- ----------------------------------------------------------------------------
-- Question 2: What is the average unique products purchased in each transaction?
-- ----------------------------------------------------------------------------

-- SQL Code:
with transaction_products_count as
(
select
      txn_id,
	  count(distinct prod_id) as total_unique_products
from balanced_tree.sales
group by txn_id
)

select
      round(avg(total_unique_products),0) as avg_unique_products
from transaction_products_count;	  

-- Business Value : Which Showcase cross-selling Effectiveness and each transactions Basket Size.
-- ----------------------------------------------------------------------------
-- Question 3: What are the 25th, 50th and 75th percentile values 
--             for the revenue per transaction?
-- ----------------------------------------------------------------------------

-- SQL Code:
with transaction_revenue as 
(
select
      txn_id,
	  round(sum(qty * price *(1 - discount:: numeric / 100)) , 2) as net_revenue
from balanced_tree.sales
group by txn_id
)
select
      round(percentile_cont(0.25) within group (order by net_revenue asc):: numeric , 2) as percentile_25,
	  round(percentile_cont(0.50) within group (order by net_revenue asc) :: numeric , 2) as percentile_50,
	  round(percentile_cont(0.75) within group (order by net_revenue asc) :: numeric , 2) as percentile_75
from transaction_revenue ;	

-- Business Value : Shows Typical , small and large transaction value

-- ----------------------------------------------------------------------------
-- Question 4: What is the average discount value per transaction?
-- ----------------------------------------------------------------------------

-- SQL Code:
with transaction_discount as 
(
select
     txn_id,
	 round(sum( (qty * price * discount ):: numeric / 100  ) , 2) as total_discount_amount
from balanced_tree.sales
group by txn_id
)
select
      round( avg(total_discount_amount) , 2) as avg_discount_in_usd
from transaction_discount;	  

-- Business Value : Shows Typical Discount impact per customer.

-- ----------------------------------------------------------------------------
-- Question 5: What is the percentage split of all transactions 
--             for members vs non-members?
-- ----------------------------------------------------------------------------

-- SQL Code:

with member_transactions as 
(
select
     member , 
	 count(distinct txn_id) as transaction_count
from balanced_tree.sales
group by member
)
select
     (case when member = True then 'Member' else 'Non-Member' end ) as customer_type,
	 transaction_count,
	 round( (transaction_count * 100) :: numeric  / sum(transaction_count) over() , 2) as transaction_pct
from member_transactions;	 
	 
-- Business Value: Its Showcase Membership program adaption and impact on customers.	 
-- 60 % Transactions were Made By Members and 40 % transactions were made by Non-Member Customers.

-- ----------------------------------------------------------------------------
-- Question 6: What is the average revenue for member transactions 
--             and non-member transactions?
-- ----------------------------------------------------------------------------

-- SQL Code:

with transaction_revenue as 
(
select
     member ,
	 count(distinct txn_id) as total_transactions,
	 round( sum(qty * price * (1 - discount :: numeric / 100)),2) as net_revenue
from balanced_tree.sales
group by member
)
select
      (case when member = True then 'Member' else 'Non-Member' end ) as customer_type,
	  total_transactions,
	  round(net_revenue ::numeric / 1000 , 2) as net_revenue_in_thousand_usd,
	  round(net_revenue::numeric / total_transactions , 2) as avg_revenue_in_usd
from transaction_revenue;	

-- Business Value : Shows if members are more likely to spend more money per transaction.

-- ============================================================================
-- TRANSACTION ANALYSIS - COMBINED REPORT
-- ============================================================================

-- Question 1: Total Unique Transactions
SELECT 
    'Total Unique Transactions' AS metric_name,
    COUNT(DISTINCT txn_id) AS metric_value
FROM balanced_tree.sales

UNION ALL

-- Question 2: Average Unique Products Per Transaction
SELECT 
    'Average Unique Products Per Transaction(Busket Size)' AS metric_name,
    ROUND(AVG(total_unique_products), 0) AS metric_value
FROM (
    SELECT 
        txn_id,
        COUNT(DISTINCT prod_id) AS total_unique_products
    FROM balanced_tree.sales
    GROUP BY txn_id
) AS transaction_products

UNION ALL

-- Question 3: 25th Percentile Revenue
SELECT 
    '25th Percentile of Transactional Revenue(in USD)' AS metric_name,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY net_revenue)::NUMERIC, 2) AS metric_value
FROM (
    SELECT 
        txn_id,
        ROUND(SUM(qty * price * (1 - discount::NUMERIC / 100)), 2) AS net_revenue
    FROM balanced_tree.sales
    GROUP BY txn_id
) AS transaction_revenue

UNION ALL

-- Question 3: 50th Percentile Revenue (Median)
SELECT 
    '50th Percentile of Transactional Revenue (in USD)' AS metric_name,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY net_revenue)::NUMERIC, 2) AS metric_value
FROM (
    SELECT 
        txn_id,
        ROUND(SUM(qty * price * (1 - discount::NUMERIC / 100)), 2) AS net_revenue
    FROM balanced_tree.sales
    GROUP BY txn_id
) AS transaction_revenue

UNION ALL

-- Question 3: 75th Percentile Revenue
SELECT 
    '75th Percentile of Transactional Revenue (in USD)' AS metric_name,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY net_revenue)::NUMERIC, 2) AS metric_value
FROM (
    SELECT 
        txn_id,
        ROUND(SUM(qty * price * (1 - discount::NUMERIC / 100)), 2) AS net_revenue
    FROM balanced_tree.sales
    GROUP BY txn_id
) AS transaction_revenue

UNION ALL

-- Question 4: Average Discount Per Transaction
SELECT 
    'Average Discount Per Transaction(in USD)' AS metric_name,
    ROUND(AVG(total_discount_amount), 2) AS metric_value
FROM (
    SELECT 
        txn_id,
        ROUND(SUM((qty * price * discount)::NUMERIC / 100), 2) AS total_discount_amount
    FROM balanced_tree.sales
    GROUP BY txn_id
) AS transaction_discount;


-- ============================================================================
-- MEMBER vs NON-MEMBER ANALYSIS - COMBINED REPORT
-- Transaction split and average revenue comparison in one table
-- ============================================================================

WITH member_stats AS (
    SELECT
        member,
        COUNT(DISTINCT txn_id) AS total_transactions,
        ROUND(SUM(qty * price * (1 - discount::NUMERIC / 100)), 2) AS net_revenue
    FROM balanced_tree.sales
    GROUP BY member
)
SELECT
    CASE WHEN member = TRUE THEN 'Member' ELSE 'Non-Member' END AS customer_type,
    total_transactions,
    ROUND((total_transactions * 100)::NUMERIC / SUM(total_transactions) OVER(), 2) AS transaction_pct,
    ROUND(net_revenue::NUMERIC / 1000, 2) AS net_revenue_in_thousand_usd,
	round(net_revenue::numeric *100 / sum(net_revenue) over() , 2) as revenue_pct,
    ROUND(net_revenue::NUMERIC / total_transactions, 2) AS avg_transactional_revenue_in_usd
FROM member_stats
ORDER BY customer_type DESC;

-- ============================================================================
-- END OF SQL