{{ config(
    materialized='table',
    transient=true,
    schema='BUSINESS_VAULT'
) }}

WITH order_details AS (
    SELECT
        o.ORDER_DATE,
        o.ORDER_AMOUNT,
        o.ORDER_STATUS
    FROM {{ ref('sat_order_details') }} o
),

status_by_date AS (
    SELECT
        ORDER_DATE AS report_date,
        ORDER_STATUS,
        COUNT(*) AS order_count,
        SUM(ORDER_AMOUNT) AS status_revenue
    FROM order_details
    GROUP BY ORDER_DATE, ORDER_STATUS
),

daily_totals AS (
    SELECT
        report_date,
        SUM(order_count) AS total_orders_day,
        SUM(status_revenue) AS total_revenue_day
    FROM status_by_date
    GROUP BY report_date
)

SELECT
    s.report_date,
    s.ORDER_STATUS AS order_status,
    s.order_count,
    s.status_revenue,
    d.total_orders_day,
    d.total_revenue_day,
    ROUND((s.order_count / d.total_orders_day) * 100, 2) AS pct_of_orders,
    ROUND((s.status_revenue / d.total_revenue_day) * 100, 2) AS pct_of_revenue
FROM status_by_date s
JOIN daily_totals d
    ON s.report_date = d.report_date
ORDER BY s.report_date, s.ORDER_STATUS
