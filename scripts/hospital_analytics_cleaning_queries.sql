CREATE SCHEMA IF NOT EXISTS analytics;

-- =============================================
-- 1. Analytics Patients Dimension Table
-- =============================================
DROP TABLE IF EXISTS analytics.dim_patients CASCADE;

CREATE TABLE analytics.dim_patients (
    id TEXT,
    birth_date DATE,
    death_date DATE,
    ssn TEXT,
    drives TEXT,
    passport TEXT,
    first_name TEXT,
    middle_name TEXT,
    last_name TEXT,
    marital_status TEXT,
    race TEXT,
    gender TEXT,
    place_of_birth TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    county TEXT,
    fips TEXT,
    zip_code TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    healthcare_expenses NUMERIC(12,2),
    healthcare_coverage NUMERIC(12,2),
    income NUMERIC(12,2)
);

INSERT INTO analytics.dim_patients (
    id, birth_date, death_date, ssn, drives, passport,
    first_name, middle_name, last_name, marital_status, race,
    gender, place_of_birth, address, city, state, county, fips,
    zip_code, latitude, longitude, healthcare_expenses, healthcare_coverage, income
)
SELECT
    id,
    birthdate::DATE AS birth_date,
    deathdate::DATE AS death_date,
    ssn,
    COALESCE(drivers, 'Unknown') AS drives,
    COALESCE(passport, 'Unknown') AS passport,
    TRIM(REGEXP_REPLACE(first, '[0-9]', '', 'g')) AS first_name,
    TRIM(REGEXP_REPLACE(middle, '[0-9]', '', 'g')) AS middle_name,
    TRIM(REGEXP_REPLACE(last, '[0-9]', '', 'g')) AS last_name,
    CASE UPPER(marital)
        WHEN 'S' THEN 'Single'
        WHEN 'M' THEN 'Married'
        WHEN 'D' THEN 'Divorced'
        WHEN 'W' THEN 'Widowed'
        ELSE 'Unknown'
    END AS marital_status,
    race,
    CASE UPPER(gender)
        WHEN 'M' THEN 'Male'
        WHEN 'F' THEN 'Female'
        ELSE 'Unknown'
    END AS gender,
    birthplace,
    address,
    city,
    state,
    county,
    fips,
    zip AS zip_code,
    CAST(lat AS DOUBLE PRECISION) AS latitude,
	CAST(lon AS DOUBLE PRECISION)longitude,
	CAST(healthcare_expenses AS NUMERIC(12,2)),
	CAST(healthcare_coverage AS NUMERIC(12,2)),
	CAST(income	AS NUMERIC(12,2))
FROM raw.patients
WHERE birthdate::DATE <= CURRENT_DATE; 

-- =============================================
-- 2. Analytics Providers Dimension Table
-- =============================================

DROP TABLE IF EXISTS analytics.dim_providers CASCADE;

CREATE TABLE analytics.dim_providers (
    id TEXT,
    organization TEXT,
    full_name TEXT,
    gender TEXT,
    speciality TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    zip_code TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    encounters INT
);

INSERT INTO analytics.dim_providers (
    id, organization, full_name, gender, speciality, address, city, state, zip_code,
    latitude, longitude, encounters
)
SELECT
    id,
    organization,
    TRIM(REGEXP_REPLACE(name, '[0-9]', '', 'g')) AS full_name,
    CASE UPPER(gender)
        WHEN 'M' THEN 'Male'
        WHEN 'F' THEN 'Female'
        ELSE 'Unknown'
    END AS gender,
    INITCAP(speciality) AS speciality,
    address,
    city,
    state,
    zip AS zip_code,
    CAST(lat AS DOUBLE PRECISION) AS latitude,
    CAST(lon AS DOUBLE PRECISION) AS longitude,
    CAST(encounters AS INT) AS encounters
FROM raw.providers;

-- =============================================
-- 3. Analytics Encounters Fact Table
-- =============================================
DROP TABLE IF EXISTS analytics.fact_encounters CASCADE;

CREATE TABLE analytics.fact_encounters (
    id TEXT,
    start_date DATE,
    end_date DATE,
    patient_id TEXT,
    organization TEXT,
    provider_id TEXT,
    payer TEXT,
    encounter_class TEXT,
    description TEXT,
    base_encounter_cost NUMERIC(12,2),
    total_claim_cost NUMERIC(12,2),
    payer_coverage NUMERIC(12,2),
    reason_code BIGINT,
    reason_description TEXT
);

INSERT INTO analytics.fact_encounters (
    id, start_date, end_date, patient_id, organization, provider_id, payer,
    encounter_class, description, base_encounter_cost, total_claim_cost,
    payer_coverage, reason_code, reason_description
)
SELECT
    id,
    CAST(start AS DATE) AS start_date,
    CAST(stop AS DATE) AS end_date,
    patient AS patient_id,
    organization,
    provider AS provider_id,
    payer,
    encounter_class,
    description,
    CAST(base_encounter_cost AS NUMERIC(12,2)) AS base_encounter_cost,
    CAST(total_claim_cost AS NUMERIC(12,2)) AS total_claim_cost,
    CAST(payer_coverage AS NUMERIC(12,2)) AS payer_coverage,
    CAST(reason_code AS BIGINT) AS reason_code,
    COALESCE(reason_description, 'Unknown') AS reason_description
FROM raw.encounters e
WHERE e.patient IN (SELECT id FROM analytics.dim_patients)
  AND e.provider IN (SELECT id FROM analytics.dim_providers);
  

-- =============================================
-- 4. Analytics Conditions Fact Table
-- =============================================
DROP TABLE IF EXISTS analytics.fact_conditions CASCADE;

CREATE TABLE analytics.fact_conditions AS
SELECT DISTINCT c.*
FROM raw.conditions c
WHERE c.patient_id IN (SELECT id FROM analytics.dim_patients)
	AND c.encounter_id IN (SELECT id FROM analytics.fact_encounters);


-- =============================================
-- 5. Analytics Claim Transactions Fact Table
-- =============================================


DROP TABLE IF EXISTS analytics.fact_claim_transactions CASCADE;

CREATE TABLE analytics.fact_claim_transactions AS
SELECT 
    id,
    claim_id,
    charge_id::INT AS charge_id,
    patient_id,
    INITCAP(type) AS type,
    COALESCE(amount::NUMERIC(12,2), 0) AS amount,
    CASE
        WHEN method = 'CHECK' THEN 'Check'
        WHEN method = 'ECHECK' THEN 'E-Check'
        WHEN method = 'CC' THEN 'Credit Card'
        WHEN method = 'CASH' THEN 'Cash'
        WHEN method = 'COPAY' THEN 'Copay'
        WHEN method IS NULL THEN 'Unknown'
        ELSE 'Other'
    END AS method,
    from_date::DATE AS from_date,
    to_date::DATE AS to_date,
    place_of_service,
    procedure_code::BIGINT AS procedure_code,
    COALESCE(modifier_1, 'Unknown') AS modifier_1,
    COALESCE(modifier_2, 'Unknown') AS modifier_2,
    COALESCE(diagnosis_ref_1::SMALLINT, 0) AS diagnosis_ref_1,
    COALESCE(diagnosis_ref_2::SMALLINT, 0) AS diagnosis_ref_2,
    COALESCE(diagnosis_ref_3::SMALLINT, 0) AS diagnosis_ref_3,
    COALESCE(diagnosis_ref_4::SMALLINT, 0) AS diagnosis_ref_4,
    units::SMALLINT AS units,
    department_id::INT AS department_id,
    notes,
    unit_amount::NUMERIC(12,2) AS unit_amount,
    COALESCE(transfer_out_id::INT, 0) AS transfer_out_id,
    COALESCE(transfers::NUMERIC(12,2), 0) AS transfers,
    payments::NUMERIC(12,2) AS payments,
    adjustments::NUMERIC(12,2) AS adjustments,
    outstanding::NUMERIC(12,2) AS outstanding,
    appointment_id,
    line_note,
    patient_insurance_id,
    fee_schedule_id,
    provider_id,
    supervising_provider_id
FROM raw.claim_transactions;


-- =============================================
-- 6. Analytics Fact_Claim Table
-- =============================================

DROP TABLE IF EXISTS analytics.fact_claims CASCADE;

CREATE TABLE analytics.fact_claims AS
SELECT
    id,
    patient_id,
    provider_id,
    COALESCE(primary_patient_insurance_id, 'Uninsured') AS primary_patient_insurance_id,
    COALESCE(secondary_patient_insurance_id, 'Uninsured') AS secondary_patient_insurance_id,
    department_id,
    patient_department_id,
    COALESCE(diagnosis_1, 'Unknown') AS diagnosis_1,
    COALESCE(diagnosis_2, 'Unknown') AS diagnosis_2,
    COALESCE(diagnosis_3, 'Unknown') AS diagnosis_3,
    COALESCE(diagnosis_4, 'Unknown') AS diagnosis_4,
    COALESCE(diagnosis_5, 'Unknown') AS diagnosis_5,
    COALESCE(diagnosis_6, 'Unknown') AS diagnosis_6,
    COALESCE(diagnosis_7, 'Unknown') AS diagnosis_7,
    COALESCE(diagnosis_8, 'Unknown') AS diagnosis_8,
    referring_provider_id,
    appointment_id,
    current_illness_date::DATE,
    service_date::DATE,
    supervising_provider_id,
    INITCAP(status_1) AS status_1,
    INITCAP(status_2) AS status_2,
    INITCAP(status_p) AS status_p,
    outstanding_1::NUMERIC(12,2),
    outstanding_2::NUMERIC(12,2),
    outstanding_p::NUMERIC(12,2),
    last_billed_date_1::DATE,
    last_billed_date_2::DATE,
    last_billed_date_p::DATE,
    healthcare_claim_type_id_1::SMALLINT
FROM raw.claims c
WHERE c.patient_id IN (SELECT id FROM analytics.dim_patients)
  AND c.provider_id IN (SELECT id FROM analytics.dim_providers);



-- =============================================
-- 7. Add Primary Key Constraints
-- =============================================

ALTER TABLE analytics.dim_patients
ADD CONSTRAINT pk_dim_patients PRIMARY KEY (id);


ALTER TABLE analytics.dim_patients
ALTER COLUMN id SET NOT NULL,
ALTER COLUMN first_name SET NOT NULL,
ALTER COLUMN last_name SET NOT NULL;


ALTER TABLE analytics.dim_providers
ADD CONSTRAINT pk_dim_providers PRIMARY KEY (id);

ALTER TABLE analytics.dim_providers
ALTER COLUMN id SET NOT NULL,
ALTER COLUMN full_name SET NOT NULL;


ALTER TABLE analytics.fact_encounters
ADD CONSTRAINT pk_fact_encounters PRIMARY KEY (id);

--
ALTER TABLE analytics.fact_encounters
ALTER COLUMN id SET NOT NULL,
ALTER COLUMN patient_id SET NOT NULL;
--

ALTER TABLE analytics.fact_conditions
ADD CONSTRAINT pk_fact_conditions PRIMARY KEY (patient_id, encounter_id, start_date, code);


ALTER TABLE analytics.fact_claim_transactions
ADD CONSTRAINT pk_fact_claim_transactions PRIMARY KEY (id);

ALTER TABLE analytics.fact_claim_transactions
ALTER COLUMN id SET NOT NULL,
ALTER COLUMN patient_id SET NOT NULL;


ALTER TABLE analytics.fact_claims
ADD CONSTRAINT pk_fact_claims PRIMARY KEY (id);

ALTER TABLE analytics.fact_claims
ALTER COLUMN id SET NOT NULL,
ALTER COLUMN patient_id SET NOT NULL,
ALTER COLUMN provider_id SET NOT NULL;



-- =============================================
-- 8. Add Foreign Key Constraints
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
-- 9. Add Indexes for Faster Analysis
-- =============================================

CREATE INDEX idx_fact_encounters_patient ON analytics.fact_encounters(patient_id);
CREATE INDEX idx_fact_encounters_provider ON analytics.fact_encounters(provider_id);
CREATE INDEX idx_fact_conditions_patient ON analytics.fact_conditions(patient_id);
CREATE INDEX idx_fact_conditions_encounter ON analytics.fact_conditions(encounter_id);
CREATE INDEX idx_fact_claim_transactions_patient ON analytics.fact_claim_transactions(patient_id);
CREATE INDEX idx_fact_claim_transactions_provider ON analytics.fact_claim_transactions(provider_id);
CREATE INDEX idx_fact_claims_patient ON analytics.fact_claims(patient_id);
CREATE INDEX idx_fact_claims_provider ON analytics.fact_claims(provider_id);











