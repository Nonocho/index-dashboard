/*
================================================================================
MODEL: fct_index_drawdown
LAYER: Gold - Performance Mart
PURPOSE: Calculate drawdown metrics (peak-to-trough decline)
================================================================================

BUSINESS LOGIC:
- Running Maximum Price: Highest price seen so far
- Drawdown: (Current_Price - Peak_Price) / Peak_Price
- Maximum Drawdown: Largest peak-to-trough decline in period
- Recovery Time: Days since last peak
- Underwater Period: Time spent below previous peak

USE CASES:
- Risk management (worst-case scenarios)
- Investor psychology (pain threshold)
- Strategy evaluation (downside risk)
- Stress testing and scenario analysis

TALKING POINTS FOR INTERVIEWS:
✅ "Max drawdown measures worst peak-to-trough decline"
✅ "2008 financial crisis: S&P 500 drawdown was -56.8%"
✅ "Used running maximum with window functions to track peaks"
✅ "Recovery time shows resilience after market corrections"
================================================================================
*/

{{ config(
    materialized='table',
    schema='performance'
) }}

WITH price_with_peaks AS (
    -- Calculate running maximum (peak) price
    SELECT 
        price_date,
        index_code,
        close_price,
        
        -- Running maximum price (all-time high up to this date)
        MAX(close_price) OVER (
            PARTITION BY index_code 
            ORDER BY price_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_max_price,
        
        -- Rolling 252-day (1 year) maximum
        MAX(close_price) OVER (
            PARTITION BY index_code 
            ORDER BY price_date
            ROWS BETWEEN 251 PRECEDING AND CURRENT ROW
        ) AS rolling_max_price_252d,
        
        -- Rolling 90-day maximum
        MAX(close_price) OVER (
            PARTITION BY index_code 
            ORDER BY price_date
            ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
        ) AS rolling_max_price_90d
        
    FROM {{ ref('stg_index_prices_daily') }}
),

drawdown_calculated AS (
    -- Calculate drawdown from peaks
    SELECT 
        pwp.*,
        
        -- ==============================================================
        -- DRAWDOWN CALCULATIONS
        -- ==============================================================
        
        -- Current Drawdown from All-Time High
        CASE 
            WHEN pwp.running_max_price > 0
            THEN (pwp.close_price - pwp.running_max_price) / pwp.running_max_price
            ELSE 0
        END AS current_drawdown_from_ath,
        
        -- Drawdown from 1-Year High
        CASE 
            WHEN pwp.rolling_max_price_252d > 0
            THEN (pwp.close_price - pwp.rolling_max_price_252d) / pwp.rolling_max_price_252d
            ELSE 0
        END AS current_drawdown_252d,
        
        -- Drawdown from 90-Day High
        CASE 
            WHEN pwp.rolling_max_price_90d > 0
            THEN (pwp.close_price - pwp.rolling_max_price_90d) / pwp.rolling_max_price_90d
            ELSE 0
        END AS current_drawdown_90d,
        
        -- ==============================================================
        -- PEAK IDENTIFICATION
        -- ==============================================================
        
        -- Is this a new all-time high?
        CASE 
            WHEN pwp.close_price = pwp.running_max_price 
            THEN TRUE 
            ELSE FALSE 
        END AS is_new_ath,
        
        -- Is this a new 1-year high?
        CASE 
            WHEN pwp.close_price = pwp.rolling_max_price_252d 
            THEN TRUE 
            ELSE FALSE 
        END AS is_new_252d_high
        
    FROM price_with_peaks pwp
),

drawdown_with_recovery AS (
    -- Add recovery time metrics
    SELECT 
        dc.*,
        
        -- Days since last all-time high
        -- Use CASE to find last peak date instead of IGNORE NULLS
        price_date - MAX(CASE WHEN is_new_ath THEN price_date END) OVER (
            PARTITION BY index_code 
            ORDER BY price_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS days_since_ath,
        
        -- ==============================================================
        -- ROLLING MAXIMUM DRAWDOWN
        -- ==============================================================
        
        -- Maximum drawdown in last 252 days
        MIN(current_drawdown_from_ath) OVER (
            PARTITION BY index_code 
            ORDER BY price_date
            ROWS BETWEEN 251 PRECEDING AND CURRENT ROW
        ) AS max_drawdown_252d,
        
        -- Maximum drawdown in last 90 days
        MIN(current_drawdown_from_ath) OVER (
            PARTITION BY index_code 
            ORDER BY price_date
            ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
        ) AS max_drawdown_90d,
        
        -- All-time maximum drawdown
        MIN(current_drawdown_from_ath) OVER (
            PARTITION BY index_code 
            ORDER BY price_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS max_drawdown_all_time
        
    FROM drawdown_calculated dc
)

-- Final output
SELECT 
    dwr.price_date,
    d.date_key,
    dwr.index_code,
    i.index_name,
    dwr.close_price,
    
    -- Peak Prices
    ROUND(dwr.running_max_price, 2) AS all_time_high,
    ROUND(dwr.rolling_max_price_252d, 2) AS high_252d,
    ROUND(dwr.rolling_max_price_90d, 2) AS high_90d,
    
    -- Current Drawdown (as percentages)
    ROUND(dwr.current_drawdown_from_ath * 100, 2) AS current_drawdown_from_ath_pct,
    ROUND(dwr.current_drawdown_252d * 100, 2) AS current_drawdown_252d_pct,
    ROUND(dwr.current_drawdown_90d * 100, 2) AS current_drawdown_90d_pct,
    
    -- Maximum Drawdown (as percentages)
    ROUND(dwr.max_drawdown_all_time * 100, 2) AS max_drawdown_all_time_pct,
    ROUND(dwr.max_drawdown_252d * 100, 2) AS max_drawdown_252d_pct,
    ROUND(dwr.max_drawdown_90d * 100, 2) AS max_drawdown_90d_pct,
    
    -- Peak Flags
    dwr.is_new_ath,
    dwr.is_new_252d_high,
    
    -- Recovery Metrics
    dwr.days_since_ath,
    
    -- Distance from Peak (in price terms)
    ROUND(dwr.close_price - dwr.running_max_price, 2) AS distance_from_ath,
    
    -- Metadata
    EXTRACT(YEAR FROM dwr.price_date) AS year,
    EXTRACT(QUARTER FROM dwr.price_date) AS quarter,
    
    -- Audit
    CURRENT_TIMESTAMP AS calculated_at

FROM drawdown_with_recovery dwr
LEFT JOIN {{ ref('dim_dates') }} d 
    ON dwr.price_date = d.calendar_date
LEFT JOIN {{ ref('dim_indices') }} i 
    ON dwr.index_code = i.index_code
ORDER BY 
    dwr.index_code,
    dwr.price_date DESC