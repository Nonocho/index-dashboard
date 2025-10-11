# app.py
"""
Index Analytics Dashboard
Single-page Streamlit app for S&P 500 vs S&P 100 analysis
"""
# CRITICAL: Load environment variables FIRST
from dotenv import load_dotenv
import os
load_dotenv()

# Verify environment variables are loaded
if not os.getenv('DB_PASSWORD'):
    import streamlit as st
    st.error("⚠️ Environment variables not loaded! Check .env file location.")
    st.stop()

import streamlit as st
import pandas as pd
import plotly.graph_objects as go
from datetime import datetime, timedelta
from config import INDEX_COLORS, CHART_COLORS, DASHBOARD_TITLE, DASHBOARD_SUBTITLE, INDICES
from utils import (
    get_latest_metrics,
    get_index_performance,
    get_sector_weights,
    get_top_holdings,
    get_all_stocks,
    get_volatility_chart_data,
    get_drawdown_chart_data,
    create_performance_chart,
    create_sector_pie_chart,
    create_sector_bar_chart,
    create_volatility_chart,
    create_drawdown_chart,
    format_percentage,
    format_number,
    format_currency
)

# ==================== PAGE CONFIG ====================

st.set_page_config(
    page_title="Index Analytics Dashboard",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ==================== CUSTOM CSS ====================

st.markdown(f"""
<style>
    /* Main styling */
    .main {{
        background-color: #ffffff;
    }}
    
    /* Sidebar styling */
    [data-testid="stSidebar"] {{
        background-color: {INDEX_COLORS['light']};
    }}
    
    /* Headers */
    h1 {{
        color: {INDEX_COLORS['primary']};
        font-weight: 700;
    }}
    
    h2, h3 {{
        color: {INDEX_COLORS['secondary']};
    }}
    
    /* Metrics cards */
    [data-testid="stMetricValue"] {{
        font-size: 28px;
        color: {INDEX_COLORS['primary']};
    }}
    
    /* Tabs */
    .stTabs [data-baseweb="tab-list"] button {{
        font-size: 16px;
        font-weight: 500;
        color: {INDEX_COLORS['dark']};
    }}
    
    .stTabs [data-baseweb="tab-list"] button[aria-selected="true"] {{
        color: {INDEX_COLORS['primary']};
        border-bottom-color: {INDEX_COLORS['primary']};
    }}
    
    /* Dataframe */
    .dataframe {{
        font-size: 14px;
    }}
    
    /* Custom container */
    .dashboard-container {{
        background-color: white;
        padding: 20px;
        border-radius: 10px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        margin-bottom: 20px;
    }}
</style>
""", unsafe_allow_html=True)

# ==================== SIDEBAR ====================

with st.sidebar:
    st.image("https://via.placeholder.com/200x80/2B1773/FFFFFF?text=Index+Analytics")
    
    st.markdown("### 🎯 Dashboard Controls")
    
    # Index selection
    index_selection = st.radio(
        "Select Index:",
        options=['Both', 'S&P 500', 'S&P 100'],
        index=0,
        help="Choose which index to analyze"
    )
        # Map selection to actual index codes
    if index_selection == 'S&P 500':
        index_code = 'GSPC.INDX'
    elif index_selection == 'S&P 100':
        index_code = 'OEX.INDX'
    else:
        index_code = None  # Both indices
    
    # Date range for performance chart
    st.markdown("### 📅 Date Range")
    date_range = st.selectbox(
        "Performance Period:",
        options=['1 Year', '3 Years', '5 Years', '10 Years', 'All Time'],
        index=4
    )
    
    # Calculate start date
    date_mapping = {
        '1 Year': datetime.now() - timedelta(days=365),
        '3 Years': datetime.now() - timedelta(days=365*3),
        '5 Years': datetime.now() - timedelta(days=365*5),
        '10 Years': datetime.now() - timedelta(days=365*10),
        'All Time': None
    }
    start_date = date_mapping[date_range]
    
    st.markdown("---")
    
    # Refresh button
    if st.button("🔄 Refresh Data", use_container_width=True):
        st.cache_data.clear()
        st.rerun()
    
    st.markdown("---")
    st.markdown("### 📊 About")
    st.info("""
    **Data Source:** PostgreSQL  
    **Update Frequency:** Daily  
    **Last Updated:** Oct 9, 2025
    
    Built with Streamlit, Plotly, and dbt
    """)

# ==================== MAIN DASHBOARD ====================

# Header
st.title(DASHBOARD_TITLE)
st.markdown(f"**{DASHBOARD_SUBTITLE}**")
st.markdown("---")

# Load latest metrics
with st.spinner("Loading data..."):
    if index_selection == 'Both':
        metrics_df = get_latest_metrics()
    elif index_selection == 'S&P 500':
        metrics_df = get_latest_metrics('GSPC.INDX')
    else:
        metrics_df = get_latest_metrics('OEX.INDX')

# ==================== TAB LAYOUT ====================

tab1, tab2, tab3, tab4 = st.tabs([
    "📈 Overview", 
    "🔍 Stock Screener", 
    "🎯 Sector Analysis", 
    "⚠️ Risk Metrics"
])

# ==================== TAB 1: OVERVIEW ====================

with tab1:
    if not metrics_df.empty:
        # KPI Cards
        st.markdown("### 📊 Key Performance Indicators")
        
        # Create columns for each index
        if index_selection == 'Both':
            col1, col2 = st.columns(2)
            
            with col1:
                st.markdown(f"#### {metrics_df.iloc[0]['index_name']}")
                kpi1, kpi2, kpi3, kpi4 = st.columns(4)
                
                with kpi1:
                    st.metric("1Y Return", format_percentage(metrics_df.iloc[0]['1Y Return %']))
                with kpi2:
                    st.metric("Sharpe Ratio", format_number(metrics_df.iloc[0]['Sharpe Ratio']))
                with kpi3:
                    st.metric("Volatility", format_percentage(metrics_df.iloc[0]['Volatility %']))
                with kpi4:
                    st.metric("Max Drawdown", format_percentage(metrics_df.iloc[0]['Max Drawdown %']))
            
            with col2:
                st.markdown(f"#### {metrics_df.iloc[1]['index_name']}")
                kpi5, kpi6, kpi7, kpi8 = st.columns(4)
                
                with kpi5:
                    st.metric("1Y Return", format_percentage(metrics_df.iloc[1]['1Y Return %']))
                with kpi6:
                    st.metric("Sharpe Ratio", format_number(metrics_df.iloc[1]['Sharpe Ratio']))
                with kpi7:
                    st.metric("Volatility", format_percentage(metrics_df.iloc[1]['Volatility %']))
                with kpi8:
                    st.metric("Max Drawdown", format_percentage(metrics_df.iloc[1]['Max Drawdown %']))
        
        else:
            # Single index view
            st.markdown(f"#### {metrics_df.iloc[0]['index_name']}")
            kpi1, kpi2, kpi3, kpi4, kpi5, kpi6 = st.columns(6)
            
            with kpi1:
                st.metric("1Y Return", format_percentage(metrics_df.iloc[0]['1Y Return %']))
            with kpi2:
                st.metric("3Y CAGR", format_percentage(metrics_df.iloc[0]['3Y CAGR %']))
            with kpi3:
                st.metric("5Y CAGR", format_percentage(metrics_df.iloc[0]['5Y CAGR %']))
            with kpi4:
                st.metric("Sharpe", format_number(metrics_df.iloc[0]['Sharpe Ratio']))
            with kpi5:
                st.metric("Volatility", format_percentage(metrics_df.iloc[0]['Volatility %']))
            with kpi6:
                st.metric("Max DD", format_percentage(metrics_df.iloc[0]['Max Drawdown %']))
        
        st.markdown("---")
        
        # Performance Chart
        st.markdown("### 📈 Cumulative Performance")
        
        if index_selection == 'Both':
            df_sp500 = get_index_performance('SP500', start_date)
            df_sp100 = get_index_performance('SP100', start_date)
            fig = create_performance_chart(df_sp500, df_sp100)
        elif index_selection == 'S&P 500':
            df_sp500 = get_index_performance('SP500', start_date)
            fig = create_performance_chart(df_sp500)
        else:
            df_sp100 = get_index_performance('SP100', start_date)
            fig = create_performance_chart(df_sp100)
        
        st.plotly_chart(fig, use_container_width=True)
        
        st.markdown("---")
        
        # Detailed Metrics Table
        st.markdown("### 📋 Detailed Metrics")
        
        # Format the dataframe for display
        display_df = metrics_df.copy()
        for col in display_df.columns:
            if '%' in col or 'Return' in col or 'Volatility' in col or 'Drawdown' in col:
                display_df[col] = display_df[col].apply(lambda x: format_percentage(x))
            elif 'Sharpe' in col or 'Ratio' in col:
                display_df[col] = display_df[col].apply(lambda x: format_number(x))
            elif 'Days' in col:
                display_df[col] = display_df[col].apply(lambda x: f"{int(x)}" if pd.notna(x) else "N/A")
        
        st.dataframe(display_df, use_container_width=True, hide_index=True)
    
    else:
        st.error("No data available. Please check database connection.")

# ==================== TAB 2: STOCK SCREENER ====================
# ==================== TAB 2: STOCK SCREENER ====================

with tab2:
    st.markdown("### 🔍 Stock Screener")
    st.markdown("Filter stocks based on fundamental metrics")
    
    # Load all stocks
    stocks_df = get_all_stocks()
    
    if not stocks_df.empty:
        # Show total stocks available
        st.info(f"📊 **{len(stocks_df)}** stocks available for screening")
        
        st.markdown("---")
        st.markdown("#### 🎚️ Filter Criteria")
        
        # Filters in a 2x2 grid
        col1, col2 = st.columns(2)
        
        with col1:
            st.markdown("**📈 Valuation Metrics**")
            
            pe_range = st.slider(
                "P/E Ratio (Trailing)",
                min_value=0.0,
                max_value=100.0,
                value=(0.0, 100.0),
                step=1.0,
                help="Price-to-Earnings ratio. Lower values may indicate undervaluation."
            )
            
            div_yield_range = st.slider(
                "Dividend Yield (%)",
                min_value=0.0,
                max_value=10.0,
                value=(0.0, 10.0),
                step=0.1,
                help="Annual dividend as percentage of stock price"
            )
        
        with col2:
            st.markdown("**💪 Quality & Risk Metrics**")
            
            roe_range = st.slider(
                "Return on Equity (%)",
                min_value=-50.0,
                max_value=150.0,
                value=(0.0, 150.0),
                step=5.0,
                help="Profitability metric. Higher is generally better."
            )
            
            beta_range = st.slider(
                "Beta (Market Sensitivity)",
                min_value=0.0,
                max_value=3.0,
                value=(0.0, 3.0),
                step=0.1,
                help="<1 = Less volatile than market, >1 = More volatile"
            )
        
        st.markdown("---")
        
        # Sector filter (optional)
        col1, col2 = st.columns([2, 1])
        with col1:
            sectors = ['All Sectors'] + sorted(stocks_df['sector'].dropna().unique().tolist())
            selected_sector = st.selectbox(
                "🎯 Filter by Sector (Optional)",
                options=sectors,
                help="Narrow results to a specific sector"
            )
        
        with col2:
            st.markdown("&nbsp;")  # Spacer
            st.markdown("&nbsp;")  # Spacer
            apply_filters = st.button("🔍 Apply Filters", type="primary", use_container_width=True)
        
        # Apply filters
        filtered_df = stocks_df[
            (stocks_df['pe_ratio_trailing'].between(pe_range[0], pe_range[1])) &
            (stocks_df['roe_pct'].between(roe_range[0], roe_range[1])) &
            (stocks_df['dividend_yield_pct'].between(div_yield_range[0], div_yield_range[1])) &
            (stocks_df['beta'].between(beta_range[0], beta_range[1]))
        ]
        
        # Apply sector filter if selected
        if selected_sector != 'All Sectors':
            filtered_df = filtered_df[filtered_df['sector'] == selected_sector]
        
        st.markdown("---")
        
        # Results
        if len(filtered_df) > 0:
            st.markdown(f"### 📊 Results: **{len(filtered_df)}** stocks match your criteria")
            
            # Calculate portfolio metrics
            avg_pe = filtered_df['pe_ratio_trailing'].mean()
            avg_roe = filtered_df['roe_pct'].mean()
            avg_div = filtered_df['dividend_yield_pct'].mean()
            avg_beta = filtered_df['beta'].mean()
            total_mcap = filtered_df['market_cap_billions'].sum()
            
            # Portfolio metrics in colored boxes
            col1, col2, col3, col4, col5 = st.columns(5)
            with col1:
                st.metric("Avg P/E", format_number(avg_pe), 
                         delta=f"{format_number(avg_pe - stocks_df['pe_ratio_trailing'].mean())} vs All",
                         delta_color="inverse")
            with col2:
                st.metric("Avg ROE", format_percentage(avg_roe),
                         delta=f"{format_number(avg_roe - stocks_df['roe_pct'].mean())}% vs All")
            with col3:
                st.metric("Avg Div Yield", format_percentage(avg_div),
                         delta=f"{format_number(avg_div - stocks_df['dividend_yield_pct'].mean())}% vs All")
            with col4:
                st.metric("Avg Beta", format_number(avg_beta),
                         delta=f"{format_number(avg_beta - stocks_df['beta'].mean())} vs All",
                         delta_color="inverse")
            with col5:
                st.metric("Total Market Cap", format_currency(total_mcap))
            
            st.markdown("---")
            
            # Comparison to S&P 500 benchmark
            st.markdown("### 📊 Portfolio vs S&P 500 Benchmark")
            
            # Get S&P 500 metrics
            sp500_metrics = get_latest_metrics('GSPC.INDX')
            
            if not sp500_metrics.empty:
                comparison_data = {
                    'Metric': ['P/E Ratio', 'ROE (%)', 'Dividend Yield (%)', 'Beta', 'Volatility (%)'],
                    'Your Portfolio': [
                        format_number(avg_pe),
                        format_percentage(avg_roe),
                        format_percentage(avg_div),
                        format_number(avg_beta),
                        'N/A'
                    ],
                    'S&P 500': [
                        'N/A',  # We don't have index P/E in metrics
                        'N/A',
                        'N/A',
                        'N/A',
                        format_percentage(sp500_metrics.iloc[0]['Volatility %'])
                    ]
                }
                comparison_df = pd.DataFrame(comparison_data)
                st.dataframe(comparison_df, use_container_width=True, hide_index=True)
            
            st.markdown("---")
            
            # Display filtered stocks with sorting
            st.markdown("### 📋 Filtered Stocks")
            
            # Add sorting option
            sort_col1, sort_col2 = st.columns([3, 1])
            with sort_col1:
                sort_by = st.selectbox(
                    "Sort by:",
                    options=['Market Cap', 'P/E Ratio', 'ROE', 'Dividend Yield', 'Beta', 'Company Name'],
                    index=0
                )
            with sort_col2:
                sort_order = st.radio("Order:", options=['Descending', 'Ascending'], horizontal=True)
            
            # Apply sorting
            sort_mapping = {
                'Market Cap': 'market_cap_billions',
                'P/E Ratio': 'pe_ratio_trailing',
                'ROE': 'roe_pct',
                'Dividend Yield': 'dividend_yield_pct',
                'Beta': 'beta',
                'Company Name': 'company_name'
            }
            
            sort_column = sort_mapping[sort_by]
            ascending = (sort_order == 'Ascending')
            filtered_df = filtered_df.sort_values(by=sort_column, ascending=ascending)
            
            # Format for display
            display_filtered = filtered_df.copy()
            display_filtered['pe_ratio_trailing'] = display_filtered['pe_ratio_trailing'].apply(lambda x: format_number(x))
            display_filtered['roe_pct'] = display_filtered['roe_pct'].apply(lambda x: format_percentage(x))
            display_filtered['dividend_yield_pct'] = display_filtered['dividend_yield_pct'].apply(lambda x: format_percentage(x))
            display_filtered['beta'] = display_filtered['beta'].apply(lambda x: format_number(x))
            display_filtered['market_cap_billions'] = display_filtered['market_cap_billions'].apply(lambda x: format_currency(x))
            display_filtered['current_price'] = display_filtered['current_price'].apply(lambda x: f"${x:.2f}")
            
            display_filtered = display_filtered.rename(columns={
                'ticker': 'Ticker',
                'company_name': 'Company',
                'sector': 'Sector',
                'industry': 'Industry',
                'pe_ratio_trailing': 'P/E',
                'roe_pct': 'ROE',
                'dividend_yield_pct': 'Div Yield',
                'beta': 'Beta',
                'market_cap_billions': 'Market Cap',
                'current_price': 'Price'
            })
            
            st.dataframe(
                display_filtered,
                use_container_width=True,
                hide_index=True,
                height=400
            )
            
            # Download button
            col1, col2, col3 = st.columns([1, 1, 2])
            with col1:
                csv = filtered_df.to_csv(index=False)
                st.download_button(
                    label="📥 Download CSV",
                    data=csv,
                    file_name=f"filtered_stocks_{datetime.now().strftime('%Y%m%d')}.csv",
                    mime="text/csv",
                    use_container_width=True
                )
            
            with col2:
                # Create summary text
                summary = f"""
                Stock Screener Results - {datetime.now().strftime('%Y-%m-%d')}
                
                Filters Applied:
                - P/E Ratio: {pe_range[0]:.1f} - {pe_range[1]:.1f}
                - ROE: {roe_range[0]:.1f}% - {roe_range[1]:.1f}%
                - Dividend Yield: {div_yield_range[0]:.1f}% - {div_yield_range[1]:.1f}%
                - Beta: {beta_range[0]:.1f} - {beta_range[1]:.1f}
                - Sector: {selected_sector}
                
                Results: {len(filtered_df)} stocks
                
                Portfolio Metrics:
                - Average P/E: {avg_pe:.2f}
                - Average ROE: {avg_roe:.2f}%
                - Average Dividend Yield: {avg_div:.2f}%
                - Average Beta: {avg_beta:.2f}
                - Total Market Cap: ${total_mcap:.2f}B
                """
                
                st.download_button(
                    label="📄 Download Summary",
                    data=summary,
                    file_name=f"screener_summary_{datetime.now().strftime('%Y%m%d')}.txt",
                    mime="text/plain",
                    use_container_width=True
                )
        
        else:
            st.warning("⚠️ No stocks match your criteria. Try adjusting the filters.")
            
            # Show some suggestions
            st.info("""
            **💡 Tips for better results:**
            - Widen the P/E range (some growth stocks have very high P/E)
            - Allow negative ROE values (some companies may be temporarily unprofitable)
            - Try "All Sectors" if you've selected a specific sector
            - Increase the Beta range to include more volatile stocks
            """)
    
    else:
        st.error("Unable to load stock data. Please check database connection.")

# ==================== TAB 3: SECTOR ANALYSIS ====================

with tab3:
    st.markdown("### 🎯 Sector Analysis")
    
    # Sector selection for analysis
    if index_selection == 'Both':
        sector_index = st.radio(
            "Select Index for Sector Analysis:",
            options=['S&P 500', 'S&P 100'],
            horizontal=True,
            key='sector_radio'
        )
        sector_code = 'GSPC.INDX' if sector_index == 'S&P 500' else 'OEX.INDX'
    elif index_selection == 'S&P 500':
        sector_code = 'GSPC.INDX'
    else:
        sector_code = 'OEX.INDX'
    
    # Load sector data
    sector_df = get_sector_weights(sector_code)
    
    if not sector_df.empty:
        col1, col2 = st.columns(2)
        
        with col1:
            # Pie chart
            fig_pie = create_sector_pie_chart(sector_df)
            st.plotly_chart(fig_pie, use_container_width=True)
        
        with col2:
            # Bar chart
            fig_bar = create_sector_bar_chart(sector_df)
            st.plotly_chart(fig_bar, use_container_width=True)
        
        st.markdown("---")
        
        # Sector metrics table
        st.markdown("### 📊 Sector Metrics")
        
        display_sector = sector_df.copy()
        display_sector['sector_weight_pct'] = display_sector['sector_weight_pct'].apply(lambda x: format_percentage(x))
        display_sector['sector_avg_pe'] = display_sector['sector_avg_pe'].apply(lambda x: format_number(x))
        display_sector['sector_avg_roe_pct'] = display_sector['sector_avg_roe_pct'].apply(lambda x: format_percentage(x))
        display_sector['company_count'] = display_sector['company_count'].apply(lambda x: int(x))
        
        display_sector = display_sector.rename(columns={
            'sector': 'Sector',
            'sector_weight_pct': 'Weight (%)',
            'company_count': '# Companies',
            'sector_avg_pe': 'Avg P/E',
            'sector_avg_roe_pct': 'Avg ROE (%)'
        })
        
        st.dataframe(display_sector, use_container_width=True, hide_index=True)
        
        st.markdown("---")
        
        # Top holdings
        st.markdown("### 🏆 Top 10 Holdings")
        top10_df = get_top_holdings(sector_code, 10)
        
        if not top10_df.empty:
            display_top10 = top10_df.copy()
            display_top10['weight_pct'] = display_top10['weight_pct'].apply(lambda x: format_percentage(x))
            display_top10['market_cap_billions'] = display_top10['market_cap_billions'].apply(lambda x: format_currency(x))
            display_top10['pe_ratio'] = display_top10['pe_ratio'].apply(lambda x: format_number(x))
            display_top10['dividend_yield_pct'] = display_top10['dividend_yield_pct'].apply(lambda x: format_percentage(x))
            
            display_top10 = display_top10.rename(columns={
                'holding_rank': 'Rank',
                'ticker': 'Ticker',
                'company_name': 'Company',
                'sector': 'Sector',
                'weight_pct': 'Weight (%)',
                'market_cap_billions': 'Market Cap',
                'pe_ratio': 'P/E',
                'dividend_yield_pct': 'Div Yield'
            })
            
            st.dataframe(display_top10, use_container_width=True, hide_index=True)
            
            # Concentration metric
            total_top10_weight = top10_df['weight_pct'].sum()
            st.info(f"**Top 10 Concentration:** {format_percentage(total_top10_weight)} of total index weight")
        else:
            st.warning("Top holdings data not available.")
    
    else:
        st.error("Unable to load sector data. Please check database connection.")

# ==================== TAB 4: RISK METRICS ====================

with tab4:
    st.markdown("### ⚠️ Risk Metrics")
    
    # Risk index selection
    if index_selection == 'Both':
        risk_index = st.radio(
            "Select Index for Risk Analysis:",
            options=['S&P 500', 'S&P 100'],
            horizontal=True,
            key='risk_radio'
        )
        risk_code = 'SP500' if risk_index == 'S&P 500' else 'SP100'
    elif index_selection == 'S&P 500':
        risk_code = 'SP500'
    else:
        risk_code = 'SP100'
    
    # Load risk data
    vol_df = get_volatility_chart_data(risk_code)
    dd_df = get_drawdown_chart_data(risk_code)
    
    if not vol_df.empty and not dd_df.empty:
        # Volatility chart
        st.markdown("### 📊 Rolling Volatility")
        fig_vol = create_volatility_chart(vol_df)
        st.plotly_chart(fig_vol, use_container_width=True)
        
        st.markdown("---")
        
        # Drawdown chart
        st.markdown("### 📉 Drawdown Analysis")
        fig_dd = create_drawdown_chart(dd_df)
        st.plotly_chart(fig_dd, use_container_width=True)
        
        st.markdown("---")
        
        # Risk statistics
        st.markdown("### 📋 Risk Statistics")
        
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            current_vol = vol_df['volatility_252d_pct'].iloc[-1]
            st.metric("Current Volatility (1Y)", format_percentage(current_vol))
        
        with col2:
            avg_vol = vol_df['volatility_252d_pct'].mean()
            st.metric("Average Volatility", format_percentage(avg_vol))
        
        with col3:
            max_dd = dd_df['drawdown_from_peak_pct'].min()
            st.metric("Maximum Drawdown", format_percentage(max_dd))
        
        with col4:
            current_dd = dd_df['drawdown_from_peak_pct'].iloc[-1]
            st.metric("Current Drawdown", format_percentage(current_dd))
        
        # Additional insights
        st.markdown("---")
        st.markdown("### 💡 Risk Insights")
        
        # Calculate some risk metrics
        vol_std = vol_df['volatility_252d_pct'].std()
        dd_recovery_days = dd_df[dd_df['drawdown_from_peak_pct'] < -10]['days_in_drawdown'].mean()
        
        col1, col2 = st.columns(2)
        
        with col1:
            st.info(f"""
            **Volatility Analysis:**
            - Current 1-Year Volatility: {format_percentage(current_vol)}
            - Average Volatility: {format_percentage(avg_vol)}
            - Volatility Std Dev: {format_percentage(vol_std)}
            
            {'📈 Above average volatility period' if current_vol > avg_vol else '📉 Below average volatility period'}
            """)
        
        with col2:
            st.info(f"""
            **Drawdown Analysis:**
            - Maximum Drawdown: {format_percentage(max_dd)}
            - Current Drawdown: {format_percentage(current_dd)}
            - Avg Recovery Time (>10% DD): {int(dd_recovery_days) if pd.notna(dd_recovery_days) else 'N/A'} days
            
            {'🚨 Currently in drawdown' if current_dd < -5 else '✅ Near all-time highs'}
            """)
    
    else:
        st.error("Unable to load risk data. Please check database connection.")

# ==================== FOOTER ====================

st.markdown("---")
st.markdown("""
<div style='text-align: center; color: #95AABE; padding: 20px;'>
    <p><strong>Index Analytics Dashboard</strong> | Built with ❤️ using Streamlit, PostgreSQL, dbt, and Dagster</p>
    <p>Data sourced from EODHD API | Portfolio project showcasing modern data stack</p>
    <p style='font-size: 12px; margin-top: 10px;'>
        🎨 Color Scheme: Purple (#2B1773) → Teal (#0D5673) → Yellow (#F2E857) → Orange (#F2913D) → Coral (#F26D3D)
    </p>
</div>
""", unsafe_allow_html=True)