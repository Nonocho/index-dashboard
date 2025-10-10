-- models/staging/bronze/stg_constituents_current.sql
{{
    config(
        materialized='table',
        schema='silver'
    )
}}

/*
    Staging model for current index constituents
    
    Transforms Bronze raw data into Silver with:
    - Proper data types (TEXT -> NUMERIC, DATE)
    - Cleaned and validated data
    - Deduplication
    - Standardized column names
*/

WITH source AS (
    SELECT *
    FROM {{ source('bronze', 'raw_index_constituents_current') }}
),

cleaned AS (
    SELECT
        -- Identifiers
        code AS ticker,
        exchange,
        name AS company_name,
        
        -- Index information
        index_code,
        as_of_date::DATE AS snapshot_date,
        
        -- Classification
        COALESCE(NULLIF(TRIM(sector), ''), 'Unknown') AS sector,
        COALESCE(NULLIF(TRIM(industry), ''), 'Unknown') AS industry,
        
        -- Weight (convert to NUMERIC)
        CASE 
            WHEN weight IS NULL OR TRIM(weight) = '' THEN NULL
            ELSE CAST(weight AS NUMERIC(10, 8))
        END AS index_weight,
        
        -- Metadata
        loaded_at,
        source_file
        
    FROM source
    WHERE code IS NOT NULL 
      AND TRIM(code) != ''
),

deduplicated AS (
    SELECT DISTINCT ON (ticker, index_code)
        *
    FROM cleaned
    ORDER BY ticker, index_code, loaded_at DESC
)

SELECT * FROM deduplicated