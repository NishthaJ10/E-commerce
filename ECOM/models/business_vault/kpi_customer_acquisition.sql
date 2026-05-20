{{ config(
    materialized='table',
    transient=true,
    schema='BUSINESS_VAULT'
) }}

WITH customers AS (
    SELECT
        CUSTOMER_ID,
        CUSTOMER_CREATED_AT
    FROM {{ ref('dim_customer') }}
    WHERE IS_CURRENT = TRUE
),

daily_signups AS (
    SELECT
        CAST(CUSTOMER_CREATED_AT AS DATE) AS signup_date,
        COUNT(*) AS new_customers
    FROM customers
    GROUP BY CAST(CUSTOMER_CREATED_AT AS DATE)
),

weekly_signups AS (
    SELECT
        DATE_TRUNC('week', signup_date) AS week_start,
        SUM(new_customers) AS weekly_new_customers
    FROM daily_signups
    GROUP BY DATE_TRUNC('week', signup_date)
)

SELECT
    d.signup_date,
    d.new_customers AS daily_new_customers,
    SUM(d.new_customers) OVER (ORDER BY d.signup_date) AS cumulative_customers,
    w.week_start,
    w.weekly_new_customers,
    LAG(d.new_customers) OVER (ORDER BY d.signup_date) AS prev_day_new_customers,
    CASE
        WHEN LAG(d.new_customers) OVER (ORDER BY d.signup_date) > 0
        THEN ROUND(((d.new_customers - LAG(d.new_customers) OVER (ORDER BY d.signup_date))
              / LAG(d.new_customers) OVER (ORDER BY d.signup_date)) * 100, 2)
        ELSE NULL
    END AS daily_acquisition_growth_pct
FROM daily_signups d
LEFT JOIN weekly_signups w
    ON DATE_TRUNC('week', d.signup_date) = w.week_start
ORDER BY d.signup_date
