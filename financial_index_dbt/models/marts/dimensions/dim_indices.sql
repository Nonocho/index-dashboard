{{
    config(
        materialized='table',
        schema='gold'
    )
}}

WITH index_metadata AS (
    -- Get unique index codes from current constituents
    SELECT DISTINCT
        index_code
    FROM {{ ref('stg_constituents_current') }}
    
    UNION
    
    -- Get unique index codes from historical constituents
    SELECT DISTINCT
        index_code
    FROM {{ ref('stg_constituents_historical') }}
)

SELECT
    ROW_NUMBER() OVER (ORDER BY index_code) AS index_key,
    index_code,
    
    -- Map index codes to proper names
    CASE 
        WHEN index_code = 'GSPC.INDX' THEN 'S&P 500'
        WHEN index_code = 'OEX.INDX' THEN 'S&P 100'
        ELSE index_code
    END AS index_name,
    
    -- Index characteristics
    CASE 
        WHEN index_code = 'GSPC.INDX' THEN 'Large Cap'
        WHEN index_code = 'OEX.INDX' THEN 'Mega Cap'
        ELSE 'Unknown'
    END AS market_cap_category,
    
    CASE 
        WHEN index_code = 'GSPC.INDX' THEN 500
        WHEN index_code = 'OEX.INDX' THEN 100
        ELSE NULL
    END AS target_constituent_count,
    
    CASE 
        WHEN index_code = 'GSPC.INDX' THEN 'Market-cap weighted index of 500 large-cap US stocks'
        WHEN index_code = 'OEX.INDX' THEN 'Market-cap weighted index of 100 mega-cap US stocks'
        ELSE NULL
    END AS description,
    
    'USD' AS base_currency,
    'Market Capitalization' AS weighting_methodology,
    
    CURRENT_TIMESTAMP AS created_at,
    CURRENT_TIMESTAMP AS updated_at
    
FROM index_metadata
ORDER BY index_code