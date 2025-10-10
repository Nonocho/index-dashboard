# dagster_project/__init__.py
"""
Dagster definitions for Financial Index Analytics Platform.
"""

from dagster import Definitions
from .resources.database import get_postgres_resource
from .assets import (
    bronze_sp500_constituents_current,
    bronze_sp100_constituents_current,
    bronze_sp500_constituents_historical,
    bronze_sp100_constituents_historical,
    bronze_index_prices_base100,
    bronze_stock_valuation_metrics,
)

defs = Definitions(
    assets=[
        bronze_sp500_constituents_current,
        bronze_sp100_constituents_current,
        bronze_sp500_constituents_historical,
        bronze_sp100_constituents_historical,
        bronze_index_prices_base100,
        bronze_stock_valuation_metrics,
    ],
    resources={
        "database": get_postgres_resource(),
    },
)