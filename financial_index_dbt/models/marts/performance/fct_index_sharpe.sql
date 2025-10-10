/*
================================================================================
MODEL: fct_index_sharpe
LAYER: Gold - Performance Mart
PURPOSE: Calculate Sharpe Ratio (risk-adjusted returns)
================================================================================

BUSINESS LOGIC:
- Sharpe Ratio = (Return - Risk_Free_Rate) / Volatility
- Risk-Free Rate: Assume 4% annual (adjustable)
- Use annualized returns and annualized volatility
- Calculate for multiple rolling windows

USE CASES:
- Portfolio performance evaluation
- Manager selection and ranking
- Risk-adjusted return comparison
- Optimization constraints

TALKING POINTS FOR INTERVIEWS:
✅ "Sharpe ratio measures excess return per unit of risk"
✅ "Values >1 indicate good risk-adjusted performance"
✅ "Calculated rolling Sharpe to track changing risk/return profile"
✅ "Used configurable risk-free rate (4% assumption)"
================================================================================
*/

{{ config(
    materialized='table',
    schema='performance'
) }}

WITH returns_and_volatility AS (
    -- Join returns and volatility data
    SELECT 
        r.price_date,
        r.index_code,
        r.annual_return_pct / 100.0 AS annual_return,
        r.monthly_return_annualized_pct / 100.0 AS monthly_return_annualized,
        r.quarterly_return_annualized_pct / 100.0 AS quarterly_return_annualized,
        v.volatility_30d_pct / 100.0 AS volatility_30d,
        v.volatility_90d_pct / 100.0 AS volatility_90d,
        v.volatility_180d_pct / 100.0 AS volatility_180d,
        v.volatility_252d_pct / 100.0 AS volatility_252d
    FROM {{ ref('fct_index_returns') }} r
    JOIN {{ ref('fct_index_volatility') }} v
        ON r.price_date = v.price_date
        AND r.index_code = v.index_code
),

sharpe_calculated AS (
    -- Calculate Sharpe ratios
    SELECT 
        rv.price_date,
        rv.index_code,
        rv.annual_return,
        rv.volatility_252d,
        rv.volatility_180d,
        rv.volatility_90d,
        rv.volatility_30d,
        
        -- Risk-Free Rate (4% assumption - can be adjusted)
        0.04 AS risk_free_rate,
        
        -- ==============================================================
        -- SHARPE RATIOS
        -- ==============================================================
        
        -- 1-Year Sharpe Ratio
        CASE 
            WHEN rv.volatility_252d > 0 
            THEN (rv.annual_return - 0.04) / rv.volatility_252d
            ELSE NULL
        END AS sharpe_ratio_1y,
        
        -- 6-Month Sharpe Ratio (using 180-day volatility)
        CASE 
            WHEN rv.volatility_180d > 0 
            THEN (rv.quarterly_return_annualized - 0.04) / rv.volatility_180d
            ELSE NULL
        END AS sharpe_ratio_6m,
        
        -- 3-Month Sharpe Ratio (using 90-day volatility)
        CASE 
            WHEN rv.volatility_90d > 0 
            THEN (rv.quarterly_return_annualized - 0.04) / rv.volatility_90d
            ELSE NULL
        END AS sharpe_ratio_3m,
        
        -- 1-Month Sharpe Ratio (using 30-day volatility)
        CASE 
            WHEN rv.volatility_30d > 0 
            THEN (rv.monthly_return_annualized - 0.04) / rv.volatility_30d
            ELSE NULL
        END AS sharpe_ratio_1m,
        
        -- ==============================================================
        -- EXCESS RETURN (Return above risk-free rate)
        -- ==============================================================
        
        rv.annual_return - 0.04 AS excess_return_1y,
        rv.monthly_return_annualized - 0.04 AS excess_return_1m_annualized,
        
        -- Store volatility for reference
        rv.volatility_30d AS vol_30d,
        rv.volatility_90d AS vol_90d,
        rv.volatility_180d AS vol_180d,
        rv.volatility_252d AS vol_252d
        
    FROM returns_and_volatility rv
)

-- Final output
SELECT 
    sc.price_date,
    d.date_key,
    sc.index_code,
    i.index_name,
    
    -- Risk-Free Rate
    ROUND(sc.risk_free_rate * 100, 2) AS risk_free_rate_pct,
    
    -- Sharpe Ratios
    ROUND(sc.sharpe_ratio_1y, 3) AS sharpe_ratio_1y,
    ROUND(sc.sharpe_ratio_6m, 3) AS sharpe_ratio_6m,
    ROUND(sc.sharpe_ratio_3m, 3) AS sharpe_ratio_3m,
    ROUND(sc.sharpe_ratio_1m, 3) AS sharpe_ratio_1m,
    
    -- Excess Returns (as percentages)
    ROUND(sc.excess_return_1y * 100, 2) AS excess_return_1y_pct,
    ROUND(sc.excess_return_1m_annualized * 100, 2) AS excess_return_1m_annualized_pct,
    
    -- Returns (as percentages)
    ROUND(sc.annual_return * 100, 2) AS annual_return_pct,
    
    -- Volatility (as percentages)
    ROUND(sc.vol_252d * 100, 2) AS volatility_252d_pct,
    ROUND(sc.vol_180d * 100, 2) AS volatility_180d_pct,
    ROUND(sc.vol_90d * 100, 2) AS volatility_90d_pct,
    ROUND(sc.vol_30d * 100, 2) AS volatility_30d_pct,
    
    -- Metadata
    EXTRACT(YEAR FROM sc.price_date) AS year,
    EXTRACT(QUARTER FROM sc.price_date) AS quarter,
    
    -- Audit
    CURRENT_TIMESTAMP AS calculated_at

FROM sharpe_calculated sc
LEFT JOIN {{ ref('dim_dates') }} d 
    ON sc.price_date = d.calendar_date
LEFT JOIN {{ ref('dim_indices') }} i 
    ON sc.index_code = i.index_code
WHERE sc.sharpe_ratio_1y IS NOT NULL  -- Only rows with valid Sharpe ratio
ORDER BY 
    sc.index_code,
    sc.price_date DESC