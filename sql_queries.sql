-- ============================================================
-- Supplier Payment & Risk Analysis — SQL Queries
-- Database: Oracle APEX
-- Author: Myrzabek Sagynzhan | SDU University | June 2026
-- Note: All supplier/object names anonymized for portfolio
-- ============================================================


-- ── QUERY 1: All suppliers summary ──────────────────────────
SELECT
    SUPPLIER_NAME,
    SUPPLIER_TYPE,
    ROUND(CONTRACT_SUM / 1000000, 2)  AS CONTRACT_M,
    ROUND(TOTAL_PAID   / 1000000, 2)  AS PAID_M,
    ROUND(AMOUNT_TO_PAY/ 1000000, 2)  AS TO_PAY_M,
    PAYMENT_RATE_PCT                   AS PAID_PCT
FROM SUPPLIERS
ORDER BY CONTRACT_SUM DESC;


-- ── QUERY 2: Summary grouped by supplier type ───────────────
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


-- ── QUERY 3: Suppliers with outstanding payments ─────────────
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


-- ── QUERY 4: JOIN suppliers and contracts (Top 10) ───────────
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


-- ── QUERY 5: Risk assessment classification ──────────────────
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
