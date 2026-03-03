-- 3. Revenue Cycle: Outstanding Claims

/* 
Tracks the facility's cash flow by comparing total costs against payments 
received and flagging any outstanding balances.
*/

CREATE OR REPLACE VIEW vw_outstanding_claims AS
SELECT
    claims.id AS claim_id,
    claims.service_date,
    claims.patient_id,
    COALESCE(SUM(tx.amount::NUMERIC), 0) AS total_billed_amount,
    COALESCE(SUM(tx.payments::NUMERIC), 0) AS total_amount_paid,
    COALESCE(SUM(tx.adjustments::NUMERIC), 0) AS total_adjustments,
    COALESCE(SUM(tx.outstanding::NUMERIC), 0) AS outstanding_balance
FROM analytics.fact_claims AS claims
LEFT JOIN analytics.fact_claim_transactions AS tx
    ON claims.id = tx.claim_id
GROUP BY 
    claims.id, 
    claims.service_date, 
    claims.patient_id
HAVING COALESCE(SUM(tx.outstanding::NUMERIC), 0) > 0;

SELECT * FROM vw_outstanding_claims;



