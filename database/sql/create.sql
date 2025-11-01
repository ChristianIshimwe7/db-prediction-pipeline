CREATE DATABASE IF NOT EXISTS heart_disease_db;
USE heart_disease_db;

CREATE TABLE IF NOT EXISTS locations (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    facility_name VARCHAR(150) NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL CHECK (latitude >= -90 AND latitude <= 90),
    longitude DECIMAL(11, 8) NOT NULL CHECK (longitude >= -180 AND longitude <= 180),
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20),
    phone VARCHAR(20),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_coordinates (latitude, longitude),
    INDEX idx_city (city),
    INDEX idx_facility_name (facility_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    medical_record_number VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    sex ENUM('M', 'F', 'Other') NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    location_id INT,
    
    -- Clinical contact info
    emergency_contact VARCHAR(150),
    emergency_phone VARCHAR(20),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (location_id) REFERENCES locations(location_id) ON DELETE SET NULL,
    INDEX idx_mrn (medical_record_number),
    INDEX idx_dob (date_of_birth),
    INDEX idx_name (last_name, first_name),
    INDEX idx_location (location_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS clinical_monitoring (
    monitoring_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    visit_id INT,
    
    -- Measurement data
    measurement_count INT NOT NULL CHECK (measurement_count >= 0),
    min_distance DECIMAL(6, 2) CHECK (min_distance >= 0),
    azimuthal_gap DECIMAL(6, 2) CHECK (azimuthal_gap >= 0 AND azimuthal_gap <= 360),
    cdi INT CHECK (cdi >= 0 AND cdi <= 9),
    mmi INT CHECK (mmi >= 1 AND mmi <= 9),
    data_quality_score DECIMAL(4, 3) CHECK (data_quality_score >= 0 AND data_quality_score <= 1),
    
    monitoring_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    INDEX idx_patient_monitoring (patient_id),
    INDEX idx_quality_score (data_quality_score),
    INDEX idx_monitoring_date (monitoring_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS clinical_events (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    event_type ENUM('acute_event', 'chronic_progression', 'symptom_onset', 'intervention') NOT NULL,
    event_occurred BOOLEAN NOT NULL,
    risk_level ENUM('LOW', 'MODERATE', 'HIGH', 'CRITICAL', 'UNKNOWN') DEFAULT 'UNKNOWN',
    severity_score DECIMAL(4, 3) CHECK (severity_score >= 0 AND severity_score <= 1),
    clinical_assessment TEXT,
    intervention_recommended VARCHAR(255),
    
    event_date DATE NOT NULL,
    event_year INT NOT NULL CHECK (event_year >= 1950 AND event_year <= YEAR(CURDATE())),
    event_month INT NOT NULL CHECK (event_month >= 1 AND event_month <= 12),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    INDEX idx_patient_event (patient_id),
    INDEX idx_risk_level (risk_level),
    INDEX idx_event_occurred (event_occurred),
    INDEX idx_event_year_month (event_year, event_month),
    INDEX idx_event_date (event_date),
    INDEX idx_severity (severity_score)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS cardiac_measurements (
    measurement_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    
    -- Core measurements
    chest_pain_type ENUM('typical_angina', 'atypical_angina', 'non_anginal', 'asymptomatic') NOT NULL,
    resting_blood_pressure INT NOT NULL CHECK (resting_blood_pressure BETWEEN 60 AND 250),
    serum_cholesterol INT NOT NULL CHECK (serum_cholesterol BETWEEN 50 AND 600),
    fasting_blood_sugar_gt_120 BOOLEAN NOT NULL DEFAULT FALSE,
    resting_ecg ENUM('normal', 'st_t_abnormality', 'lv_hypertrophy') NOT NULL,
    max_heart_rate_achieved INT NOT NULL CHECK (max_heart_rate_achieved BETWEEN 40 AND 220),
    exercise_induced_angina BOOLEAN NOT NULL DEFAULT FALSE,
    st_depression DECIMAL(4, 2) NOT NULL DEFAULT 0 CHECK (st_depression >= 0),
    st_segment_slope ENUM('upsloping', 'flat', 'downsloping') NOT NULL,
    num_major_vessels INT CHECK (num_major_vessels BETWEEN 0 AND 3),
    thalassemia_type ENUM('normal', 'fixed_defect', 'reversible_defect', 'unknown') DEFAULT 'unknown',
    
    measurement_date DATE NOT NULL,
    measurement_time TIME,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    INDEX idx_patient_measurement (patient_id),
    INDEX idx_measurement_date (measurement_date),
    INDEX idx_bp (resting_blood_pressure),
    INDEX idx_cholesterol (serum_cholesterol)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS model_predictions (
    prediction_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    measurement_id INT,
    
    -- Prediction results (0=no disease, 1-4=varying severity)
    disease_prediction INT NOT NULL CHECK (disease_prediction BETWEEN 0 AND 4),
    confidence_score DECIMAL(5, 4) NOT NULL CHECK (confidence_score BETWEEN 0 AND 1),
    
    -- Probability distribution for all classes
    prob_class_0 DECIMAL(5, 4),
    prob_class_1 DECIMAL(5, 4),
    prob_class_2 DECIMAL(5, 4),
    prob_class_3 DECIMAL(5, 4),
    prob_class_4 DECIMAL(5, 4),
    
    model_version VARCHAR(50) NOT NULL,
    model_name VARCHAR(100),
    model_algorithm VARCHAR(100),
    
    predicted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (measurement_id) REFERENCES cardiac_measurements(measurement_id) ON DELETE SET NULL,
    INDEX idx_patient_pred (patient_id),
    INDEX idx_confidence (confidence_score),
    INDEX idx_predicted_at (predicted_at),
    INDEX idx_model_version (model_version),
    INDEX idx_disease_prediction (disease_prediction)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audit_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    operation ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    record_id INT,
    user_id VARCHAR(100),
    ip_address VARCHAR(45),
    old_values JSON,
    new_values JSON,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_table_name (table_name),
    INDEX idx_operation (operation),
    INDEX idx_changed_at (changed_at),
    INDEX idx_user_id (user_id),
    INDEX idx_record (table_name, record_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


DELIMITER $$

CREATE PROCEDURE validate_cardiac_measurements(
    IN p_resting_bp INT,
    IN p_cholesterol INT,
    IN p_max_hr INT,
    IN p_st_depression DECIMAL(4,2),
    OUT validation_status VARCHAR(255)
)
READS SQL DATA
BEGIN
    SET validation_status = 'VALID';
    
    IF p_resting_bp < 60 OR p_resting_bp > 250 THEN
        SET validation_status = 'ERROR: Resting BP out of valid range (60-250 mmHg)';
    ELSEIF p_cholesterol < 50 OR p_cholesterol > 600 THEN
        SET validation_status = 'ERROR: Cholesterol out of valid range (50-600 mg/dL)';
    ELSEIF p_max_hr < 40 OR p_max_hr > 220 THEN
        SET validation_status = 'ERROR: Max HR out of valid range (40-220 bpm)';
    ELSEIF p_st_depression < 0 THEN
        SET validation_status = 'ERROR: ST depression cannot be negative';
    END IF;
END$$

CREATE PROCEDURE get_patient_latest_assessment(
    IN p_patient_id INT
)
READS SQL DATA
BEGIN
    SELECT 
        p.patient_id,
        p.medical_record_number,
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        YEAR(FROM_DAYS(DATEDIFF(NOW(), p.date_of_birth))) AS age,
        p.sex,
        cm.chest_pain_type,
        cm.resting_blood_pressure,
        cm.serum_cholesterol,
        cm.max_heart_rate_achieved,
        cm.measurement_date,
        mp.disease_prediction,
        mp.confidence_score,
        mp.model_version,
        mp.predicted_at
    FROM patients p
    LEFT JOIN cardiac_measurements cm ON p.patient_id = cm.patient_id
    LEFT JOIN model_predictions mp ON cm.measurement_id = mp.measurement_id
    WHERE p.patient_id = p_patient_id
    ORDER BY cm.measurement_date DESC, mp.predicted_at DESC
    LIMIT 1;
END$$

CREATE PROCEDURE get_high_risk_patients(
    IN p_risk_threshold DECIMAL(4,3)
)
READS SQL DATA
BEGIN
    SELECT 
        p.patient_id,
        p.medical_record_number,
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        YEAR(FROM_DAYS(DATEDIFF(NOW(), p.date_of_birth))) AS age,
        MAX(mp.confidence_score) AS max_risk_score,
        MAX(mp.disease_prediction) AS severity_level,
        MAX(mp.predicted_at) AS latest_assessment
    FROM patients p
    JOIN model_predictions mp ON p.patient_id = mp.patient_id
    WHERE mp.confidence_score >= p_risk_threshold
    GROUP BY p.patient_id, p.medical_record_number, p.first_name, p.last_name
    ORDER BY max_risk_score DESC;
END$$

DELIMITER ;


DELIMITER $$

CREATE TRIGGER audit_patient_insert
AFTER INSERT ON patients
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, operation, record_id, user_id, new_values)
    VALUES (
        'patients',
        'INSERT',
        NEW.patient_id,
        USER(),
        JSON_OBJECT(
            'medical_record_number', NEW.medical_record_number,
            'name', CONCAT(NEW.first_name, ' ', NEW.last_name),
            'sex', NEW.sex,
            'date_of_birth', NEW.date_of_birth
        )
    );
END$$

CREATE TRIGGER audit_patient_update
AFTER UPDATE ON patients
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, operation, record_id, user_id, old_values, new_values)
    VALUES (
        'patients',
        'UPDATE',
        NEW.patient_id,
        USER(),
        JSON_OBJECT(
            'phone', OLD.phone,
            'email', OLD.email
        ),
        JSON_OBJECT(
            'phone', NEW.phone,
            'email', NEW.email
        )
    );
END$$

CREATE TRIGGER audit_patient_delete
AFTER DELETE ON patients
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, operation, record_id, user_id, old_values)
    VALUES (
        'patients',
        'DELETE',
        OLD.patient_id,
        USER(),
        JSON_OBJECT(
            'medical_record_number', OLD.medical_record_number,
            'name', CONCAT(OLD.first_name, ' ', OLD.last_name)
        )
    );
END$$

CREATE TRIGGER audit_clinical_event_insert
AFTER INSERT ON clinical_events
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, operation, record_id, user_id, new_values)
    VALUES (
        'clinical_events',
        'INSERT',
        NEW.event_id,
        USER(),
        JSON_OBJECT(
            'patient_id', NEW.patient_id,
            'event_type', NEW.event_type,
            'risk_level', NEW.risk_level,
            'severity_score', NEW.severity_score
        )
    );
END$$

CREATE TRIGGER audit_prediction_insert
AFTER INSERT ON model_predictions
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, operation, record_id, user_id, new_values)
    VALUES (
        'model_predictions',
        'INSERT',
        NEW.prediction_id,
        USER(),
        JSON_OBJECT(
            'patient_id', NEW.patient_id,
            'disease_prediction', NEW.disease_prediction,
            'confidence_score', NEW.confidence_score,
            'model_version', NEW.model_version
        )
    );
END$$

DELIMITER ;
