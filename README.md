# Sql-video-rental-analysis
SQL business analysis project using the Sakila database

SQL Business Analysis Project — Video Rental Revenue & Inventory Optimization

## Overview
This project uses SQL to analyze a video rental company's data, answering a
central business question: **which film categories and store locations
should the company prioritize for inventory investment and marketing, and
where is money being lost on underused inventory or at-risk customers?**

Eight business questions are answered using joins, aggregate functions,
CASE WHEN logic, subqueries, and HAVING clauses — each paired with a
finding and a "so what" takeaway connecting the data back to a business
decision.

## About the Data
This project uses the Sakila sample database (a fictional DVD rental
company) to demonstrate SQL and business analysis skills. The business
problem, questions, and dataset are for portfolio purposes — not live
company data — but the analytical approach (identifying revenue drivers,
segmenting customers, spotting underperforming assets, and translating
findings into a recommendation) mirrors real reporting and analysis work.

## Key Findings
- **Invest in Comedy, New Releases, and Games** — these categories earn
  above-average revenue per rental ($4.20+), outperforming high-volume
  categories like Action on a per-transaction basis.
- **A large share of the highest lifetime-spending customers are at risk
  of churning** — including top spenders like Karl Seal ($221.55) and
  Eleanor Hunt ($216.54), who haven't rented since mid-to-late 2005.
- **Store 1 and Store 2 perform almost identically**, so there's no
  location-based case for shifting investment between them.
- **No dead inventory** — every title in the catalog has been rented at
  least once, though individual copy-level underuse may still exist.
- **Shorter rental windows show higher late-return rates** — 3-day
  rentals come back late roughly 66% of the time, versus 23% for 7-day
  rentals, suggesting rental duration policy is worth revisiting.

## Tools Used
MySQL Workbench, SQL (joins, aggregates, CASE WHEN, subqueries, HAVING)

## File
See `Averys_portfolio_project.sql` for all 8 questions, queries, and
findings.
