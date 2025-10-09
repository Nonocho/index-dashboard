# 📊 Financial Index Analytics Platform

> A modern data engineering portfolio project showcasing quantitative finance expertise with production-grade data infrastructure.

[![Python](https://img.shields.io/badge/Python-3.9+-blue.svg)](https://www.python.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-336791.svg)](https://www.postgresql.org/)
[![Dagster](https://img.shields.io/badge/Dagster-Latest-blueviolet.svg)](https://dagster.io/)
[![dbt](https://img.shields.io/badge/dbt-Latest-orange.svg)](https://www.getdbt.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 🎯 Project Overview

**Financial Index Analytics Platform** is an end-to-end data engineering project that combines:
- **68 years** of S&P 500 historical constituent data (1957-2025)
- **Modern data stack** (Dagster + dbt + PostgreSQL + Streamlit)
- **Quantitative finance** domain expertise (custom index construction, risk analytics)


- ✅ **Real financial data**: S&P 500/100 constituents, not toy datasets
- ✅ **Survivorship-bias-free**: Historical constituent changes with exact dates
- ✅ **Production-quality**: Proper data architecture, testing, documentation
- ✅ **Interview-ready**: Demonstrates both finance + engineering expertise

---

## 🚀 Quick Start

### Prerequisites

- Python 3.9+
- PostgreSQL 14+ (optional for now)
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/index-dashboard.git
cd index-dashboard

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set up environment variables
cp .env.example .env
# Edit .env and add your EODHD_API_TOKEN
```

### Run Data Acquisition (Phase 1)

```bash
# Navigate to notebooks
cd notebooks

# Launch Jupyter
jupyter notebook

# Open and run: 01_data_acquisition_exploration.ipynb
```

---

## 📁 Project Structure

```
index-dashboard/
├── data/
│   ├── raw/                    # Bronze layer - raw data from APIs
│   │   ├── indices/           # Index constituents (EODHD)
│   │   ├── prices/            # Index prices (Yahoo Finance)
│   │   └── fundamentals/      # Valuation metrics (Yahoo Finance)
│   └── processed/             # Silver/Gold layers (coming soon)
│
├── notebooks/
│   └── 01_data_acquisition_exploration.ipynb
│
├── dagster/                   # Orchestration (Phase 3)
│   └── (coming soon)
│
├── dbt_project/              # Transformations (Phase 4)
│   └── (coming soon)
│
├── streamlit_app/            # Dashboards (Phase 6)
│   └── (coming soon)
│
├── .env.example              # Environment template
├── .gitignore
├── requirements.txt
├── README.md
└── project.md                # Detailed technical documentation
```

---

## 📊 Data Sources

### 1. EODHD Marketplace API (€29 one-time)
- **S&P 500 constituents**: 503 current + 794 historical (1957-2025)
- **S&P 100 constituents**: 101 current + 158 historical (2013-2025)
- **Index weights**: For proper cap-weighted calculations
- **Total coverage**: 794 unique tickers

### 2. Yahoo Finance (Free)
- **Index prices**: 10 years daily data (^GSPC, ^OEX)
- **Valuation metrics**: P/E, P/B, market cap, beta, dividends
- **Coverage**: All 794 tickers, $64.7T total market cap

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────┐
│              DATA SOURCES                         │
│  EODHD API          │    Yahoo Finance           │
│  (Constituents)     │    (Prices, Valuations)    │
└──────────────────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────┐
│         ORCHESTRATION: Dagster                    │
│         (Asset-based pipeline)                    │
└──────────────────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────┐
│    STORAGE: PostgreSQL (Medallion Architecture)  │
│                                                   │
│    Bronze → Silver → Gold                        │
│    (Raw)    (Clean)   (Analytics)               │
└──────────────────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────┐
│    TRANSFORMATION: dbt                            │
│    (SQL-based models)                            │
└──────────────────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────┐
│    VISUALIZATION: Streamlit                       │
│    (Interactive dashboards)                      │
└──────────────────────────────────────────────────┘
```