/*
================================================================================
MODEL: fct_index_returns
LAYER: Gold - Performance Mart
PURPOSE: Calculate daily, weekly, monthly, quarterly, and annual returns
================================================================================

BUSINESS LOGIC:
- Daily Returns: (price_t / price_t-1) - 1
- Weekly Returns: Last 5 trading days
- Monthly Returns: Last ~21 trading days
- Quarterly Returns: Last ~63 trading days
- Annual Returns: Last ~252 trading days
- Log Returns: LN(price_t / price_t-1) for statistical analysis

USE CASES:
- Performance reporting and attribution
- Time-series analysis
- Risk modeling (volatility calculations)
- Backtesting and strategy development

TALKING POINTS FOR INTERVIEWS:
✅ "Calculated returns using LAG window functions for efficient time-series"
✅ "Implemented both simple and log returns for different analytical needs"
✅ "Generated multi-period returns (daily to annual) in single model"
✅ "Handled edge cases like first trading day (no prior price)"
================================================================================
*/

{{ config(
    materialized='table',
    schema='performance'
) }}

WITH price_with_lags AS (
    -- Get current and lagged prices for return calculations
    SELECT 
        price_date,
        index_code,
        close_price,
        
        -- Previous periods' prices using LAG
        LAG(close_price, 1) OVER (PARTITION BY index_code ORDER BY price_date) AS price_1d_ago,
        LAG(close_price, 5) OVER (PARTITION BY index_code ORDER BY price_date) AS price_1w_ago,
        LAG(close_price, 21) OVER (PARTITION BY index_code ORDER BY price_date) AS price_1m_ago,
        LAG(close_price, 63) OVER (PARTITION BY index_code ORDER BY price_date) AS price_3m_ago,
        LAG(close_price, 252) OVER (PARTITION BY index_code ORDER BY price_date) AS price_1y_ago,
        LAG(close_price, 756) OVER (PARTITION BY index_code ORDER BY price_date) AS price_3y_ago,
        LAG(close_price, 1260) OVER (PARTITION BY index_code ORDER BY price_date) AS price_5y_ago,
        
        -- Year-to-date calculation (price at start of year)
        FIRST_VALUE(close_price) OVER (
            PARTITION BY index_code, EXTRACT(YEAR FROM price_date) 
            ORDER BY price_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS price_ytd_start
        
    FROM {{ ref('stg_index_prices_daily') }}
),

returns_calculated AS (
    -- Calculate returns for all periods
    SELECT 
        pwl.price_date,
        pwl.index_code,
        pwl.close_price,
        
        -- ==============================================================
        -- SIMPLE RETURNS (percentage change)
        -- ==============================================================
        
        -- Daily Return
        CASE 
            WHEN pwl.price_1d_ago IS NOT NULL AND pwl.price_1d_ago > 0
            THEN (pwl.close_price / pwl.price_1d_ago) - 1
            ELSE NULL
        END AS daily_return,
        
        -- Weekly Return (5 trading days)
        CASE 
            WHEN pwl.price_1w_ago IS NOT NULL AND pwl.price_1w_ago > 0
            THEN (pwl.close_price / pwl.price_1w_ago) - 1
            ELSE NULL
        END AS weekly_return,
        
        -- Monthly Return (21 trading days)
        CASE 
            WHEN pwl.price_1m_ago IS NOT NULL AND pwl.price_1m_ago > 0
            THEN (pwl.close_price / pwl.price_1m_ago) - 1
            ELSE NULL
        END AS monthly_return,
        
        -- Quarterly Return (63 trading days)
        CASE 
            WHEN pwl.price_3m_ago IS NOT NULL AND pwl.price_3m_ago > 0
            THEN (pwl.close_price / pwl.price_3m_ago) - 1
            ELSE NULL
        END AS quarterly_return,
        
        -- Annual Return (252 trading days)
        CASE 
            WHEN pwl.price_1y_ago IS NOT NULL AND pwl.price_1y_ago > 0
            THEN (pwl.close_price / pwl.price_1y_ago) - 1
            ELSE NULL
        END AS annual_return,
        
        -- 3-Year Return (756 trading days)
        CASE 
            WHEN pwl.price_3y_ago IS NOT NULL AND pwl.price_3y_ago > 0
            THEN (pwl.close_price / pwl.price_3y_ago) - 1
            ELSE NULL
        END AS return_3y_total,
        
        -- 5-Year Return (1260 trading days)
        CASE 
            WHEN pwl.price_5y_ago IS NOT NULL AND pwl.price_5y_ago > 0
            THEN (pwl.close_price / pwl.price_5y_ago) - 1
            ELSE NULL
        END AS return_5y_total,
        
        -- 3-Year Return (756 trading days)
        CASE 
            WHEN pwl.price_3y_ago IS NOT NULL AND pwl.price_3y_ago > 0
            THEN (pwl.close_price / pwl.price_3y_ago) - 1
            ELSE NULL
        END AS return_3y,
        
        -- 5-Year Return (1260 trading days)
        CASE 
            WHEN pwl.price_5y_ago IS NOT NULL AND pwl.price_5y_ago > 0
            THEN (pwl.close_price / pwl.price_5y_ago) - 1
            ELSE NULL
        END AS return_5y,
        
        -- Year-to-Date Return
        CASE 
            WHEN pwl.price_ytd_start IS NOT NULL AND pwl.price_ytd_start > 0
            THEN (pwl.close_price / pwl.price_ytd_start) - 1
            ELSE NULL
        END AS ytd_return,
        
        -- ==============================================================
        -- LOG RETURNS (for statistical analysis)
        -- ==============================================================
        
        -- Daily Log Return
        CASE 
            WHEN pwl.price_1d_ago IS NOT NULL AND pwl.price_1d_ago > 0
            THEN LN(pwl.close_price / pwl.price_1d_ago)
            ELSE NULL
        END AS daily_log_return,
        
        -- ==============================================================
        -- ANNUALIZED RETURNS (for comparison across periods)
        -- ==============================================================
        
        -- Annualized from Monthly (compound to annual)
        CASE 
            WHEN pwl.price_1m_ago IS NOT NULL AND pwl.price_1m_ago > 0
            THEN POWER((pwl.close_price / pwl.price_1m_ago), (252.0 / 21.0)) - 1
            ELSE NULL
        END AS monthly_return_annualized,
        
        -- Annualized from Quarterly
        CASE 
            WHEN pwl.price_3m_ago IS NOT NULL AND pwl.price_3m_ago > 0
            THEN POWER((pwl.close_price / pwl.price_3m_ago), (252.0 / 63.0)) - 1
            ELSE NULL
        END AS quarterly_return_annualized,
        
        -- Annualized from 3-Year
        CASE 
            WHEN pwl.price_3y_ago IS NOT NULL AND pwl.price_3y_ago > 0
            THEN POWER((pwl.close_price / pwl.price_3y_ago), (1.0 / 3.0)) - 1
            ELSE NULL
        END AS return_3y_cagr,
        
        -- Annualized from 5-Year
        CASE 
            WHEN pwl.price_5y_ago IS NOT NULL AND pwl.price_5y_ago > 0
            THEN POWER((pwl.close_price / pwl.price_5y_ago), (1.0 / 5.0)) - 1
            ELSE NULL
        END AS return_5y_cagr,
        
        -- Annualized from 3-Year
        CASE 
            WHEN pwl.price_3y_ago IS NOT NULL AND pwl.price_3y_ago > 0
            THEN POWER((pwl.close_price / pwl.price_3y_ago), (1.0 / 3.0)) - 1
            ELSE NULL
        END AS return_3y_annualized,
        
        -- Annualized from 5-Year
        CASE 
            WHEN pwl.price_5y_ago IS NOT NULL AND pwl.price_5y_ago > 0
            THEN POWER((pwl.close_price / pwl.price_5y_ago), (1.0 / 5.0)) - 1
            ELSE NULL
        END AS return_5y_annualized
        
    FROM price_with_lags pwl
)

-- Final output with index dimension join
SELECT 
    rc.price_date,
    d.date_key,
    rc.index_code,
    i.index_name,
    rc.close_price,
    
    -- Simple Returns (as percentages)
    ROUND(rc.daily_return * 100, 4) AS daily_return_pct,
    ROUND(rc.weekly_return * 100, 4) AS weekly_return_pct,
    ROUND(rc.monthly_return * 100, 4) AS monthly_return_pct,
    ROUND(rc.quarterly_return * 100, 4) AS quarterly_return_pct,
    ROUND(rc.annual_return * 100, 4) AS annual_return_pct,
    ROUND(rc.return_3y_total * 100, 4) AS return_3y_pct,
    ROUND(rc.return_5y_total * 100, 4) AS return_5y_pct,
    ROUND(rc.ytd_return * 100, 4) AS ytd_return_pct,
    
    -- Log Returns (for statistical use)
    ROUND(rc.daily_log_return, 6) AS daily_log_return,
    
    -- Annualized Returns (as percentages)
    ROUND(rc.monthly_return_annualized * 100, 2) AS monthly_return_annualized_pct,
    ROUND(rc.quarterly_return_annualized * 100, 2) AS quarterly_return_annualized_pct,
    ROUND(rc.return_3y_cagr * 100, 2) AS return_3y_annualized_pct,
    ROUND(rc.return_5y_cagr * 100, 2) AS return_5y_annualized_pct,
    
    -- Metadata
    EXTRACT(YEAR FROM rc.price_date) AS year,
    EXTRACT(QUARTER FROM rc.price_date) AS quarter,
    EXTRACT(MONTH FROM rc.price_date) AS month,
    EXTRACT(DOW FROM rc.price_date) AS day_of_week,
    
    -- Audit
    CURRENT_TIMESTAMP AS calculated_at

FROM returns_calculated rc
LEFT JOIN {{ ref('dim_dates') }} d 
    ON rc.price_date = d.calendar_date
LEFT JOIN {{ ref('dim_indices') }} i 
    ON rc.index_code = i.index_code
ORDER BY 
    rc.index_code,
    rc.price_date DESC