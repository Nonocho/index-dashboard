-- models/staging/bronze/stg_stock_fundamentals.sql
{{
    config(
        materialized='table',
        schema='silver'
    )
}}

/*
    Staging model for stock valuation metrics
    
    Point-in-time snapshot of fundamental data for 794 stocks
    Used for factor-based index construction
*/

WITH source AS (
    SELECT *
    FROM {{ source('bronze', 'raw_stock_valuation_metrics') }}
),

cleaned AS (
    SELECT
        -- Identifiers
        UPPER(TRIM(ticker)) AS ticker,
        short_name AS company_name,
        long_name AS company_long_name,
        
        -- Market data
        CASE 
            WHEN market_cap IS NULL 
                OR TRIM(market_cap) = '' 
                OR LOWER(TRIM(market_cap)) IN ('nan', 'none') THEN NULL
            ELSE CAST(market_cap AS NUMERIC(20, 2))
        END AS market_cap,
        
        -- Valuation ratios
        CASE 
            WHEN trailing_pe IS NULL 
                OR TRIM(trailing_pe) = '' 
                OR LOWER(TRIM(trailing_pe)) IN ('nan', 'none') THEN NULL
            ELSE CAST(trailing_pe AS NUMERIC(10, 2))
        END AS trailing_pe,
        
        CASE 
            WHEN forward_pe IS NULL 
                OR TRIM(forward_pe) = '' 
                OR LOWER(TRIM(forward_pe)) IN ('nan', 'none') THEN NULL
            ELSE CAST(forward_pe AS NUMERIC(10, 2))
        END AS forward_pe,
        
        CASE 
            WHEN price_to_book IS NULL 
                OR TRIM(price_to_book) = '' 
                OR LOWER(TRIM(price_to_book)) IN ('nan', 'none') THEN NULL
            ELSE CAST(price_to_book AS NUMERIC(10, 2))
        END AS price_to_book,
        
        CASE 
            WHEN price_to_sales_trailing_12_months IS NULL 
                OR TRIM(price_to_sales_trailing_12_months) = '' 
                OR LOWER(TRIM(price_to_sales_trailing_12_months)) IN ('nan', 'none') THEN NULL
            ELSE CAST(price_to_sales_trailing_12_months AS NUMERIC(10, 2))
        END AS price_to_sales,
        
        -- Profitability metrics
        CASE 
            WHEN return_on_equity IS NULL 
                OR TRIM(return_on_equity) = '' 
                OR LOWER(TRIM(return_on_equity)) IN ('nan', 'none') THEN NULL
            ELSE CAST(return_on_equity AS NUMERIC(10, 6))
        END AS return_on_equity,
        
        CASE 
            WHEN return_on_assets IS NULL 
                OR TRIM(return_on_assets) = '' 
                OR LOWER(TRIM(return_on_assets)) IN ('nan', 'none') THEN NULL
            ELSE CAST(return_on_assets AS NUMERIC(10, 6))
        END AS return_on_assets,
        
        CASE 
            WHEN profit_margins IS NULL 
                OR TRIM(profit_margins) = '' 
                OR LOWER(TRIM(profit_margins)) IN ('nan', 'none') THEN NULL
            ELSE CAST(profit_margins AS NUMERIC(10, 6))
        END AS profit_margin,
        
        -- Growth metrics
        CASE 
            WHEN revenue_growth IS NULL 
                OR TRIM(revenue_growth) = '' 
                OR LOWER(TRIM(revenue_growth)) IN ('nan', 'none') THEN NULL
            ELSE CAST(revenue_growth AS NUMERIC(10, 6))
        END AS revenue_growth,
        
        CASE 
            WHEN earnings_growth IS NULL 
                OR TRIM(earnings_growth) = '' 
                OR LOWER(TRIM(earnings_growth)) IN ('nan', 'none') THEN NULL
            ELSE CAST(earnings_growth AS NUMERIC(10, 6))
        END AS earnings_growth,
        
        -- Risk metrics
        CASE 
            WHEN beta IS NULL 
                OR TRIM(beta) = '' 
                OR LOWER(TRIM(beta)) IN ('nan', 'none') THEN NULL
            ELSE CAST(beta AS NUMERIC(6, 3))
        END AS beta,
        
        -- Dividend data
        CASE 
            WHEN dividend_yield IS NULL 
                OR TRIM(dividend_yield) = '' 
                OR LOWER(TRIM(dividend_yield)) IN ('nan', 'none') THEN NULL
            ELSE CAST(dividend_yield AS NUMERIC(10, 6))
        END AS dividend_yield,
        
        CASE 
            WHEN dividend_rate IS NULL 
                OR TRIM(dividend_rate) = '' 
                OR LOWER(TRIM(dividend_rate)) IN ('nan', 'none') THEN NULL
            ELSE CAST(dividend_rate AS NUMERIC(10, 2))
        END AS dividend_rate,
        
        -- Price range
        CASE 
            WHEN fifty_two_week_high IS NULL 
                OR TRIM(fifty_two_week_high) = '' 
                OR LOWER(TRIM(fifty_two_week_high)) IN ('nan', 'none') THEN NULL
            ELSE CAST(fifty_two_week_high AS NUMERIC(12, 2))
        END AS fifty_two_week_high,
        
        CASE 
            WHEN fifty_two_week_low IS NULL 
                OR TRIM(fifty_two_week_low) = '' 
                OR LOWER(TRIM(fifty_two_week_low)) IN ('nan', 'none') THEN NULL
            ELSE CAST(fifty_two_week_low AS NUMERIC(12, 2))
        END AS fifty_two_week_low,
        
        CASE 
            WHEN current_price IS NULL 
                OR TRIM(current_price) = '' 
                OR LOWER(TRIM(current_price)) IN ('nan', 'none') THEN NULL
            ELSE CAST(current_price AS NUMERIC(12, 2))
        END AS current_price,
        
        CASE 
            WHEN volume IS NULL 
                OR TRIM(volume) = '' 
                OR LOWER(TRIM(volume)) IN ('nan', 'none') THEN NULL
            ELSE CAST(CAST(volume AS NUMERIC) AS BIGINT)
        END AS volume,
        
        -- Metadata
        CASE 
            WHEN data_fetched_at IS NULL 
                OR TRIM(data_fetched_at) = '' 
                OR LOWER(TRIM(data_fetched_at)) IN ('nan', 'none') THEN NULL
            ELSE data_fetched_at::TIMESTAMP
        END AS data_fetched_at,
        
        loaded_at,
        source_file
        
    FROM source
    WHERE ticker IS NOT NULL 
      AND TRIM(ticker) != ''
)

SELECT * FROM cleaned