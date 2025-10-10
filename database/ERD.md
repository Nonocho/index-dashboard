Entity-Relationship Diagram (ERD)
Financial Index Analytics Platform - Database Schema
🎯 Schema Overview
mermaid
graph LR
    A[Bronze Layer<br/>Raw Data] --> B[Silver Layer<br/>Cleaned Data]
    B --> C[Gold Layer<br/>Analytics Ready]
    C --> D[Streamlit<br/>Dashboard]
📊 Gold Layer - Star Schema (Main Analytics Layer)
mermaid
erDiagram
    dim_dates ||--o{ fct_index_prices : "date_key"
    dim_dates ||--o{ fct_stock_valuations : "date_key"
    dim_dates ||--o{ fct_index_constituents : "start_date_key"
    dim_dates ||--o{ fct_index_constituents : "end_date_key"
    
    dim_stocks ||--o{ fct_index_constituents : "stock_key"
    dim_stocks ||--o{ fct_stock_valuations : "stock_key"
    
    dim_indices ||--o{ fct_index_constituents : "index_key"
    dim_indices ||--o{ fct_index_prices : "index_key"
    
    dim_sectors ||--o{ dim_stocks : "sector"

    dim_dates {
        int date_key PK
        date full_date UK
        int year
        int quarter
        int month
        varchar month_name
        int day
        int day_of_week
        varchar day_name
        int week_of_year
        boolean is_weekend
        boolean is_month_end
        boolean is_quarter_end
        boolean is_year_end
    }

    dim_stocks {
        int stock_key PK
        varchar ticker UK
        varchar company_name
        varchar short_name
        varchar sector FK
        varchar industry
        boolean is_currently_listed
        date first_seen_date
        date last_seen_date
        date effective_from
        date effective_to
        boolean is_current
    }

    dim_indices {
        int index_key PK
        varchar index_code UK
        varchar index_name
        text index_description
        date base_date
    }

    dim_sectors {
        int sector_key PK
        varchar sector_name UK
        text sector_description
    }

    fct_index_constituents {
        int constituent_key PK
        int stock_key FK
        int index_key FK
        int start_date_key FK
        int end_date_key FK
        numeric index_weight
        boolean is_active
    }

    fct_index_prices {
        int price_key PK
        int date_key FK
        int index_key FK
        numeric close_price
        numeric base_100_value
        numeric daily_return
        numeric cumulative_return
        bigint volume
    }

    fct_stock_valuations {
        int valuation_key PK
        int stock_key FK
        int date_key FK
        numeric market_cap
        numeric trailing_pe
        numeric forward_pe
        numeric price_to_book
        numeric price_to_sales
        numeric beta
        numeric dividend_yield
        numeric dividend_rate
        numeric profit_margins
        numeric return_on_equity
        numeric return_on_assets
        numeric revenue_growth
        numeric earnings_growth
        numeric current_price
        bigint volume
    }
🥉 Bronze Layer - Raw Data Storage
mermaid
erDiagram
    raw_index_constituents_current {
        int id PK
        text code
        text exchange
        text name
        text sector
        text industry
        text weight
        text index_code
        text as_of_date
        timestamp loaded_at
        text source_file
    }

    raw_index_constituents_historical {
        int id PK
        text code
        text name
        text start_date
        text end_date
        text is_active_now
        text is_delisted
        text index_code
        timestamp loaded_at
        text source_file
    }

    raw_index_prices_base100 {
        int id PK
        text date
        text index_name
        text close
        text base_100
        timestamp loaded_at
        text source_file
    }

    raw_stock_valuation_metrics {
        int id PK
        text ticker
        text short_name
        text long_name
        text market_cap
        text trailing_pe
        text forward_pe
        text price_to_book
        text beta
        text dividend_yield
        timestamp loaded_at
        text source_file
    }
🥈 Silver Layer - Cleaned Data
mermaid
erDiagram
    stg_constituents_current {
        int id PK
        varchar ticker
        varchar exchange
        varchar company_name
        varchar sector
        varchar industry
        numeric index_weight
        varchar index_code
        date as_of_date
        timestamp loaded_at
        timestamp updated_at
    }

    stg_constituents_historical {
        int id PK
        varchar ticker
        varchar company_name
        date start_date
        date end_date
        boolean is_active_now
        boolean is_delisted
        varchar index_code
        timestamp loaded_at
        timestamp updated_at
    }

    stg_index_prices_daily {
        int id PK
        date trade_date UK
        varchar index_name UK
        numeric close_price
        numeric base_100_value
        timestamp loaded_at
        timestamp updated_at
    }

    stg_stock_fundamentals {
        int id PK
        varchar ticker
        varchar short_name
        varchar long_name
        numeric market_cap
        numeric trailing_pe
        numeric forward_pe
        numeric price_to_book
        numeric beta
        numeric dividend_yield
        timestamp loaded_at
        timestamp updated_at
    }
🔄 Data Flow Through Layers
mermaid
flowchart TD
    subgraph Sources
        CSV1[CSV: constituents_current.csv]
        CSV2[CSV: constituents_historical.csv]
        CSV3[CSV: index_prices_base100.csv]
        CSV4[CSV: stock_valuation_metrics.csv]
    end

    subgraph Bronze["Bronze Layer (Raw)"]
        B1[raw_index_constituents_current]
        B2[raw_index_constituents_historical]
        B3[raw_index_prices_base100]
        B4[raw_stock_valuation_metrics]
    end

    subgraph Silver["Silver Layer (Cleaned)"]
        S1[stg_constituents_current]
        S2[stg_constituents_historical]
        S3[stg_index_prices_daily]
        S4[stg_stock_fundamentals]
    end

    subgraph Gold["Gold Layer (Analytics)"]
        G1[dim_stocks]
        G2[dim_dates]
        G3[dim_indices]
        G4[dim_sectors]
        G5[fct_index_constituents]
        G6[fct_index_prices]
        G7[fct_stock_valuations]
    end

    CSV1 --> B1
    CSV2 --> B2
    CSV3 --> B3
    CSV4 --> B4

    B1 --> S1
    B2 --> S2
    B3 --> S3
    B4 --> S4

    S1 --> G1
    S2 --> G1
    S1 --> G4
    S2 --> G5
    S3 --> G6
    S4 --> G7
    
    S3 --> G2
    S4 --> G2
    S1 --> G3
📋 Table Relationships Summary
Dimension Tables (Lookup/Reference Tables)
Table	Purpose	Key Field	Records
dim_stocks	Master list of all stocks	ticker	~794
dim_dates	Date dimension for time analysis	full_date	~2,520
dim_indices	Index metadata (S&P 500, S&P 100)	index_code	2
dim_sectors	Sector hierarchy	sector_name	~11
Fact Tables (Transactional/Measurement Tables)
Table	Purpose	Grain	Records
fct_index_constituents	Stock membership in indices over time	One row per stock per index per time period	~1,000
fct_index_prices	Daily index prices and returns	One row per index per trading day	~5,000
fct_stock_valuations	Stock fundamentals snapshot	One row per stock per snapshot date	~794
🔗 Key Relationships
Star Schema Pattern
The Gold layer follows a star schema design:

Center (Facts): Measurement tables with foreign keys
Points (Dimensions): Lookup tables with descriptive attributes
Example Query Pattern:

sql
-- Get daily returns for S&P 500 stocks in Technology sector
SELECT 
    d.full_date,
    s.ticker,
    s.company_name,
    p.close_price,
    p.daily_return
FROM gold.fct_index_prices p
INNER JOIN gold.dim_dates d ON p.date_key = d.date_key
INNER JOIN gold.dim_indices i ON p.index_key = i.index_key
INNER JOIN gold.fct_index_constituents c ON i.index_key = c.index_key
INNER JOIN gold.dim_stocks s ON c.stock_key = s.stock_key
WHERE i.index_name = 'S&P 500'
  AND s.sector = 'Technology'
  AND d.full_date BETWEEN '2024-01-01' AND '2024-12-31';
🎯 Design Principles
1. Separation of Concerns
Bronze: Raw data preservation (audit trail)
Silver: Data quality layer (clean, typed)
Gold: Business logic layer (analytics-ready)
2. Referential Integrity
Foreign keys enforce relationships
Prevents orphaned records
Maintains data quality
3. Query Optimization
Indexes on frequently queried columns
Star schema for simple, fast joins
Date dimension for time-based filtering
4. Slowly Changing Dimensions (SCD Type 2)
dim_stocks tracks company changes over time
effective_from / effective_to / is_current pattern
Preserves historical accuracy
📝 Notes
PK = Primary Key (unique identifier)
FK = Foreign Key (references another table)
UK = Unique Key (must be unique, but not primary identifier)
Numeric types use appropriate precision for financial data
Audit columns (created_at, updated_at, loaded_at) track data lineage
