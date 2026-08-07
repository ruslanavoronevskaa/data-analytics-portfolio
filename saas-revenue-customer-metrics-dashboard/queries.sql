-- 1. СТЕ для підрахунку Monthly revenue
-- Один рядок = один користувач + сума всіх платежів за один календарний місяць

WITH monthly_revenue AS (

    SELECT
        DATE_TRUNC('month', payment_date ::date)::date AS payment_month,
        user_id,
        SUM(revenue_amount_usd) AS total_revenue

    FROM project.games_payments

    GROUP BY
        payment_month,
        user_id
),

-- 2. Payment history
-- Формуємо історію платежів користувача

payment_history AS (

    select *,
    
        (payment_month - interval '1 month')::date AS previous_calendar_month,
        (payment_month + interval '1 month')::date AS next_calendar_month,

        LAG(total_revenue)
            OVER(
                PARTITION BY user_id
                ORDER BY payment_month
            ) AS previous_paid_month_revenue,

        LAG(payment_month)
            OVER(
                PARTITION BY user_id
                ORDER BY payment_month
            ) AS previous_paid_month,

        LEAD(payment_month)
            OVER(
                PARTITION BY user_id
                ORDER BY payment_month
            ) AS next_paid_month

    FROM monthly_revenue
),

-- 3. Розраховуємо Revenue metrics

revenue_metrics AS (

SELECT *,

-- New MRR

CASE
WHEN previous_paid_month IS NULL
THEN total_revenue
ELSE 0
END AS new_mrr,

-- New Paid Users

CASE
WHEN previous_paid_month IS NULL
THEN 1
ELSE 0
END AS new_paid_users,

-- Expansion Revenue

CASE
WHEN previous_paid_month = previous_calendar_month
AND total_revenue > previous_paid_month_revenue
THEN total_revenue - previous_paid_month_revenue
ELSE 0
END AS expansion_revenue,

-- Contraction Revenue

CASE
WHEN previous_paid_month = previous_calendar_month
AND total_revenue < previous_paid_month_revenue
THEN total_revenue - previous_paid_month_revenue
ELSE 0
END AS contraction_revenue,

-- Churn Revenue

CASE
WHEN next_paid_month IS NULL
OR next_paid_month <> next_calendar_month
THEN total_revenue
ELSE 0
END AS churned_revenue,

-- Churn Month

CASE
WHEN next_paid_month IS NULL
OR next_paid_month <> next_calendar_month
THEN next_calendar_month
END AS churn_month
FROM payment_history
),

-- 4. User attributes
-- Додаємо інформацію з таблиці games_paid_users для фільтрів Tableau

final_dataset AS (

SELECT
    rm.*,
    gpu.language,
    gpu.age,
    gpu.has_older_device_model
FROM revenue_metrics rm
LEFT JOIN games_paid_users gpu
ON rm.user_id = gpu.user_id
)

-- RESULT

SELECT *
FROM final_dataset
ORDER BY
payment_month,
user_id;