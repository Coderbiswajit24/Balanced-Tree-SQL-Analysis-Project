-- =================================================================================================
-- Balanced Tree Clothing CO. Exploratory Data Analysis (EDA) & Checking Data Quality Before Analysis
-- ==================================================================================================
-- Task 1: Printing product_details Table Metadata

-- SQL Code:
SELECT
    c.column_name,
    c.data_type,
    c.is_nullable,
    c.column_default,
    tc.constraint_type
FROM information_schema.columns c
LEFT JOIN information_schema.key_column_usage kcu
    ON c.column_name = kcu.column_name
    AND c.table_name = kcu.table_name
LEFT JOIN information_schema.table_constraints tc
    ON kcu.constraint_name = tc.constraint_name
WHERE c.table_schema = 'balanced_tree'
  AND c.table_name = 'product_details'
ORDER BY c.ordinal_position;

-- Task 2: Printing sales Table Metadata

-- SQL Code:
SELECT
    c.column_name,
    c.data_type,
    c.is_nullable,
    c.column_default,
    tc.constraint_type
FROM information_schema.columns c
LEFT JOIN information_schema.key_column_usage kcu
    ON c.column_name = kcu.column_name
    AND c.table_name = kcu.table_name
LEFT JOIN information_schema.table_constraints tc
    ON kcu.constraint_name = tc.constraint_name
WHERE c.table_schema = 'balanced_tree'
  AND c.table_name = 'sales'
ORDER BY c.ordinal_position;

-- Task 3: Are there any NULLs where they should never exist?

-- SQL Code:
select
     * 
from balanced_tree.sales
where txn_id is null or prod_id is null or price is null or qty is null;

-- Task 4: Do we have zero or negative quantities sold?

-- SQL Code:
select
     *
from balanced_tree.sales 
where qty <= 0 ;

-- Task 5: Are there products sold at zero or negative price?

-- SQL Code:
select
      *
from balanced_tree.sales 
where price <= 0 ;

-- Task 6 : Are there any discount values outside valid range (0–100)?

-- SQL Code:
select
     *
from balanced_tree.sales
where discount < 0 or discount >= 100 ;	

-- Task 7: Are there duplicate rows at transaction–product level?

-- SQL Code:

select
      txn_id,
	  prod_id,
	  count(*) as row_counts
from balanced_tree.sales
group by txn_id , prod_id
having count(*) > 1 ;

-- Task 8: Does the same product have multiple prices?

-- SQL Code:
select
     prod_id,
	 count(distinct price) as price_count
from balanced_tree.sales
group by prod_id
having count(distinct price) > 1 ;

-- Task 9: Extreme quantity outliers (possible data entry errors)

-- SQL Code:

select
      *
from balanced_tree.sales
where qty > (
select
     percentile_disc(0.99) within group(order by qty asc)
from balanced_tree.sales	 
);

-- Task 10: Extreme price outliers (possible data entry errors)

-- SQL Code:

select
     *
from balanced_tree.sales
where price > (
select
     percentile_cont(0.99) within group(order by price asc)
from balanced_tree.sales	 
);

-- Task 11 : Products sold but missing in product_details table.

-- SQL Code:
select
     distinct s.prod_id
from balanced_tree.sales as s
left join balanced_tree.product_details as p on s.prod_id = p.product_id
where p.product_id is null ;

-- Task 12: Are there any nulls value in transaction date column

-- SQL Code:

select
      *
from balanced_tree.sales 
where start_txn_time is null ;

-- Task 13: Are there any transaction which take two different dates or more ?

-- SQL Code:
select
     txn_id,
	 count(distinct start_txn_time) as row_counts
from balanced_tree.sales
group by txn_id
having count(distinct start_txn_time) > 1 ;

-- Task 14: Is there any Duplicate Records in the sales table?

-- SQL Code:

select
      prod_id,
	  qty,
	  price,
	  discount,
	  member,
	  txn_id,
	  start_txn_time,
	  count(*) as row_counts
from balanced_tree.sales
group by prod_id, qty, price, discount, member, txn_id, start_txn_time
having count(*) > 1 ;

-- Task 15: How Many Unique Products are there and display them ?

-- SQL Code:

select
     count(distinct product_id) as total_unique_products
from balanced_tree.product_details;	

select
      product_name
from balanced_tree.product_details;	  
	  

-- Task 16: How Many Unique segemnt are there and display them ?

-- SQL Code:
select
      count(distinct segment_name) as total_unique_segments
from balanced_tree.product_details;

select
     distinct segment_name
from balanced_tree.product_details;	 
      
-- Task 17: How Many Unique Category are there and display them ?
-- SQL Code:
select
      count(distinct category_name) as total_unique_categories
from balanced_tree.product_details;	

select
      distinct category_name
from balanced_tree.product_details;	 

-- Task 18: What is my Transaction Date Range ?

-- SQL Code:
select
     min(cast(start_txn_time as date)) as first_transaction_date,
	 max(cast(start_txn_time as date)) as last_transaction_date
from balanced_tree.sales;	 
	  
	 