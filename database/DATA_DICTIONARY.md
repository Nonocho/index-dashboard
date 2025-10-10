Data Dictionary
Financial Index Analytics Platform - Complete Column Reference
Table of Contents
Bronze Layer Tables
Silver Layer Tables
Gold Layer Tables
Bronze Layer Tables
bronze.raw_index_constituents_current
Purpose: Raw snapshot of current index constituents exactly as received from EODHD API

Column	Data Type	Nullable	Description	Example
id	SERIAL	NOT NULL	Auto-incrementing primary key	1
code	TEXT	YES	Stock ticker symbol	'AAPL'
exchange	TEXT	YES	Exchange code	'US'
name	TEXT	YES	Full company name	'Apple Inc.'
sector	TEXT	YES	GICS Sector classification	'Technology'
industry	TEXT	YES	GICS Industry classification	'Consumer Electronics'
weight	TEXT	YES	Index weight as decimal string	'0.07500000'
index_code	TEXT	YES	Index identifier	'GSPC.INDX'
as_of_date	TEXT	YES	Data snapshot date	'2025-10-09'
loaded_at	TIMESTAMP	NOT NULL	When data was loaded into database	'2025-10-09 14:30:00'
source_file	TEXT	YES	Original CSV filename	'sandp_500_constituents_historical.csv'
Record Count: ~794 (S&P 500) + ~158 (S&P 100)

bronze.raw_index_prices_base100
Purpose: Raw daily index prices normalized to base 100

Column	Data Type	Nullable	Description	Example
id	SERIAL	NOT NULL	Auto-incrementing primary key	1
date	TEXT	YES	Trading date	'2024-01-03'
index_name	TEXT	YES	Index name	'S&P 500'
close	TEXT	YES	Actual closing price	'4697.24'
base_100	TEXT	YES	Normalized value (base 100)	'245.6789'
loaded_at	TIMESTAMP	NOT NULL	When data was loaded into database	'2025-10-09 14:30:00'
source_file	TEXT	YES	Original CSV filename	'index_prices_base100.csv'
Record Count: ~5,040 (10 years × 2 indices × ~252 trading days/year)

bronze.raw_stock_valuation_metrics
Purpose: Raw valuation and fundamental metrics from Yahoo Finance

Column	Data Type	Nullable	Description	Example
id	SERIAL	NOT NULL	Auto-incrementing primary key	1
ticker	TEXT	YES	Stock ticker symbol	'AAPL'
short_name	TEXT	YES	Short company name	'Apple Inc.'
long_name	TEXT	YES	Full legal company name	'Apple Inc.'
market_cap	TEXT	YES	Market capitalization	'3450000000000'
trailing_pe	TEXT	YES	Trailing P/E ratio	'32.45'
forward_pe	TEXT	YES	Forward P/E ratio	'28.90'
price_to_book	TEXT	YES	Price-to-Book ratio	'45.67'
price_to_sales_trailing_12_months	TEXT	YES	Price-to-Sales ratio	'8.34'
beta	TEXT	YES	Beta (volatility vs market)	'1.25'
dividend_yield	TEXT	YES	Dividend yield as decimal	'0.0045'
dividend_rate	TEXT	YES	Annual dividend per share	'0.96'
profit_margins	TEXT	YES	Profit margin as decimal	'0.2567'
return_on_equity	TEXT	YES	ROE as decimal	'1.4789'
return_on_assets	TEXT	YES	ROA as decimal	'0.2234'
revenue_growth	TEXT	YES	Revenue growth rate	'0.0821'
earnings_growth	TEXT	YES	Earnings growth rate	'0.1123'
fifty_two_week_high	TEXT	YES	52-week high price	'199.62'
fifty_two_week_low	TEXT	YES	52-week low price	'164.08'
current_price	TEXT	YES	Current stock price	'178.18'
volume	TEXT	YES	Trading volume	'54789320'
data_fetched_at	TEXT	YES	When data was fetched from API	'2025-10-09T14:30:00'
loaded_at	TIMESTAMP	NOT NULL	When data was loaded into database	'2025-10-09 14:30:00'
source_file	TEXT	YES	Original CSV filename	'stock_valuation_metrics.csv'
Record Count: ~794 unique tickers

Silver Layer Tables
silver.stg_constituents_current
Purpose: Cleaned and typed current index constituents

Column	Data Type	Nullable	Description	Example
id	SERIAL	NOT NULL	Auto-incrementing primary key	1
ticker	VARCHAR(10)	NOT NULL	Stock ticker symbol	'AAPL'
exchange	VARCHAR(10)	YES	Exchange code	'US'
company_name	VARCHAR(255)	YES	Full company name	'Apple Inc.'
sector	VARCHAR(100)	YES	GICS Sector classification	'Technology'
industry	VARCHAR(150)	YES	GICS Industry classification	'Consumer Electronics'
index_weight	NUMERIC(10,8)	YES	Index weight as proper decimal	0.07500000
index_code	VARCHAR(20)	YES	Index identifier	'GSPC.INDX'
as_of_date	DATE	YES	Data snapshot date	2025-10-09
loaded_at	TIMESTAMP	NOT NULL	When data was loaded	'2025-10-09 14:30:00'
updated_at	TIMESTAMP	NOT NULL	When data was last updated	'2025-10-09 14:30:00'
Transformations from Bronze:

code → ticker (renamed for clarity)
weight (TEXT) → index_weight (NUMERIC) for calculations
as_of_date (TEXT) → as_of_date (DATE) for proper date handling
silver.stg_constituents_historical
Purpose: Cleaned historical constituent changes with proper dates and booleans

Column	Data Type	Nullable	Description	Example
id	SERIAL	NOT NULL	Auto-incrementing primary key	1
ticker	VARCHAR(10)	NOT NULL	Stock ticker symbol	'IBM'
company_name	VARCHAR(255)	YES	Company name	'International Business Machines'
start_date	DATE	NOT NULL	Date added to index	1957-03-04
end_date	DATE	YES	Date removed (NULL = still active)	2020-08-31
is_active_now	BOOLEAN	YES	Currently in index?	FALSE
is_delisted	BOOLEAN	YES	Stock delisted?	FALSE
index_code	VARCHAR(20)	YES	Index identifier	'GSPC.INDX'
loaded_at	TIMESTAMP	NOT NULL	When data was loaded	'2025-10-09 14:30:00'
updated_at	TIMESTAMP	NOT NULL	When data was last updated	'2025-10-09 14:30:00'
Transformations from Bronze:

start_date (TEXT) → start_date (DATE)
end_date (TEXT) → end_date (DATE)
is_active_now ('1'/'0') → is_active_now (BOOLEAN)
is_delisted ('1'/'0') → is_delisted (BOOLEAN)
silver.stg_index_prices_daily
Purpose: Cleaned daily index prices with proper numeric types

Column	Data Type	Nullable	Description	Example
id	SERIAL	NOT NULL	Auto-incrementing primary key	1
trade_date	DATE	NOT NULL	Trading date	2024-01-03
index_name	VARCHAR(50)	NOT NULL	Index name	'S&P 500'
close_price	NUMERIC(12,2)	YES	Actual closing price	4697.24
base_100_value	NUMERIC(12,4)	YES	Normalized to base 100	245.6789
loaded_at	TIMESTAMP	NOT NULL	When data was loaded	'2025-10-09 14:30:00'
updated_at	TIMESTAMP	NOT NULL	When data was last updated	'2025-10-09 14:30:00'
Unique Constraint: (trade_date, index_name) - one price per index per day

Transformations from Bronze:

date (TEXT) → trade_date (DATE)
close (TEXT) → close_price (NUMERIC)
base_100 (TEXT) → base_100_value (NUMERIC)
silver.stg_stock_fundamentals
Purpose: Cleaned stock valuation metrics with proper numeric types

Column	Data Type	Nullable	Description	Example
id	SERIAL	NOT NULL	Auto-incrementing primary key	1
ticker	VARCHAR(10)	NOT NULL	Stock ticker symbol	'AAPL'
short_name	VARCHAR(255)	YES	Short company name	'Apple Inc.'
long_name	VARCHAR(255)	YES	Full legal name	'Apple Inc.'
market_cap	NUMERIC(20,2)	YES	Market cap in dollars	3450000000000.00
trailing_pe	NUMERIC(10,2)	YES	Trailing P/E ratio	32.45
forward_pe	NUMERIC(10,2)	YES	Forward P/E ratio	28.90
price_to_book	NUMERIC(10,2)	YES	Price-to-Book ratio	45.67
price_to_sales	NUMERIC(10,2)	YES	Price-to-Sales ratio	8.34
beta	NUMERIC(6,3)	YES	Beta coefficient	1.250
dividend_yield	NUMERIC(8,6)	YES	Dividend yield	0.004500
dividend_rate	NUMERIC(10,2)	YES	Annual dividend/share	0.96
profit_margins	NUMERIC(8,6)	YES	Profit margin	0.256700
return_on_equity	NUMERIC(8,6)	YES	Return on Equity	1.478900
return_on_assets	NUMERIC(8,6)	YES	Return on Assets	0.223400
revenue_growth	NUMERIC(8,6)	YES	Revenue growth rate	0.082100
earnings_growth	NUMERIC(8,6)	YES	Earnings growth rate	0.112300
fifty_two_week_high	NUMERIC(12,2)	YES	52-week high	199.62
fifty_two_week_low	NUMERIC(12,2)	YES	52-week low	164.08
current_price	NUMERIC(12,2)	YES	Current stock price	178.18
volume	BIGINT	YES	Trading volume	54789320
data_fetched_at	TIMESTAMP	YES	API fetch timestamp	'2025-10-09 14:30:00'
loaded_at	TIMESTAMP	NOT NULL	Database load time	'2025-10-09 14:30:00'
updated_at	TIMESTAMP	NOT NULL	Last update time	'2025-10-09 14:30:00'
Transformations from Bronze:

All TEXT fields → proper NUMERIC types with appropriate precision
Ratios/percentages stored as decimals (not percentages)
Large numbers (market cap, volume) use appropriate size types
Gold Layer Tables
Dimension Tables
gold.dim_stocks
Purpose: Master dimension table for all stocks (SCD Type 2)

Column	Data Type	Nullable	Description	Example
stock_key	SERIAL	NOT NULL	Surrogate key (PK)	1
ticker	VARCHAR(10)	NOT NULL	Stock ticker (unique)	'AAPL'
company_name	VARCHAR(255)	YES	Current company name	'Apple Inc.'
short_name	VARCHAR(255)	YES	Short name	'Apple Inc.'
sector	VARCHAR(100)	YES	GICS Sector	'Technology'
industry	VARCHAR(150)	YES	GICS Industry	'Consumer Electronics'
is_currently_listed	BOOLEAN	YES	Still trading?	TRUE
first_seen_date	DATE	YES	First appearance in data	1980-12-12
last_seen_date	DATE	YES	Last appearance (NULL if active)	NULL
effective_from	DATE	YES	SCD Type 2: Valid from date	2020-01-01
effective_to	DATE	YES	SCD Type 2: Valid to date	2024-12-31
is_current	BOOLEAN	YES	SCD Type 2: Current record?	TRUE
created_at	TIMESTAMP	NOT NULL	Record creation time	'2025-10-09 14:30:00'
updated_at	TIMESTAMP	NOT NULL	Record update time	'2025-10-09 14:30:00'
Key Features:

Surrogate key (stock_key) for immutability
Natural key (ticker) for business reference
SCD Type 2 columns track historical changes (e.g., sector reclassifications)
gold.dim_sectors
Purpose: Sector hierarchy lookup table

Column	Data Type	Nullable	Description	Example
sector_key	SERIAL	NOT NULL	Surrogate key (PK)	1
sector_name	VARCHAR(100)	NOT NULL	GICS Sector name (unique)	'Technology'
sector_description	TEXT	YES	Sector description	'Companies producing technology products'
created_at	TIMESTAMP	NOT NULL	Record creation time	'2025-10-09 14:30:00'
updated_at	TIMESTAMP	NOT NULL	Record update time	'2025-10-09 14:30:00'
Expected Sectors (GICS Level 1):

Technology
Financial Services
Healthcare
Consumer Cyclical
Industrials
Communication Services
Consumer Defensive
Energy
Utilities
Real Estate
Basic Materials
gold.dim_indices
Purpose: Index metadata lookup table

Column	Data Type	Nullable	Description	Example
index_key	SERIAL	NOT NULL	Surrogate key (PK)	1
index_code	VARCHAR(20)	NOT NULL	Index code (unique)	'GSPC.INDX'
index_name	VARCHAR(50)	NOT NULL	Display name	'S&P 500'
index_description	TEXT	YES	Index description	'Large-cap US equity index'
base_date	DATE	YES	Index inception date	1957-03-04
created_at	TIMESTAMP	NOT NULL	Record creation time	'2025-10-09 14:30:00'
updated_at	TIMESTAMP	NOT NULL	Record update time	'2025-10-09 14:30:00'
Expected Records:

GSPC.INDX → 'S&P 500'
OEX.INDX → 'S&P 100'
gold.dim_dates
Purpose: Date dimension for time intelligence and filtering

Column	Data Type	Nullable	Description	Example
date_key	SERIAL	NOT NULL	Surrogate key (PK)	1
full_date	DATE	NOT NULL	Actual date (unique)	2024-01-03
year	INTEGER	YES	Year	2024
quarter	INTEGER	YES	Quarter (1-4)	1
month	INTEGER	YES	Month (1-12)	1
month_name	VARCHAR(20)	YES	Month name	'January'
day	INTEGER	YES	Day of month (1-31)	3
day_of_week	INTEGER	YES	Day of week (0=Sunday, 6=Saturday)	3
day_name	VARCHAR(20)	YES	Day name	'Wednesday'
week_of_year	INTEGER	YES	ISO week number (1-53)	1
is_weekend	BOOLEAN	YES	Saturday or Sunday?	FALSE
is_month_end	BOOLEAN	YES	Last day of month?	FALSE
is_quarter_end	BOOLEAN	YES	Last day of quarter?	FALSE
is_year_end	BOOLEAN	YES	Last day of year?	FALSE
created_at	TIMESTAMP	NOT NULL	Record creation time	'2025-10-09 14:30:00'
Purpose in Queries:

Filter by year, quarter, month without date parsing
Identify trading patterns (day of week analysis)
Aggregate by time periods easily
Fact Tables
gold.fct_index_constituents
Purpose: Point-in-time membership of stocks in indices

Column	Data Type	Nullable	Description	Example
constituent_key	SERIAL	NOT NULL	Surrogate key (PK)	1
stock_key	INTEGER	YES	Foreign key to dim_stocks	42
index_key	INTEGER	YES	Foreign key to dim_indices	1
start_date_key	INTEGER	YES	FK to dim_dates (membership start)	1523
end_date_key	INTEGER	YES	FK to dim_dates (membership end)	2456
index_weight	NUMERIC(10,8)	YES	Stock weight in index	0.07500000
is_active	BOOLEAN	YES	Currently in index?	TRUE
created_at	TIMESTAMP	NOT NULL	Record creation time	'2025-10-09 14:30:00'
updated_at	TIMESTAMP	NOT NULL	Record update time	'2025-10-09 14:30:00'
Grain: One row per stock per index per time period

Use Cases:

Point-in-time index reconstruction
Tracking when stocks joined/left indices
Historical backtesting with correct constituents
gold.fct_index_prices
Purpose: Daily index prices with calculated returns

Column	Data Type	Nullable	Description	Example
price_key	SERIAL	NOT NULL	Surrogate key (PK)	1
date_key	INTEGER	YES	Foreign key to dim_dates	1523
index_key	INTEGER	YES	Foreign key to dim_indices	1
close_price	NUMERIC(12,2)	YES	Closing price	4697.24
base_100_value	NUMERIC(12,4)	YES	Base 100 normalized	245.6789
daily_return	NUMERIC(10,6)	YES	Daily return (calculated by dbt)	0.012345
cumulative_return	NUMERIC(10,6)	YES	Cumulative return (calculated by dbt)	1.456789
volume	BIGINT	YES	Trading volume	3500000000
created_at	TIMESTAMP	NOT NULL	Record creation time	'2025-10-09 14:30:00'
updated_at	TIMESTAMP	NOT NULL	Record update time	'2025-10-09 14:30:00'
Unique Constraint: (date_key, index_key) - one price per index per day

Grain: One row per index per trading day

Calculated Fields (populated by dbt):

daily_return = (today_price / yesterday_price) - 1
cumulative_return = (current_price / base_price) - 1
gold.fct_stock_valuations
Purpose: Point-in-time fundamental metrics for stocks

Column	Data Type	Nullable	Description	Example
valuation_key	SERIAL	NOT NULL	Surrogate key (PK)	1
stock_key	INTEGER	YES	Foreign key to dim_stocks	42
date_key	INTEGER	YES	Foreign key to dim_dates	1523
market_cap	NUMERIC(20,2)	YES	Market capitalization	3450000000000.00
trailing_pe	NUMERIC(10,2)	YES	Trailing P/E ratio	32.45
forward_pe	NUMERIC(10,2)	YES	Forward P/E ratio	28.90
price_to_book	NUMERIC(10,2)	YES	P/B ratio	45.67
price_to_sales	NUMERIC(10,2)	YES	P/S ratio	8.34
beta	NUMERIC(6,3)	YES	Beta coefficient	1.250
dividend_yield	NUMERIC(8,6)	YES	Dividend yield	0.004500
dividend_rate	NUMERIC(10,2)	YES	Annual dividend/share	0.96
profit_margins	NUMERIC(8,6)	YES	Profit margin	0.256700
return_on_equity	NUMERIC(8,6)	YES	ROE	1.478900
return_on_assets	NUMERIC(8,6)	YES	ROA	0.223400
revenue_growth	NUMERIC(8,6)	YES	Revenue growth rate	0.082100
earnings_growth	NUMERIC(8,6)	YES	Earnings growth rate	0.112300
current_price	NUMERIC(12,2)	YES	Stock price at snapshot	178.18
volume	BIGINT	YES	Trading volume	54789320
created_at	TIMESTAMP	NOT NULL	Record creation time	'2025-10-09 14:30:00'
updated_at	TIMESTAMP	NOT NULL	Record update time	'2025-10-09 14:30:00'
Grain: One row per stock per valuation snapshot date

Use Cases:

Factor-based index construction (low P/E, high dividend, etc.)
Stock screening and filtering
Historical valuation analysis
Data Type Rationale
Why NUMERIC instead of FLOAT/DOUBLE?
Financial data requires precision!

sql
-- ❌ BAD: Floating point loses precision
0.1 + 0.2 = 0.30000000000000004  -- In most programming languages!

-- ✅ GOOD: NUMERIC maintains exact precision
0.1 + 0.2 = 0.3  -- Always exact in PostgreSQL NUMERIC
Our NUMERIC types:

NUMERIC(10,8) - Index weights (e.g., 0.07500000)
NUMERIC(12,2) - Prices (e.g., 4697.24)
NUMERIC(10,6) - Returns/ratios (e.g., 0.012345)
NUMERIC(20,2) - Market cap (e.g., 3.45 trillion)
Audit Columns
All tables include audit columns for data lineage:

Column	Purpose
loaded_at	When data first entered the database
updated_at	When data was last modified
created_at	When this specific record was created
source_file	Original CSV filename (Bronze only)
These help with:

Debugging data issues
Tracking data freshness
Understanding data lineage
Naming Conventions
Tables
bronze.* → raw_* prefix
silver.* → stg_* prefix (staging)
gold.* → dim_* (dimensions) or fct_* (facts)
Columns
Use snake_case (not camelCase)
Suffix keys with _key (surrogate) or _id (natural)
Use full words, avoid abbreviations (except common ones like pe, roe)
Date columns: *_date or *_at (timestamp)
📊 Summary Statistics
Layer	Tables	Total Columns	Purpose
Bronze	4	~60	Raw data preservation
Silver	4	~70	Clean, validated data
Gold	7	~100	Analytics-ready star schema
Total Expected Records:

Dimensions: ~3,500 rows
Facts: ~10,000+ rows (grows over time) | NOT NULL | When data was loaded into database | '2025-10-09 14:30:00' | | source_file | TEXT | YES | Original CSV filename | 'sandp_500_constituents_current.csv' |
Record Count: ~503 (S&P 500) + ~101 (S&P 100)

bronze.raw_index_constituents_historical
Purpose: Raw historical constituent changes (additions/removals) from 1957-2025

Column	Data Type	Nullable	Description	Example
id	SERIAL	NOT NULL	Auto-incrementing primary key	1
code	TEXT	YES	Stock ticker symbol	'IBM'
name	TEXT	YES	Company name at time of membership	'International Business Machines'
start_date	TEXT	YES	Date added to index	'1957-03-04'
end_date	TEXT	YES	Date removed from index (NULL if still active)	'2020-08-31'
is_active_now	TEXT	YES	'1' if currently in index, '0' otherwise	'0'
is_delisted	TEXT	YES	'1' if stock delisted, '0' if still trading	'0'
index_code	TEXT	YES	Index identifier	'GSPC.INDX'
loaded_at	TIMESTAMP			
