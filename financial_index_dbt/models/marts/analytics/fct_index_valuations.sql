/*
================================================================================
MODEL: fct_index_valuations
LAYER: Gold - Analytics Mart
PURPOSE: Calculate index-level valuation metrics using proper weighting
================================================================================

BUSINESS LOGIC:
- P/E, P/B, P/S Ratios: Use HARMONIC MEAN (not arithmetic mean!)
  Formula: 1 / SUM(weight / ratio)
  Why? Prevents high P/E stocks from dominating the index metric
  
- Dividend Yield: Use WEIGHTED AVERAGE
  Formula: SUM(weight * dividend_yield)
  Why? Reflects actual portfolio yield
  
- Other Metrics (ROE, ROA, Profit Margin): Use WEIGHTED AVERAGE
  Formula: SUM(weight * metric)

DATA QUALITY RULES:
- Exclude stocks with NULL or negative P/E ratios from P/E calculation
- Exclude stocks with NULL or zero P/B ratios from P/B calculation  
- Exclude stocks with NULL or zero P/S ratios from P/S calculation
- Include all stocks with valid dividend yield (including 0%)

TALKING POINTS FOR INTERVIEWS:
✅ "I implemented harmonic mean for P/E ratios to prevent outlier distortion"
✅ "Proper handling of negative earnings and missing data in valuation metrics"
✅ "Weighted aggregations that respect market cap methodology"
================================================================================
*/

{{ config(
    materialized='table',
    schema='analytics'
) }}

WITH index_constituents AS (
    -- Get current index membership with weights and stock fundamentals
    SELECT 
        fc.index_key,
        fc.stock_key,
        fc.date_key,
        fc.index_weight,
        s.ticker,
        s.company_name,
        s.sector,
        s.market_cap,
        s.trailing_pe,
        s.price_to_book,
        s.price_to_sales,
        s.dividend_yield,
        s.return_on_equity,
        s.return_on_assets,
        s.profit_margin,
        s.revenue_growth,
        s.earnings_growth,
        s.beta
    FROM {{ ref('fct_index_constituents') }} fc
    JOIN {{ ref('dim_stocks') }} s 
        ON fc.stock_key = s.stock_key
    JOIN {{ ref('dim_indices') }} i 
        ON fc.index_key = i.index_key
),

valuation_metrics AS (
    -- Calculate index-level valuation metrics
    SELECT 
        ic.index_key,
        ic.date_key,
        
        -- ==============================================================
        -- VALUATION RATIOS (Harmonic Mean)
        -- ==============================================================
        
        -- P/E Ratio (Harmonic Mean)
        -- Only include positive P/E ratios
        CASE 
            WHEN SUM(CASE WHEN trailing_pe > 0 THEN index_weight / trailing_pe END) > 0
            THEN 1.0 / SUM(CASE WHEN trailing_pe > 0 THEN index_weight / trailing_pe END)
            ELSE NULL
        END AS index_pe_ratio,
        
        -- P/B Ratio (Harmonic Mean)
        -- Only include positive P/B ratios
        CASE 
            WHEN SUM(CASE WHEN price_to_book > 0 THEN index_weight / price_to_book END) > 0
            THEN 1.0 / SUM(CASE WHEN price_to_book > 0 THEN index_weight / price_to_book END)
            ELSE NULL
        END AS index_pb_ratio,
        
        -- P/S Ratio (Harmonic Mean)
        -- Only include positive P/S ratios
        CASE 
            WHEN SUM(CASE WHEN price_to_sales > 0 THEN index_weight / price_to_sales END) > 0
            THEN 1.0 / SUM(CASE WHEN price_to_sales > 0 THEN index_weight / price_to_sales END)
            ELSE NULL
        END AS index_ps_ratio,
        
        -- ==============================================================
        -- INCOME METRICS (Weighted Average)
        -- ==============================================================
        
        -- Dividend Yield (Weighted Average)
        -- Include all stocks, even those with 0% yield
        SUM(index_weight * COALESCE(dividend_yield, 0)) AS index_dividend_yield,
        
        -- Return on Equity (Weighted Average)
        SUM(CASE WHEN return_on_equity IS NOT NULL THEN index_weight * return_on_equity END) / 
            NULLIF(SUM(CASE WHEN return_on_equity IS NOT NULL THEN index_weight END), 0) AS index_roe,
        
        -- Return on Assets (Weighted Average)
        SUM(CASE WHEN return_on_assets IS NOT NULL THEN index_weight * return_on_assets END) / 
            NULLIF(SUM(CASE WHEN return_on_assets IS NOT NULL THEN index_weight END), 0) AS index_roa,
        
        -- Profit Margin (Weighted Average)
        SUM(CASE WHEN profit_margin IS NOT NULL THEN index_weight * profit_margin END) / 
            NULLIF(SUM(CASE WHEN profit_margin IS NOT NULL THEN index_weight END), 0) AS index_profit_margin,
        
        -- ==============================================================
        -- GROWTH METRICS (Weighted Average)
        -- ==============================================================
        
        -- Revenue Growth (Weighted Average)
        SUM(CASE WHEN revenue_growth IS NOT NULL THEN index_weight * revenue_growth END) / 
            NULLIF(SUM(CASE WHEN revenue_growth IS NOT NULL THEN index_weight END), 0) AS index_revenue_growth,
        
        -- Earnings Growth (Weighted Average)
        SUM(CASE WHEN earnings_growth IS NOT NULL THEN index_weight * earnings_growth END) / 
            NULLIF(SUM(CASE WHEN earnings_growth IS NOT NULL THEN index_weight END), 0) AS index_earnings_growth,
        
        -- ==============================================================
        -- RISK METRICS (Weighted Average)
        -- ==============================================================
        
        -- Beta (Weighted Average)
        SUM(CASE WHEN beta IS NOT NULL THEN index_weight * beta END) / 
            NULLIF(SUM(CASE WHEN beta IS NOT NULL THEN index_weight END), 0) AS index_beta,
        
        -- ==============================================================
        -- AGGREGATE STATISTICS
        -- ==============================================================
        
        -- Total Market Cap
        SUM(index_weight * market_cap) AS total_market_cap,
        
        -- Number of constituents with valid metrics
        COUNT(DISTINCT CASE WHEN trailing_pe > 0 THEN stock_key END) AS stocks_with_pe,
        COUNT(DISTINCT CASE WHEN price_to_book > 0 THEN stock_key END) AS stocks_with_pb,
        COUNT(DISTINCT CASE WHEN price_to_sales > 0 THEN stock_key END) AS stocks_with_ps,
        COUNT(DISTINCT CASE WHEN dividend_yield > 0 THEN stock_key END) AS stocks_paying_dividends,
        COUNT(DISTINCT stock_key) AS total_constituents
        
    FROM index_constituents ic
    GROUP BY ic.index_key, ic.date_key
)

-- Final output with dimension joins for readability
SELECT 
    vm.index_key,
    i.index_name,
    i.index_code,
    vm.date_key,
    d.calendar_date AS valuation_date,
    
    -- Valuation Ratios (rounded to 2 decimals)
    ROUND(vm.index_pe_ratio, 2) AS index_pe_ratio,
    ROUND(vm.index_pb_ratio, 2) AS index_pb_ratio,
    ROUND(vm.index_ps_ratio, 2) AS index_ps_ratio,
    
    -- Income Metrics (as percentages)
    ROUND(vm.index_dividend_yield, 2) AS index_dividend_yield_pct,
    ROUND(vm.index_roe * 100, 2) AS index_roe_pct,
    ROUND(vm.index_roa * 100, 2) AS index_roa_pct,
    ROUND(vm.index_profit_margin * 100, 2) AS index_profit_margin_pct,
    
    -- Growth Metrics (as percentages)
    ROUND(vm.index_revenue_growth * 100, 2) AS index_revenue_growth_pct,
    ROUND(vm.index_earnings_growth * 100, 2) AS index_earnings_growth_pct,
    
    -- Risk Metrics
    ROUND(vm.index_beta, 3) AS index_beta,
    
    -- Market Cap (in billions)
    ROUND(vm.total_market_cap / 1000000000, 2) AS total_market_cap_billions,
    
    -- Data Quality Metrics
    vm.stocks_with_pe,
    vm.stocks_with_pb,
    vm.stocks_with_ps,
    vm.stocks_paying_dividends,
    vm.total_constituents,
    
    -- Audit columns
    CURRENT_TIMESTAMP AS calculated_at

FROM valuation_metrics vm
JOIN {{ ref('dim_indices') }} i 
    ON vm.index_key = i.index_key
JOIN {{ ref('dim_dates') }} d 
    ON vm.date_key = d.date_key
ORDER BY i.index_name, d.calendar_date