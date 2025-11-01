-- Update the patient
UPDATE patients SET age = 56 WHERE patient_id = 1;

-- Check audit log again
SELECT * FROM audit_log;