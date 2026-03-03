-- 1. Patient Clinical Profile
/* 
Pulls together a patient's background, health issues, and visit history to give you the full picture at a glance
*/

CREATE OR REPLACE VIEW vw_patient_summary AS
WITH patient_encounter_summary AS (
    SELECT 
        patient_id, 
        COUNT(*) AS total_visits
    FROM analytics.fact_encounters
    GROUP BY patient_id
)
SELECT
    patients.id AS patient_id,
    TRIM(
        patients.first_name || ' ' ||
        COALESCE(patients.middle_name || ' ', '') ||
        patients.last_name
    ) AS patient_full_name,
    patients.birth_date,
    patients.race,
    patients.gender,
    STRING_AGG(conditions.description, ', ') AS all_conditions,  -- alias changed back
    COALESCE(summary.total_visits, 0) AS lifetime_encounter_count
FROM analytics.dim_patients AS patients
LEFT JOIN patient_encounter_summary AS summary
    ON patients.id = summary.patient_id
LEFT JOIN analytics.fact_conditions AS conditions
    ON patients.id = conditions.patient_id
   AND conditions.description LIKE '%(disorder)'  -- filter for disorders only
GROUP BY patients.id, patients.first_name, patients.middle_name, patients.last_name,
         patients.birth_date, patients.race, patients.gender, summary.total_visits
;

SELECT * FROM vw_patient_summary;


