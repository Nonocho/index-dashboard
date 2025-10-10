/*
================================================================================
MODEL: fct_index_marketcap_breakdown
LAYER: Gold - Analytics Mart
PURPOSE: Classify index constituents by market cap size buckets
================================================================================

BUSINESS LOGIC:
- Mega Cap:  > $200B market cap
- Large Cap: $10B - $200B
- Mid Cap:   $2B - $10B
- Small Cap: < $2B

- Aggregate index weights by market cap bucket
- Calculate average metrics per bucket
- Show index's market cap bias

USE CASES:
- Style analysis (growth vs value, large vs small cap)
- Index construction validation
- Risk assessment (small cap volatility exposure)
- Factor analysis

TALKING POINTS FOR INTERVIEWS:
✅ "S&P 500 is 75% Large/Mega Cap weighted - not truly representative"
✅ "Classified stocks into 4 market cap buckets using CASE statements"
✅ "Mega caps (>$200B) have higher P/E but also higher margins"
✅ "Small caps (<$2B) contribute <1% to index weight despite being 10% of constituents"
================================================================================
*/

{{ config(
    materialized='table',
    schema='analytics'
) }}

WITH marketcap_classification AS (
    -- Classify each stock into market cap bucket
    SELECT 
        fc.index_key,
        fc.date_key,
        fc.stock_key,
        fc.index_weight,
        s.ticker,
        s.company_name,
        s.sector,
        s.market_cap,
        s.trailing_pe,
        s.price_to_book,
        s.dividend_yield,
        s.beta,
        s.return_on_equity,
        s.profit_margin,
        
        -- Market Cap Classification
        CASE 
            WHEN s.market_cap >= 200000000000 THEN 'Mega Cap (>$200B)'
            WHEN s.market_cap >= 10000000000 THEN 'Large Cap ($10B-$200B)'
            WHEN s.market_cap >= 2000000000 THEN 'Mid Cap ($2B-$10B)'
            ELSE 'Small Cap (<$2B)'
        END AS market_cap_category,
        
        -- Numeric rank for ordering (1 = Mega Cap, 4 = Small Cap)
        CASE 
            WHEN s.market_cap >= 200000000000 THEN 1
            WHEN s.market_cap >= 10000000000 THEN 2
            WHEN s.market_cap >= 2000000000 THEN 3
            ELSE 4
        END AS category_rank
        
    FROM {{ ref('fct_index_constituents') }} fc
    JOIN {{ ref('dim_stocks') }} s 
        ON fc.stock_key = s.stock_key
    WHERE s.market_cap IS NOT NULL  -- Exclude stocks without market cap data
),

marketcap_aggregation AS (
    -- Aggregate by market cap bucket
    SELECT 
        mc.index_key,
        mc.date_key,
        mc.market_cap_category,
        mc.category_rank,
        
        -- Bucket Weight
        SUM(mc.index_weight) AS bucket_weight,
        
        -- Number of Companies
        COUNT(DISTINCT mc.stock_key) AS company_count,
        
        -- Weighted Average Metrics
        SUM(CASE 
            WHEN mc.trailing_pe > 0 
            THEN mc.index_weight * mc.trailing_pe 
        END) / NULLIF(SUM(CASE 
            WHEN mc.trailing_pe > 0 
            THEN mc.index_weight 
        END), 0) AS bucket_avg_pe,
        
        SUM(CASE 
            WHEN mc.price_to_book > 0 
            THEN mc.index_weight * mc.price_to_book 
        END) / NULLIF(SUM(CASE 
            WHEN mc.price_to_book > 0 
            THEN mc.index_weight 
        END), 0) AS bucket_avg_pb,
        
        SUM(mc.index_weight * COALESCE(mc.dividend_yield, 0)) AS bucket_avg_div_yield,
        
        SUM(CASE 
            WHEN mc.return_on_equity IS NOT NULL 
            THEN mc.index_weight * mc.return_on_equity 
        END) / NULLIF(SUM(CASE 
            WHEN mc.return_on_equity IS NOT NULL 
            THEN mc.index_weight 
        END), 0) AS bucket_avg_roe,
        
        SUM(CASE 
            WHEN mc.profit_margin IS NOT NULL 
            THEN mc.index_weight * mc.profit_margin 
        END) / NULLIF(SUM(CASE 
            WHEN mc.profit_margin IS NOT NULL 
            THEN mc.index_weight 
        END), 0) AS bucket_avg_profit_margin,
        
        SUM(CASE 
            WHEN mc.beta IS NOT NULL 
            THEN mc.index_weight * mc.beta 
        END) / NULLIF(SUM(CASE 
            WHEN mc.beta IS NOT NULL 
            THEN mc.index_weight 
        END), 0) AS bucket_avg_beta,
        
        -- Total market cap in bucket
        SUM(mc.index_weight * mc.market_cap) AS bucket_total_market_cap,
        
        -- Average market cap per company
        AVG(mc.market_cap) AS bucket_avg_market_cap
        
    FROM marketcap_classification mc
    GROUP BY 
        mc.index_key,
        mc.date_key,
        mc.market_cap_category,
        mc.category_rank
),

marketcap_with_cumulative AS (
    -- Add cumulative weight
    SELECT 
        ma.*,
        
        -- Cumulative weight by bucket size
        SUM(bucket_weight) OVER (
            PARTITION BY index_key, date_key 
            ORDER BY category_rank
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_weight
        
    FROM marketcap_aggregation ma
)

-- Final output
SELECT 
    mc.index_key,
    i.index_name,
    i.index_code,
    mc.date_key,
    d.calendar_date AS marketcap_allocation_date,
    
    -- Market Cap Bucket
    mc.category_rank,
    mc.market_cap_category,
    mc.company_count,
    
    -- Weight Metrics (as percentages)
    ROUND(mc.bucket_weight * 100, 2) AS bucket_weight_pct,
    ROUND(mc.cumulative_weight * 100, 2) AS cumulative_weight_pct,
    
    -- Valuation Metrics
    ROUND(mc.bucket_avg_pe, 2) AS bucket_avg_pe,
    ROUND(mc.bucket_avg_pb, 2) AS bucket_avg_pb,
    ROUND(mc.bucket_avg_div_yield, 2) AS bucket_avg_div_yield_pct,
    
    -- Quality Metrics (as percentages)
    ROUND(mc.bucket_avg_roe * 100, 2) AS bucket_avg_roe_pct,
    ROUND(mc.bucket_avg_profit_margin * 100, 2) AS bucket_avg_profit_margin_pct,
    
    -- Risk Metrics
    ROUND(mc.bucket_avg_beta, 3) AS bucket_avg_beta,
    
    -- Market Cap Statistics (in billions)
    ROUND(mc.bucket_total_market_cap / 1000000000, 2) AS bucket_total_market_cap_billions,
    ROUND(mc.bucket_avg_market_cap / 1000000000, 2) AS bucket_avg_market_cap_billions,
    
    -- Audit
    CURRENT_TIMESTAMP AS calculated_at

FROM marketcap_with_cumulative mc
JOIN {{ ref('dim_indices') }} i 
    ON mc.index_key = i.index_key
JOIN {{ ref('dim_dates') }} d 
    ON mc.date_key = d.date_key
ORDER BY 
    i.index_name,
    mc.category_rank