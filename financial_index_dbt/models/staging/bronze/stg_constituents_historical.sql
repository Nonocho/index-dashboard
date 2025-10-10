-- models/staging/bronze/stg_constituents_historical.sql
{{
    config(
        materialized='table',
        schema='silver'
    )
}}

/*
    Staging model for historical index constituents
    
    Contains 68 years of S&P 500 membership changes (1957-2025)
    Critical for survivorship-bias-free backtesting
*/

WITH source AS (
    SELECT *
    FROM {{ source('bronze', 'raw_index_constituents_historical') }}
),

cleaned AS (
    SELECT
        -- Identifiers
        code AS ticker,
        name AS company_name,
        
        -- Index information
        index_code,
        
        -- Membership dates (handle 'nan', 'NaN', empty strings)
        CASE 
            WHEN start_date IS NULL 
                OR TRIM(start_date) = '' 
                OR LOWER(TRIM(start_date)) = 'nan'
                OR LOWER(TRIM(start_date)) = 'none' THEN NULL
            ELSE start_date::DATE
        END AS start_date,
        
        CASE 
            WHEN end_date IS NULL 
                OR TRIM(end_date) = '' 
                OR LOWER(TRIM(end_date)) = 'nan'
                OR LOWER(TRIM(end_date)) = 'none' THEN NULL
            ELSE end_date::DATE
        END AS end_date,
        
        -- Status flags (convert TEXT to BOOLEAN)
        CASE 
            WHEN LOWER(TRIM(is_active_now)) IN ('true', 't', '1', 'yes') THEN TRUE
            WHEN LOWER(TRIM(is_active_now)) IN ('false', 'f', '0', 'no') THEN FALSE
            ELSE FALSE
        END AS is_current_member,
        
        CASE 
            WHEN LOWER(TRIM(is_delisted)) IN ('true', 't', '1', 'yes') THEN TRUE
            WHEN LOWER(TRIM(is_delisted)) IN ('false', 'f', '0', 'no') THEN FALSE
            ELSE FALSE
        END AS is_delisted,
        
        -- Metadata
        loaded_at,
        source_file
        
    FROM source
    WHERE code IS NOT NULL 
      AND TRIM(code) != ''
),

deduplicated AS (
    SELECT DISTINCT ON (ticker, index_code, start_date)
        *
    FROM cleaned
    ORDER BY ticker, index_code, start_date, loaded_at DESC
)

SELECT * FROM deduplicated