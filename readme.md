# 🏦 The Iron Bank of Braavos – Analytics Suite

## 📌 Project Overview
This project delivers a full-stack analytics solution for the Iron Bank of Braavos, integrating customer, account, and transaction data to uncover insights across profitability, risk exposure, branch performance, and churn. Built using SQL and Power BI, the suite includes strategic finance metrics, anomaly detection, and executive dashboards.

---

## 📊 Executive Summary
- **Profitability Concentration:** Top 10% of customers drive ~82% of net amounts.
- **Risk Exposure:** Branches BR022, BR014, BR009, BR024, and BR030 show elevated exposure.
- **Customer Health:** 180 customers hold negative balances; 240 are inactive (>90 days).
- **Retention Challenge:** Churn rate estimated at 48%; retained customers show 23% higher CLV proxy.
- **Product Insights:** Credit Card and Savings accounts dominate balances; Investment accounts underperform.
- **Fraud Risk:** No anomalies detected among high-risk customers in current dataset.

---

## 🧠 Strategic Recommendations
- Prioritise retention for top-decile customers with high CLV proxy.
- Launch reactivation campaigns for inactive customers.
- Cap exposure limits at high-risk branches.
- Repackage Investment products for high-net-worth segments.
- Introduce overdraft scoring for volatile Current accounts.
- Accelerate KYC verification for medium/high-risk customers.
- Deploy churn prediction models using transaction recency and net value.

---

## 🗂️ Data Sources
- `customers_500.csv`: Demographics, region, risk segment, KYC status.
- `accounts_500.csv`: Account type, balance, branch, status.
- `transactions_500.csv`: Transaction type, amount, channel, merchant, status.

---

## 🛠️ Methodology

### 🔹 SQL Views
All views are stored under `braavos.analytics` schema:
- `customer_profitability_view`: Ranks customers by net value per region.
- `account_health`: Flags negative and below-average balance holders.
- `customer_retention`: Identifies inactive customers (> 90 days).
- `risky_accounts`: Summarizes branch-level exposure.
- `account_analysis`: Provides average, median, and percentile balance metrics.
- `high_risk_customers`: Flags anomalies > 2.5× average for high-risk customers.
- `clv_proxy`: Estimates CLV for churned vs retained customers.
- `top_10_contribution`: Calculates Pareto contribution of top 10% customers.
- `branch_risk_index`: Compares branch exposure to network average.

### 🔹 Power BI Dashboards
- **Executive Summary:** KPIs, headline insights, and strategic metrics.
- **Customer Insights:** Segmentation, account health, and retention.
- **Financials:** Transaction trends, product performance, and churn metrics.
- **Risk Monitoring:** Branch exposure, anomaly flags, and KYC compliance.

### 🔹 DAX Measures
- `Total Customers`
- `Active Accounts`
- `Risky Accounts %`
- `Transaction Volume (YTD)`
- `Total Amount`
- `Retention Rate`
- `Churn Rate`
- `Average Amount per region`

---

## 📈 Key Metrics

### 🔸 Account Type Distribution

| Account Type   | Avg Balance | Median | Min | Max | 25th %ile | 75th %ile |
|----------------|-------------|--------|-----|-----|-----------|-----------|
| Investment     | R7,035.14   | R3,863 | –R41K | R120K | –R12K | R23K  
| Credit Card    | R14,140.85  | R7,082 | –R50K | R245K | –R2.7K | R21K  
| Savings        | R12,083.79  | R7,380 | –R45K | R247K | R5.4K | R21K  
| Current        | R10,640.57  | R7,156 | –R50K | R219K | –R7.3K | R12K  
| Money Market   | R8,293.45   | R4,591 | –R43K | R91K | –R9.8K | R12K  

---

## 📬 Contact

**Author:** Wavhothe Masakona  
**Location:** Johannesburg, South Africa  
**Focus:** Banking & Insurance Analytics | SQL | Power BI | Strategic Reporting

