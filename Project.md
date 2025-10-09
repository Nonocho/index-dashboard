# Financial Index Analytics Platform - Project Documentation

**Project Owner**: Former Quantitative Investment Strategist (CFA, 8+ years at Amundi, €250B+ AUM)  
**Project Goal**: Portfolio project showcasing financial domain expertise + modern data engineering skills  
**Target Audience**: Fintech/hedge fund technical interviews  
**Status**: Phase 1 Complete - Data Acquisition ✅

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Technical Architecture](#technical-architecture)
3. [Data Sources](#data-sources)
4. [Current Progress](#current-progress)
5. [Data Inventory](#data-inventory)
6. [Next Phases](#next-phases)
7. [Technical Decisions & Rationale](#technical-decisions--rationale)

---

## 🎯 Project Overview

### Objective
Build an end-to-end **Financial Index Analytics Platform** that demonstrates:
- Modern data stack proficiency (Dagster, dbt, PostgreSQL, Streamlit)
- Financial domain expertise (index construction, risk analytics, factor investing)
- Production-quality data engineering practices
- SQL mastery through complex financial queries

### Key Features
- **Custom Index Construction**: Equal-weighted, cap-weighted, factor-based indices
- **Performance Analytics**: Returns, volatility, Sharpe ratios, tracking error
- **Risk Metrics**: VaR, maximum drawdown, beta calculations
- **Historical Backtesting**: 68 years of S&P 500 constituent history
- **Interactive Dashboards**: Streamlit-based visualization platform

### Why This Project Stands Out
1. **Real financial data** (S&P 500/100, not toy datasets)
2. **68 years of historical constituent data** (survivorship-bias-free)
3. **Production-ready architecture** (not just Jupyter notebooks)
4. **Demonstrates both finance + engineering expertise**

---

## 🏗️ Technical Architecture

### Modern Data Stack

```
┌─────────────────────────────────────────────────────────────┐
│                    DATA SOURCES                              │
├─────────────────────────────────────────────────────────────┤
│  EODHD Marketplace API          │  Yahoo Finance (yfinance) │
│  • S&P 500/100 constituents     │  • Index prices (10 years)│
│  • Historical changes (68 years)│  • Valuation metrics      │
│  • Index weights                │  • P/E, P/B, market cap   │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│              ORCHESTRATION: Dagster                          │
│  • Asset-based pipeline (declarative)                       │
│  • Data lineage tracking                                     │
│  • Schedule-based ingestion                                  │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│         STORAGE: PostgreSQL (Medallion Architecture)         │
│                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    │
│  │   BRONZE    │ →  │   SILVER    │ →  │    GOLD     │    │
│  │  Raw Data   │    │  Cleaned    │    │  Business   │    │
│  │             │    │  Validated  │    │   Logic     │    │
│  └─────────────┘    └─────────────┘    └─────────────┘    │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│         TRANSFORMATION: dbt (Data Build Tool)                │
│  • SQL-based transformations                                 │
│  • Version controlled models                                 │
│  • Automated testing & documentation                         │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│         VISUALIZATION: Streamlit                             │
│  • Interactive index builder                                 │
│  • Performance dashboards                                    │
│  • Risk analytics                                            │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

| Layer | Technology | Why Chosen |
|-------|-----------|------------|
| **Orchestration** | Dagster | Modern asset-based approach, better than Airflow for small teams |
| **Database** | PostgreSQL 14+ | Industry standard, excellent for financial data, window functions |
| **Transformation** | dbt | SQL-based, version controlled, testable transformations |
| **Visualization** | Streamlit | Python-native, rapid prototyping, perfect for financial dashboards |
| **API Client** | yfinance, requests | Free tier access, well-documented |
| **Data Format** | Parquet + CSV | Parquet for efficiency, CSV for compatibility |

---

## 📊 Data Sources

### 1. EODHD Marketplace API (€29 one-time)

**What We Get:**
- S&P 500 constituents (current: 503 stocks)
- S&P 100 constituents (current: 101 stocks)
- Historical constituent changes (1957-2025 for S&P 500)
- Index weights (for proper cap-weighted calculations)

**API Details:**
- Base URL: `https://eodhd.com/api/mp/unicornbay/spglobal`
- Rate Limit: 100,000 calls/day, 1,000/minute
- Endpoints Used:
  - `/list` - List of available indices
  - `/comp/{index_code}` - Current constituents + historical changes

**Key Value:**
- 68 years of S&P 500 history = survivorship-bias-free backtesting
- Professional-grade data source
- Historical constituent changes with exact dates

### 2. Yahoo Finance (yfinance - Free)

**What We Get:**
- Index prices (^GSPC, ^OEX) - 10 years daily data
- Valuation metrics for 794 stocks:
  - Market cap, P/E ratios (trailing/forward), Price-to-Book
  - Beta, dividend yield, profit margins
  - ROE, ROA, revenue/earnings growth

**Why Yahoo Finance:**
- Free and reliable for daily EOD data
- No API key required
- Widely used in finance/quant industry
- Good enough for portfolio project (not production trading)

**Limitations Accepted:**
- Occasional data gaps (handled via data quality checks)
- No intraday data on free tier (don't need it)
- Rate limiting (handled with batch processing + sleep timers)

---

## ✅ Current Progress

### Phase 1: Data Acquisition (COMPLETE)

**Completed Tasks:**

1. ✅ **Environment Setup**
   - Python virtual environment
   - Required packages installed
   - `.env` file for API credentials
   - Directory structure created

2. ✅ **EODHD Index Constituents**
   - Fetched S&P 500: 503 current + 794 historical (1957-2025)
   - Fetched S&P 100: 101 current + 158 historical (2013-2025)
   - 794 unique tickers total
   - Index weights for cap-weighted calculations

3. ✅ **Yahoo Finance Index Prices**
   - 10 years of daily data (2014-12-31 to 2025-10-09)
   - Base 100 normalized (both indices start at 100)
   - ~2,520 trading days per index

4. ✅ **Yahoo Finance Valuation Metrics**
   - 794 tickers fetched (100% success rate!)
   - Key metrics: P/E, P/B, market cap, beta, dividends
   - Total market cap covered: $64.7 Trillion

**Success Metrics:**
- 100% API fetch success rate
- Zero data loss
- Clean, validated datasets
- Comprehensive documentation

---

## 📁 Data Inventory

### Current Data Files

```
data/
├── raw/
│   ├── indices/
│   │   ├── available_indices_list.csv (110 indices available)
│   │   ├── sandp_500_constituents_current.csv (503 rows)
│   │   ├── sandp_500_constituents_historical.csv (794 rows, 1957-2025)
│   │   ├── sandp_500_metadata.json
│   │   ├── sandp_100_constituents_current.csv (101 rows)
│   │   ├── sandp_100_constituents_historical.csv (158 rows, 2013-2025)
│   │   ├── sandp_100_metadata.json
│   │   ├── complete_ticker_universe.csv (794 unique tickers)
│   │   ├── indices_summary.csv
│   │   └── sector_distribution_comparison.csv
│   │
│   ├── prices/
│   │   ├── index_prices_base100.csv (2,520 rows × 2 indices)
│   │   ├── index_prices_base100.parquet (compressed version)
│   │   ├── index_prices_base100_summary.csv
│   │   └── index_base100_comparison.png (visualization)
│   │
│   └── fundamentals/
│       ├── stock_valuation_metrics.csv (794 rows, ~40 columns)
│       └── stock_valuation_metrics.parquet
```

### Data Schemas

#### Index Constituents Schema
```
Columns:
- Code (ticker symbol)
- Exchange (US)
- Name (company name)
- Sector (Technology, Financial Services, etc.)
- Industry (Software, Banks, etc.)
- Weight (index weight, 0.0001 to 0.08)
- IndexCode (GSPC.INDX or OEX.INDX)
- AsOfDate (data snapshot date)
```

#### Historical Constituents Schema
```
Columns:
- Code (ticker symbol)
- Name (company name)
- StartDate (when added to index)
- EndDate (when removed from index)
- IsActiveNow (1 if still in index, 0 if removed)
- IsDelisted (1 if delisted, 0 if still trading)
- IndexCode (GSPC.INDX or OEX.INDX)
```

#### Index Prices Schema (Base 100)
```
Columns:
- date (trading date, datetime)
- index_name (S&P 500, S&P 100)
- close (actual closing price)
- base_100 (normalized to 100 at start date)
```

#### Valuation Metrics Schema
```
Key Columns:
- ticker
- shortName, longName
- marketCap (market capitalization)
- trailingPE, forwardPE (P/E ratios)
- priceToBook, priceToSalesTrailing12Months
- beta (volatility vs market)
- dividendYield, dividendRate
- profitMargins, returnOnEquity, returnOnAssets
- revenueGrowth, earningsGrowth
- fiftyTwoWeekHigh, fiftyTwoWeekLow
- currentPrice, volume
- data_fetched_at (timestamp)
```

### Data Quality Metrics

| Dataset | Rows | Completeness | Notes |
|---------|------|--------------|-------|
| S&P 500 Current | 503 | 100% | All fields populated |
| S&P 500 Historical | 794 | 100% | 68 years coverage |
| S&P 100 Current | 101 | 100% | All fields populated |
| S&P 100 Historical | 158 | 100% | 12 years coverage |
| Index Prices | 5,040 | 100% | No missing dates |
| Valuation Metrics | 794 | 72-81% | Varies by field (expected) |

---

## 🚀 Next Phases

### Phase 2: Database Design & Setup (Next)

**Objectives:**
- Design PostgreSQL schema (Bronze/Silver/Gold layers)
- Set up local PostgreSQL database
- Define table relationships and constraints
- Create indexes for query optimization

**Deliverables:**
- `schema.sql` - Complete database schema
- Entity-Relationship Diagram (ERD)
- Data dictionary documentation

**Key Tables to Design:**
```
Bronze Layer (Raw):
- raw_index_constituents
- raw_index_constituents_historical
- raw_index_prices
- raw_stock_valuation

Silver Layer (Cleaned):
- stg_constituents
- stg_index_prices
- stg_stock_fundamentals

Gold Layer (Business Logic):
- dim_stocks (stock master table)
- dim_sectors (sector hierarchy)
- dim_dates (date dimension)
- fct_index_returns (daily returns)
- fct_stock_valuation (point-in-time valuations)
```

### Phase 3: Data Ingestion Pipeline (Dagster)

**Objectives:**
- Set up Dagster project
- Create assets for each data source
- Implement incremental loading
- Add data quality checks

**Dagster Assets to Build:**
```python
@asset
def raw_sp500_constituents() -> pd.DataFrame:
    """Load S&P 500 constituents from CSV to PostgreSQL"""

@asset
def raw_index_prices() -> pd.DataFrame:
    """Load index prices from CSV to PostgreSQL"""

@asset
def raw_stock_valuation() -> pd.DataFrame:
    """Load valuation metrics from CSV to PostgreSQL"""
```

### Phase 4: Data Transformation (dbt)

**Objectives:**
- Set up dbt project
- Build staging models (Silver layer)
- Build analytics models (Gold layer)
- Add tests and documentation

**Key dbt Models:**
```sql
-- Silver layer
models/staging/stg_constituents.sql
models/staging/stg_index_prices.sql

-- Gold layer
models/marts/dim_stocks.sql
models/marts/fct_daily_returns.sql
models/marts/fct_index_performance.sql
```

**SQL Skills to Demonstrate:**
- Window functions (LAG, LEAD for returns)
- CTEs (Common Table Expressions)
- Recursive queries (cumulative returns)
- Complex joins (point-in-time constituent matching)
- Aggregations (index-level metrics)

### Phase 5: Analytics & Custom Indices

**Objectives:**
- Calculate custom indices (equal-weight, factor-based)
- Build risk analytics
- Create rebalancing logic
- Implement backtesting framework

**Custom Indices to Build:**
1. **Equal-Weighted S&P 500** (vs cap-weighted)
2. **Low Volatility Index** (lowest beta stocks)
3. **High Dividend Index** (highest dividend yield)
4. **Value Index** (lowest P/E ratio)
5. **Quality Index** (highest ROE + profit margins)

### Phase 6: Visualization (Streamlit)

**Objectives:**
- Build interactive dashboards
- Create custom index builder interface
- Add performance comparison tools
- Implement risk analytics views

**Dashboard Pages:**
1. **Home**: Index overview and latest data
2. **Index Builder**: Interactive custom index creation
3. **Performance**: Multi-index comparison charts
4. **Risk Analytics**: VaR, drawdown, correlation matrix
5. **Stock Screener**: Filter by valuation metrics

### Phase 7: Deployment & Polish

**Objectives:**
- Dockerize the application
- Set up CI/CD (optional)
- Create comprehensive documentation
- Deploy demo (local or cloud)
