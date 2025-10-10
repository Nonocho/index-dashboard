-- models/staging/bronze/stg_index_prices_daily.sql
{{
    config(
        materialized='table',
        schema='silver'
    )
}}

/*
    Staging model for daily index prices (base 100)
    
    10 years of daily data for S&P 500 and S&P 100
    Normalized to base 100 for easy comparison
*/

WITH source AS (
    SELECT *
    FROM {{ source('bronze', 'raw_index_prices_base100') }}
),

cleaned AS (
    SELECT
        -- Date (extract just the date part, remove timezone)
        CASE 
            WHEN date IS NULL OR TRIM(date) = '' THEN NULL
            ELSE date::TIMESTAMP::DATE
        END AS price_date,
        
        -- Index identifier
        CASE 
            WHEN UPPER(TRIM(index_name)) = 'S&P 500' THEN 'SP500'
            WHEN UPPER(TRIM(index_name)) = 'S&P 100' THEN 'SP100'
            ELSE UPPER(TRIM(index_name))
        END AS index_code,
        
        -- Prices (convert to NUMERIC)
        CASE 
            WHEN close IS NULL OR TRIM(close) = '' THEN NULL
            ELSE CAST(close AS NUMERIC(12, 2))
        END AS close_price,
        
        CASE 
            WHEN base_100 IS NULL OR TRIM(base_100) = '' THEN NULL
            ELSE CAST(base_100 AS NUMERIC(12, 6))
        END AS base_100_value,
        
        -- Metadata
        loaded_at,
        source_file
        
    FROM source
    WHERE date IS NOT NULL 
      AND TRIM(date) != ''
),

deduplicated AS (
    SELECT DISTINCT ON (price_date, index_code)
        *
    FROM cleaned
    ORDER BY price_date, index_code, loaded_at DESC
)

SELECT * FROM deduplicated