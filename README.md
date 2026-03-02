# Healthcare-Utilization-Revenue-Analysis
Healthcare Analytics: From Data Chaos to Clinical Insight
Healthcare leaders are often drowning in data but starving for insights. This project bridges that gap. Using realistic synthetic data, I built a system that transforms messy, disorganized spreadsheets into a High-Performance Engine for decision-making.
The goal: Create a "Single Source of Truth" to improve patient health outcomes, maintain financial viability, and optimize operational efficiency.
🛠️ Project Stack
Database: PostgreSQL (Relational Data Modeling)
Data Engineering: CTEs, Window Functions (RANK), Complex JOIN logic, and Data Type Casting.
Business Intelligence: Power BI (Connected via SQL Views).
Domain Knowledge: Revenue Cycle Management (RCM), Population Health, and Clinical Operations.
🏗️ The Data Pipeline: "Chaos" to "Clean"
I designed a two-step "sorting" process to protect the integrity of the final results:
The Junk Drawer (Raw Schema): I ingest data exactly as-is. This ensures no information is lost due to strange date formatting or misplaced characters.
The Clean Room (Analytics Schema): This is where the transformation happens. I scrub the data using four strict rules:
Deduplication: Utilizing SELECT DISTINCT to ensure no patient or encounter is counted twice.
Orphan Control: Filtering child tables to eliminate "ghost" records.
Relational Integrity: Enforcing Primary and Foreign Keys to connect patients to their specific claims.
Performance: Structuring data so complex queries return results in seconds, not minutes.
📊 The Four Pillars of Insight
I developed four specific SQL queries (and corresponding Power BI Views) to answer critical healthcare questions:
1. The 360-Degree Patient View
Goal: See the whole person, not just a chart.
Logic: Merged demographics and medical history to identify how age or race correlates with health outcomes.
2. Patient Risk Forecasting
Goal: Identify high-risk patients for proactive care.
Logic: Created a "Risk Score" by aggregating chronic conditions, helping care managers prioritize outreach and reduce hospital readmissions.
3. The Revenue Roadmap
Goal: Identify and recover missing revenue.
Logic: Tracked the lifecycle of a medical claim. By isolating Outstanding Balances, I created a roadmap for the billing department to improve cash flow.
4. Provider Workload Analysis
Goal: Efficient resource allocation.
Logic: Analyzed clinician and clinic throughput to identify where the organization is overstretched and where additional staffing is required.
🚀 How to Run the Project
Environment: Set up a PostgreSQL database.
Schema Setup: Run the CREATE SCHEMA scripts for the raw and analytics layers.
Data Load: Use COPY commands to import Synthea CSVs into the raw schema.
Transformation: Run the ETL scripts to deduplicate and enforce keys in the analytics schema.
Insights: Navigate to the /queries folder to run the analysis scripts.
💡 Why This Approach Works
Safety First: The original data is never touched (Immutability). We can "reset" without data loss.
Quality Control: The system acts as a bouncer, blocking bad data from entering final reports.
Actionable Results: This isn't just a dashboard; it’s a roadmap to better patient care and a stronger bottom line.
