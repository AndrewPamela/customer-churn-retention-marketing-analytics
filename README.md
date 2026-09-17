# Customer Churn, Retention & Marketing Analytics

## Project Overview

This project analyses customer behaviour, churn risk, retention patterns, customer value and marketing activity.

The dataset was created using **Python and Faker** to simulate a realistic business environment. I used the data to explore customer behaviour, build churn and customer lifetime value predictions, and present the findings in Power BI.

## Business Questions

* Which customers are most at risk of churn?
* Which customer segments have higher churn risk?
* What factors are associated with customer churn?
* Which customers have higher predicted future value?
* How can customer risk and value support better retention decisions?

## Tools Used

* **Python** – data generation, cleaning, analysis and predictive modelling
* **Pandas & NumPy** – data preparation and analysis
* **Matplotlib & Seaborn** – exploratory data analysis and visualisation
* **Scikit-learn** – churn and CLV modelling
* **SQL** – data analysis and querying
* **Power BI** – dashboard development and reporting
* **Excel** – supporting data preparation and documentation

## Dataset

The dataset is **synthetic data i generated with Faker** for portfolio purposes.

The raw datasets are stored in the `data` folder.

The project contains customer, transaction and marketing-related data used to analyse customer behaviour and business performance.

## Project Workflow

**Data Generation → Data Cleaning → Exploratory Analysis → SQL Analysis → Predictive Modelling → Power BI Dashboard**

## Key Analysis

The project includes:

### Customer Churn Analysis

Customer churn status and churn probability were analysed to identify customers with different levels of retention risk.

### Customer Lifetime Value

Predicted future customer lifetime value was used alongside churn probability to understand the relationship between customer value and retention risk.

### Risk Segmentation

Customers were grouped into risk segments using churn risk and customer value.

### Feature Importance

Feature importance analysis was used to identify the variables contributing most to churn and customer lifetime value predictions.

## Power BI Dashboard

The Power BI dashboard presents the analysis through interactive pages covering:

* **Executive Overview**
* **Customer Demographics**
* **Churn & Retention 1**
* **Churn & Retention 2**

Dashboard screenshots are available in the `screenshots` folder.

The Power BI report is available in the `power-bi` folder.

## Repository Structure

```text
customer-churn-retention-marketing-analytics/
│
├── data/
│   └── Raw synthetic datasets
│
├── screenshots/
│   └── Power BI dashboard screenshots
│
├── python/
│   ├── Python analysis notebook
│   └── outputs/
│       ├── customer_churn_clv_predictions.csv
│       ├── customer_risk_segment_summary.csv
│       ├── churn_feature_importance.csv
│       └── clv_feature_importance.csv
│
├── power-bi/
│   └── Power BI dashboard
│
├── sql/
│   └── SQL analysis
│
└── documentation/
    └── Project Directory.xlsx
## Dashboard Preview

### Executive Overview

![Executive Overview](screenshots/01-executive-overview.png)

### Customer Demographics

![Customer Demographics](screenshots/02-customer-demographics.png)

### Churn & Retention 1

![Churn & Retention 1](screenshots/03-churn-retention-1.png)

### Churn & Retention 2

![Churn & Retention 2](screenshots/04-churn-retention-2.png)


## Project Purpose

This project demonstrates my ability to work across the full analytics process — from creating and preparing data to analysing it with Python and SQL, building predictive outputs, and communicating findings through Power BI.

## Author

**Andrew Pamela**
**DataByPam**

© 2026 Andrew Pamela | DataByPam
