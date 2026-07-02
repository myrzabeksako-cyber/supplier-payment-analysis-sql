# Supplier Payment & Risk Analysis — SQL + Python

**Project:** Industrial Internship 1 | SDU University | June 2026  
**Author:** Myrzabek Sagynzhan  
**Tools:** Oracle APEX (SQL) · Python · pandas · matplotlib  

> All company and supplier names have been anonymized (Supplier A–M, Residential Complex A–C, etc.) to protect confidential business information.

---

## Project Goal

Analyze supplier and subcontractor payment data for a construction company:
- Track **contract values vs actual payments** per supplier
- Identify suppliers with **outstanding debts**
- Classify suppliers by **financial risk level** (Low / Medium / High)
- Build a **relational database** and run SQL queries in Oracle APEX

---

## Files

| File | Description |
|---|---|
| `SUPPLIERS_ANON.csv` | Master supplier table — 13 suppliers, contract sums, payment rates |
| `CONTRACTS_ANON.csv` | Detail contracts table — 30 contracts linked to suppliers |
| `supplier_analysis.ipynb` | Python dashboard built on SQL query results |
| `sql_queries.sql` | All 5 SQL queries used in Oracle APEX |
| `figures/` | Dashboard images |

---

## Database Structure

Two relational tables connected via `SUPPLIER_ID`:

```
SUPPLIERS (13 rows)
├── SUPPLIER_ID (PK)
├── SUPPLIER_NAME
├── SUPPLIER_TYPE (Supplier / Subcontractor)
├── CONTRACT_SUM
├── TOTAL_PAID
├── WORK_DONE
├── AMOUNT_TO_PAY
└── PAYMENT_RATE_PCT

CONTRACTS (30 rows)
├── CONTRACT_ID (PK)
├── SUPPLIER_ID (FK → SUPPLIERS)
├── CONTRACT_REF
├── WORK_TYPE
├── OBJECT_NAME
├── CONTRACT_SUM
├── AMOUNT_PAID
├── WORK_DONE
└── BALANCE
```

---

## SQL Queries (Oracle APEX)

### Query 1 — All Suppliers Summary
```sql
SELECT
    SUPPLIER_NAME,
    SUPPLIER_TYPE,
    ROUND(CONTRACT_SUM / 1000000, 2)  AS CONTRACT_M,
    ROUND(TOTAL_PAID   / 1000000, 2)  AS PAID_M,
    ROUND(AMOUNT_TO_PAY/ 1000000, 2)  AS TO_PAY_M,
    PAYMENT_RATE_PCT                   AS PAID_PCT
FROM SUPPLIERS
ORDER BY CONTRACT_SUM DESC;
```

### Query 2 — Group by Supplier Type
```sql
SELECT
    SUPPLIER_TYPE,
    COUNT(*)                               AS SUPPLIER_COUNT,
    ROUND(SUM(CONTRACT_SUM)/1000000, 2)    AS TOTAL_CONTRACT_M,
    ROUND(SUM(TOTAL_PAID)  /1000000, 2)    AS TOTAL_PAID_M,
    ROUND(SUM(AMOUNT_TO_PAY)/1000000, 2)   AS TOTAL_TO_PAY_M,
    ROUND(AVG(PAYMENT_RATE_PCT), 1)        AS AVG_PAID_PCT
FROM SUPPLIERS
GROUP BY SUPPLIER_TYPE
ORDER BY TOTAL_CONTRACT_M DESC;
```

### Query 3 — Suppliers with Outstanding Payments
```sql
SELECT
    SUPPLIER_NAME,
    SUPPLIER_TYPE,
    ROUND(AMOUNT_TO_PAY / 1000000, 2)              AS TO_PAY_M,
    ROUND(AMOUNT_TO_PAY * 100 / CONTRACT_SUM, 1)   AS UNPAID_PCT,
    CASE
        WHEN PAYMENT_RATE_PCT = 0   THEN 'NOT STARTED'
        WHEN PAYMENT_RATE_PCT < 50  THEN 'EARLY STAGE'
        WHEN PAYMENT_RATE_PCT < 90  THEN 'IN PROGRESS'
        ELSE 'NEARLY DONE'
    END AS STATUS
FROM SUPPLIERS
WHERE AMOUNT_TO_PAY > 0
ORDER BY AMOUNT_TO_PAY DESC;
```

### Query 4 — JOIN: Suppliers × Contracts (Top 10)
```sql
SELECT
    S.SUPPLIER_NAME,
    C.WORK_TYPE,
    C.OBJECT_NAME,
    ROUND(C.CONTRACT_SUM / 1000000, 2)  AS CONTRACT_M,
    ROUND(C.AMOUNT_PAID  / 1000000, 2)  AS PAID_M,
    ROUND(C.BALANCE      / 1000000, 2)  AS BALANCE_M
FROM CONTRACTS C
JOIN SUPPLIERS S ON C.SUPPLIER_ID = S.SUPPLIER_ID
ORDER BY C.CONTRACT_SUM DESC
FETCH FIRST 10 ROWS ONLY;
```

### Query 5 — Risk Assessment
```sql
SELECT
    SUPPLIER_NAME,
    ROUND(CONTRACT_SUM   / 1000000, 2)  AS CONTRACT_M,
    ROUND(AMOUNT_TO_PAY  / 1000000, 2)  AS TO_PAY_M,
    PAYMENT_RATE_PCT,
    CASE
        WHEN PAYMENT_RATE_PCT >= 80 THEN 'LOW RISK'
        WHEN PAYMENT_RATE_PCT >= 40 THEN 'MEDIUM RISK'
        ELSE                             'HIGH RISK'
    END AS RISK_LEVEL
FROM SUPPLIERS
ORDER BY
    CASE
        WHEN PAYMENT_RATE_PCT >= 80 THEN 3
        WHEN PAYMENT_RATE_PCT >= 40 THEN 2
        ELSE 1
    END,
    CONTRACT_SUM DESC;
```

---

## Key Findings

- Total contract value: **~161 M₸** across 13 suppliers
- Total paid: **~101 M₸** (62.7% of all contracts)
- Outstanding payments: **~60 M₸** — 8 suppliers with unpaid balances
- **4 suppliers classified as HIGH RISK** (payment rate = 0%)
- Largest single outstanding payment: **~26.9 M₸** (Supplier J — external networks)

---

## How to Use

1. Import `SUPPLIERS_ANON.csv` and `CONTRACTS_ANON.csv` into any SQL database (Oracle, PostgreSQL, SQLite)
2. Run queries from `sql_queries.sql`
3. Open `supplier_analysis.ipynb` to see the Python visualization

```python
# Quick start in Python
import pandas as pd
import sqlite3

df_s = pd.read_csv('SUPPLIERS_ANON.csv')
df_c = pd.read_csv('CONTRACTS_ANON.csv')

conn = sqlite3.connect(':memory:')
df_s.to_sql('SUPPLIERS', conn, index=False)
df_c.to_sql('CONTRACTS', conn, index=False)

# Run any query
result = pd.read_sql("SELECT * FROM SUPPLIERS ORDER BY CONTRACT_SUM DESC", conn)
print(result)
```
