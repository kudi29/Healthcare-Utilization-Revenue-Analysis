-- =============================================
-- Make sure the analytics schema exists
-- =============================================
CREATE SCHEMA IF NOT EXISTS analytics;

-- =============================================
-- 1. Analytics Patients Dimension Table
-- =============================================
DROP TABLE IF EXISTS analytics.dim_patients CASCADE;
CREATE TABLE analytics.dim_patients AS
SELECT DISTINCT ON (id) *
FROM raw.patients
ORDER BY id, birthdate DESC;

ALTER TABLE analytics.dim_patients
ADD CONSTRAINT pk_dim_patients PRIMARY KEY (id);

ALTER TABLE analytics.dim_patients
ALTER COLUMN id SET NOT NULL,
ALTER COLUMN first SET NOT NULL,
ALTER COLUMN last SET NOT NULL;

-- =============================================
-- 2. Analytics Providers Dimension Table
-- =============================================
DROP TABLE IF EXISTS analytics.dim_providers CASCADE;
CREATE TABLE analytics.dim_providers AS
SELECT DISTINCT ON(id) *
FROM raw.providers
ORDER BY id;

ALTER TABLE analytics.dim_providers
ADD CONSTRAINT pk_dim_providers PRIMARY KEY (id);

ALTER TABLE analytics.dim_providers
ALTER COLUMN id SET NOT NULL,
ALTER COLUMN name SET NOT NULL;

-- =============================================
-- 3. Analytics Encounters Fact Table
-- =============================================
DROP TABLE IF EXISTS analytics.fact_encounters CASCADE;
CREATE TABLE analytics.fact_encounters AS
SELECT e.*
FROM raw.encounters e
WHERE e.patient IN (SELECT id FROM analytics.dim_patients)
AND e.provider IN (SELECT id FROM analytics.dim_providers);

ALTER TABLE analytics.fact_encounters
ADD CONSTRAINT pk_fact_encounters PRIMARY KEY (id);

ALTER TABLE analytics.fact_encounters
ALTER COLUMN id SET NOT NULL,
ALTER COLUMN patient SET NOT NULL;

-- =============================================
-- 4. Analytics Conditions Fact Table
-- =============================================
DROP TABLE IF EXISTS analytics.fact_conditions CASCADE;
CREATE TABLE analytics.fact_conditions AS
SELECT DISTINCT c.*
FROM raw.conditions c
WHERE c.patient_id IN (SELECT id FROM analytics.dim_patients)
AND c.encounter_id IN (SELECT id FROM analytics.fact_encounters);

ALTER TABLE analytics.fact_conditions
ADD CONSTRAINT pk_fact_conditions PRIMARY KEY (patient_id, encounter_id, start_date, code);

-- =============================================
-- 5. Analytics Claim Transactions Fact Table
-- =============================================
DROP TABLE IF EXISTS analytics.fact_claim_transactions CASCADE;
CREATE TABLE analytics.fact_claim_transactions AS
SELECT ct.*
FROM raw.claim_transactions ct
WHERE ct.patient_id IN (SELECT id FROM analytics.dim_patients)
AND ct.provider_id IN (SELECT id FROM analytics.dim_providers);

ALTER TABLE analytics.fact_claim_transactions
ADD CONSTRAINT pk_fact_claim_transactions PRIMARY KEY (id);

ALTER TABLE analytics.fact_claim_transactions
ALTER COLUMN id SET NOT NULL,
ALTER COLUMN patient_id SET NOT NULL;

-- =============================================
-- 6. Analytics Claims Fact Table
-- =============================================
DROP TABLE IF EXISTS analytics.fact_claims CASCADE;
CREATE TABLE analytics.fact_claims AS
SELECT c.*
FROM raw.claims c
WHERE c.patient_id IN (SELECT id FROM analytics.dim_patients)
AND c.provider_id IN (SELECT id FROM analytics.dim_providers);

ALTER TABLE analytics.fact_claims
ADD CONSTRAINT pk_fact_claims PRIMARY KEY (id);

ALTER TABLE analytics.fact_claims
ALTER COLUMN id SET NOT NULL,
ALTER COLUMN patient_id SET NOT NULL,
ALTER COLUMN provider_id SET NOT NULL;

-- =============================================
-- 7. Add Foreign Key Constraints
-- =============================================
-- Encounters -> Patients, Providers

ALTER TABLE analytics.fact_encounters
ADD CONSTRAINT fk_fact_encounters_patient FOREIGN KEY (patient_id) REFERENCES analytics.dim_patients(id),
ADD CONSTRAINT fk_fact_encounters_provider FOREIGN KEY (provider_id) REFERENCES analytics.dim_providers(id);

-- Conditions -> Patients, Encounters
ALTER TABLE analytics.fact_conditions
ADD CONSTRAINT fk_fact_conditions_patient FOREIGN KEY (patient_id) REFERENCES analytics.dim_patients(id),
ADD CONSTRAINT fk_fact_conditions_encounter FOREIGN KEY (encounter_id) REFERENCES analytics.fact_encounters(id);

-- Claim Transactions -> Patients, Providers
ALTER TABLE analytics.fact_claim_transactions
ADD CONSTRAINT fk_fact_claim_transactions_patient FOREIGN KEY (patient_id) REFERENCES analytics.dim_patients(id),
ADD CONSTRAINT fk_fact_claim_transactions_provider FOREIGN KEY (provider_id) REFERENCES analytics.dim_providers(id),
ADD CONSTRAINT fk_fact_claim_transactions_supervising_provider FOREIGN KEY (supervising_provider_id) REFERENCES analytics.dim_providers(id);

-- Claims -> Patients, Providers
ALTER TABLE analytics.fact_claims
ADD CONSTRAINT fk_fact_claims_patient FOREIGN KEY (patient_id) REFERENCES analytics.dim_patients(id),
ADD CONSTRAINT fk_fact_claims_provider FOREIGN KEY (provider_id) REFERENCES analytics.dim_providers(id),
ADD CONSTRAINT fk_fact_claims_referring_provider FOREIGN KEY (referring_provider_id) REFERENCES analytics.dim_providers(id),
ADD CONSTRAINT fk_fact_claims_supervising_provider FOREIGN KEY (supervising_provider_id) REFERENCES analytics.dim_providers(id);

-- =============================================
-- 8. Add Indexes for Faster Analysis
-- =============================================

CREATE INDEX idx_fact_encounters_patient ON analytics.fact_encounters(patient_id);
CREATE INDEX idx_fact_encounters_provider ON analytics.fact_encounters(provider_id);
CREATE INDEX idx_fact_conditions_patient ON analytics.fact_conditions(patient_id);
CREATE INDEX idx_fact_conditions_encounter ON analytics.fact_conditions(encounter_id);
CREATE INDEX idx_fact_claim_transactions_patient ON analytics.fact_claim_transactions(patient_id);
CREATE INDEX idx_fact_claim_transactions_provider ON analytics.fact_claim_transactions(provider_id);
CREATE INDEX idx_fact_claims_patient ON analytics.fact_claims(patient_id);
CREATE INDEX idx_fact_claims_provider ON analytics.fact_claims(provider_id);

UPDATE analytics.dim_patients
SET marital = CASE
    WHEN marital ILIKE 'single%' OR marital IN ('S') THEN 'Single'
    WHEN marital ILIKE 'married%' OR marital IN ('M') THEN 'Married'
    WHEN marital ILIKE 'divorc%' OR marital IN ('D') THEN 'Divorced'
    WHEN marital ILIKE 'widow%' THEN 'Widowed'
    WHEN marital ILIKE 'separat%' THEN 'Seperated'
    ELSE 'Unknown'
END;


-- ======================================================================================================================================




-- =======================================================================================================================
-- ALALYSIS QUERY INSIGHTS
-- =======================================================================================================================


SELECT * FROM analytics.dim_patients;
SELECT * FROM analytics.dim_providers;
SELECT * FROM analytics.fact_encounters;
SELECT * FROM analytics.fact_conditions;
SELECT * FROM analytics.fact_claim_transactions;
SELECT * FROM analytics.fact_claims;



-- Total Patients

SELECT COUNT(DISTINCT id) AS total_patients
FROM analytics.dim_patients;


-- Total Encounters

SELECT COUNT(*) AS total_encounters
FROM analytics.fact_encounters;


-- -- Returns each patient’s demographics, diagnosed conditions, 
-- -- and total number of encounters, ranked by encounter frequency


WITH encounter_counts AS (
    SELECT patient_id, COUNT(*) AS encounter_count
    FROM analytics.fact_encounters
    GROUP BY patient_id
)
SELECT
    TRIM(
        dp.first_name || ' ' ||
        COALESCE(dp.middle_name || ' ', '') ||
        dp.last_name
    ) AS full_name,
    dp.birth_date,
    dp.race,
    dp.gender,
    fc.description,
    COALESCE(ec.encounter_count, 0) AS number_of_encounters
FROM analytics.dim_patients dp
LEFT JOIN encounter_counts ec
    ON dp.id = ec.patient_id
LEFT JOIN analytics.fact_conditions fc
    ON dp.id = fc.patient_id
ORDER BY number_of_encounters DESC;



-- For each patient and each medical condition, count how many encounters (visits) happened.

SELECT
	dp.id AS patient_id,
    TRIM(dp.first_name || ' ' ||
         COALESCE(dp.middle_name || ' ', '') ||
         dp.last_name) AS full_name,
    fc.description AS condition,
    COUNT(fe.id) AS encounters_per_condition
FROM analytics.dim_patients dp
JOIN analytics.fact_conditions fc
    ON dp.id = fc.patient_id
JOIN analytics.fact_encounters fe
    ON fc.encounter_id = fe.id
GROUP BY dp.id, dp.first_name, dp.middle_name, dp.last_name, fc.description
ORDER BY encounters_per_condition DESC;



SELECT	
	p.id AS patient_id,
	TRIM(p.first_name||' '|| COALESCE(p.middle_name||' ', '')|| p.last_name) AS full_name,
	COUNT(e.id) AS total_encounters
FROM analytics.dim_patients p
JOIN analytics.fact_encounters e
	ON p.id = e.patient_id
GROUP BY p.id, p.first_name, p.middle_name, p.last_name
ORDER BY total_encounters DESC;



SELECT 
	p.id AS patient_id,
	TRIM(p.first_name||' '|| COALESCE(p.middle_name||' ', '')|| p.last_name) AS full_name,
	c.description AS condition,
	COUNT(*) AS condition_count
FROM analytics.fact_conditions c
JOIN analytics.dim_patients p
	ON c.patient_id = p.id
GROUP BY p.id, c.description, p.first_name, p.middle_name, p.last_name
ORDER BY condition_count DESC;



SELECT
	pr.id AS provider_id,
	pr.name AS provider_name,
	pr.city,
	COUNT(e.id) AS total_encounters
FROM analytics.fact_encounters e
JOIN analytics.dim_providers pr
	ON e.provider_id = pr.id
GROUP BY pr.id, pr.name, city
ORDER BY total_encounters DESC;
	


SELECT
    fc.id AS claim_id,

    -- Total billed amount (claim cost)
    COALESCE(SUM(fct.amount::numeric), 0) AS total_claim_cost,

    -- Total paid
    COALESCE(SUM(fct.payments::numeric), 0) AS total_paid,

    -- Total adjustments
    COALESCE(SUM(fct.adjustments::numeric), 0) AS total_adjustments,

    -- Remaining balance (authoritative)
    COALESCE(SUM(fct.outstanding::numeric), 0) AS remaining_balance

FROM analytics.fact_claims fc
LEFT JOIN analytics.fact_claim_transactions fct
    ON fc.id = fct.claim_id
GROUP BY fc.id
HAVING COALESCE(SUM(fct.outstanding::numeric), 0) > 0;


























