# dagster_project/assets/bronze_ingestion.py
"""
Bronze Layer Ingestion Assets
Loads raw CSV files into PostgreSQL Bronze tables.
"""

import os
import pandas as pd
from datetime import datetime
from dagster import asset, AssetExecutionContext
from ..resources.database import PostgresResource


# Base paths
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
DATA_RAW_PATH = os.path.join(PROJECT_ROOT, "data", "raw")


@asset(
    group_name="bronze_layer",
    description="Load S&P 500 current constituents from CSV to Bronze table"
)
def bronze_sp500_constituents_current(
    context: AssetExecutionContext,
    database: PostgresResource
) -> None:
    """
    Loads S&P 500 current constituents CSV into bronze.raw_index_constituents_current.
    
    Source: data/raw/indices/sandp_500_constituents_current.csv
    Target: bronze.raw_index_constituents_current
    """
    
    # Read CSV
    csv_path = os.path.join(DATA_RAW_PATH, "indices", "sandp_500_constituents_current.csv")
    context.log.info(f"Reading CSV from: {csv_path}")
    
    df = pd.read_csv(csv_path)
    context.log.info(f"Loaded {len(df)} rows from CSV")
    
    # Clear existing data (idempotent loading)
    delete_query = """
        DELETE FROM bronze.raw_index_constituents_current 
        WHERE source_file = %s;
    """
    database.execute_query(delete_query, ('sandp_500_constituents_current.csv',))
    
    # Prepare data for insertion
    loaded_at = datetime.now()
    source_file = 'sandp_500_constituents_current.csv'
    
    data_to_insert = []
    for _, row in df.iterrows():
        data_to_insert.append((
            str(row.get('Code', '')),          # code
            str(row.get('Exchange', '')),      # exchange
            str(row.get('Name', '')),          # name
            str(row.get('Sector', '')),        # sector
            str(row.get('Industry', '')),      # industry
            str(row.get('Weight', '')),        # weight
            str(row.get('IndexCode', '')),     # index_code
            str(row.get('AsOfDate', '')),      # as_of_date
            loaded_at,                         # loaded_at
            source_file                        # source_file
        ))
    
    # Bulk insert
    columns = [
        'code', 'exchange', 'name', 'sector', 'industry', 
        'weight', 'index_code', 'as_of_date', 'loaded_at', 'source_file'
    ]
    
    rows_inserted = database.bulk_insert(
        'bronze.raw_index_constituents_current',
        columns,
        data_to_insert
    )
    
    context.log.info(f"✅ Inserted {rows_inserted} rows into bronze.raw_index_constituents_current")


@asset(
    group_name="bronze_layer",
    description="Load S&P 100 current constituents from CSV to Bronze table"
)
def bronze_sp100_constituents_current(
    context: AssetExecutionContext,
    database: PostgresResource
) -> None:
    """
    Loads S&P 100 current constituents CSV into bronze.raw_index_constituents_current.
    
    Source: data/raw/indices/sandp_100_constituents_current.csv
    Target: bronze.raw_index_constituents_current
    """
    
    csv_path = os.path.join(DATA_RAW_PATH, "indices", "sandp_100_constituents_current.csv")
    context.log.info(f"Reading CSV from: {csv_path}")
    
    df = pd.read_csv(csv_path)
    context.log.info(f"Loaded {len(df)} rows from CSV")
    
    # Clear existing data
    delete_query = """
        DELETE FROM bronze.raw_index_constituents_current 
        WHERE source_file = %s;
    """
    database.execute_query(delete_query, ('sandp_100_constituents_current.csv',))
    
    # Prepare data
    loaded_at = datetime.now()
    source_file = 'sandp_100_constituents_current.csv'
    
    data_to_insert = []
    for _, row in df.iterrows():
        data_to_insert.append((
            str(row.get('Code', '')),
            str(row.get('Exchange', '')),
            str(row.get('Name', '')),
            str(row.get('Sector', '')),
            str(row.get('Industry', '')),
            str(row.get('Weight', '')),
            str(row.get('IndexCode', '')),
            str(row.get('AsOfDate', '')),
            loaded_at,
            source_file
        ))
    
    columns = [
        'code', 'exchange', 'name', 'sector', 'industry',
        'weight', 'index_code', 'as_of_date', 'loaded_at', 'source_file'
    ]
    
    rows_inserted = database.bulk_insert(
        'bronze.raw_index_constituents_current',
        columns,
        data_to_insert
    )
    
    context.log.info(f"✅ Inserted {rows_inserted} rows into bronze.raw_index_constituents_current")


@asset(
    group_name="bronze_layer",
    description="Load S&P 500 historical constituents from CSV to Bronze table"
)
def bronze_sp500_constituents_historical(
    context: AssetExecutionContext,
    database: PostgresResource
) -> None:
    """
    Loads S&P 500 historical constituents CSV into bronze.raw_index_constituents_historical.
    
    Source: data/raw/indices/sandp_500_constituents_historical.csv
    Target: bronze.raw_index_constituents_historical
    """
    
    csv_path = os.path.join(DATA_RAW_PATH, "indices", "sandp_500_constituents_historical.csv")
    context.log.info(f"Reading CSV from: {csv_path}")
    
    df = pd.read_csv(csv_path)
    context.log.info(f"Loaded {len(df)} rows from CSV")
    
    # Clear existing data
    delete_query = """
        DELETE FROM bronze.raw_index_constituents_historical 
        WHERE source_file = %s;
    """
    database.execute_query(delete_query, ('sandp_500_constituents_historical.csv',))
    
    # Prepare data
    loaded_at = datetime.now()
    source_file = 'sandp_500_constituents_historical.csv'
    
    data_to_insert = []
    for _, row in df.iterrows():
        data_to_insert.append((
            str(row.get('Code', '')),
            str(row.get('Name', '')),
            str(row.get('StartDate', '')),
            str(row.get('EndDate', '')),
            str(row.get('IsActiveNow', '')),
            str(row.get('IsDelisted', '')),
            str(row.get('IndexCode', '')),
            loaded_at,
            source_file
        ))
    
    columns = [
        'code', 'name', 'start_date', 'end_date', 'is_active_now',
        'is_delisted', 'index_code', 'loaded_at', 'source_file'
    ]
    
    rows_inserted = database.bulk_insert(
        'bronze.raw_index_constituents_historical',
        columns,
        data_to_insert
    )
    
    context.log.info(f"✅ Inserted {rows_inserted} rows into bronze.raw_index_constituents_historical")


@asset(
    group_name="bronze_layer",
    description="Load S&P 100 historical constituents from CSV to Bronze table"
)
def bronze_sp100_constituents_historical(
    context: AssetExecutionContext,
    database: PostgresResource
) -> None:
    """
    Loads S&P 100 historical constituents CSV into bronze.raw_index_constituents_historical.
    
    Source: data/raw/indices/sandp_100_constituents_historical.csv
    Target: bronze.raw_index_constituents_historical
    """
    
    csv_path = os.path.join(DATA_RAW_PATH, "indices", "sandp_100_constituents_historical.csv")
    context.log.info(f"Reading CSV from: {csv_path}")
    
    df = pd.read_csv(csv_path)
    context.log.info(f"Loaded {len(df)} rows from CSV")
    
    # Clear existing data
    delete_query = """
        DELETE FROM bronze.raw_index_constituents_historical 
        WHERE source_file = %s;
    """
    database.execute_query(delete_query, ('sandp_100_constituents_historical.csv',))
    
    # Prepare data
    loaded_at = datetime.now()
    source_file = 'sandp_100_constituents_historical.csv'
    
    data_to_insert = []
    for _, row in df.iterrows():
        data_to_insert.append((
            str(row.get('Code', '')),
            str(row.get('Name', '')),
            str(row.get('StartDate', '')),
            str(row.get('EndDate', '')),
            str(row.get('IsActiveNow', '')),
            str(row.get('IsDelisted', '')),
            str(row.get('IndexCode', '')),
            loaded_at,
            source_file
        ))
    
    columns = [
        'code', 'name', 'start_date', 'end_date', 'is_active_now',
        'is_delisted', 'index_code', 'loaded_at', 'source_file'
    ]
    
    rows_inserted = database.bulk_insert(
        'bronze.raw_index_constituents_historical',
        columns,
        data_to_insert
    )
    
    context.log.info(f"✅ Inserted {rows_inserted} rows into bronze.raw_index_constituents_historical")

@asset(
    group_name="bronze_layer",
    description="Load index prices (base 100) from CSV to Bronze table"
)
def bronze_index_prices_base100(
    context: AssetExecutionContext,
    database: PostgresResource
) -> None:
    """
    Loads index prices CSV into bronze.raw_index_prices_base100.
    
    Source: data/raw/prices/index_prices_base100.csv
    Target: bronze.raw_index_prices_base100
    
    CSV format: date, index_name, close, base_100 (already in long format)
    """
    
    csv_path = os.path.join(DATA_RAW_PATH, "prices", "index_prices_base100.csv")
    context.log.info(f"Reading CSV from: {csv_path}")
    
    df = pd.read_csv(csv_path)
    context.log.info(f"Loaded {len(df)} rows from CSV")
    
    # Clear existing data
    delete_query = "DELETE FROM bronze.raw_index_prices_base100 WHERE source_file = %s;"
    database.execute_query(delete_query, ('index_prices_base100.csv',))
    
    # Prepare data - CSV is already in the right format!
    loaded_at = datetime.now()
    source_file = 'index_prices_base100.csv'
    
    data_to_insert = []
    for _, row in df.iterrows():
        data_to_insert.append((
            str(row.get('date', '')),           # date
            str(row.get('index_name', '')),     # index_name
            str(row.get('close', '')),          # close
            str(row.get('base_100', '')),       # base_100
            loaded_at,                          # loaded_at
            source_file                         # source_file
        ))
    
    columns = ['date', 'index_name', 'close', 'base_100', 'loaded_at', 'source_file']
    
    rows_inserted = database.bulk_insert(
        'bronze.raw_index_prices_base100',
        columns,
        data_to_insert
    )
    
    context.log.info(f"✅ Inserted {rows_inserted} rows into bronze.raw_index_prices_base100")
    
@asset(
    group_name="bronze_layer",
    description="Load stock valuation metrics from CSV to Bronze table"
)
def bronze_stock_valuation_metrics(
    context: AssetExecutionContext,
    database: PostgresResource
) -> None:
    """
    Loads stock valuation metrics CSV into bronze.raw_stock_valuation_metrics.
    
    Source: data/raw/fundamentals/stock_valuation_metrics.csv
    Target: bronze.raw_stock_valuation_metrics
    """
    
    csv_path = os.path.join(DATA_RAW_PATH, "fundamentals", "stock_valuation_metrics.csv")
    context.log.info(f"Reading CSV from: {csv_path}")
    
    df = pd.read_csv(csv_path)
    context.log.info(f"Loaded {len(df)} rows from CSV")
    
    # Clear existing data
    delete_query = "DELETE FROM bronze.raw_stock_valuation_metrics WHERE source_file = %s;"
    database.execute_query(delete_query, ('stock_valuation_metrics.csv',))
    
    # Prepare data - MAP CSV columns (camelCase) to DB columns (snake_case)
    loaded_at = datetime.now()
    source_file = 'stock_valuation_metrics.csv'
    
    # Column mapping: CSV column -> DB column
    column_mapping = {
        'ticker': 'ticker',
        'shortName': 'short_name',
        'longName': 'long_name',
        'marketCap': 'market_cap',
        'trailingPE': 'trailing_pe',
        'forwardPE': 'forward_pe',
        'priceToBook': 'price_to_book',
        'priceToSalesTrailing12Months': 'price_to_sales_trailing_12_months',
        'beta': 'beta',
        'dividendYield': 'dividend_yield',
        'dividendRate': 'dividend_rate',
        'profitMargins': 'profit_margins',
        'returnOnEquity': 'return_on_equity',
        'returnOnAssets': 'return_on_assets',
        'revenueGrowth': 'revenue_growth',
        'earningsGrowth': 'earnings_growth',
        'fiftyTwoWeekHigh': 'fifty_two_week_high',
        'fiftyTwoWeekLow': 'fifty_two_week_low',
        'currentPrice': 'current_price',
        'volume': 'volume',
        'data_fetched_at': 'data_fetched_at'
    }
    
    data_to_insert = []
    for _, row in df.iterrows():
        row_data = []
        # Map CSV columns to database columns in correct order
        for db_col in column_mapping.values():
            # Find the CSV column that maps to this DB column
            csv_col = [k for k, v in column_mapping.items() if v == db_col][0]
            value = row.get(csv_col, '')
            row_data.append(str(value) if pd.notna(value) else '')
        
        row_data.extend([loaded_at, source_file])
        data_to_insert.append(tuple(row_data))
    
    # Database columns in order
    columns = list(column_mapping.values()) + ['loaded_at', 'source_file']
    
    rows_inserted = database.bulk_insert(
        'bronze.raw_stock_valuation_metrics',
        columns,
        data_to_insert
    )
    
    context.log.info(f"✅ Inserted {rows_inserted} rows into bronze.raw_stock_valuation_metrics")