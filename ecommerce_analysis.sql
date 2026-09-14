-- =====================================================
-- Global E-commerce Sales Analytics
-- Database and Schema Setup
-- =====================================================

CREATE OR REPLACE DATABASE ECOMMERCE_DB;

CREATE OR REPLACE SCHEMA ECOMMERCE_DB.ANALYTICS;

CREATE OR REPLACE WAREHOUSE ECOMMERCE_WH
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE WAREHOUSE ECOMMERCE_WH;
USE DATABASE ECOMMERCE_DB;
USE SCHEMA ANALYTICS;


-- =====================================================
-- Raw Orders Table
-- =====================================================

CREATE OR REPLACE TABLE ORDERS_RAW (
    ORDER_ID NUMBER,
    COUNTRY VARCHAR,
    CATEGORY VARCHAR,
    UNIT_PRICE NUMBER(10,2),
    QUANTITY NUMBER,
    ORDER_DATE VARCHAR,
    TOTAL_AMOUNT NUMBER(12,2)
);


-- =====================================================
-- Clean Orders Table
-- Converts ORDER_DATE from VARCHAR to DATE
-- =====================================================

CREATE OR REPLACE TABLE ORDERS_CLEAN AS
SELECT
    ORDER_ID,
    TRIM(COUNTRY) AS COUNTRY,
    TRIM(CATEGORY) AS CATEGORY,
    UNIT_PRICE,
    QUANTITY,
    TRY_TO_DATE(ORDER_DATE, 'MM/DD/YYYY') AS ORDER_DATE,
    TOTAL_AMOUNT
FROM ORDERS_RAW;


-- =====================================================
-- KPI View
-- =====================================================

CREATE OR REPLACE VIEW VW_ECOMMERCE_KPIS AS
SELECT
    SUM(TOTAL_AMOUNT) AS TOTAL_REVENUE,
    COUNT(DISTINCT ORDER_ID) AS TOTAL_ORDERS,
    SUM(QUANTITY) AS TOTAL_UNITS_SOLD,
    ROUND(
        SUM(TOTAL_AMOUNT) / NULLIF(COUNT(DISTINCT ORDER_ID), 0),
        2
    ) AS AVERAGE_ORDER_VALUE
FROM ORDERS_CLEAN;


-- =====================================================
-- Monthly Sales View
-- =====================================================

CREATE OR REPLACE VIEW VW_MONTHLY_SALES AS
SELECT
    DATE_TRUNC('MONTH', ORDER_DATE) AS MONTH,
    SUM(TOTAL_AMOUNT) AS MONTHLY_REVENUE,
    COUNT(DISTINCT ORDER_ID) AS TOTAL_ORDERS,
    SUM(QUANTITY) AS TOTAL_UNITS_SOLD
FROM ORDERS_CLEAN
GROUP BY DATE_TRUNC('MONTH', ORDER_DATE)
ORDER BY MONTH;


-- =====================================================
-- Country Performance View
-- =====================================================

CREATE OR REPLACE VIEW VW_COUNTRY_PERFORMANCE AS
SELECT
    COUNTRY,
    SUM(TOTAL_AMOUNT) AS TOTAL_REVENUE,
    COUNT(DISTINCT ORDER_ID) AS TOTAL_ORDERS,
    SUM(QUANTITY) AS TOTAL_UNITS_SOLD,
    ROUND(
        SUM(TOTAL_AMOUNT) / NULLIF(COUNT(DISTINCT ORDER_ID), 0),
        2
    ) AS AVERAGE_ORDER_VALUE
FROM ORDERS_CLEAN
GROUP BY COUNTRY
ORDER BY TOTAL_REVENUE DESC;


-- =====================================================
-- Category Performance View
-- =====================================================

CREATE OR REPLACE VIEW VW_CATEGORY_PERFORMANCE AS
SELECT
    CATEGORY,
    SUM(TOTAL_AMOUNT) AS TOTAL_REVENUE,
    COUNT(DISTINCT ORDER_ID) AS TOTAL_ORDERS,
    SUM(QUANTITY) AS TOTAL_UNITS_SOLD,
    ROUND(
        SUM(TOTAL_AMOUNT) / NULLIF(COUNT(DISTINCT ORDER_ID), 0),
        2
    ) AS AVERAGE_ORDER_VALUE
FROM ORDERS_CLEAN
GROUP BY CATEGORY
ORDER BY TOTAL_REVENUE DESC;


-- =====================================================
-- Data Validation Queries
-- =====================================================

-- Check row count
SELECT COUNT(*) AS TOTAL_ROWS
FROM ORDERS_CLEAN;

-- Check missing values in important fields
SELECT
    COUNT_IF(ORDER_ID IS NULL) AS NULL_ORDER_IDS,
    COUNT_IF(COUNTRY IS NULL) AS NULL_COUNTRIES,
    COUNT_IF(CATEGORY IS NULL) AS NULL_CATEGORIES,
    COUNT_IF(ORDER_DATE IS NULL) AS NULL_ORDER_DATES,
    COUNT_IF(TOTAL_AMOUNT IS NULL) AS NULL_TOTAL_AMOUNTS
FROM ORDERS_CLEAN;

-- Validate total amount against unit price multiplied by quantity
SELECT
    COUNT(*) AS TOTAL_ROWS,
    COUNT_IF(
        ABS(TOTAL_AMOUNT - (UNIT_PRICE * QUANTITY)) > 0.01
    ) AS AMOUNT_MISMATCHES
FROM ORDERS_CLEAN;