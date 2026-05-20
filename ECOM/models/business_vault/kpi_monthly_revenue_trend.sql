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
)

SELECT
    DATE_TRUNC('month', ORDER_DATE) AS report_month,
    COUNT(*) AS total_orders,
    SUM(ORDER_AMOUNT) AS monthly_gmv,
    AVG(ORDER_AMOUNT) AS avg_order_value,
    SUM(CASE WHEN ORDER_STATUS = 'delivered' THEN ORDER_AMOUNT ELSE 0 END) AS delivered_revenue,
    LAG(SUM(ORDER_AMOUNT)) OVER (ORDER BY DATE_TRUNC('month', ORDER_DATE)) AS prev_month_gmv,
    CASE
        WHEN LAG(SUM(ORDER_AMOUNT)) OVER (ORDER BY DATE_TRUNC('month', ORDER_DATE)) > 0
        THEN ROUND(((SUM(ORDER_AMOUNT) - LAG(SUM(ORDER_AMOUNT)) OVER (ORDER BY DATE_TRUNC('month', ORDER_DATE)))
              / LAG(SUM(ORDER_AMOUNT)) OVER (ORDER BY DATE_TRUNC('month', ORDER_DATE))) * 100, 2)
        ELSE NULL
    END AS monthly_gmv_growth_pct
FROM order_details
GROUP BY DATE_TRUNC('month', ORDER_DATE)
ORDER BY report_month
