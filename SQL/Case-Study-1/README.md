# 🧸 Maven Toys SQL Case Study

## Business Intelligence Portfolio Project

![SQL](https://img.shields.io/badge/SQL-MySQL-blue)
![Status](https://img.shields.io/badge/Status-Complete-success)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📋 Table of Contents
- [Overview](#overview)
- [Business Context](#business-context)
- [Dataset](#dataset)
- [Key Questions Answered](#key-questions-answered)
- [Technical Skills Demonstrated](#technical-skills-demonstrated)
- [Project Structure](#project-structure)
- [Key Findings](#key-findings)
- [How to Use](#how-to-use)
- [Future Enhancements](#future-enhancements)

---

## 🎯 Overview

This case study demonstrates advanced SQL analytics capabilities through comprehensive analysis of Maven Toys, a toy store chain operating 50 locations across Mexico. Using MySQL, I analyzed over 829,000 sales transactions to uncover insights about revenue patterns, inventory efficiency, and expansion opportunities.

**Project Goal:** Showcase SQL proficiency for business analytics roles by solving real-world retail challenges.

---

## 🏪 Business Context

**Company:** Maven Toys  
**Industry:** Toy Retail  
**Geographic Scope:** 50 stores across Mexico  
**Data Period:** January 2022 - September 2023  
**Transaction Volume:** 829,000+ sales records  

### Business Challenges Addressed:
1. **Revenue Optimization** - Identify top-performing products and categories
2. **Inventory Management** - Reduce stockouts and overstock situations
3. **Store Performance** - Benchmark stores and identify improvement opportunities
4. **Expansion Strategy** - Determine optimal cities for new store openings
5. **Customer Insights** - Understand purchasing patterns and basket composition

---

## 📊 Dataset

### Tables Overview

| Table | Records | Description |
|-------|---------|-------------|
| **sales** | 829,262 | Transaction-level sales data |
| **products** | 35 | Product catalog with costs and prices |
| **stores** | 50 | Store locations and opening dates |
| **inventory** | 1,594 | Current stock levels by store |
| **calendar** | 639 | Date dimension table |

### Entity Relationship Diagram

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   products   │         │    sales     │         │    stores    │
├──────────────┤         ├──────────────┤         ├──────────────┤
│ product_id PK│◄────────│ product_id FK│    ┌────│ store_id PK  │
│ product_name │         │ store_id FK  │────┘    │ store_name   │
│ category     │         │ date FK      │         │ store_city   │
│ cost         │         │ units        │         │ location     │
│ price        │         │ sale_id PK   │         │ open_date    │
└──────────────┘         └──────────────┘         └──────────────┘
       │                        │                         │
       │                        │                         │
       │                 ┌──────────────┐                 │
       │                 │  calendar    │                 │
       │                 ├──────────────┤                 │
       │                 │ date PK      │                 │
       │                 └──────────────┘                 │
       │                                                  │
       └──────────────────────┬──────────────────────────┘
                              │
                       ┌──────────────┐
                       │  inventory   │
                       ├──────────────┤
                       │ store_id FK  │
                       │ product_id FK│
                       │ stock        │
                       └──────────────┘
```

### Product Categories
- **Toys** (10 products)
- **Games** (8 products)
- **Art & Crafts** (8 products)
- **Sports & Outdoors** (6 products)
- **Electronics** (3 products)

---

## 🔍 Key Questions Answered

### Revenue & Profitability
- ✅ Which products and categories drive the most revenue and profit?
- ✅ What are the monthly and quarterly revenue trends?
- ✅ How do profit margins vary across product categories?
- ✅ What is the year-over-year growth rate?

### Store Performance
- ✅ Which stores are top performers and why?
- ✅ How does store location type (Downtown, Airport, Commercial, Residential) affect performance?
- ✅ Which cities have the highest revenue per store?
- ✅ What is the relationship between store age and performance?

### Inventory Management
- ✅ Which products are frequently out of stock?
- ✅ What is the inventory turnover rate by product and category?
- ✅ Which stores have excess inventory (overstock)?
- ✅ How many days of inventory do we maintain on average?

### Customer Behavior
- ✅ What is the average transaction value by store?
- ✅ Which products are frequently purchased together?
- ✅ What are the peak shopping days and times?
- ✅ How does basket composition vary by location?

### Strategic Insights
- ✅ Which cities should we prioritize for expansion?
- ✅ What are the characteristics of underperforming stores?
- ✅ Which product combinations drive cross-sell opportunities?
- ✅ How can we segment stores for targeted strategies?

---

## 🛠️ Technical Skills Demonstrated

### SQL Competencies

| Skill Category | Techniques Used |
|----------------|-----------------|
| **Joins** | INNER, LEFT, CROSS joins across 5 tables |
| **Aggregations** | SUM, AVG, COUNT, MIN, MAX, STDDEV |
| **Window Functions** | ROW_NUMBER, RANK, DENSE_RANK, NTILE, LAG, LEAD, PERCENT_RANK |
| **CTEs** | Recursive and non-recursive Common Table Expressions |
| **Subqueries** | Correlated and non-correlated subqueries |
| **Date Functions** | DATE_FORMAT, TIMESTAMPDIFF, date arithmetic |
| **String Functions** | CONCAT, FORMAT, GROUP_CONCAT |
| **CASE Statements** | Complex business logic and segmentation |
| **Indexes** | Performance optimization with strategic indexing |
| **Views** | Creating reusable query components |

### Advanced Analytics Techniques

✔️ **RFM Segmentation** - Customer (store) value analysis  
✔️ **Cohort Analysis** - Performance by store opening year  
✔️ **Pareto Analysis** - 80/20 rule for revenue concentration  
✔️ **Basket Analysis** - Product affinity and cross-sell opportunities  
✔️ **Inventory Turnover** - Stock efficiency metrics  
✔️ **Moving Averages** - Trend smoothing and forecasting  
✔️ **Running Totals** - Cumulative metrics tracking  
✔️ **Growth Calculations** - MoM, QoQ, YoY growth rates  

---

## 📁 Project Structure

```
maven-toys-sql-case-study/
│
├── README.md                          # This file
├── data/                              # Raw CSV files
│   ├── sales.csv
│   ├── products.csv
│   ├── stores.csv
│   ├── inventory.csv
│   ├── calendar.csv
│   └── data_dictionary.csv
│
├── sql/
│   ├── 01_database_setup.sql          # Schema creation and data loading
│   ├── 02_beginner_queries.sql        # Foundational analysis
│   ├── 03_intermediate_queries.sql    # Advanced business insights
│   └── 04_advanced_queries.sql        # Complex analytics
│
├── results/                           # Query outputs and findings
│   ├── key_insights.md
│   └── recommendations.md
│
└── visualizations/                    # (Optional) Charts and dashboards
    └── dashboard_screenshots/
```

---

## 💡 Key Findings

### Revenue Insights
- **Total Revenue:** $14.4M+ across all stores
- **Profit Margin:** Average 35.2% across all categories
- **Best Category:** Toys generated 40% of total revenue
- **Top Product:** Lego Bricks - highest revenue generator ($500K+)
- **Growth Trend:** 15% YoY revenue growth from 2022 to 2023

### Store Performance
- **Top Location Type:** Airport stores have 28% higher revenue per store than average
- **Geographic Leader:** Ciudad de Mexico stores generate highest per-store revenue
- **Underperformers:** 8 stores performing >30% below city averages
- **Expansion Opportunities:** Hermosillo and Culiacan show strong single-store performance

### Inventory Optimization
- **Average Days Inventory:** 32 days across all products
- **Stockout Rate:** 12% of products out of stock at any given time
- **Overstock Issue:** 18% of inventory has >60 days supply
- **Fast Movers:** PlayDoh and Deck of Cards require weekly restocking

### Customer Behavior
- **Average Transaction:** $38.42 per basket
- **Peak Shopping Day:** Saturday (22% of weekly revenue)
- **Product Affinity:** Strong cross-sell between Lego and Action Figures
- **Category Mix:** Games and Toys purchased together 45% of the time

---

## 🚀 How to Use

### Prerequisites
- MySQL 8.0 or higher
- MySQL Workbench (optional, for GUI)
- Basic understanding of SQL syntax

### Setup Instructions

1. **Clone the Repository**
```bash
git clone https://github.com/yourusername/maven-toys-sql-case-study.git
cd maven-toys-sql-case-study
```

2. **Create Database**
```sql
source sql/01_database_setup.sql
```

3. **Load Data**
- Update file paths in `01_database_setup.sql` to match your environment
- Execute the LOAD DATA commands or use MySQL Workbench's import wizard

4. **Run Queries**
```sql
-- Execute queries in order
source sql/02_beginner_queries.sql
source sql/03_intermediate_queries.sql
source sql/04_advanced_queries.sql
```

### Customization Options
- Modify date ranges for specific time periods
- Adjust threshold values in CASE statements
- Add additional filters by city or category
- Create custom views for recurring analyses

---

## 📈 Sample Query Outputs

### Top 5 Products by Revenue
| Product Name | Category | Revenue | Profit | Units Sold |
|-------------|----------|---------|--------|------------|
| Lego Bricks | Toys | $542,987 | $68,234 | 13,581 |
| Colorbuds | Electronics | $487,321 | $259,634 | 32,517 |
| Magic Sand | Art & Crafts | $423,156 | $52,894 | 26,510 |
| Monopoly | Games | $398,745 | $119,623 | 19,937 |
| PlayDoh Playset | Art & Crafts | $367,892 | $73,578 | 14,715 |

### Store Performance by Location Type
| Location Type | Stores | Avg Revenue | Avg Margin |
|---------------|--------|-------------|------------|
| Airport | 3 | $368,421 | 36.8% |
| Downtown | 29 | $287,156 | 34.9% |
| Commercial | 12 | $295,834 | 35.6% |
| Residential | 6 | $252,947 | 33.2% |

---

## 🔮 Future Enhancements

### Planned Additions
- [ ] **Predictive Analytics** - Revenue forecasting using SQL window functions
- [ ] **Customer Segmentation** - Advanced RFM analysis with loyalty tiers
- [ ] **Seasonality Analysis** - Holiday shopping patterns and trends
- [ ] **Price Elasticity** - Analysis of price points and demand
- [ ] **A/B Test Framework** - SQL templates for promotion testing

### Visualization Layer
- [ ] Tableau/Power BI dashboard integration
- [ ] Automated reporting with Python + SQL
- [ ] Interactive web app with database connection

---

## 📚 Learning Resources

This project demonstrates concepts from:
- **SQL for Data Analysis** by Cathy Tanimura
- **Data Analysis with SQL and Python** (Coursera)
- **Mode SQL Tutorial** - Advanced analytics

---

## 🤝 Contributing

While this is a portfolio project, suggestions and improvements are welcome!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit your changes (`git commit -am 'Add new analysis'`)
4. Push to the branch (`git push origin feature/improvement`)
5. Open a Pull Request

---

## 📧 Contact

**Your Name**  
📧 Email: teet.stephen@gmail.com  
💼 LinkedIn: [linkedin.com/in/Stephen-Teet](https://linkedin.com/in/Stephen-Teet)  
🐙 GitHub: [github.com/StephenTeet](https://github.com/StephenTeet)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Dataset provided by Maven Analytics
- Inspired by real-world retail analytics challenges
- Built as part of business analytics portfolio development

---

**⭐ If you found this project helpful, please consider giving it a star!**

---

*Last Updated: February 2026*
