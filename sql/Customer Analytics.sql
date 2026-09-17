CREATE DATABASE customer_analytics;
USE customer_analytics;

SHOW TABLES;
DESCRIBE customers;
DESCRIBE transactions;
SELECT COUNT(CustomerID), COUNT(DISTINCT CustomerID)
FROM customers;
SELECT t.CustomerID
FROM transactions t
LEFT JOIN customers c ON t.CustomerID = c.CustomerID
WHERE c.CustomerID IS NULL;
SELECT CustomerID, Acquisition_Date, Churn_Date
FROM customers
WHERE Churn_Date < Acquisition_Date;
USE customer_analytics;

-- 1. Check unique IDs
SELECT COUNT(CustomerID) AS TotalCustomers,
       COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM customers;

SELECT COUNT(ProductID) AS TotalProducts,
       COUNT(DISTINCT ProductID) AS UniqueProducts
FROM products;

SELECT COUNT(TransactionID) AS TotalTransactions,
       COUNT(DISTINCT TransactionID) AS UniqueTransactions
FROM transactions;

-- 2. Validate foreign keys
SELECT t.CustomerID
FROM transactions t
LEFT JOIN customers c ON t.CustomerID = c.CustomerID
WHERE c.CustomerID IS NULL;

SELECT t.ProductID
FROM transactions t
LEFT JOIN products p ON t.ProductID = p.ProductID
WHERE p.ProductID IS NULL;

-- 3. Date consistency
SELECT CustomerID, Acquisition_Date, Churn_Date
FROM customers
WHERE Churn_Date IS NOT NULL AND Churn_Date < Acquisition_Date;

SELECT TransactionID, Transaction_Date, c.Acquisition_Date
FROM transactions t
JOIN customers c ON t.CustomerID = c.CustomerID
WHERE Transaction_Date < Acquisition_Date;

-- 4. Revenue & Profit accuracy
SELECT TransactionID, Revenue, Cost, Profit,
       (Revenue - Cost) AS ExpectedProfit
FROM transactions
WHERE Profit <> (Revenue - Cost);

-- 5. Missing data checks
SELECT COUNT(*) AS MissingOccupation
FROM customers
WHERE Occupation IS NULL;

SELECT COUNT(*) AS MissingIncomeBand
FROM customers
WHERE Income_Band IS NULL;

SELECT COUNT(*) AS MissingSatisfaction
FROM customer_service;

DELETE FROM customers
WHERE CustomerID IN (
    SELECT CustomerID
    FROM (
        SELECT CustomerID,
               ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY Acquisition_Date) AS rn
        FROM customers
    ) tmp
    WHERE rn > 1
);

DELETE FROM transactions
WHERE CustomerID NOT IN (SELECT CustomerID FROM customers);

DELETE FROM transactions
WHERE ProductID NOT IN (SELECT ProductID FROM products);

UPDATE customers
SET Churn_Date = NULL
WHERE Churn_Date < Acquisition_Date;

UPDATE transactions
SET Profit = Revenue - Cost
WHERE Profit <> (Revenue - Cost);

-- Example: fill missing occupation with 'Unknown'
UPDATE customers
SET Occupation = 'Unknown'
WHERE Occupation IS NULL;

-- Example: fill missing income band with 'Not Provided'
UPDATE customers
SET Income_Band = 'Not Provided'
WHERE Income_Band IS NULL;

-- Create an RFM base table
WITH rfm_base AS (
    SELECT 
        t.CustomerID,
        DATEDIFF(CURDATE(), MAX(t.Transaction_Date)) AS Recency,   -- days since last purchase
        COUNT(t.TransactionID) AS Frequency,                       -- number of transactions
        SUM(t.Revenue) AS Monetary                                 -- total spending
    FROM transactions t
    GROUP BY t.CustomerID
)
SELECT * FROM rfm_base;

WITH rfm_scores AS (
    SELECT 
        CustomerID,
        Recency,
        Frequency,
        Monetary,
        NTILE(5) OVER (ORDER BY Recency ASC) AS R_Score,   -- lower recency = better
        NTILE(5) OVER (ORDER BY Frequency DESC) AS F_Score,
        NTILE(5) OVER (ORDER BY Monetary DESC) AS M_Score
    FROM (
        SELECT 
            t.CustomerID,
            DATEDIFF(CURDATE(), MAX(t.Transaction_Date)) AS Recency,
            COUNT(t.TransactionID) AS Frequency,
            SUM(t.Revenue) AS Monetary
        FROM transactions t
        GROUP BY t.CustomerID
    ) sub
)
SELECT * FROM rfm_scores;

WITH rfm_scores AS (
    SELECT 
        CustomerID,
        DATEDIFF(CURDATE(), MAX(Transaction_Date)) AS Recency,
        COUNT(TransactionID) AS Frequency,
        SUM(Revenue) AS Monetary,
        NTILE(5) OVER (ORDER BY DATEDIFF(CURDATE(), MAX(Transaction_Date)) ASC) AS R_Score,
        NTILE(5) OVER (ORDER BY COUNT(TransactionID) DESC) AS F_Score,
        NTILE(5) OVER (ORDER BY SUM(Revenue) DESC) AS M_Score
    FROM transactions
    GROUP BY CustomerID
),
rfm_segments AS (
    SELECT 
        CustomerID,
        R_Score,
        F_Score,
        M_Score,
        (R_Score + F_Score + M_Score) AS RFM_Total,
        CASE
            WHEN R_Score >=4 AND F_Score >=4 AND M_Score >=4 THEN 'Champions'
            WHEN R_Score >=3 AND F_Score >=4 THEN 'Loyal Customers'
            WHEN R_Score >=4 AND F_Score <=2 THEN 'Potential Loyalists'
            WHEN R_Score <=2 AND F_Score >=4 THEN 'At Risk'
            WHEN R_Score <=2 AND F_Score <=2 THEN 'Lost Customers'
            ELSE 'Others'
        END AS Segment
    FROM rfm_scores
)
SELECT * FROM rfm_segments;

WITH customer_cohorts AS (
    SELECT 
        CustomerID,
        DATE_FORMAT(Acquisition_Date, '%Y-%m') AS CohortMonth
    FROM customers
)
SELECT * FROM customer_cohorts;

WITH customer_cohorts AS (
    SELECT 
        CustomerID,
        DATE_FORMAT(Acquisition_Date, '%Y-%m') AS CohortMonth
    FROM customers
),
cohort_activity AS (
    SELECT 
        c.CohortMonth,
        DATE_FORMAT(t.Transaction_Date, '%Y-%m') AS ActivityMonth,
        COUNT(DISTINCT t.CustomerID) AS ActiveCustomers
    FROM transactions t
    JOIN customer_cohorts c ON t.CustomerID = c.CustomerID
    GROUP BY c.CohortMonth, ActivityMonth
)
SELECT * FROM cohort_activity
ORDER BY CohortMonth, ActivityMonth;

WITH customer_cohorts AS (
    SELECT 
        CustomerID,
        DATE_FORMAT(Acquisition_Date, '%Y-%m') AS CohortMonth
    FROM customers
),
cohort_sizes AS (
    SELECT CohortMonth, COUNT(DISTINCT CustomerID) AS CohortSize
    FROM customer_cohorts
    GROUP BY CohortMonth
),
cohort_activity AS (
    SELECT 
        c.CohortMonth,
        DATE_FORMAT(t.Transaction_Date, '%Y-%m') AS ActivityMonth,
        COUNT(DISTINCT t.CustomerID) AS ActiveCustomers
    FROM transactions t
    JOIN customer_cohorts c ON t.CustomerID = c.CustomerID
    GROUP BY c.CohortMonth, ActivityMonth
)
SELECT 
    a.CohortMonth,
    a.ActivityMonth,
    a.ActiveCustomers,
    s.CohortSize,
    ROUND(a.ActiveCustomers / s.CohortSize * 100, 2) AS RetentionRate
FROM cohort_activity a
JOIN cohort_sizes s ON a.CohortMonth = s.CohortMonth
ORDER BY a.CohortMonth, a.ActivityMonth;

SELECT 
    COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN Churn_Status = 'Churned' THEN 1 ELSE 0 END) AS ChurnedCustomers,
    ROUND(SUM(CASE WHEN Churn_Status = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS ChurnRate
FROM customers;

-- Churn by Age Group
SELECT Age_Group,
       SUM(CASE WHEN Churn_Status = 'Churned' THEN 1 ELSE 0 END) AS Churned,
       COUNT(*) AS Total,
       ROUND(SUM(CASE WHEN Churn_Status = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS ChurnRate
FROM customers
GROUP BY Age_Group
ORDER BY ChurnRate DESC;

-- Churn by Gender
SELECT Gender,
       SUM(CASE WHEN Churn_Status = 'Churned' THEN 1 ELSE 0 END) AS Churned,
       COUNT(*) AS Total,
       ROUND(SUM(CASE WHEN Churn_Status = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS ChurnRate
FROM customers
GROUP BY Gender;

WITH rfm_scores AS (
    SELECT 
        CustomerID,
        DATEDIFF(CURDATE(), MAX(Transaction_Date)) AS Recency,
        COUNT(TransactionID) AS Frequency,
        SUM(Revenue) AS Monetary,
        NTILE(5) OVER (ORDER BY DATEDIFF(CURDATE(), MAX(Transaction_Date)) ASC) AS R_Score,
        NTILE(5) OVER (ORDER BY COUNT(TransactionID) DESC) AS F_Score,
        NTILE(5) OVER (ORDER BY SUM(Revenue) DESC) AS M_Score
    FROM transactions
    GROUP BY CustomerID
),
rfm_segments AS (
    SELECT 
        CustomerID,
        CASE
            WHEN R_Score >=4 AND F_Score >=4 AND M_Score >=4 THEN 'Champions'
            WHEN R_Score >=3 AND F_Score >=4 THEN 'Loyal Customers'
            WHEN R_Score >=4 AND F_Score <=2 THEN 'Potential Loyalists'
            WHEN R_Score <=2 AND F_Score >=4 THEN 'At Risk'
            WHEN R_Score <=2 AND F_Score <=2 THEN 'Lost Customers'
            ELSE 'Others'
        END AS Segment
    FROM rfm_scores
)
SELECT r.Segment,
       SUM(CASE WHEN c.Churn_Status = 'Churned' THEN 1 ELSE 0 END) AS Churned,
       COUNT(*) AS Total,
       ROUND(SUM(CASE WHEN c.Churn_Status = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS ChurnRate
FROM customers c
JOIN rfm_segments r ON c.CustomerID = r.CustomerID
GROUP BY r.Segment
ORDER BY ChurnRate DESC;

SELECT Churn_Reason,
       COUNT(*) AS Count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customers WHERE Churn_Status='Churned'), 2) AS Percentage
FROM customers
WHERE Churn_Status = 'Churned'
GROUP BY Churn_Reason
ORDER BY Count DESC;









