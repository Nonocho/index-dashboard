-- ============================================================================
-- Financial Index Analytics Platform - Database Schema
-- ============================================================================
-- Version: 1.0
-- PostgreSQL Version: 15.3+
-- Architecture: Medallion (Bronze → Silver → Gold)
-- 
-- Usage:
--   1. Connect to database: psql -U postgres -d financial_index_db
--   2. Run this file: \i path/to/schema.sql
--   3. Verify: \dt bronze.* silver.* gold.*
-- ============================================================================

-- ============================================================================
-- BRONZE LAYER - Raw Data (Exact CSV Mirror)
-- ============================================================================

DROP TABLE IF EXISTS bronze.raw_index_constituents_current CASCADE;
DROP TABLE IF EXISTS bronze.raw_index_constituents_historical CASCADE;
DROP TABLE IF EXISTS bronze.raw_index_prices_base100 CASCADE;
DROP TABLE IF EXISTS bronze.raw_stock_valuation_metrics CASCADE;

CREATE TABLE bronze.raw_index_constituents_current (
    id SERIAL PRIMARY KEY,
    code TEXT,
    exchange TEXT,
    name TEXT,
    sector TEXT,
    industry TEXT,
    weight TEXT,
    index_code TEXT,
    as_of_date TEXT,
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_file TEXT
);

CREATE TABLE bronze.raw_index_constituents_historical (
    id SERIAL PRIMARY KEY,
    code TEXT,
    name TEXT,
    start_date TEXT,
    end_date TEXT,
    is_active_now TEXT,
    is_delisted TEXT,
    index_code TEXT,
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_file TEXT
);

CREATE TABLE bronze.raw_index_prices_base100 (
    id SERIAL PRIMARY KEY,
    date TEXT,
    index_name TEXT,
    close TEXT,
    base_100 TEXT,
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_file TEXT
);

CREATE TABLE bronze.raw_stock_valuation_metrics (
    id SERIAL PRIMARY KEY,
    ticker TEXT,
    short_name TEXT,
    long_name TEXT,
    market_cap TEXT,
    trailing_pe TEXT,
    forward_pe TEXT,
    price_to_book TEXT,
    price_to_sales_trailing_12_months TEXT,
    beta TEXT,
    dividend_yield TEXT,
    dividend_rate TEXT,
    profit_margins TEXT,
    return_on_equity TEXT,
    return_on_assets TEXT,
    revenue_growth TEXT,
    earnings_growth TEXT,
    fifty_two_week_high TEXT,
    fifty_two_week_low TEXT,
    current_price TEXT,
    volume TEXT,
    data_fetched_at TEXT,
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_file TEXT
);

CREATE INDEX idx_bronze_constituents_current_code ON bronze.raw_index_constituents_current(code);
CREATE INDEX idx_bronze_constituents_historical_code ON bronze.raw_index_constituents_historical(code);
CREATE INDEX idx_bronze_prices_date ON bronze.raw_index_prices_base100(date);
CREATE INDEX idx_bronze_valuation_ticker ON bronze.raw_stock_valuation_metrics(ticker);

-- ============================================================================
-- SILVER LAYER - Cleaned & Validated Data
-- ============================================================================

DROP TABLE IF EXISTS silver.stg_constituents_current CASCADE;
DROP TABLE IF EXISTS silver.stg_constituents_historical CASCADE;
DROP TABLE IF EXISTS silver.stg_index_prices_daily CASCADE;
DROP TABLE IF EXISTS silver.stg_stock_fundamentals CASCADE;

CREATE TABLE silver.stg_constituents_current (
    id SERIAL PRIMARY KEY,
    ticker VARCHAR(10) NOT NULL,
    exchange VARCHAR(10),
    company_name VARCHAR(255),
    sector VARCHAR(100),
    industry VARCHAR(150),
    index_weight NUMERIC(10, 8),
    index_code VARCHAR(20),
    as_of_date DATE,
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE silver.stg_constituents_historical (
    id SERIAL PRIMARY KEY,
    ticker VARCHAR(10) NOT NULL,
    company_name VARCHAR(255),
    start_date DATE NOT NULL,
    end_date DATE,
    is_active_now BOOLEAN,
    is_delisted BOOLEAN,
    index_code VARCHAR(20),
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE silver.stg_index_prices_daily (
    id SERIAL PRIMARY KEY,
    trade_date DATE NOT NULL,
    index_name VARCHAR(50) NOT NULL,
    close_price NUMERIC(12, 2),
    base_100_value NUMERIC(12, 4),
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(trade_date, index_name)
);

CREATE TABLE silver.stg_stock_fundamentals (
    id SERIAL PRIMARY KEY,
    ticker VARCHAR(10) NOT NULL,
    short_name VARCHAR(255),
    long_name VARCHAR(255),
    market_cap NUMERIC(20, 2),
    trailing_pe NUMERIC(10, 2),
    forward_pe NUMERIC(10, 2),
    price_to_book NUMERIC(10, 2),
    price_to_sales NUMERIC(10, 2),
    beta NUMERIC(6, 3),
    dividend_yield NUMERIC(8, 6),
    dividend_rate NUMERIC(10, 2),
    profit_margins NUMERIC(8, 6),
    return_on_equity NUMERIC(8, 6),
    return_on_assets NUMERIC(8, 6),
    revenue_growth NUMERIC(8, 6),
    earnings_growth NUMERIC(8, 6),
    fifty_two_week_high NUMERIC(12, 2),
    fifty_two_week_low NUMERIC(12, 2),
    current_price NUMERIC(12, 2),
    volume BIGINT,
    data_fetched_at TIMESTAMP,
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_silver_constituents_current_ticker ON silver.stg_constituents_current(ticker);
CREATE INDEX idx_silver_constituents_historical_ticker ON silver.stg_constituents_historical(ticker);
CREATE INDEX idx_silver_constituents_historical_dates ON silver.stg_constituents_historical(start_date, end_date);
CREATE INDEX idx_silver_prices_date ON silver.stg_index_prices_daily(trade_date);
CREATE INDEX idx_silver_prices_index_name ON silver.stg_index_prices_daily(index_name);
CREATE INDEX idx_silver_fundamentals_ticker ON silver.stg_stock_fundamentals(ticker);

-- ============================================================================
-- GOLD LAYER - Analytics-Ready Data (Star Schema)
-- ============================================================================

DROP TABLE IF EXISTS gold.fct_stock_valuations CASCADE;
DROP TABLE IF EXISTS gold.fct_index_prices CASCADE;
DROP TABLE IF EXISTS gold.fct_index_constituents CASCADE;
DROP TABLE IF EXISTS gold.dim_dates CASCADE;
DROP TABLE IF EXISTS gold.dim_indices CASCADE;
DROP TABLE IF EXISTS gold.dim_sectors CASCADE;
DROP TABLE IF EXISTS gold.dim_stocks CASCADE;

CREATE TABLE gold.dim_stocks (
    stock_key SERIAL PRIMARY KEY,
    ticker VARCHAR(10) UNIQUE NOT NULL,
    company_name VARCHAR(255),
    short_name VARCHAR(255),
    sector VARCHAR(100),
    industry VARCHAR(150),
    is_currently_listed BOOLEAN DEFAULT TRUE,
    first_seen_date DATE,
    last_seen_date DATE,
    effective_from DATE,
    effective_to DATE,
    is_current BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE gold.dim_sectors (
    sector_key SERIAL PRIMARY KEY,
    sector_name VARCHAR(100) UNIQUE NOT NULL,
    sector_description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE gold.dim_indices (
    index_key SERIAL PRIMARY KEY,
    index_code VARCHAR(20) UNIQUE NOT NULL,
    index_name VARCHAR(50) NOT NULL,
    index_description TEXT,
    base_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE gold.dim_dates (
    date_key SERIAL PRIMARY KEY,
    full_date DATE UNIQUE NOT NULL,
    year INTEGER,
    quarter INTEGER,
    month INTEGER,
    month_name VARCHAR(20),
    day INTEGER,
    day_of_week INTEGER,
    day_name VARCHAR(20),
    week_of_year INTEGER,
    is_weekend BOOLEAN,
    is_month_end BOOLEAN,
    is_quarter_end BOOLEAN,
    is_year_end BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE gold.fct_index_constituents (
    constituent_key SERIAL PRIMARY KEY,
    stock_key INTEGER REFERENCES gold.dim_stocks(stock_key),
    index_key INTEGER REFERENCES gold.dim_indices(index_key),
    start_date_key INTEGER REFERENCES gold.dim_dates(date_key),
    end_date_key INTEGER REFERENCES gold.dim_dates(date_key),
    index_weight NUMERIC(10, 8),
    is_active BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE gold.fct_index_prices (
    price_key SERIAL PRIMARY KEY,
    date_key INTEGER REFERENCES gold.dim_dates(date_key),
    index_key INTEGER REFERENCES gold.dim_indices(index_key),
    close_price NUMERIC(12, 2),
    base_100_value NUMERIC(12, 4),
    daily_return NUMERIC(10, 6),
    cumulative_return NUMERIC(10, 6),
    volume BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(date_key, index_key)
);

CREATE TABLE gold.fct_stock_valuations (
    valuation_key SERIAL PRIMARY KEY,
    stock_key INTEGER REFERENCES gold.dim_stocks(stock_key),
    date_key INTEGER REFERENCES gold.dim_dates(date_key),
    market_cap NUMERIC(20, 2),
    trailing_pe NUMERIC(10, 2),
    forward_pe NUMERIC(10, 2),
    price_to_book NUMERIC(10, 2),
    price_to_sales NUMERIC(10, 2),
    beta NUMERIC(6, 3),
    dividend_yield NUMERIC(8, 6),
    dividend_rate NUMERIC(10, 2),
    profit_margins NUMERIC(8, 6),
    return_on_equity NUMERIC(8, 6),
    return_on_assets NUMERIC(8, 6),
    revenue_growth NUMERIC(8, 6),
    earnings_growth NUMERIC(8, 6),
    current_price NUMERIC(12, 2),
    volume BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dim_stocks_ticker ON gold.dim_stocks(ticker);
CREATE INDEX idx_dim_stocks_sector ON gold.dim_stocks(sector);
CREATE INDEX idx_dim_dates_full_date ON gold.dim_dates(full_date);
CREATE INDEX idx_dim_dates_year_month ON gold.dim_dates(year, month);
CREATE INDEX idx_fct_constituents_stock ON gold.fct_index_constituents(stock_key);
CREATE INDEX idx_fct_constituents_index ON gold.fct_index_constituents(index_key);
CREATE INDEX idx_fct_constituents_dates ON gold.fct_index_constituents(start_date_key, end_date_key);
CREATE INDEX idx_fct_prices_date ON gold.fct_index_prices(date_key);
CREATE INDEX idx_fct_prices_index ON gold.fct_index_prices(index_key);
CREATE INDEX idx_fct_valuations_stock ON gold.fct_stock_valuations(stock_key);
CREATE INDEX idx_fct_valuations_date ON gold.fct_stock_valuations(date_key);

COMMENT ON SCHEMA bronze IS 'Raw data layer - exact mirror of source files';
COMMENT ON SCHEMA silver IS 'Cleaned data layer - validated and typed';
COMMENT ON SCHEMA gold IS 'Analytics layer - star schema for dashboards';

-- ============================================================================
-- Schema creation complete!
-- ============================================================================