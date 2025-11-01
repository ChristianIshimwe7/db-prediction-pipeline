
-- Function: Calculate risk based on cardiac parameters
CREATE FUNCTION calculate_cardiac_risk(
    p_resting_bp INT,
    p_cholesterol INT,
    p_max_hr INT,
    p_st_depression DECIMAL(4,2)
) RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE risk_level VARCHAR(20);

    IF p_resting_bp < 60 OR p_resting_bp > 250 THEN
        SET risk_level = 'HIGH';
    ELSEIF p_cholesterol < 50 OR p_cholesterol > 600 THEN
        SET risk_level = 'MODERATE';
    ELSEIF p_max_hr < 40 OR p_max_hr > 220 THEN
        SET risk_level = 'MODERATE';
    ELSEIF p_st_depression < 0 THEN
        SET risk_level = 'HIGH';
    ELSE
        SET risk_level = 'LOW';
    END IF;

    RETURN risk_level;
END$$

-- Procedure: Get basic patient statistics
CREATE PROCEDURE get_patient_stats()
BEGIN
    SELECT 
        COUNT(*) AS total_patients,
        AVG(YEAR(CURDATE()) - YEAR(date_of_birth)) AS avg_age,
        SUM(CASE WHEN sex='M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN sex='F' THEN 1 ELSE 0 END) AS female_count
    FROM patients;
END$$

DELIMITER ;
