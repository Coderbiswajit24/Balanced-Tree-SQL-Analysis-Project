-- ============================================================================
-- SECTION E: MONTHLY REPORTING SCRIPT
-- ============================================================================
-- Combined script for automated monthly reporting

-- SQL Code: 
-- Create the stored procedure for monthly Reporting
-- ============================================================================
-- STORED PROCEDURE: Monthly Sales Report Generator
-- ============================================================================

CREATE OR REPLACE PROCEDURE balanced_tree.generate_monthly_report(
    p_year INTEGER,
    p_month INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    start_date DATE;
    end_date DATE;
BEGIN
    -- Calculate date range for the given month
    start_date := make_date(p_year, p_month, 1);
    end_date := (start_date + INTERVAL '1 month' - INTERVAL '1 day')::DATE;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'MONTHLY REPORT FOR: % %', 
        to_char(start_date, 'Month'), p_year;
    RAISE NOTICE '========================================';
    
    -- ========================================================================
    -- SECTION 1: EXECUTIVE SUMMARY
    -- ========================================================================
    RAISE NOTICE '';
    RAISE NOTICE '--- EXECUTIVE SUMMARY ---';
    
    -- Create temp table for executive summary
    DROP TABLE IF EXISTS temp_executive_summary;
    CREATE TEMP TABLE temp_executive_summary AS
    SELECT 
        COUNT(DISTINCT s.txn_id) AS total_transactions,
        SUM(s.qty) AS total_units_sold,
        ROUND(SUM(s.qty * s.price)::numeric / 1000, 2) AS gross_revenue_in_thousand_usd,
        ROUND(SUM(s.qty * s.price * s.discount::numeric / 100) / 1000 , 2) AS total_discounts_in_thousand_usd,
        ROUND(SUM(s.qty * s.price * (1 - s.discount::numeric / 100)) / 1000, 2) AS net_revenue_in_thousand_usd
    FROM balanced_tree.sales s
    WHERE s.start_txn_time >= start_date 
    AND s.start_txn_time < (end_date + INTERVAL '1 day');
    
    -- Display results
    RAISE NOTICE 'Results stored in: temp_executive_summary';
    
    
    -- ========================================================================
    -- SECTION 2: TOP 10 PRODUCTS BY REVENUE
    -- ========================================================================
    RAISE NOTICE '';
    RAISE NOTICE '--- TOP 10 PRODUCTS BY REVENUE ---';
    
    DROP TABLE IF EXISTS temp_top_products;
    CREATE TEMP TABLE temp_top_products AS
    SELECT
        product_name,
		units_sold,
		round(gross_revenue:: numeric / 1000 , 2) as gross_revenue_in_thousand_usd,
		round(total_discounts / 1000 , 2) as total_discount_in_thousand_usd,
		round(net_revenue / 1000 , 2) as net_revenue_in_thousand_usd,
        ROUND(net_revenue::numeric * 100 / SUM(net_revenue) OVER(), 2) AS revenue_pct,
		round(total_transactions ::numeric *100 / (select count(distinct txn_id) from balanced_tree.sales where start_txn_time >= start_date and start_txn_time < (end_date + INTERVAL '1 day')),2) as penetration_pct
    FROM (
        SELECT 
            pd.product_name,
			count(distinct s.txn_id) as total_transactions,
            SUM(s.qty) AS units_sold,
            SUM(s.qty * s.price) AS gross_revenue,
            ROUND(SUM(s.qty * s.price * s.discount::numeric / 100), 2) AS total_discounts,
            ROUND(SUM(s.qty * s.price * (1 - s.discount::numeric / 100)), 2) AS net_revenue
        FROM balanced_tree.sales s
        JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
        WHERE s.start_txn_time >= start_date 
            AND s.start_txn_time < (end_date + INTERVAL '1 day')
        GROUP BY pd.product_name
    ) AS t
    ORDER BY revenue_pct DESC
    LIMIT 10;
    
    RAISE NOTICE 'Results stored in: temp_top_products';
    
    
    -- ========================================================================
    -- SECTION 3: CATEGORY PERFORMANCE
    -- ========================================================================
    RAISE NOTICE '';
    RAISE NOTICE '--- CATEGORY PERFORMANCE ---';
    
    DROP TABLE IF EXISTS temp_category_performance;
    CREATE TEMP TABLE temp_category_performance AS
    SELECT
	    category_name,
		total_transactions,
		units_sold,
        round(gross_revenue:: numeric / 1000 , 2) as gross_revenue_in_thousand_usd,
		round(total_discounts / 1000 , 2) as total_discount_in_thousand_usd,
		round(net_revenue / 1000 , 2) as net_revenue_in_thousand_usd,
        ROUND(net_revenue::numeric * 100 / SUM(net_revenue) OVER(), 2) AS revenue_pct
    FROM (
        SELECT 
            pd.category_name,
            COUNT(DISTINCT s.txn_id) AS total_transactions,
            SUM(s.qty) AS units_sold,
            SUM(s.qty * s.price) AS gross_revenue,
            ROUND(SUM(s.qty * s.price * s.discount::numeric / 100), 2) AS total_discounts,
            ROUND(SUM(s.qty * s.price * (1 - s.discount::numeric / 100)), 2) AS net_revenue
        FROM balanced_tree.sales s
        JOIN balanced_tree.product_details pd ON s.prod_id = pd.product_id
        WHERE s.start_txn_time >= start_date 
            AND s.start_txn_time < (end_date + INTERVAL '1 day')
        GROUP BY pd.category_name
    ) AS t
    ORDER BY revenue_pct DESC;
    
    RAISE NOTICE 'Results stored in: temp_category_performance';
    
    
    -- ========================================================================
    -- SECTION 4: MEMBER VS NON-MEMBER ANALYSIS
    -- ========================================================================
    RAISE NOTICE '';
    RAISE NOTICE '--- MEMBER ANALYSIS ---';
    
    DROP TABLE IF EXISTS temp_member_analysis;
    CREATE TEMP TABLE temp_member_analysis AS
    SELECT 
        CASE WHEN t.member THEN 'Member' ELSE 'Non-Member' END AS customer_type,
        total_transactions,
        ROUND((net_revenue::numeric / total_transactions), 2) AS avg_transaction_value_in_usd,
        round(gross_revenue:: numeric / 1000 , 2) as gross_revenue_in_thousand_usd,
		round(total_discounts / 1000 , 2) as total_discount_in_thousand_usd,
        round(net_revenue / 1000 , 2) as net_revenue_in_thousand__usd,
        ROUND(total_transactions::numeric * 100 / SUM(total_transactions) OVER(), 2) AS transaction_pct,
        ROUND(net_revenue::numeric * 100 / SUM(net_revenue) OVER(), 2) AS revenue_pct
    FROM ( 
        SELECT 
            member,
            COUNT(DISTINCT txn_id) AS total_transactions,
            SUM(s.qty * s.price) AS gross_revenue,
            ROUND(SUM(s.qty * s.price * s.discount::numeric / 100), 2) AS total_discounts,
            ROUND(SUM(s.qty * s.price * (1 - s.discount::numeric / 100)), 2) AS net_revenue
        FROM balanced_tree.sales s
        WHERE start_txn_time >= start_date 
            AND start_txn_time < (end_date + INTERVAL '1 day')
        GROUP BY member
    ) AS t
    ORDER BY gross_revenue DESC;
    
    RAISE NOTICE 'Results stored in: temp_member_analysis';
    
    
    -- ========================================================================
    -- COMPLETION MESSAGE
    -- ========================================================================
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'REPORT GENERATION COMPLETE!';
    RAISE NOTICE 'View results with:';
    RAISE NOTICE '  SELECT * FROM temp_executive_summary;';
    RAISE NOTICE '  SELECT * FROM temp_top_products;';
    RAISE NOTICE '  SELECT * FROM temp_category_performance;';
    RAISE NOTICE '  SELECT * FROM temp_member_analysis;';
    RAISE NOTICE '========================================';
    
END;
$$;


-- Generate January 2021 report
CALL balanced_tree.generate_monthly_report(2021, 1);

select * from temp_executive_summary;

select * from  temp_top_products;

select * from temp_category_performance;

select * from temp_member_analysis ;


-- Generate February 2021 report
CALL balanced_tree.generate_monthly_report(2021, 2);

select * from temp_executive_summary;

select * from  temp_top_products;

select * from temp_category_performance;

select * from temp_member_analysis ;

-- Generate March 2021 report
CALL balanced_tree.generate_monthly_report(2021, 3);

select * from temp_executive_summary;

select * from  temp_top_products;

select * from temp_category_performance;

select * from temp_member_analysis ;