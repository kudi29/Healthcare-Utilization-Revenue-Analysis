-- 4. Provider Workload Analysis

/* 
Tracks provider workloads by showing how many patients each person is seeing at every location.
*/

CREATE VIEW vw_provider_visits AS
SELECT
    providers.id AS provider_id,
    INITCAP(providers.full_name) AS provider_name,
    INITCAP(providers.city) AS facility_location,
    COUNT(encounters.id) AS total_patient_visits
FROM analytics.fact_encounters AS encounters
JOIN analytics.dim_providers AS providers
    ON encounters.provider_id = providers.id
GROUP BY 
    providers.id, 
    providers.full_name, 
    providers.city
ORDER BY total_patient_visits DESC;


SELECT * FROM vw_provider_visits;




