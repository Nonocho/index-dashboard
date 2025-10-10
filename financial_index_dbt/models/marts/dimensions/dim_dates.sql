{{
    config(
        materialized='table',
        schema='gold'
    )
}}

WITH RECURSIVE date_spine AS (
    SELECT DATE '1957-01-01' AS calendar_date
    
    UNION ALL
    
    SELECT (calendar_date + INTERVAL '1 day')::DATE
    FROM date_spine
    WHERE calendar_date < DATE '2025-12-31'
),

date_attributes AS (
    SELECT
        calendar_date,
        TO_CHAR(calendar_date, 'YYYYMMDD')::INTEGER AS date_key,
        EXTRACT(DAY FROM calendar_date)::INTEGER AS day_of_month,
        EXTRACT(DOW FROM calendar_date)::INTEGER AS day_of_week,
        TRIM(TO_CHAR(calendar_date, 'Day')) AS day_name,
        EXTRACT(DOY FROM calendar_date)::INTEGER AS day_of_year,
        EXTRACT(WEEK FROM calendar_date)::INTEGER AS week_of_year,
        DATE_TRUNC('week', calendar_date)::DATE AS week_start_date,
        EXTRACT(MONTH FROM calendar_date)::INTEGER AS month_number,
        TRIM(TO_CHAR(calendar_date, 'Month')) AS month_name,
        TRIM(TO_CHAR(calendar_date, 'Mon')) AS month_name_short,
        DATE_TRUNC('month', calendar_date)::DATE AS month_start_date,
        (DATE_TRUNC('month', calendar_date) + INTERVAL '1 month - 1 day')::DATE AS month_end_date,
        EXTRACT(QUARTER FROM calendar_date)::INTEGER AS quarter_number,
        'Q' || EXTRACT(QUARTER FROM calendar_date) AS quarter_name,
        DATE_TRUNC('quarter', calendar_date)::DATE AS quarter_start_date,
        EXTRACT(YEAR FROM calendar_date)::INTEGER AS year_number,
        DATE_TRUNC('year', calendar_date)::DATE AS year_start_date,
        CASE 
            WHEN EXTRACT(DOW FROM calendar_date) IN (0, 6) THEN FALSE
            ELSE TRUE
        END AS is_business_day,
        CASE
            WHEN calendar_date = (DATE_TRUNC('month', calendar_date) + INTERVAL '1 month - 1 day')::DATE 
            THEN TRUE
            ELSE FALSE
        END AS is_month_end,
        CASE
            WHEN calendar_date = (DATE_TRUNC('quarter', calendar_date) + INTERVAL '3 months - 1 day')::DATE 
            THEN TRUE
            ELSE FALSE
        END AS is_quarter_end,
        CASE
            WHEN EXTRACT(MONTH FROM calendar_date) = 12 
                AND EXTRACT(DAY FROM calendar_date) = 31 
            THEN TRUE
            ELSE FALSE
        END AS is_year_end,
        EXTRACT(QUARTER FROM calendar_date)::INTEGER AS fiscal_quarter,
        EXTRACT(YEAR FROM calendar_date)::INTEGER AS fiscal_year
    FROM date_spine
)

SELECT 
    date_key,
    calendar_date,
    day_of_month,
    day_of_week,
    day_name,
    day_of_year,
    week_of_year,
    week_start_date,
    month_number,
    month_name,
    month_name_short,
    month_start_date,
    month_end_date,
    quarter_number,
    quarter_name,
    quarter_start_date,
    year_number,
    year_start_date,
    is_business_day,
    is_month_end,
    is_quarter_end,
    is_year_end,
    fiscal_quarter,
    fiscal_year
FROM date_attributes
WHERE is_business_day = TRUE
ORDER BY calendar_date