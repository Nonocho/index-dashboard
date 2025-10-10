/*
================================================================================
MODEL: fct_index_volatility
LAYER: Gold - Performance Mart
PURPOSE: Calculate rolling volatility (standard deviation of returns)
================================================================================

BUSINESS LOGIC:
- Volatility = Standard Deviation of Returns
- Rolling Windows: 30D, 90D, 180D, 252D (1 year)
- Annualized Volatility: STDDEV(daily_returns) * SQRT(252)
- Use log returns for statistical accuracy

USE CASES:
- Risk assessment and VaR calculations
- Portfolio optimization (mean-variance)
- Options pricing (implied vs realized volatility)
- Risk-adjusted performance metrics (Sharpe ratio)

TALKING POINTS FOR INTERVIEWS:
✅ "Calculated annualized volatility using sqrt(252) scaling factor"
✅ "Implemented rolling window functions for time-varying risk"
✅ "Used log returns for statistical accuracy in volatility calculations"
✅ "Tracked multiple windows (30D to 1Y) for different risk horizons"
================================================================================
*/

{{ config(
    materialized='table',
    schema='performance'
) }}

WITH daily_returns AS (
    -- Get daily returns from the returns model
    SELECT 
        price_date,
        index_code,
        daily_return_pct / 100.0 AS daily_return,  -- Convert back to decimal
        daily_log_return
    FROM {{ ref('fct_index_returns') }}
    WHERE daily_return_pct IS NOT NULL  -- Exclude first day with no return
),

rolling_volatility AS (
    -- Calculate rolling volatility for multiple windows
    SELECT 
        dr.price_date,
        dr.index_code,
        dr.daily_return,
        dr.daily_log_return,
        
        -- ==============================================================
        -- ROLLING VOLATILITY (Standard Deviation)
        -- ==============================================================
        
        -- 30-Day Rolling Volatility (annualized)
        STDDEV(dr.daily_log_return) OVER (
            PARTITION BY dr.index_code 
            ORDER BY dr.price_date
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) * SQRT(252) AS volatility_30d,
        
        -- 90-Day Rolling Volatility (annualized)
        STDDEV(dr.daily_log_return) OVER (
            PARTITION BY dr.index_code 
            ORDER BY dr.price_date
            ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
        ) * SQRT(252) AS volatility_90d,
        
        -- 180-Day Rolling Volatility (annualized)
        STDDEV(dr.daily_log_return) OVER (
            PARTITION BY dr.index_code 
            ORDER BY dr.price_date
            ROWS BETWEEN 179 PRECEDING AND CURRENT ROW
        ) * SQRT(252) AS volatility_180d,
        
        -- 252-Day (1 Year) Rolling Volatility (annualized)
        STDDEV(dr.daily_log_return) OVER (
            PARTITION BY dr.index_code 
            ORDER BY dr.price_date
            ROWS BETWEEN 251 PRECEDING AND CURRENT ROW
        ) * SQRT(252) AS volatility_252d,
        
        -- ==============================================================
        -- REALIZED VOLATILITY (for comparison with VIX)
        -- ==============================================================
        
        -- 21-Day Realized Volatility (monthly)
        STDDEV(dr.daily_log_return) OVER (
            PARTITION BY dr.index_code 
            ORDER BY dr.price_date
            ROWS BETWEEN 20 PRECEDING AND CURRENT ROW
        ) * SQRT(252) AS realized_volatility_21d,
        
        -- ==============================================================
        -- VOLATILITY METRICS
        -- ==============================================================
        
        -- Count of days in window (for data quality)
        COUNT(*) OVER (
            PARTITION BY dr.index_code 
            ORDER BY dr.price_date
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS days_in_30d_window,
        
        COUNT(*) OVER (
            PARTITION BY dr.index_code 
            ORDER BY dr.price_date
            ROWS BETWEEN 251 PRECEDING AND CURRENT ROW
        ) AS days_in_252d_window
        
    FROM daily_returns dr
)

-- Final output
SELECT 
    rv.price_date,
    d.date_key,
    rv.index_code,
    i.index_name,
    
    -- Volatility Metrics (as percentages)
    ROUND((rv.volatility_30d * 100)::numeric, 2) AS volatility_30d_pct,
    ROUND((rv.volatility_90d * 100)::numeric, 2) AS volatility_90d_pct,
    ROUND((rv.volatility_180d * 100)::numeric, 2) AS volatility_180d_pct,
    ROUND((rv.volatility_252d * 100)::numeric, 2) AS volatility_252d_pct,
    ROUND((rv.realized_volatility_21d * 100)::numeric, 2) AS realized_volatility_21d_pct,
    
    -- Data Quality
    rv.days_in_30d_window,
    rv.days_in_252d_window,
    
    -- Metadata
    EXTRACT(YEAR FROM rv.price_date) AS year,
    EXTRACT(QUARTER FROM rv.price_date) AS quarter,
    EXTRACT(MONTH FROM rv.price_date) AS month,
    
    -- Audit
    CURRENT_TIMESTAMP AS calculated_at

FROM rolling_volatility rv
LEFT JOIN {{ ref('dim_dates') }} d 
    ON rv.price_date = d.calendar_date
LEFT JOIN {{ ref('dim_indices') }} i 
    ON rv.index_code = i.index_code
WHERE rv.days_in_30d_window >= 30  -- Only return rows with full 30-day window
ORDER BY 
    rv.index_code,
    rv.price_date DESC