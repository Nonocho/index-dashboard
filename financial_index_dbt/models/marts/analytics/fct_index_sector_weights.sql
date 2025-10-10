/*
================================================================================
MODEL: fct_index_sector_weights
LAYER: Gold - Analytics Mart
PURPOSE: Calculate sector allocation and characteristics for each index
================================================================================

BUSINESS LOGIC:
- Aggregate index weights by GICS sector
- Calculate sector-level valuation metrics (weighted averages)
- Count number of companies per sector
- Rank sectors by weight within each index

USE CASES:
- Sector rotation strategy analysis
- Portfolio diversification assessment
- Index comparison (sector tilt analysis)
- Risk management (sector concentration)

TALKING POINTS FOR INTERVIEWS:
✅ "Technology represents ~30% of S&P 500 weight vs 15% in 1990s"
✅ "Used GROUP BY with window functions to rank sectors"
✅ "Calculated sector-level P/E using weighted averages"
✅ "Identified sector concentration risk across indices"
================================================================================
*/

{{ config(
    materialized='table',
    schema='analytics'
) }}

WITH sector_aggregation AS (
    -- Aggregate metrics by sector within each index
    SELECT 
        fc.index_key,
        fc.date_key,
        s.sector,
        
        -- Sector Weight
        SUM(fc.index_weight) AS sector_weight,
        
        -- Number of Companies
        COUNT(DISTINCT s.stock_key) AS company_count,
        
        -- Weighted Average Valuation Metrics
        -- Only include stocks with positive P/E
        SUM(CASE 
            WHEN s.trailing_pe > 0 
            THEN fc.index_weight * s.trailing_pe 
        END) / NULLIF(SUM(CASE 
            WHEN s.trailing_pe > 0 
            THEN fc.index_weight 
        END), 0) AS sector_avg_pe,
        
        -- Weighted average P/B
        SUM(CASE 
            WHEN s.price_to_book > 0 
            THEN fc.index_weight * s.price_to_book 
        END) / NULLIF(SUM(CASE 
            WHEN s.price_to_book > 0 
            THEN fc.index_weight 
        END), 0) AS sector_avg_pb,
        
        -- Weighted average dividend yield
        SUM(fc.index_weight * COALESCE(s.dividend_yield, 0)) AS sector_avg_div_yield,
        
        -- Weighted average ROE
        SUM(CASE 
            WHEN s.return_on_equity IS NOT NULL 
            THEN fc.index_weight * s.return_on_equity 
        END) / NULLIF(SUM(CASE 
            WHEN s.return_on_equity IS NOT NULL 
            THEN fc.index_weight 
        END), 0) AS sector_avg_roe,
        
        -- Weighted average profit margin
        SUM(CASE 
            WHEN s.profit_margin IS NOT NULL 
            THEN fc.index_weight * s.profit_margin 
        END) / NULLIF(SUM(CASE 
            WHEN s.profit_margin IS NOT NULL 
            THEN fc.index_weight 
        END), 0) AS sector_avg_profit_margin,
        
        -- Weighted average beta
        SUM(CASE 
            WHEN s.beta IS NOT NULL 
            THEN fc.index_weight * s.beta 
        END) / NULLIF(SUM(CASE 
            WHEN s.beta IS NOT NULL 
            THEN fc.index_weight 
        END), 0) AS sector_avg_beta,
        
        -- Total market cap in sector
        SUM(fc.index_weight * s.market_cap) AS sector_total_market_cap
        
    FROM {{ ref('fct_index_constituents') }} fc
    JOIN {{ ref('dim_stocks') }} s 
        ON fc.stock_key = s.stock_key
    WHERE s.sector IS NOT NULL  -- Exclude unknown sectors
    GROUP BY 
        fc.index_key,
        fc.date_key,
        s.sector
),

sector_ranked AS (
    -- Rank sectors by weight within each index
    SELECT 
        sa.*,
        
        -- Rank by weight (1 = largest sector)
        ROW_NUMBER() OVER (
            PARTITION BY index_key, date_key 
            ORDER BY sector_weight DESC
        ) AS sector_rank,
        
        -- Cumulative weight
        SUM(sector_weight) OVER (
            PARTITION BY index_key, date_key 
            ORDER BY sector_weight DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_sector_weight
        
    FROM sector_aggregation sa
)

-- Final output with dimension joins
SELECT 
    sr.index_key,
    i.index_name,
    i.index_code,
    sr.date_key,
    d.calendar_date AS sector_allocation_date,
    
    -- Sector Information
    sr.sector_rank,
    sr.sector,
    sr.company_count,
    
    -- Weight Metrics (as percentages)
    ROUND(sr.sector_weight * 100, 2) AS sector_weight_pct,
    ROUND(sr.cumulative_sector_weight * 100, 2) AS cumulative_weight_pct,
    
    -- Valuation Metrics
    ROUND(sr.sector_avg_pe, 2) AS sector_avg_pe,
    ROUND(sr.sector_avg_pb, 2) AS sector_avg_pb,
    ROUND(sr.sector_avg_div_yield, 2) AS sector_avg_div_yield_pct,
    
    -- Quality Metrics (as percentages)
    ROUND(sr.sector_avg_roe * 100, 2) AS sector_avg_roe_pct,
    ROUND(sr.sector_avg_profit_margin * 100, 2) AS sector_avg_profit_margin_pct,
    
    -- Risk Metrics
    ROUND(sr.sector_avg_beta, 3) AS sector_avg_beta,
    
    -- Market Cap (in billions)
    ROUND(sr.sector_total_market_cap / 1000000000, 2) AS sector_market_cap_billions,
    
    -- Audit
    CURRENT_TIMESTAMP AS calculated_at

FROM sector_ranked sr
JOIN {{ ref('dim_indices') }} i 
    ON sr.index_key = i.index_key
JOIN {{ ref('dim_dates') }} d 
    ON sr.date_key = d.date_key
ORDER BY 
    i.index_name,
    sr.sector_rank