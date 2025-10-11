# utils.py
"""
Utility functions for Index Analytics Dashboard
Database connections, queries, and chart generation
"""

# Load environment first
from dotenv import load_dotenv
import os
load_dotenv()

# Now import everything else
import streamlit as st
import pandas as pd
import numpy as np
import psycopg2
from psycopg2.extras import RealDictCursor
import plotly.graph_objects as go
import plotly.express as px
from datetime import datetime
from config import INDEX_COLORS, CHART_COLORS, DB_CONFIG, INDICES

# ==================== DATABASE FUNCTIONS ====================

@st.cache_resource
def get_database_connection():
    """Create cached PostgreSQL connection"""
    try:
        conn = psycopg2.connect(
            host=DB_CONFIG['host'],
            database=DB_CONFIG['database'],
            user=DB_CONFIG['user'],
            password=DB_CONFIG['password'],
            port=DB_CONFIG['port']
        )
        return conn
    except Exception as e:
        st.error(f"❌ Database connection failed: {e}")
        return None

@st.cache_data(ttl=600)  # Cache for 10 minutes
def get_latest_metrics(index_code=None):
    """Get latest performance metrics for index/indices"""
    conn = get_database_connection()
    if not conn:
        return pd.DataFrame()
    
    query = """
    SELECT 
        r.index_name,
        r.annual_return_pct AS "1Y Return %",
        r.return_3y_annualized_pct AS "3Y CAGR %",
        r.return_5y_annualized_pct AS "5Y CAGR %",
        r.ytd_return_pct AS "YTD %",
        v.volatility_252d_pct AS "Volatility %",
        s.sharpe_ratio_1y AS "Sharpe Ratio",
        d.max_drawdown_all_time_pct AS "Max Drawdown %",
        d.days_since_ath AS "Days Since ATH"
    FROM performance.fct_index_returns r
    JOIN performance.fct_index_volatility v 
        ON r.price_date = v.price_date AND r.index_code = v.index_code
    JOIN performance.fct_index_sharpe s
        ON r.price_date = s.price_date AND r.index_code = s.index_code
    JOIN performance.fct_index_drawdown d
        ON r.price_date = d.price_date AND r.index_code = d.index_code
    WHERE r.price_date = (SELECT MAX(price_date) FROM performance.fct_index_returns)
    """
    
    if index_code:
        query += f" AND r.index_code = '{index_code}'"
    
    query += " ORDER BY r.index_name"
    
    try:
        df = pd.read_sql(query, conn)
        return df
    except Exception as e:
        st.error(f"Query failed: {e}")
        return pd.DataFrame()

@st.cache_data(ttl=600)
def get_index_performance(index_code, start_date=None):
    """Get historical performance data for line chart"""
    conn = get_database_connection()
    if not conn:
        return pd.DataFrame()
    
    query = f"""
    SELECT 
        price_date,
        index_name,
        close_price,
        ytd_return_pct AS cumulative_return_pct
    FROM performance.fct_index_returns
    WHERE index_code = '{index_code}'
    """
    
    if start_date:
        query += f" AND price_date >= '{start_date}'"
    
    query += " ORDER BY price_date"
    
    try:
        df = pd.read_sql(query, conn)
        df['price_date'] = pd.to_datetime(df['price_date'])
        return df
    except Exception as e:
        st.error(f"Query failed: {e}")
        return pd.DataFrame()

@st.cache_data(ttl=600)
def get_sector_weights(index_code):
    """Get sector allocation for pie/bar chart"""
    conn = get_database_connection()
    if not conn:
        return pd.DataFrame()
    
    query = f"""
    SELECT 
        sector,
        sector_weight_pct,
        company_count,
        sector_avg_pe,
        sector_avg_roe_pct
    FROM analytics.fct_index_sector_weights
    WHERE index_code = '{index_code}'
    ORDER BY sector_weight_pct DESC
    """
    
    try:
        df = pd.read_sql(query, conn)
        return df
    except Exception as e:
        st.error(f"Query failed: {e}")
        return pd.DataFrame()

@st.cache_data(ttl=600)
def get_top_holdings(index_code, n=10):
    """Get top N holdings"""
    conn = get_database_connection()
    if not conn:
        return pd.DataFrame()
    
    query = f"""
    SELECT 
        holding_rank,
        ticker,
        company_name,
        sector,
        weight_pct,
        market_cap_billions,
        pe_ratio,
        dividend_yield_pct
    FROM analytics.fct_top10_holdings
    WHERE index_code = '{index_code}'
    ORDER BY holding_rank
    LIMIT {n}
    """
    
    try:
        df = pd.read_sql(query, conn)
        return df
    except Exception as e:
        st.error(f"Query failed: {e}")
        return pd.DataFrame()

@st.cache_data(ttl=600)
def get_all_stocks():
    """Get all stocks with fundamentals for screener"""
    conn = get_database_connection()
    if not conn:
        return pd.DataFrame()
    
    query = """
    SELECT 
        ticker,
        company_name,
        sector,
        industry,
        trailing_pe AS pe_ratio_trailing,
        return_on_equity * 100 AS roe_pct,
        dividend_yield * 100 AS dividend_yield_pct,
        beta,
        market_cap / 1000000000 AS market_cap_billions,
        current_price
    FROM gold.dim_stocks
    WHERE is_current_constituent = TRUE
    AND trailing_pe IS NOT NULL
    AND trailing_pe > 0
    ORDER BY market_cap DESC
    """
    
    try:
        df = pd.read_sql(query, conn)
        return df
    except Exception as e:
        st.error(f"Query failed: {e}")
        return pd.DataFrame()

@st.cache_data(ttl=600)
def get_volatility_chart_data(index_code):
    """Get rolling volatility for chart"""
    conn = get_database_connection()
    if not conn:
        return pd.DataFrame()
    
    query = f"""
    SELECT 
        price_date,
        index_name,
        volatility_30d_pct,
        volatility_90d_pct,
        volatility_252d_pct
    FROM performance.fct_index_volatility
    WHERE index_code = '{index_code}'
    AND price_date >= CURRENT_DATE - INTERVAL '2 years'
    ORDER BY price_date
    """
    
    try:
        df = pd.read_sql(query, conn)
        df['price_date'] = pd.to_datetime(df['price_date'])
        return df
    except Exception as e:
        st.error(f"Query failed: {e}")
        return pd.DataFrame()

@st.cache_data(ttl=600)
def get_drawdown_chart_data(index_code):
    """Get drawdown data for chart"""
    conn = get_database_connection()
    if not conn:
        return pd.DataFrame()
    
    query = f"""
    SELECT 
        price_date,
        index_name,
        current_drawdown_from_ath_pct AS drawdown_from_peak_pct,
        days_since_ath AS days_in_drawdown
    FROM performance.fct_index_drawdown
    WHERE index_code = '{index_code}'
    AND price_date >= CURRENT_DATE - INTERVAL '5 years'
    ORDER BY price_date
    """
    
    try:
        df = pd.read_sql(query, conn)
        df['price_date'] = pd.to_datetime(df['price_date'])
        return df
    except Exception as e:
        st.error(f"Query failed: {e}")
        return pd.DataFrame()

# ==================== CHART FUNCTIONS ====================

def create_kpi_card(label, value, delta=None, delta_color="normal"):
    """Create a styled KPI card"""
    st.metric(
        label=label,
        value=value,
        delta=delta,
        delta_color=delta_color
    )

def create_performance_chart(df_sp500, df_sp100=None):
    """Create multi-line performance comparison chart"""
    fig = go.Figure()
    
    # Add S&P 500 line
    fig.add_trace(go.Scatter(
        x=df_sp500['price_date'],
        y=df_sp500['cumulative_return_pct'],
        mode='lines',
        name='S&P 500',
        line=dict(color=CHART_COLORS[0], width=2.5),
        hovertemplate='<b>S&P 500</b><br>Date: %{x}<br>Return: %{y:.2f}%<extra></extra>'
    ))
    
    # Add S&P 100 line if provided
    if df_sp100 is not None and not df_sp100.empty:
        fig.add_trace(go.Scatter(
            x=df_sp100['price_date'],
            y=df_sp100['cumulative_return_pct'],
            mode='lines',
            name='S&P 100',
            line=dict(color=CHART_COLORS[1], width=2.5),
            hovertemplate='<b>S&P 100</b><br>Date: %{x}<br>Return: %{y:.2f}%<extra></extra>'
        ))
    
    fig.update_layout(
        title="Cumulative Returns Over Time (YTD)",
        xaxis_title="Date",
        yaxis_title="Return (%)",
        hovermode='x unified',
        template="plotly_white",
        height=500,
        legend=dict(
            orientation="h",
            yanchor="bottom",
            y=1.02,
            xanchor="right",
            x=1
        )
    )
    
    return fig

def create_sector_pie_chart(df):
    """Create sector allocation pie chart"""
    fig = px.pie(
        df,
        values='sector_weight_pct',
        names='sector',
        title='Sector Allocation',
        color_discrete_sequence=CHART_COLORS,
        hole=0.4  # Donut chart
    )
    
    fig.update_traces(
        textposition='outside',
        textinfo='label+percent',
        hovertemplate='<b>%{label}</b><br>Weight: %{value:.2f}%<br>Companies: %{customdata[0]}<extra></extra>',
        customdata=df[['company_count']].values
    )
    
    fig.update_layout(
        height=500,
        showlegend=True,
        legend=dict(
            orientation="v",
            yanchor="middle",
            y=0.5,
            xanchor="left",
            x=1.05
        )
    )
    
    return fig

def create_sector_bar_chart(df):
    """Create sector allocation bar chart"""
    fig = px.bar(
        df,
        x='sector_weight_pct',
        y='sector',
        orientation='h',
        title='Sector Weights (%)',
        color='sector_weight_pct',
        color_continuous_scale=[CHART_COLORS[0], CHART_COLORS[3]],
        text='sector_weight_pct'
    )
    
    fig.update_traces(
        texttemplate='%{text:.1f}%',
        textposition='outside',
        hovertemplate='<b>%{y}</b><br>Weight: %{x:.2f}%<extra></extra>'
    )
    
    fig.update_layout(
        height=400,
        showlegend=False,
        xaxis_title="Weight (%)",
        yaxis_title="",
        yaxis={'categoryorder':'total ascending'}
    )
    
    return fig

def create_volatility_chart(df):
    """Create rolling volatility chart"""
    fig = go.Figure()
    
    # 30-day volatility
    fig.add_trace(go.Scatter(
        x=df['price_date'],
        y=df['volatility_30d_pct'],
        mode='lines',
        name='30-Day Vol',
        line=dict(color=CHART_COLORS[4], width=1.5, dash='dot'),
        opacity=0.6
    ))
    
    # 90-day volatility
    fig.add_trace(go.Scatter(
        x=df['price_date'],
        y=df['volatility_90d_pct'],
        mode='lines',
        name='90-Day Vol',
        line=dict(color=CHART_COLORS[1], width=2)
    ))
    
    # 252-day (1-year) volatility
    fig.add_trace(go.Scatter(
        x=df['price_date'],
        y=df['volatility_252d_pct'],
        mode='lines',
        name='1-Year Vol',
        line=dict(color=CHART_COLORS[0], width=2.5)
    ))
    
    fig.update_layout(
        title="Rolling Volatility (Annualized %)",
        xaxis_title="Date",
        yaxis_title="Volatility (%)",
        hovermode='x unified',
        template="plotly_white",
        height=400,
        legend=dict(
            orientation="h",
            yanchor="bottom",
            y=1.02,
            xanchor="right",
            x=1
        )
    )
    
    return fig

def create_drawdown_chart(df):
    """Create drawdown chart"""
    fig = go.Figure()
    
    fig.add_trace(go.Scatter(
        x=df['price_date'],
        y=df['drawdown_from_peak_pct'],
        mode='lines',
        name='Drawdown',
        fill='tozeroy',
        line=dict(color=CHART_COLORS[3], width=2),
        fillcolor=f'rgba({int(INDEX_COLORS["highlight"][1:3], 16)}, {int(INDEX_COLORS["highlight"][3:5], 16)}, {int(INDEX_COLORS["highlight"][5:7], 16)}, 0.3)',
        hovertemplate='Date: %{x}<br>Drawdown: %{y:.2f}%<extra></extra>'
    ))
    
    fig.update_layout(
        title="Drawdown from All-Time High (%)",
        xaxis_title="Date",
        yaxis_title="Drawdown (%)",
        hovermode='x',
        template="plotly_white",
        height=400,
        showlegend=False
    )
    
    return fig

# ==================== UTILITY FUNCTIONS ====================

def format_percentage(value):
    """Format number as percentage"""
    if pd.isna(value):
        return "N/A"
    return f"{value:.2f}%"

def format_number(value, decimals=2):
    """Format number with comma separators"""
    if pd.isna(value):
        return "N/A"
    return f"{value:,.{decimals}f}"

def format_currency(value):
    """Format as currency (billions)"""
    if pd.isna(value):
        return "N/A"
    return f"${value:.2f}B"