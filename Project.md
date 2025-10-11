**Tech Stack:**
- **Orchestration:** Dagster (asset-based pipeline)
- **Transformation:** dbt-core (medallion architecture)
- **Database:** PostgreSQL 15.3
- **Frontend:** Streamlit + Plotly
- **Language:** Python 3.12

## 📈 Features

### 1. **Overview Dashboard**
- Key performance indicators (1Y, 3Y, 5Y returns)
- Risk-adjusted metrics (Sharpe ratio, volatility)
- Interactive performance comparison charts

### 2. **Stock Screener**
- Multi-criteria filtering (P/E, ROE, dividend yield, beta)
- Sector-based screening
- Portfolio metrics calculation
- Export results to CSV

### 3. **Sector Analysis**
- Sector allocation pie/bar charts
- Sector-level valuation metrics
- Top 10 holdings with concentration analysis

### 4. **Risk Metrics**
- Rolling volatility (30D, 90D, 252D windows)
- Maximum drawdown tracking
- Days since all-time high

## 🗄️ Data Model

**Bronze Layer:** Raw data from API  
**Silver Layer:** Cleaned and typed staging tables  
**Gold Layer:** Star schema with dimensions and facts  
**Analytics Layer:** Pre-aggregated business metrics  
**Performance Layer:** Time-series calculations

**Key Tables:**
- `dim_dates` (18,002 business days)
- `dim_stocks` (794 constituents)
- `fct_index_returns` (5,418 daily observations)
- `fct_index_volatility`, `fct_index_sharpe`, `fct_index_drawdown`

## 🚀 Quick Start

### Prerequisites
- Python 3.12+
- PostgreSQL 15.3+
- EODHD API token

### Installation
```bash
# Clone repository
git clone https://github.com/yourusername/index-analytics-dashboard.git
cd index-analytics-dashboard

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
cd streamlit_app
pip install -r requirements.txt

# Set up environment variables
cp .env.example .env
# Edit .env with your credentials

# Run dashboard
streamlit run app.py