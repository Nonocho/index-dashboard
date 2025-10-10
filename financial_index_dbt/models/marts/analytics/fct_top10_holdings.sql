/*
================================================================================
MODEL: fct_top10_holdings
LAYER: Gold - Analytics Mart
PURPOSE: Identify top 10 weighted holdings per index for portfolio analysis
================================================================================

BUSINESS LOGIC:
- Rank stocks by index weight within each index
- Return top 10 positions per index
- Include key valuation and fundamental metrics
- Calculate concentration risk (cumulative weight of top 10)

USE CASES:
- Portfolio concentration analysis
- Index tracking and replication
- Risk management (single-stock exposure)
- Marketing materials (show index composition)

TALKING POINTS FOR INTERVIEWS:
✅ "Top 10 holdings represent ~35% of S&P 500 (concentration risk!)"
✅ "Used window functions (ROW_NUMBER) to rank by weight"
✅ "Star schema joins across 3 dimensions for complete context"
================================================================================
*/

{{ config(
    materialized='table',
    schema='analytics'
) }}

WITH ranked_holdings AS (
    -- Rank all constituents by weight within each index
    SELECT 
        fc.index_key,
        fc.stock_key,
        fc.date_key,
        fc.index_weight,
        s.ticker,
        s.company_name,
        s.sector,
        s.industry,
        s.market_cap,
        s.trailing_pe,
        s.price_to_book,
        s.dividend_yield,
        s.beta,
        s.return_on_equity,
        s.profit_margin,
        
        -- Rank by weight within each index (1 = highest weight)
        ROW_NUMBER() OVER (
            PARTITION BY fc.index_key 
            ORDER BY fc.index_weight DESC
        ) AS holding_rank
        
    FROM {{ ref('fct_index_constituents') }} fc
    JOIN {{ ref('dim_stocks') }} s 
        ON fc.stock_key = s.stock_key
),

top10_with_cumulative AS (
    -- Get top 10 and calculate cumulative weight
    SELECT 
        rh.*,
        
        -- Cumulative weight (running total)
        SUM(index_weight) OVER (
            PARTITION BY index_key 
            ORDER BY holding_rank
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_weight
        
    FROM ranked_holdings rh
    WHERE holding_rank <= 10
)

-- Final output with dimension joins
SELECT 
    t10.index_key,
    i.index_name,
    i.index_code,
    t10.date_key,
    d.calendar_date AS holdings_date,
    
    -- Holding Information
    t10.holding_rank,
    t10.ticker,
    t10.company_name,
    t10.sector,
    t10.industry,
    
    -- Weight Metrics
    ROUND(t10.index_weight * 100, 2) AS weight_pct,
    ROUND(t10.cumulative_weight * 100, 2) AS cumulative_weight_pct,
    
    -- Valuation Metrics
    ROUND(t10.market_cap / 1000000000, 2) AS market_cap_billions,
    ROUND(t10.trailing_pe, 2) AS pe_ratio,
    ROUND(t10.price_to_book, 2) AS pb_ratio,
    ROUND(t10.dividend_yield, 2) AS dividend_yield_pct,
    
    -- Quality Metrics
    ROUND(t10.beta, 3) AS beta,
    ROUND(t10.return_on_equity * 100, 2) AS roe_pct,
    ROUND(t10.profit_margin * 100, 2) AS profit_margin_pct,
    
    -- Audit
    CURRENT_TIMESTAMP AS calculated_at

FROM top10_with_cumulative t10
JOIN {{ ref('dim_indices') }} i 
    ON t10.index_key = i.index_key
JOIN {{ ref('dim_dates') }} d 
    ON t10.date_key = d.date_key
ORDER BY 
    i.index_name,
    t10.holding_rank