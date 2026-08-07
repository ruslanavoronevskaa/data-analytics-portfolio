SELECT
    transactions.transaction_id,
    transactions.timestamp::date AS transaction_date,
    DATE_TRUNC('month', transactions.timestamp)::date AS transaction_month,

    transactions.customer_id,
    transactions.product_id,
    transactions.campaign_id,

    campaigns.channel AS campaign_channel,
    campaigns.objective AS campaign_objective,
    campaigns.target_segment AS campaign_target_segment,
    campaigns.expected_uplift,

    products.category AS product_category,
    products.brand AS product_brand,
    products.base_price,
    products.is_premium,

    transactions.quantity,
    transactions.gross_revenue as revenue,

    Round(transactions.gross_revenue
    / NULLIF(transactions.quantity, 0), 2) AS revenue_per_unit_row,

    transactions.quantity > 0 AS is_valid_quantity,

    transactions.gross_revenue > 0 AS is_positive_revenue

FROM transactions AS transactions
LEFT JOIN products AS products
    ON transactions.product_id = products.product_id
LEFT JOIN campaigns AS campaigns
    ON transactions.campaign_id = campaigns.campaign_id

WHERE transactions.transaction_id IS NOT NULL
    AND transactions.customer_id IS NOT NULL
    AND transactions.product_id IS NOT NULL
    AND transactions.gross_revenue IS NOT NULL
    AND transactions.quantity IS NOT NULL;
