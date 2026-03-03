-- Table for raw patients data

CREATE TABLE raw.patients (
    id TEXT,
    birthdate TEXT,
    deathdate TEXT,
    ssn TEXT,
    drivers TEXT,
    passport TEXT,
    prefix TEXT,
    first TEXT,
    middle TEXT,
    last TEXT,
    suffix TEXT,
    maiden TEXT,
    marital TEXT,
    race TEXT,
    ethnicity TEXT,
    gender TEXT,
    birthplace TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    county TEXT,
    fips TEXT,
    zip TEXT,
    lat TEXT,
    lon TEXT,
    healthcare_expenses TEXT,
    healthcare_coverage TEXT,
    income TEXT
);


-- Table for the raw providers

CREATE TABLE raw.providers (
    id TEXT,
    organization TEXT,
    name TEXT,
    gender TEXT,
    speciality TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    zip TEXT,
    lat TEXT,
    lon TEXT,
    encounters TEXT,
    procedures TEXT
);


-- Table for raw enconters

CREATE TABLE raw.encounters (
    id TEXT,
    start TEXT,
    stop TEXT,
    patient TEXT,
	organization TEXT,
    provider TEXT,
    payer TEXT,
	encounter_class TEXT,
    code TEXT,
	description TEXT,
	base_encounter_cost TEXT,
	total_claim_cost TEXT,
	payer_coverage TEXT,
	reason_code TEXT,
	reason_description TEXT
);


-- Table for raw conditions

CREATE TABLE raw.conditions (
    start_date TEXT,
    stop_date TEXT,
    patient_id TEXT,
    encounter_id TEXT,
    system TEXT,
    code TEXT,
    description TEXT
);


-- Tale for raw claim_transactions

CREATE TABLE raw.claim_transactions (
    id TEXT,
    claim_id TEXT,
    charge_id TEXT,
    patient_id TEXT,
    type TEXT,
    amount TEXT,
    method TEXT,
    from_date TEXT,
    to_date TEXT,
    place_of_service TEXT,
    procedure_code TEXT,
    modifier_1 TEXT,
    modifier_2 TEXT,
    diagnosis_ref_1 TEXT,
    diagnosis_ref_2 TEXT,
    diagnosis_ref_3 TEXT,
    diagnosis_ref_4 TEXT,
    units TEXT,
    department_id TEXT,
    notes TEXT,
    unit_amount TEXT,
    transfer_out_id TEXT,
    transfer_type TEXT,
    payments TEXT,
    adjustments TEXT,
    transfers TEXT,
    outstanding TEXT,
    appointment_id TEXT,
    line_note TEXT,
    patient_insurance_id TEXT,
    fee_schedule_id TEXT,
    provider_id TEXT,
    supervising_provider_id TEXT
);

--

CREATE TABLE raw.claims (
    id TEXT,
    patient_id TEXT,
    provider_id TEXT,
    primary_patient_insurance_id TEXT,
    secondary_patient_insurance_id TEXT,
    department_id TEXT,
    patient_department_id TEXT,

    diagnosis_1 TEXT,
    diagnosis_2 TEXT,
    diagnosis_3 TEXT,
    diagnosis_4 TEXT,
    diagnosis_5 TEXT,
    diagnosis_6 TEXT,
    diagnosis_7 TEXT,
    diagnosis_8 TEXT,

    referring_provider_id TEXT,
    appointment_id TEXT,

    current_illness_date TEXT,
    service_date TEXT,

    supervising_provider_id TEXT,

    status_1 TEXT,
    status_2 TEXT,
    status_p TEXT,

    outstanding_1 TEXT,
    outstanding_2 TEXT,
    outstanding_p TEXT,

    last_billed_date_1 TEXT,
    last_billed_date_2 TEXT,
    last_billed_date_p TEXT,

    healthcare_claim_type_id_1 TEXT,
    healthcare_claim_type_id_2 TEXT
);

-- =========================
-- Primary Keys
-- =========================

-- Patients
ALTER TABLE raw.patients
ADD CONSTRAINT pk_patients PRIMARY KEY (id);

-- Providers
ALTER TABLE raw.providers
ADD CONSTRAINT pk_providers PRIMARY KEY (id);

-- Encounters
ALTER TABLE raw.encounters
ADD CONSTRAINT pk_encounters PRIMARY KEY (id);

-- Conditions
-- No single ID in Synthea → composite key
ALTER TABLE raw.conditions
ADD CONSTRAINT pk_conditions PRIMARY KEY (
    patient_id,
    encounter_id,
    start_date,
    code
);

-- Claim Transactions
ALTER TABLE raw.claim_transactions
ADD CONSTRAINT pk_claim_transactions PRIMARY KEY (id);

-- Claims
ALTER TABLE raw.claims
ADD CONSTRAINT pk_claims PRIMARY KEY (id);


-- patients
ALTER TABLE raw.patients
ALTER COLUMN id SET NOT NULL,
ALTER COLUMN first SET NOT NULL,
ALTER COLUMN last SET NOT NULL;

-- providers
ALTER TABLE raw.providers
ALTER COLUMN id SET NOT NULL,
ALTER COLUMN name SET NOT NULL;

-- encounters
ALTER TABLE raw.encounters
ALTER COLUMN id SET NOT NULL,
ALTER COLUMN patient SET NOT NULL;

-- claim_transactions
ALTER TABLE raw.claim_transactions
ALTER COLUMN id SET NOT NULL,
ALTER COLUMN patient_id SET NOT NULL;

-- claims
ALTER TABLE raw.claims
ALTER COLUMN id SET NOT NULL,
ALTER COLUMN patient_id SET NOT NULL,
ALTER COLUMN provider_id SET NOT NULL;



-- Encounters -> Patients, Providers
ALTER TABLE raw.encounters
ADD CONSTRAINT fk_encounters_patient
    FOREIGN KEY (patient) REFERENCES raw.patients(id),
ADD CONSTRAINT fk_encounters_provider
    FOREIGN KEY (provider) REFERENCES raw.providers(id);

-- Conditions -> Patients, Encounters
ALTER TABLE raw.conditions
ADD CONSTRAINT fk_conditions_patient
    FOREIGN KEY (patient_id) REFERENCES raw.patients(id),
ADD CONSTRAINT fk_conditions_encounter
    FOREIGN KEY (encounter_id) REFERENCES raw.encounters(id);

-- Claim Transactions -> Patients, Providers
ALTER TABLE raw.claim_transactions
ADD CONSTRAINT fk_claim_transactions_patient
    FOREIGN KEY (patient_id) REFERENCES raw.patients(id),
ADD CONSTRAINT fk_claim_transactions_provider
    FOREIGN KEY (provider_id) REFERENCES raw.providers(id),
ADD CONSTRAINT fk_claim_transactions_supervising_provider
    FOREIGN KEY (supervising_provider_id) REFERENCES raw.providers(id);

-- Claims -> Patients, Providers
ALTER TABLE raw.claims
ADD CONSTRAINT fk_claims_patient
    FOREIGN KEY (patient_id) REFERENCES raw.patients(id),
ADD CONSTRAINT fk_claims_provider
    FOREIGN KEY (provider_id) REFERENCES raw.providers(id),
ADD CONSTRAINT fk_claims_referring_provider
    FOREIGN KEY (referring_provider_id) REFERENCES raw.providers(id),
ADD CONSTRAINT fk_claims_supervising_provider
    FOREIGN KEY (supervising_provider_id) REFERENCES raw.providers(id);




-- =============================================
-- 1. Load raw.patients
-- =============================================
COPY raw.patients (
    id, birthdate, deathdate, ssn, drivers, passport, prefix, first, middle,
    last, suffix, maiden, marital, race, ethnicity, gender, birthplace, address,
    city, state, county, fips, zip, lat, lon, healthcare_expenses,
    healthcare_coverage, income
)
FROM 'C:/Users/ThinkPad/OneDrive/Desktop/Hospital_Admissions_&_Patient_Outcomes_Analysis/patients.csv'
DELIMITER ',' CSV HEADER;

-- =============================================
-- 2. Load raw.providers
-- =============================================
COPY raw.providers (
    id, organization, name, gender, speciality, address, city, state,
    zip, lat, lon, encounters, procedures
)
FROM 'C:/Users/ThinkPad/OneDrive/Desktop/Hospital_Admissions_&_Patient_Outcomes_Analysis/providers.csv'
DELIMITER ',' CSV HEADER;

-- =============================================
-- 3. Load raw.encounters
-- =============================================
COPY raw.encounters (
    id, start, stop, patient, organization, provider, payer,
    encounter_class, code, description, base_encounter_cost, total_claim_cost,
    payer_coverage, reason_code, reason_description
)
FROM 'C:/Users/ThinkPad/OneDrive/Desktop/Hospital_Admissions_&_Patient_Outcomes_Analysis/encounters.csv'
DELIMITER ',' CSV HEADER;

-- =============================================
-- 4. Load raw.conditions
-- =============================================
COPY raw.conditions (
    start_date, stop_date, patient_id, encounter_id, system, code, description
)
FROM 'C:/Users/ThinkPad/OneDrive/Desktop/Hospital_Admissions_&_Patient_Outcomes_Analysis/conditions.csv'
DELIMITER ',' CSV HEADER;

-- =============================================
-- 5. Load raw.claim_transactions
-- =============================================
COPY raw.claim_transactions (
    id, claim_id, charge_id, patient_id, type, amount, method,
    from_date, to_date, place_of_service, procedure_code, modifier_1,
    modifier_2, diagnosis_ref_1, diagnosis_ref_2, diagnosis_ref_3,
    diagnosis_ref_4, units, department_id, notes, unit_amount,
    transfer_out_id, transfer_type, payments, adjustments, transfers,
    outstanding, appointment_id, line_note, patient_insurance_id,
    fee_schedule_id, provider_id, supervising_provider_id
)
FROM 'C:/Users/ThinkPad/OneDrive/Desktop/Hospital_Admissions_&_Patient_Outcomes_Analysis/claims_transactions.csv'
DELIMITER ',' CSV HEADER;

-- =============================================
-- 6. Load raw.claims
-- =============================================
COPY raw.claims (
    id, patient_id, provider_id, primary_patient_insurance_id,
    secondary_patient_insurance_id, department_id, patient_department_id,
    diagnosis_1, diagnosis_2, diagnosis_3, diagnosis_4, diagnosis_5,
    diagnosis_6, diagnosis_7, diagnosis_8, referring_provider_id,
    appointment_id, current_illness_date, service_date,
    supervising_provider_id, status_1, status_2, status_p,
    outstanding_1, outstanding_2, outstanding_p,
    last_billed_date_1, last_billed_date_2, last_billed_date_p,
    healthcare_claim_type_id_1, healthcare_claim_type_id_2
)
FROM 'C:/Users/ThinkPad/OneDrive/Desktop/Hospital_Admissions_&_Patient_Outcomes_Analysis/claims.csv'
DELIMITER ',' CSV HEADER;


SELECT * FROM raw.patients





