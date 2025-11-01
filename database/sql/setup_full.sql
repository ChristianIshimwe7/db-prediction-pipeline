-- Drop everything safely (so you can re-run)
DROP PROCEDURE IF EXISTS sp_insert_patient;
DROP TRIGGER IF EXISTS trg_patient_update;
DROP TABLE IF EXISTS predictions;
DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS patients;

-- Recreate tables
CREATE TABLE patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,  -- FIXED!
    age INT CHECK (age > 0),
    sex INT CHECK (sex IN (0,1)),
    cp INT,
    trestbps INT,
    chol INT,
    fbs INT CHECK (fbs IN (0,1)),
    restecg INT,
    thalach INT,
    exang INT CHECK (exang IN (0,1)),
    oldpeak DECIMAL(5,2),
    slope INT,
    ca INT,
    thal INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE predictions (
    prediction_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT,
    prediction FLOAT,
    probability FLOAT CHECK (probability BETWEEN 0 AND 1),
    predicted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    model_version VARCHAR(20) DEFAULT 'v1.0',
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE
);

CREATE TABLE audit_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50),
    operation VARCHAR(10),
    record_id INT,
    changed_by VARCHAR(50),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- STORED PROCEDURE
DELIMITER $$

CREATE PROCEDURE sp_insert_patient(
    IN p_age INT, IN p_sex INT, IN p_cp INT, IN p_trestbps INT,
    IN p_chol INT, IN p_fbs INT, IN p_restecg INT, IN p_thalach INT,
    IN p_exang INT, IN p_oldpeak DECIMAL(5,2),
    IN p_slope INT, IN p_ca INT, IN p_thal INT
)
BEGIN
    DECLARE new_id INT;

    INSERT INTO patients(age, sex, cp, trestbps, chol, fbs, restecg,
                         thalach, exang, oldpeak, slope, ca, thal)
    VALUES(p_age, p_sex, p_cp, p_trestbps, p_chol, p_fbs, p_restecg,
           p_thalach, p_exang, p_oldpeak, p_slope, p_ca, p_thal);

    SET new_id = LAST_INSERT_ID();

    INSERT INTO audit_log(table_name, operation, record_id, changed_by)
    VALUES('patients', 'INSERT', new_id, USER());
END$$

DELIMITER ;

-- TRIGGER
DELIMITER $$

CREATE TRIGGER trg_patient_update
    AFTER UPDATE ON patients
    FOR EACH ROW
BEGIN
    INSERT INTO audit_log(table_name, operation, record_id, changed_by)
    VALUES('patients', 'UPDATE', NEW.patient_id, USER());
END$$

DELIMITER ;