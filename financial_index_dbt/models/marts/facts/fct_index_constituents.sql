{{
    config(
        materialized='table',
        schema='gold'
    )
}}

/*
    Fact table: Index Constituents
    
    Captures daily membership of stocks in indices with weights
    Point-in-time accurate for backtesting
    Grain: One row per stock per index per date
*/

WITH current_constituents AS (
    SELECT
        ticker,
        index_code,
        snapshot_date,
        index_weight
    FROM {{ ref('stg_constituents_current') }}
    WHERE ticker IS NOT NULL
      AND index_code IS NOT NULL
      AND snapshot_date IS NOT NULL
)

SELECT
    ROW_NUMBER() OVER (ORDER BY c.index_code, c.ticker, c.snapshot_date) AS constituent_key,
    
    -- Foreign keys to dimensions
    s.stock_key,
    i.index_key,
    d.date_key,
    
    -- Natural keys (for easier querying)
    c.ticker,
    c.index_code,
    c.snapshot_date AS effective_date,
    
    -- Metrics
    c.index_weight,
    
    -- Audit columns
    CURRENT_TIMESTAMP AS created_at,
    CURRENT_TIMESTAMP AS updated_at

FROM current_constituents c
INNER JOIN {{ ref('dim_stocks') }} s 
    ON c.ticker = s.ticker
INNER JOIN {{ ref('dim_indices') }} i 
    ON c.index_code = i.index_code
INNER JOIN {{ ref('dim_dates') }} d 
    ON c.snapshot_date = d.calendar_date

ORDER BY c.index_code, c.ticker, c.snapshot_date