-- 2. Patient Risk Stratification
/* 
Flags high-risk patients by ranking them across total diagnoses and encounter frequency.
*/


CREATE VIEW vw_patient_clinical_risk AS
SELECT
    patients.id AS patient_id,
    TRIM(
        patients.first_name || ' ' ||
        COALESCE(patients.middle_name || ' ', '') ||
        patients.last_name
    ) AS patient_full_name,
    COUNT(DISTINCT conditions.encounter_id) AS total_encounters,
    COUNT(*) AS total_conditions,
    RANK() OVER (
        ORDER BY COUNT(*) DESC
    ) AS clinical_risk_rank
FROM analytics.fact_conditions AS conditions
LEFT JOIN analytics.dim_patients AS patients
    ON conditions.patient_id = patients.id
GROUP BY
    patients.id,
    patients.first_name,
	patients.middle_name,
    patients.last_name
ORDER BY clinical_risk_rank ASC;

SELECT * FROM vw_patient_clinical_risk;


























