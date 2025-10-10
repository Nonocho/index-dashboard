-- ============================================================================
-- Schema Validation Queries
-- ============================================================================
-- Purpose: Verify that the database schema was created correctly
-- Run these queries AFTER executing schema.sql
-- ============================================================================

-- Check if tables exist in each schema
SELECT 
    table_schema,
    COUNT(*) as table_count,
    STRING_AGG(table_name, ', ' ORDER BY table_name) as tables
FROM information_schema.tables
WHERE table_schema IN ('bronze', 'silver', 'gold')
  AND table_type = 'BASE TABLE'
GROUP BY table_schema
ORDER BY table_schema;

-- Expected output:
-- bronze  | 4 | raw_index_constituents_current, raw_index_constituents_historical, raw_index_prices_base100, raw_stock_valuation_metrics
-- silver  | 4 | stg_constituents_current, stg_constituents_historical, stg_index_prices_daily, stg_stock_fundamentals
-- gold    | 7 | dim_dates, dim_indices, dim_sectors, dim_stocks, fct_index_constituents, fct_index_prices, fct_stock_valuations