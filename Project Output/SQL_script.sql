-- The Iron Bank of Braavos Analysis
-- the analysis is divided into multiple sections that have individual solutions
-- author: Wavhothe Masakona

-------------------------------------------------------------------------------------------
-- 1) Most profitable customers by region/segment
-------------------------------------------------------------------------------------------
-- CREATE OR REPLACE VIEW braavos.analytics.customer_profitability_view AS
WITH tmpcustprofit AS(
    SELECT 
        c.customer_id,
        c.full_name,
        c.region,
        SUM(CASE
                WHEN t.txn_type = 'Deposit' THEN t.amount
                WHEN t.txn_type = 'Transfer' THEN t.amount
                ELSE -t.amount
            END) AS net_amount
        FROM braavos.data.customers c
        JOIN braavos.data.accounts a
            ON c.customer_id = a.customer_id
        JOIN braavos.data.transactions t
            ON a.account_id = t.account_id
        GROUP BY c.customer_id, c.full_name, c.region
)
SELECT
    customer_id,
    full_name,
    region,
    net_amount,
    RANK() OVER (PARTITION BY region ORDER BY net_amount DESC) AS region_rank
FROM tmpcustprofit;

SELECT * FROM braavos.analytics.customer_profitability_view;
-------------------------------------------------------------------------------------------
-- 2) Consistently low or negative balances
-------------------------------------------------------------------------------------------
-- getting the threshold
SELECT (AVG(balance) * 0.05) AS threshold FROM braavos.data.accounts;

-- getting the solution using multiple CTEs
CREATE OR REPLACE VIEW braavos.analytics.account_health AS
--getting the overal average
WITH overall_avg AS(
    SELECT
        AVG(balance) AS global_avg
    FROM braavos.data.accounts
),
-- getting the specific customer's average
customer_avg AS(
    SELECT
        c.customer_id,
        c.full_name,
        AVG(a.balance) AS customer_avg_balance
    FROM braavos.data.customers c
    JOIN braavos.data.accounts a
        ON c.customer_id = a.customer_id
    GROUP BY c.customer_id, c.full_name
)
-- comparing the two figures
SELECT
    ca.customer_id,
    ca.full_name,
    ca.customer_avg_balance,
    oa.global_avg,
    (oa.global_avg * 0.05) AS threshold,
    CASE
        WHEN ca.customer_avg_balance < 0 THEN 'Negative Balance'
        WHEN ca.customer_avg_balance < (oa.global_avg * 0.05) THEN 'Consistently Below Average'
        ELSE 'Good'
    END AS account_classification
FROM customer_avg ca
CROSS JOIN overall_avg oa;

SELECT * FROM braavos.analytics.account_health;
-------------------------------------------------------------------------------------------
-- 3) Quiet customers (no deposits/transactions in recent months)
-------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW braavos.analytics.customer_retention AS
SELECT
    c.customer_id,
    c.full_name,
    MAX(t.txn_date) AS latest_transaction,
    CASE
        WHEN DATEDIFF(DAY,latest_transaction,CURRENT_DATE()) > 90 THEN 'Inactive User'
        ELSE 'Active'
    END AS user_status
FROM braavos.data.customers c
JOIN braavos.data.accounts a
    ON c.customer_id = a.customer_id
JOIN braavos.data.transactions t
    ON a.account_id = t.account_id
GROUP BY c.customer_id, c.full_name;

SELECT * FROM braavos.analytics.customer_retention;

-------------------------------------------------------------------------------------------
-- 4) Account types holding most value
-------------------------------------------------------------------------------------------
SELECT
    account_type,
    account_status,
    SUM(balance) AS tot_balance
FROM braavos.data.accounts
GROUP BY account_type,account_status
HAVING account_status  = 'Active'
ORDER BY tot_balance DESC;

-------------------------------------------------------------------------------------------
-- 5) Branch exposure to risky accounts
-------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW braavos.analytics.risky_accounts AS
WITH tmprisk AS(
    SELECT
        branch_code,
        SUM(CASE
                WHEN balance < 0 THEN balance
                WHEN balance < 100 THEN balance
                ELSE 0
            END) AS total_exposure,
        COUNT(CASE
                WHEN balance < 0 OR  balance <100
                THEN account_id
            END) AS risky_accounts
    FROM braavos.data.accounts a
    GROUP BY branch_code
)
SELECT
    branch_code,
    total_exposure,
    risky_accounts
FROM tmprisk
ORDER BY total_exposure ASC LIMIT 10;

SELECT * FROM braavos.analytics.risky_accounts;

-------------------------------------------------------------------------------------------
-- 6) Performance differences between branches/products
-------------------------------------------------------------------------------------------
-- branch level performance
SELECT
    branch_code,
    SUM(balance) AS total_balance
FROM braavos.data.accounts
GROUP BY branch_code
ORDER BY total_balance DESC;

SELECT
    branch_code,
    AVG(balance) AS avg_balance
FROM braavos.data.accounts
GROUP BY branch_code
ORDER BY avg_balance DESC;

SELECT DISTINCT
    branch_code,
    COUNT(customer_id) AS tot_customers
FROM braavos.data.accounts
GROUP BY branch_code
ORDER BY tot_customers DESC;

-- product-level performance
SELECT
    account_type,
    SUM(balance) AS total_balance
FROM braavos.data.accounts
GROUP BY account_type
ORDER BY total_balance DESC;

SELECT
    account_type,
    AVG(balance) AS avg_balance
FROM braavos.data.accounts
GROUP BY account_type
ORDER BY avg_balance DESC;

SELECT DISTINCT
    account_type,
    COUNT(customer_id) AS tot_customers
FROM braavos.data.accounts
GROUP BY account_type
ORDER BY tot_customers DESC;

-- Combined branch × product view
SELECT
    account_type,
    branch_code,
    SUM(balance) AS total_balance
FROM braavos.data.accounts
GROUP BY account_type,branch_code
ORDER BY total_balance DESC;

SELECT
    account_type,
    branch_code,
    AVG(balance) AS avg_balance
FROM braavos.data.accounts
GROUP BY account_type,branch_code
ORDER BY avg_balance DESC;

SELECT DISTINCT
    account_type,
    branch_code,
    COUNT(customer_id) AS tot_customers
FROM braavos.data.accounts
GROUP BY account_type, branch_code
ORDER BY tot_customers DESC;

-- transaction amounts per month
SELECT 
    branch_code,
    account_type,
    MONTHNAME(t.txn_date) AS txn_month,
    SUM(t.amount) AS monthly_txn_value
FROM accounts a
JOIN transactions t ON a.account_id = t.account_id
GROUP BY branch_code, account_type, txn_month
ORDER BY branch_code, account_type, txn_month;

SELECT 
    branch_code,
    account_type,
    MONTHNAME(t.txn_date) AS txn_month,
    COUNT(t.txn_id) AS txn_volume
FROM accounts a
JOIN transactions t ON a.account_id = t.account_id
GROUP BY branch_code, account_type, txn_month
ORDER BY branch_code, account_type, txn_month;

-------------------------------------------------------------------------------------------
-- 7) average and median value per account type
-------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW braavos.analytics.account_analysis AS
SELECT
    account_type,
    AVG(balance) AS avg_balance,
    MIN(balance) AS min_balance,
    MAX(balance) AS max_balance,
    APPROX_PERCENTILE(balance, 0.5) AS median_balance
FROM braavos.data.accounts
GROUP BY account_type;

SELECT * FROM braavos.analytics.account_analysis;
-------------------------------------------------------------------------------------------
-- 8) High‑risk customers with anomalies
-------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW braavos.analytics.high_risk_customers AS
WITH tmptransactions AS(
SELECT
    c.full_name,
    c.risk_segment,
    a.account_id,
    a.account_type,
    a.account_status,
    t.txn_date,
    t.txn_type,
    t.amount,
    
    -- daily transaction volume per account
    SUM(t.amount) OVER (PARTITION BY t.account_id, t.txn_date) AS daily_txn_volume,

    -- Average transaction amount per customer
    AVG(t.amount) OVER (PARTITION BY c.customer_id) AS avg_txn_amount
    FROM braavos.data.customers c
    JOIN braavos.data.accounts a
        ON c.customer_id = a.customer_id
    JOIN braavos.data.transactions t
        ON a.account_id = t.account_id
    WHERE a.account_status = 'Active'
)
SELECT
    full_name,
    account_type,
    account_status,
    daily_txn_volume,
    avg_txn_amount,
    
    -- checking the transactions that are 2.5x the avg transaction amount for specific account
    CASE
        WHEN (txn_type IN ('Withdrawal', 'Purchase') AND amount > 2.5 * avg_txn_amount)
            THEN 'Anomaly'
        ELSE 'Normal'
    END AS anomaly_flag,
    FROM tmptransactions
    WHERE risk_segment = 'High'
    AND anomaly_flag = 'Anomaly'
    ORDER BY amount DESC;

SELECT * FROM braavos.analytics.high_risk_customers;

-------------------------------------------------------------------------------------------
-- 8) The percentage of the total net amount driven by our top 10% of customers
-------------------------------------------------------------------------------------------

WITH net_cust AS(
    SELECT
        c.customer_id,
        c.full_name,
        -- getting the net amount per customer
        SUM(CASE
                WHEN t.txn_type IN ('Deposit', 'Transfer') THEN t.amount
                ELSE -t.amount
            END) AS net_amount
    FROM customers c
    JOIN accounts a 
        ON c.customer_id = a.customer_id
    JOIN transactions t 
        ON a.account_id = t.account_id
    GROUP BY c.customer_id, c.full_name
),
ranked AS(
    -- splitting the customer list into deciles (10 equal groups) based on net amount from above CTE
    SELECT *,
        NTILE(10) OVER (ORDER BY net_amount DESC) as decile
    FROM net_cust
),
totals AS(
    -- Aggregate total net value, and what the top 10% contributes
    SELECT 
        SUM(net_amount) AS total_net,
        SUM(CASE
                WHEN decile = 1 THEN net_amount ELSE 0 END) 
            AS top_10_net
    FROM ranked
)
-- percentage
SELECT 
    top_10_net,
    total_net,
    ROUND((top_10_net / total_net) * 100, 2) AS top_10_pct_contribution
FROM totals;

-------------------------------------------------------------------------------------------
-- 9) Branch risk vs the network's average
-------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW braavos.analytics.branch_risk_vs_N_average AS
WITH branch_risk AS (
    -- Compare each branch’s risky exposure to the network average.
    SELECT 
        branch_code,
        SUM(CASE 
            WHEN balance < 0 OR balance < 100 THEN balance ELSE 0 END) 
        AS risky_balance
    FROM braavos.data.accounts
    GROUP BY branch_code
),
network_avg AS (
    SELECT AVG(risky_balance) AS avg_risk FROM branch_risk
)
SELECT 
    br.branch_code,
    br.risky_balance,
    na.avg_risk,
    ROUND(br.risky_balance / na.avg_risk, 2) AS risk_exposure_index
FROM branch_risk br
CROSS JOIN network_avg na
ORDER BY risk_exposure_index DESC LIMIT 5;

SELECT * FROM braavos.analytics.branch_risk_vs_n_average;
-------------------------------------------------------------------------------------------
-- 10) Estimate CLV for retained vs churned customers.
-------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW braavos.analytics.churn_est_clv AS
WITH txn_summary AS (
    -- Getting their last transaction date, and average amount
    SELECT 
        c.customer_id,
        c.full_name,
        MAX(t.txn_date) AS last_txn,
        AVG(t.amount) AS avg_monthly_amount
    FROM braavos.data.customers c
    JOIN braavos.data.accounts a 
        ON c.customer_id = a.customer_id
    JOIN braavos.data.transactions t 
        ON a.account_id = t.account_id
    GROUP BY c.customer_id, c.full_name
),
classified AS (
    -- churn status
    SELECT *,
        CASE 
            WHEN DATEDIFF(DAY, last_txn, CURRENT_DATE()) > 90 THEN 'Churned'
            ELSE 'Retained'
        END AS churn_status
    FROM txn_summary
)
SELECT 
    churn_status,
    ROUND(AVG(avg_monthly_amount * 12), 2) AS est_clv
FROM classified
GROUP BY churn_status;

SELECT * FROM braavos.analytics.churn_est_clv;
-------------------------------------------------------------------------------------------
-- 10) How much balance is held by unverified customers in medium/high risk segments?
-------------------------------------------------------------------------------------------

CREATE OR REPLACE VIEW braavos.analytics.unverified AS
WITH total_sum AS(
    SELECT
        SUM(a.balance) AS total_amount
    FROM braavos.data.customers c
    JOIN braavos.data.accounts a
        ON c.customer_id = a.customer_id
),
risky_balance AS(
    SELECT 
    SUM(a.balance) AS unverified_risk_balance
FROM braavos.data.customers c
JOIN braavos.data.accounts a 
    ON c.customer_id = a.customer_id
WHERE c.kyc_status != 'Verified'
  AND c.risk_segment IN ('Medium', 'High')
)
SELECT
    unverified_risk_balance,
    total_amount,
    ROUND(rb.unverified_risk_balance/ts.total_amount * 100, 2) AS percentage_risky

FROM total_sum ts
CROSS JOIN risky_balance rb;
