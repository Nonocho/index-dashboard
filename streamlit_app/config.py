# config.py
"""
Configuration file for Index Analytics Dashboard
Contains color scheme, database settings, and constants
"""

import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Color Scheme - Modern Purple to Orange Gradient
INDEX_COLORS = {
    'primary': '#2B1773',      # Deep Purple
    'secondary': '#0D5673',    # Teal Blue
    'accent': '#F2E857',       # Bright Yellow
    'warning': '#F2913D',      # Orange
    'highlight': '#F26D3D',    # Coral Red
    'light': '#F5F5F5',        # Light grey
    'dark': '#2C3E50'          # Dark blue-grey
}

# Chart colors (5-color palette for multiple series)
CHART_COLORS = [
    INDEX_COLORS['primary'],    # Purple
    INDEX_COLORS['secondary'],  # Teal
    INDEX_COLORS['warning'],    # Orange
    INDEX_COLORS['highlight'],  # Coral
    INDEX_COLORS['accent']      # Yellow
]

# Database connection settings (read from .env)
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'database': os.getenv('DB_NAME', 'financial_index_db'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD'),
    'port': int(os.getenv('DB_PORT', 5432))
}

# Available indices
INDICES = {
    'GSPC.INDX': 'S&P 500',
    'OEX.INDX': 'S&P 100'
}

# Dashboard settings
DASHBOARD_TITLE = "📊 Index Analytics Dashboard"
DASHBOARD_SUBTITLE = "S&P 500 vs S&P 100 Performance Analysis"