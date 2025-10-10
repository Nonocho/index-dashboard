{{
    config(
        materialized='table',
        schema='gold'
    )
}}

WITH base_tickers AS (
    SELECT DISTINCT ticker 
    FROM {{ ref('stg_constituents_current') }} 
    WHERE ticker IS NOT NULL
    UNION
    SELECT DISTINCT ticker 
    FROM {{ ref('stg_constituents_historical') }} 
    WHERE ticker IS NOT NULL
),

current_info AS (
    SELECT DISTINCT ON (ticker) 
        ticker, 
        company_name, 
        sector, 
        industry
    FROM {{ ref('stg_constituents_current') }}
    WHERE ticker IS NOT NULL
    ORDER BY ticker
),

fund_data AS (
    SELECT 
        ticker,
        company_name,           -- From stg_stock_fundamentals (not short_name)
        company_long_name,      -- From stg_stock_fundamentals (not long_name)
        market_cap,
        trailing_pe,
        forward_pe,
        price_to_book,
        price_to_sales,
        beta,
        dividend_yield,
        dividend_rate,
        profit_margin,          -- Note: profit_margin not profit_margins
        return_on_equity,
        return_on_assets,
        revenue_growth,
        earnings_growth,
        fifty_two_week_high,
        fifty_two_week_low,
        current_price,
        volume,
        data_fetched_at
    FROM {{ ref('stg_stock_fundamentals') }}
    WHERE ticker IS NOT NULL
)

SELECT
    ROW_NUMBER() OVER (ORDER BY t.ticker) AS stock_key,
    t.ticker,
    COALESCE(c.company_name, f.company_name, 'Unknown') AS company_name,
    f.company_long_name,
    COALESCE(c.sector, 'Unknown') AS sector,
    COALESCE(c.industry, 'Unknown') AS industry,
    f.market_cap,
    f.trailing_pe,
    f.forward_pe,
    f.price_to_book,
    f.price_to_sales,
    f.beta,
    f.dividend_yield,
    f.dividend_rate,
    f.profit_margin,
    f.return_on_equity,
    f.return_on_assets,
    f.revenue_growth,
    f.earnings_growth,
    f.fifty_two_week_high,
    f.fifty_two_week_low,
    f.current_price,
    f.volume,
    CASE WHEN c.ticker IS NOT NULL THEN TRUE ELSE FALSE END AS is_current_constituent,
    f.data_fetched_at,
    CURRENT_TIMESTAMP AS created_at,
    CURRENT_TIMESTAMP AS updated_at
FROM base_tickers t
LEFT JOIN current_info c ON t.ticker = c.ticker
LEFT JOIN fund_data f ON t.ticker = f.ticker
ORDER BY t.ticker