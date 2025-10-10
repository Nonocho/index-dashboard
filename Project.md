# Financial Index Analytics Platform - Project Documentation

**Project Owner**: Former Quantitative Investment Strategist (CFA, 8+ years at Amundi, €250B+ AUM)  
**Project Goal**: Portfolio project showcasing financial domain expertise + modern data engineering skills  
**Target Audience**: Fintech/hedge fund technical interviews  
**Status**: Phase 5 Complete - Analytics & Performance Models Built ✅

---

## ✅ Current Progress Summary

### Completed Phases

#### Phase 1: Data Acquisition ✅ COMPLETE
- EODHD API: 794 unique tickers (S&P 500 + S&P 100)
- 68 years of historical constituent data (1957-2025)
- 10 years of daily index prices (2,709 trading days)
- 794 stock valuation metrics fetched

#### Phase 2: Database Design ✅ COMPLETE
- PostgreSQL 15.3 database created
- Medallion architecture: Bronze/Silver/Gold schemas
- Complete ERD and data dictionary
- 20+ indexes for query optimization

#### Phase 3: Data Ingestion (Dagster) ✅ COMPLETE
- 6 Bronze layer ingestion assets built
- PostgreSQL connection resource created
- All CSV data loaded successfully:
  - ✅ 604 current constituents
  - ✅ 952 historical constituent records
  - ✅ 5,418 index price records
  - ✅ 794 stock valuations
- Idempotent pipeline (can re-run safely)
- Full data lineage tracking in Dagster UI

#### Phase 4: Data Transformation (dbt) ✅ COMPLETE
- dbt-core 1.10.13 and dbt-postgres 1.9.1 installed
- 4 Silver layer staging models built:
  - ✅ `stg_constituents_current` (604 rows)
  - ✅ `stg_constituents_historical` (952 rows)
  - ✅ `stg_index_prices_daily` (5,418 rows)
  - ✅ `stg_stock_fundamentals` (794 rows)
- Advanced SQL transformations with proper data types
- Custom schema macro to control table placement

#### Phase 5A: Gold Layer - Dimensional Model ✅ COMPLETE

**Dimension Tables:**
- ✅ `dim_dates` - 18,002 business days (1957-2025)
  - Complete date attributes (day, week, month, quarter, year)
  - Business day filtering (excludes weekends)
  - Fiscal calendar support
  - Month-end, quarter-end, year-end flags

- ✅ `dim_indices` - 2 indices
  - S&P 500 (SP500) - 503 constituents
  - S&P 100 (SP100) - 101 constituents
  - Market cap categories and descriptions
  - Weighting methodology metadata

- ✅ `dim_stocks` - 794 unique stocks
  - Company names, sectors, industries
  - Valuation metrics (trailing P/E, forward P/E, P/B, P/S)
  - Profitability metrics (ROE, ROA, profit margins)
  - Growth metrics (revenue growth, earnings growth)
  - Risk metrics (beta)
  - Dividend data (yield, rate)
  - Price ranges (52-week high/low, current price)
  - Current constituent flag

**Fact Tables:**
- ✅ `fct_index_constituents` - 604 membership records
  - Foreign keys to all 3 dimensions
  - Index weights (sum to 100% per index)
  - Point-in-time accurate snapshot (2025-10-09)
  - Star schema enabling complex analytics

#### Phase 5B: Index-Level Analytics ✅ COMPLETE

**Analytics Models Built:**
- ✅ `fct_index_valuations` - 2 rows
  - S&P 500: P/E 29.43x, P/B 5.62x, Div Yield 1.16%
  - S&P 100: P/E 30.49x, P/B 6.89x, Div Yield 1.05%
  - Harmonic mean for valuation ratios
  - Weighted averages for income metrics

- ✅ `fct_top10_holdings` - 20 rows
  - Top 3: NVDA 8.01%, MSFT 6.77%, AAPL 6.65%
  - Cumulative weight tracking
  - Concentration risk analysis

- ✅ `fct_index_sector_weights` - ~22 rows
  - GICS sector allocation
  - Sector-level valuation metrics
  - Technology dominance (~30% weight)

- ✅ `fct_index_marketcap_breakdown` - 8 rows
  - Mega Cap (>$200B)
  - Large Cap ($10B-$200B)
  - Mid Cap ($2B-$10B)
  - Small Cap (<$2B)

**Key Achievements:**
- Implemented harmonic mean for P/E, P/B, P/S ratios
- Calculated weighted averages for dividend yield, ROE, profit margins
- Built concentration risk analysis (top 10 = ~35% of index)
- Created sector and size factor breakdowns

#### Phase 5C: Performance & Risk Metrics ✅ COMPLETE

**Performance Models Built:**
- ✅ `fct_index_returns` - 5,418 rows
  - Daily, weekly, monthly, quarterly, annual returns
  - 3-year and 5-year total & annualized returns
  - YTD performance tracking
  - Log returns for statistical analysis

- ✅ `fct_index_volatility` - 5,358 rows
  - Rolling volatility: 30D, 90D, 180D, 252D windows
  - Annualized with SQRT(252) scaling
  - S&P 500: 19.7% annual volatility
  - S&P 100: 18.5% annual volatility

- ✅ `fct_index_sharpe` - 4,914 rows
  - Risk-adjusted returns (4% risk-free rate)
  - S&P 500 Sharpe: 0.90
  - S&P 100 Sharpe: 0.73
  - Multiple time horizons (1M, 3M, 6M, 1Y)

- ✅ `fct_index_drawdown` - 5,418 rows
  - Peak-to-trough decline tracking
  - S&P 500 max drawdown: -33.9%
  - S&P 100 max drawdown: -31.5%
  - Recovery time metrics (days since peak)

**Latest Performance Metrics (Oct 8, 2025):**

| Metric | S&P 500 | S&P 100 |
|--------|---------|---------|
| 1Y Return | 21.6% | 17.4% |
| 3Y CAGR | 26.5% | 22.5% |
| 5Y CAGR | 16.5% | 14.8% |
| 3Y Total | 102.4% | 83.6% |
| 5Y Total | 114.5% | 99.8% |
| YTD Return | 16.8% | 15.1% |
| Volatility (1Y) | 19.7% | 18.5% |
| Sharpe Ratio | 0.90 | 0.73 |
| Max Drawdown | -33.9% | -31.5% |
| Days Since Peak | 0 | 0 |

**Key Achievements:**
- Calculated multi-period returns (daily to 5-year)
- Implemented annualized volatility with SQRT(252) scaling
- Built Sharpe ratio for risk-adjusted performance
- Tracked maximum drawdown and recovery metrics
- Used LAG window functions for efficient time-series calculations

---

## 🏆 Phase 5 Complete: Analytics & Performance Layer

### What We Built (8 Analytics Models + 4 Performance Models)

**Analytics Mart** (`analytics` schema):
1. **Index Valuations** - Harmonic mean P/E, weighted avg dividend yield
2. **Top 10 Holdings** - Concentration analysis with cumulative weights
3. **Sector Weights** - GICS sector allocation and metrics
4. **Market Cap Breakdown** - Size factor analysis (Mega/Large/Mid/Small)

**Performance Mart** (`performance` schema):
1. **Returns** - Daily to 5-year returns with annualization
2. **Volatility** - Rolling windows (30D to 252D) with proper scaling
3. **Sharpe Ratios** - Risk-adjusted returns across multiple periods
4. **Drawdowns** - Peak-to-trough analysis with recovery tracking

### SQL Techniques Demonstrated

**Advanced Aggregations:**
```sql
-- Harmonic mean for P/E ratios
1 / SUM(CASE WHEN pe_ratio > 0 THEN index_weight / pe_ratio END)

-- Weighted average for dividend yield
SUM(index_weight * dividend_yield)

-- Filtered aggregation
SUM(CASE WHEN roe IS NOT NULL THEN index_weight * roe END) / 
    NULLIF(SUM(CASE WHEN roe IS NOT NULL THEN index_weight END), 0)
```

**Window Functions:**
```sql
-- LAG for time-series calculations
LAG(close_price, 252) OVER (PARTITION BY index_code ORDER BY price_date)

-- STDDEV for rolling volatility
STDDEV(daily_log_return) OVER (
    PARTITION BY index_code 
    ORDER BY price_date
    ROWS BETWEEN 251 PRECEDING AND CURRENT ROW
) * SQRT(252)

-- ROW_NUMBER for rankings
ROW_NUMBER() OVER (PARTITION BY index_key ORDER BY index_weight DESC)

-- Running MAX for peak tracking
MAX(close_price) OVER (
    PARTITION BY index_code 
    ORDER BY price_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
```

**Performance Calculations:**
```sql
-- Annualized returns (CAGR)
POWER((price_end / price_start), (1.0 / years)) - 1

-- Annualized volatility
STDDEV(log_returns) * SQRT(252)

-- Sharpe ratio
(annualized_return - risk_free_rate) / annualized_volatility

-- Maximum drawdown
(current_price - peak_price) / peak_price
```

---

## 📁 Complete Project Structure

```
index-dashboard/
├── dagster_project/                    # Orchestration layer
│   ├── __init__.py
│   ├── assets/
│   │   ├── __init__.py
│   │   └── bronze_ingestion.py        # 6 Bronze assets
│   ├── resources/
│   │   ├── __init__.py
│   │   └── database.py                # PostgreSQL resource
│   └── test_connection.py
│
├── financial_index_dbt/                # Transformation layer
│   ├── dbt_project.yml                # Project configuration
│   ├── macros/
│   │   └── get_custom_schema.sql      # Custom schema naming
│   ├── models/
│   │   ├── staging/
│   │   │   └── bronze/
│   │   │       ├── sources.yml        # Source definitions
│   │   │       ├── stg_constituents_current.sql
│   │   │       ├── stg_constituents_historical.sql
│   │   │       ├── stg_index_prices_daily.sql
│   │   │       └── stg_stock_fundamentals.sql
│   │   └── marts/
│   │       ├── dimensions/
│   │       │   ├── dim_dates.sql      # 18,002 business days
│   │       │   ├── dim_indices.sql    # 2 indices
│   │       │   └── dim_stocks.sql     # 794 stocks
│   │       ├── facts/
│   │       │   └── fct_index_constituents.sql  # 604 records
│   │       ├── analytics/
│   │       │   ├── fct_index_valuations.sql
│   │       │   ├── fct_top10_holdings.sql
│   │       │   ├── fct_index_sector_weights.sql
│   │       │   └── fct_index_marketcap_breakdown.sql
│   │       └── performance/
│   │           ├── fct_index_returns.sql
│   │           ├── fct_index_volatility.sql
│   │           ├── fct_index_sharpe.sql
│   │           └── fct_index_drawdown.sql
│   └── target/                        # Compiled SQL
│
├── data/
│   └── raw/                           # Source CSV files
│       ├── indices/
│       ├── prices/
│       └── fundamentals/
│
├── database/
│   ├── schema.sql
│   ├── ERD.md
│   └── DATA_DICTIONARY.md
│
├── .env                               # Database credentials
├── venv/                              # Python environment
└── PROJECT_DOCUMENTATION.md           # This file
```

---

## 🗄️ Database Status

### Bronze Layer (Raw Data)
```
bronze.raw_index_constituents_current    → 604 rows
bronze.raw_index_constituents_historical → 952 rows
bronze.raw_index_prices_base100          → 5,418 rows
bronze.raw_stock_valuation_metrics       → 794 rows
```

### Silver Layer (Cleaned & Typed)
```
silver.stg_constituents_current    → 604 rows   ✅
silver.stg_constituents_historical → 952 rows   ✅
silver.stg_index_prices_daily      → 5,418 rows ✅
silver.stg_stock_fundamentals      → 794 rows   ✅
```

### Gold Layer (Analytics Ready)

**Dimensions:**
```
gold.dim_dates   → 18,002 rows (business days 1957-2025) ✅
gold.dim_indices → 2 rows      (S&P 500 & S&P 100)       ✅
gold.dim_stocks  → 794 rows    (unique stocks)           ✅
```

**Facts:**
```
gold.fct_index_constituents → 604 rows (current membership) ✅
```

**Analytics:**
```
analytics.fct_index_valuations          → 2 rows     ✅
analytics.fct_top10_holdings            → 20 rows    ✅
analytics.fct_index_sector_weights      → ~22 rows   ✅
analytics.fct_index_marketcap_breakdown → 8 rows     ✅
```

**Performance:**
```
performance.fct_index_returns    → 5,418 rows  ✅
performance.fct_index_volatility → 5,358 rows  ✅
performance.fct_index_sharpe     → 4,914 rows  ✅
performance.fct_index_drawdown   → 5,418 rows  ✅
```

**Total Analytics-Ready Data:** ~21,000 rows spanning 10+ years of daily metrics

---

## 🚀 Next Phases

### Phase 6: Custom Index Construction (NEXT!)
**Objective:** Build alternative index strategies for backtesting and comparison

**Custom Indices to Build:**
1. Equal-Weighted S&P 500 (vs market-cap weighted)
2. Low Volatility Index (lowest beta stocks)
3. High Dividend Index (highest dividend yield stocks)
4. Value Index (lowest P/E ratios)
5. Quality Index (highest ROE + profit margins)

**Why This Matters:**
- Demonstrates factor investing knowledge
- Shows ability to implement investment strategies in SQL
- Enables performance comparison vs benchmarks
- Showcases understanding of smart beta / alternative indexing

### Phase 7: Visualization (Streamlit)
**Dashboard Pages:**
1. Home: Index overview and latest data
2. Index Builder: Interactive custom index creation
3. Performance: Multi-index comparison charts
4. Risk Analytics: VaR, drawdown, correlation
5. Stock Screener: Filter by valuation metrics

---

## 💻 Technology Stack

| Layer | Technology | Version | Status |
|-------|-----------|---------|--------|
| Database | PostgreSQL | 15.3 | ✅ Running |
| Orchestration | Dagster | Latest | ✅ Configured |
| Transformation | dbt-core | 1.10.13 | ✅ Configured |
| Transformation | dbt-postgres | 1.9.1 | ✅ Configured |
| Language | Python | 3.12.2 | ✅ Active |
| Visualization | Streamlit | - | ⏳ Phase 7 |

---

## 📊 Key Metrics

### Data Volume
- **Total Records Processed:** 30,000+ rows across all layers
- **Time Period Covered:** 68 years (1957-2025) for constituents, 10 years for prices
- **Stocks Tracked:** 794 unique tickers
- **Trading Days:** 2,709 daily observations
- **Business Days:** 18,002 date dimension records

### Pipeline Performance
- **Dagster Assets:** 6 Bronze ingestion assets (100% success)
- **dbt Models:** 20 total models
  - 4 Silver staging models
  - 3 Dimension tables
  - 1 Core fact table
  - 4 Analytics models
  - 4 Performance models (skipped beta/alpha)
- **Build Time:** ~5 seconds for full refresh
- **Data Quality:** 100% success rate on all transformations

### Data Quality Checks
- ✅ No NULL tickers in any dimension
- ✅ 604 current constituents properly flagged
- ✅ Index weights sum to 100% (S&P 500: 99.99%, S&P 100: 99.99%)
- ✅ All foreign key relationships validated
- ✅ 96-98% data coverage for valuation metrics

---

## 🎯 Portfolio Talking Points

### Quantitative Finance Skills

✅ **"Calculated index-level P/E using harmonic means"** - the mathematically correct method that prevents high-P/E outliers from distorting results. For example, a stock with P/E of 200 shouldn't dominate the index calculation.

✅ **"Built multi-period return analysis"** - covering daily to 5-year CAGR, handling 2,709 trading days with proper annualization formulas using POWER functions.

✅ **"Implemented rolling volatility calculations"** - with SQRT(252) scaling for annualization. S&P 500 currently at 19.7% annual volatility vs S&P 100 at 18.5%.

✅ **"Calculated Sharpe ratios"** - showing S&P 500 at 0.90 vs S&P 100 at 0.73, demonstrating better risk-adjusted returns in the broader index.

✅ **"Tracked maximum drawdown of -33.9%"** - measuring peak-to-trough declines for risk management. Both indices currently at all-time highs (0 days since peak).

✅ **"Analyzed sector concentration"** - showing Technology at ~30% of index weight with higher P/E ratios, identifying concentration risk.

✅ **"Discovered valuation insights"** - S&P 100 trades at 30.5x P/E vs S&P 500 at 29.4x, with mega-caps commanding a valuation premium despite similar profitability.

### Advanced SQL & Data Engineering

✅ **"Used LAG window functions"** - for efficient time-series calculations, computing 1Y returns by comparing current price vs LAG(price, 252).

✅ **"Implemented rolling window aggregations"** - STDDEV OVER with 252-day windows for volatility metrics, avoiding expensive self-joins.

✅ **"Built 12 analytics and performance models"** - processing 21,000+ rows of daily metrics across multiple time horizons.

✅ **"Handled PostgreSQL type casting issues"** - converting DOUBLE PRECISION → NUMERIC for proper rounding with ::numeric casts.

✅ **"Created modular SQL with CTEs"** - separating price lags, return calculations, and final output for maintainability and debugging.

✅ **"Implemented custom dbt schema macros"** - to override default schema naming and control table placement (analytics vs performance schemas).

✅ **"Used harmonic mean aggregations"** - mathematically correct formula: 1 / SUM(weight / ratio) for index-level P/E calculations.

✅ **"Built star schema"** - with 3 dimensions and multiple fact tables enabling complex joins across time, stocks, and indices.

### Business Impact & Insights

✅ **"S&P 500 showing 21.6% 1-year return vs 26.5% 3-year CAGR"** - indicating recent underperformance vs longer-term trend, suggesting mean reversion potential.

✅ **"Top 10 holdings represent ~35% of index weight"** - significant concentration risk in mega-cap technology stocks (NVDA, MSFT, AAPL).

✅ **"S&P 100 trades at higher valuation multiple (30.5x P/E) but lower Sharpe ratio (0.73)"** - suggesting mega-caps are expensive relative to risk-adjusted returns.

✅ **"Maximum drawdown analysis"** - shows both indices have fully recovered to all-time highs, with historical worst decline at -33.9%.

✅ **"3-year total returns of 102% (S&P 500) vs 84% (S&P 100)"** - broader market outperforming mega-caps over intermediate term.

### Problem-Solving & Technical Challenges

✅ **"Debugged schema naming conflicts"** - between dbt and PostgreSQL, created custom macro to override default behavior.

✅ **"Fixed column name mismatches"** - (trailing_pe vs pe_ratio, price_to_book vs pb_ratio) by querying information_schema.

✅ **"Resolved PostgreSQL function errors"** - ROUND(double precision) not supported, required ::numeric casting for proper rounding.

✅ **"Handled IGNORE NULLS syntax"** - not supported in PostgreSQL version, replaced with MAX(CASE WHEN) pattern for peak date tracking.

✅ **"Built idempotent pipelines"** - safe to re-run without duplicates using proper primary keys and upsert logic.

✅ **"Implemented comprehensive NULL handling"** - handling 'nan', '', NULL consistently across all transformations.

---

## 🔧 How to Run

### Start Dagster UI
```bash
cd C:\Users\Windows\Desktop\Coding\git-nonocho\index-dashboard
dagster dev -m dagster_project
```
Access at: http://localhost:3000

### Run dbt Transformations
```bash
cd financial_index_dbt

# Run all staging models (Silver layer)
dbt run --select staging

# Run all dimension models
dbt run --select marts.dimensions

# Run all fact models
dbt run --select marts.facts

# Run analytics models
dbt run --select marts.analytics

# Run performance models
dbt run --select marts.performance

# Run everything
dbt run

# Run with full refresh
dbt run --full-refresh
```

### Query the Database
```bash
psql -U postgres -d financial_index_db
```

**Example Queries:**

```sql
-- Latest performance summary
SELECT 
    r.index_name,
    r.annual_return_pct AS "1Y %",
    r.return_3y_annualized_pct AS "3Y CAGR %",
    r.return_5y_annualized_pct AS "5Y CAGR %",
    v.volatility_252d_pct AS "Vol %",
    s.sharpe_ratio_1y AS "Sharpe",
    d.max_drawdown_all_time_pct AS "Max DD %"
FROM performance.fct_index_returns r
JOIN performance.fct_index_volatility v 
    ON r.price_date = v.price_date AND r.index_code = v.index_code
JOIN performance.fct_index_sharpe s
    ON r.price_date = s.price_date AND r.index_code = s.index_code
JOIN performance.fct_index_drawdown d
    ON r.price_date = d.price_date AND r.index_code = d.index_code
WHERE r.price_date = (SELECT MAX(price_date) FROM performance.fct_index_returns)
ORDER BY r.index_name;

-- Top 10 holdings with valuations
SELECT 
    holding_rank,
    ticker,
    company_name,
    sector,
    weight_pct,
    cumulative_weight_pct,
    market_cap_billions,
    pe_ratio,
    dividend_yield_pct
FROM analytics.fct_top10_holdings
WHERE index_name = 'S&P 500'
ORDER BY holding_rank;

-- Sector allocation
SELECT 
    sector,
    sector_weight_pct,
    company_count,
    sector_avg_pe,
    sector_avg_roe_pct
FROM analytics.fct_index_sector_weights
WHERE index_name = 'S&P 500'
ORDER BY sector_weight_pct DESC;
```

---

## 📝 Notes & Lessons Learned

### Technical Challenges Solved

**1. dbt Schema Naming Issue**
- **Problem:** dbt was creating `silver_silver` schema instead of `silver`
- **Solution:** Created custom `generate_schema_name` macro to override default behavior
- **Learning:** dbt appends custom schema to target schema by default

**2. Column Name Mismatches**
- **Problem:** `trailing_pe` vs `pe_ratio`, `price_to_book` vs `pb_ratio`
- **Solution:** Queried `information_schema.columns` to verify actual column names
- **Learning:** Always verify schema before writing SQL

**3. PostgreSQL ROUND Function**
- **Problem:** `ROUND(double precision, integer)` doesn't exist
- **Solution:** Cast to NUMERIC first: `ROUND(value::numeric, 2)`
- **Learning:** PostgreSQL has strict type requirements

**4. IGNORE NULLS Syntax**
- **Problem:** `LAG(...) IGNORE NULLS OVER (...)` not supported
- **Solution:** Used `MAX(CASE WHEN condition THEN value END) OVER (...)`
- **Learning:** Different SQL dialects have different window function features

**5. Ambiguous Column Names**
- **Problem:** `return_3y` appeared in multiple CTEs causing ambiguity
- **Solution:** Renamed to `return_3y_total` and `return_3y_cagr` for clarity
- **Learning:** Use descriptive names to avoid CTE column conflicts

### Best Practices Implemented

✅ **Idempotent pipelines** - Safe to re-run without duplicates  
✅ **Source file tracking** - All Bronze tables track origin CSV  
✅ **Timestamp audit columns** - created_at, updated_at, loaded_at  
✅ **Comprehensive NULL handling** - Handle 'nan', '', NULL consistently  
✅ **DISTINCT ON for deduplication** - Efficient row selection  
✅ **Proper NUMERIC precision** - Financial data uses NUMERIC(20,2)  
✅ **Custom schema macros** - Control table placement explicitly  
✅ **Foreign key relationships** - Enforce referential integrity in queries  
✅ **Modular CTEs** - Break complex queries into readable steps  
✅ **Data quality metrics** - Track how many records contributed to each calculation

---

## 🔗 Resources

- [Dagster Documentation](https://docs.dagster.io/)
- [dbt Documentation](https://docs.getdbt.com/)
- [PostgreSQL Numeric Types](https://www.postgresql.org/docs/current/datatype-numeric.html)
- [EODHD API Documentation](https://eodhd.com/financial-apis/)
- [Kimball Dimensional Modeling](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/)

---

**Last Updated:** October 10, 2025  
**Current Phase:** Phase 6 (Custom Indices) - Ready to Start  
**Project Status:** On Track ✅ | **Phase 5 COMPLETE!** (Analytics + Performance)

---

## 🎉 Phase 5 Achievement Unlocked!

You now have a production-quality dimensional data warehouse with:

✅ **3 dimension tables** (18,806 total rows)  
✅ **1 core fact table** (604 records with perfect star schema joins)  
✅ **4 analytics models** (index valuations, holdings, sectors, market cap)  
✅ **4 performance models** (returns, volatility, Sharpe, drawdown)  
✅ **Complete data lineage** from Bronze → Silver → Gold  
✅ **Point-in-time accurate analytics** capability  
✅ **10+ years of daily performance metrics**  
✅ **Foundation for custom index construction**

**Next session:** Build custom indices (equal-weight, low-vol, high-div, value, quality) and compare their performance! 🚀