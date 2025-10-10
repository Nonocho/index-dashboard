# dagster/assets/__init__.py
"""
Asset definitions for the Financial Index Analytics Platform.
"""

from .bronze_ingestion import (
    bronze_sp500_constituents_current,
    bronze_sp100_constituents_current,
    bronze_sp500_constituents_historical,
    bronze_sp100_constituents_historical,
    bronze_index_prices_base100,
    bronze_stock_valuation_metrics,
)

__all__ = [
    "bronze_sp500_constituents_current",
    "bronze_sp100_constituents_current",
    "bronze_sp500_constituents_historical",
    "bronze_sp100_constituents_historical",
    "bronze_index_prices_base100",
    "bronze_stock_valuation_metrics",
]