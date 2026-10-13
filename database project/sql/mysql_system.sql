-- ============================================================================
-- BCSE302L - Database Systems Course Project
-- Title: Hospital Management System
-- Student Name: Kankanala Havish Kumar | Reg. No: 24BYB0057
-- Schema & Routines for MySQL 8.0+
-- ============================================================================

DROP DATABASE IF EXISTS hospital_db;
CREATE DATABASE hospital_db;
USE hospital_db;

-- 1. Departments
CREATE TABLE departments (
    dept_id         INT             PRIMARY KEY,
    dept_name       VARCHAR(50)     NOT NULL UNIQUE,
    block_name      VARCHAR(20)     NOT NULL,
    contact_ext     VARCHAR(10)     NOT NULL,
    head_doctor_id  INT
);

-- 2. Doctors
CREATE TABLE doctors (
    doctor_id       INT             PRIMARY KEY,
    doc_name        VARCHAR(60)     NOT NULL,
    specialization  VARCHAR(50)     NOT NULL,
    dept_id         INT             NOT NULL,
    phone           VARCHAR(15)     NOT NULL UNIQUE,
    email           VARCHAR(80)     NOT NULL UNIQUE,
    fee             DECIMAL(8,2)    NOT NULL CHECK (fee >= 0),
    status          VARCHAR(20)     DEFAULT 'Active' NOT NULL CHECK (status IN ('Active', 'On Leave', 'Retired')),
    CONSTRAINT fk_doc_dept FOREIGN KEY (dept_id) REFERENCES departments(dept_id) ON DELETE CASCADE
);

ALTER TABLE departments ADD CONSTRAINT fk_dept_head 
    FOREIGN KEY (head_doctor_id) REFERENCES doctors(doctor_id) ON DELETE SET NULL;

-- 3. Patients
CREATE TABLE patients (
    patient_id      INT             PRIMARY KEY,
    patient_name    VARCHAR(60)     NOT NULL,
    dob             DATE            NOT NULL,
    gender          VARCHAR(10)     NOT NULL CHECK (gender IN ('Male', 'Female', 'Other')),
    blood_group     VARCHAR(5)      NOT NULL CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    phone           VARCHAR(15)     NOT NULL UNIQUE,
    emergency_phone VARCHAR(15)     NOT NULL,
    city            VARCHAR(50)     NOT NULL,
    registered_on   DATE            DEFAULT (CURRENT_DATE) NOT NULL
);

-- 4. Appointments
CREATE TABLE appointments (
    app_id          INT             PRIMARY KEY,
    patient_id      INT             NOT NULL,
    doctor_id       INT             NOT NULL,
    app_date        DATE            NOT NULL,
    app_time        VARCHAR(10)     NOT NULL,
    status          VARCHAR(20)     DEFAULT 'Scheduled' NOT NULL CHECK (status IN ('Scheduled', 'Completed', 'Cancelled', 'No-Show')),
    problem_desc    VARCHAR(200)    NOT NULL,
    created_at      DATETIME        DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_app_pat FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    CONSTRAINT fk_app_doc FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE
);

-- 5. Medical Records
CREATE TABLE medical_records (
    record_id       INT             PRIMARY KEY,
    app_id          INT             NOT NULL UNIQUE,
    patient_id      INT             NOT NULL,
    doctor_id       INT             NOT NULL,
    diagnosis       VARCHAR(200)    NOT NULL,
    prescription    VARCHAR(300)    NOT NULL,
    notes           VARCHAR(255),
    entry_date      DATE            DEFAULT (CURRENT_DATE) NOT NULL,
    CONSTRAINT fk_mr_app FOREIGN KEY (app_id) REFERENCES appointments(app_id) ON DELETE CASCADE,
    CONSTRAINT fk_mr_pat FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    CONSTRAINT fk_mr_doc FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE
);

-- 6. Bills
CREATE TABLE bills (
    bill_id         INT             PRIMARY KEY,
    app_id          INT             NOT NULL UNIQUE,
    patient_id      INT             NOT NULL,
    doctor_fee      DECIMAL(8,2)    NOT NULL CHECK (doctor_fee >= 0),
    medicine_fee    DECIMAL(8,2)    DEFAULT 0.00 NOT NULL CHECK (medicine_fee >= 0),
    total_amt       DECIMAL(8,2)    NOT NULL CHECK (total_amt >= 0),
    discount        DECIMAL(8,2)    DEFAULT 0.00 NOT NULL CHECK (discount >= 0),
    net_amt         DECIMAL(8,2)    NOT NULL CHECK (net_amt >= 0),
    payment_status  VARCHAR(20)     DEFAULT 'Pending' NOT NULL CHECK (payment_status IN ('Pending', 'Paid', 'Refunded')),
    payment_date    DATE,
    CONSTRAINT fk_bill_app FOREIGN KEY (app_id) REFERENCES appointments(app_id) ON DELETE CASCADE,
    CONSTRAINT fk_bill_pat FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE
);

-- 7. Audit Logs
CREATE TABLE audit_logs (
    log_id          INT             AUTO_INCREMENT PRIMARY KEY,
    table_name      VARCHAR(40)     NOT NULL,
    action_type     VARCHAR(20)     NOT NULL,
    record_id       INT             NOT NULL,
    action_time     DATETIME        DEFAULT CURRENT_TIMESTAMP NOT NULL,
    details         VARCHAR(255)    NOT NULL
);

-- ============================================================================
-- DATA POPULATION
-- ============================================================================

INSERT INTO departments VALUES 
(1, 'Cardiology', 'Block A', '101', NULL),
(2, 'Neurology', 'Block B', '102', NULL),
(3, 'Orthopedics', 'Block A', '103', NULL),
(4, 'Pediatrics', 'Block C', '104', NULL),
(5, 'Dermatology', 'Block D', '105', NULL),
(6, 'General Medicine', 'Block A', '106', NULL),
(7, 'ENT', 'Block C', '107', NULL),
(8, 'Gastroenterology', 'Block B', '108', NULL),
(9, 'Oncology', 'Block E', '109', NULL),
(10, 'Psychiatry', 'Block D', '110', NULL);

INSERT INTO doctors VALUES 
(101, 'Dr. Ramesh Sharma', 'Cardiologist', 1, '9840123456', 'ramesh.sharma@hospital.org', 800.0, 'Active'),
(102, 'Dr. Priya Swaminathan', 'Neurologist', 2, '9840234567', 'priya.s@hospital.org', 1000.0, 'Active'),
(103, 'Dr. K. Venkatesh', 'Orthopedic Surgeon', 3, '9840345678', 'k.venkat@hospital.org', 750.0, 'Active'),
(104, 'Dr. Anitha Reddy', 'Pediatrician', 4, '9840456789', 'anitha.reddy@hospital.org', 600.0, 'Active'),
(105, 'Dr. Suresh Babu', 'Dermatologist', 5, '9840567890', 'suresh.babu@hospital.org', 500.0, 'Active'),
(106, 'Dr. Meenakshi Sundaram', 'General Physician', 6, '9840678901', 'meenakshi@hospital.org', 450.0, 'Active'),
(107, 'Dr. Harish Kumar', 'ENT Specialist', 7, '9840789012', 'harish.k@hospital.org', 550.0, 'Active'),
(108, 'Dr. Deepa Nair', 'Gastroenterologist', 8, '9840890123', 'deepa.nair@hospital.org', 850.0, 'Active'),
(109, 'Dr. Arun Prasad', 'Oncologist', 9, '9840901234', 'arun.prasad@hospital.org', 1200.0, 'Active'),
(110, 'Dr. Shalini Gupta', 'Psychiatrist', 10, '9840012345', 'shalini.g@hospital.org', 700.0, 'Active');

UPDATE departments SET head_doctor_id = 101 WHERE dept_id = 1;
UPDATE departments SET head_doctor_id = 102 WHERE dept_id = 2;
UPDATE departments SET head_doctor_id = 103 WHERE dept_id = 3;
UPDATE departments SET head_doctor_id = 104 WHERE dept_id = 4;
UPDATE departments SET head_doctor_id = 105 WHERE dept_id = 5;
UPDATE departments SET head_doctor_id = 106 WHERE dept_id = 6;
UPDATE departments SET head_doctor_id = 107 WHERE dept_id = 7;
UPDATE departments SET head_doctor_id = 108 WHERE dept_id = 8;
UPDATE departments SET head_doctor_id = 109 WHERE dept_id = 9;
UPDATE departments SET head_doctor_id = 110 WHERE dept_id = 10;

INSERT INTO patients VALUES 
(201, 'Rahul Verma', '1998-04-12', 'Male', 'B+', '9789123401', '9789123499', 'Vellore', '2024-01-05'),
(202, 'Sneha Krishnan', '1995-11-20', 'Female', 'O+', '9789123402', '9789123498', 'Katpadi', '2024-01-08'),
(203, 'Manoj Kumar', '1982-07-15', 'Male', 'A+', '9789123403', '9789123497', 'Chennai', '2024-01-14'),
(204, 'Divya Balaji', '2001-02-28', 'Female', 'AB+', '9789123404', '9789123496', 'Ranipet', '2024-01-22'),
(205, 'Vigneshwaran S', '1976-09-04', 'Male', 'O-', '9789123405', '9789123495', 'Vellore', '2024-02-01'),
(206, 'Pooja Hegde', '1999-06-18', 'Female', 'A-', '9789123406', '9789123494', 'Bengaluru', '2024-02-10'),
(207, 'Karthik Raja', '1988-12-09', 'Male', 'B+', '9789123407', '9789123493', 'Chittoor', '2024-02-15'),
(208, 'Lakshmi Ammal', '1955-03-30', 'Female', 'O+', '9789123408', '9789123492', 'Vellore', '2024-02-20'),
(209, 'Goutham Menon', '2003-10-05', 'Male', 'B-', '9789123409', '9789123491', 'Katpadi', '2024-03-01'),
(210, 'Swathi Raman', '1993-08-25', 'Female', 'AB-', '9789123410', '9789123490', 'Kanchipuram', '2024-03-05'),
(211, 'Siddharth Rao', '1980-01-19', 'Male', 'A+', '9789123411', '9789123489', 'Chennai', '2024-03-12'),
(212, 'Nandhini Devi', '1968-05-14', 'Female', 'O+', '9789123412', '9789123488', 'Vellore', '2024-03-18');

INSERT INTO appointments VALUES 
(301, 201, 101, '2024-02-01', '10:00 AM', 'Completed', 'Chest tightness during walking', '2024-01-30 09:15:00'),
(302, 202, 102, '2024-02-02', '11:00 AM', 'Completed', 'Severe migraine on right side', '2024-01-31 10:20:00'),
(303, 203, 103, '2024-02-03', '02:30 PM', 'Completed', 'Left knee pain after gym workout', '2024-02-01 11:00:00'),
(304, 204, 104, '2024-02-04', '04:00 PM', 'Completed', 'High fever and cold since 2 days', '2024-02-02 12:45:00'),
(305, 205, 105, '2024-02-05', '10:30 AM', 'Completed', 'Dry skin patches on arms', '2024-02-03 14:10:00'),
(306, 206, 106, '2024-02-06', '09:30 AM', 'Completed', 'Routine full body health check', '2024-02-04 15:00:00'),
(307, 207, 107, '2024-02-07', '11:30 AM', 'Completed', 'Ear blockage and throat pain', '2024-02-05 09:30:00'),
(308, 208, 108, '2024-02-08', '03:00 PM', 'Completed', 'Stomach burning and acidity', '2024-02-06 10:00:00'),
(309, 209, 109, '2024-02-09', '12:00 PM', 'Completed', 'Follow up for biopsy review', '2024-02-07 11:30:00'),
(310, 210, 110, '2024-02-10', '05:00 PM', 'Completed', 'Trouble sleeping and anxiety', '2024-02-08 14:00:00'),
(311, 211, 101, '2024-03-20', '10:00 AM', 'Scheduled', 'BP routine checkup', '2024-03-15 09:00:00'),
(312, 212, 103, '2024-03-21', '03:00 PM', 'Scheduled', 'Joint stiffness in morning', '2024-03-16 11:00:00'),
(313, 201, 106, '2024-03-22', '09:00 AM', 'Cancelled', 'Viral fever follow up cancelled', '2024-03-17 12:00:00'),
(314, 203, 101, '2024-03-23', '10:30 AM', 'Scheduled', 'ECG report consultation', '2024-03-18 10:00:00'),
(315, 205, 108, '2024-03-24', '04:00 PM', 'No-Show', 'Endoscopy follow up', '2024-03-19 14:00:00');

INSERT INTO medical_records VALUES 
(401, 301, 201, 101, 'Stable Angina', 'Tab Sorbitrate 5mg, Tab Atorva 10mg', 'Treadmill test suggested', '2024-02-01'),
(402, 302, 202, 102, 'Migraine without aura', 'Tab Vasograin SOS, Tab Naprosyn 250mg', 'Avoid bright lights and caffeine', '2024-02-02'),
(403, 303, 203, 103, 'Knee Meniscus strain', 'Tab Zerodol-P BD, Volini spray', 'Ice compression and rest for 5 days', '2024-02-03'),
(404, 304, 204, 104, 'Viral Pharyngitis', 'Syp Paracetamol 250mg, Syp TusQ-D', 'Drink warm water and rest', '2024-02-04'),
(405, 305, 205, 105, 'Mild Psoriasis', 'Betnovate-N cream, Moisturex lotion', 'Apply lotion after bathing', '2024-02-05'),
(406, 306, 206, 106, 'Normal vitals', 'Multivitamin Becosules OD for 15 days', 'Healthy diet and 30 min walk', '2024-02-06'),
(407, 307, 207, 107, 'Otitis media (Ear infection)', 'Ciplox ear drops 3 drops TDS, Tab Amox 500mg', 'Keep ear dry while bathing', '2024-02-07'),
(408, 308, 208, 108, 'Hyperacidity / GERD', 'Tab Pan-D 40mg before food, Gelusil syrup', 'Avoid oily and spicy dinner', '2024-02-08'),
(409, 309, 209, 109, 'Benign cyst under observation', 'Tab Shelcal 500mg OD', 'Review ultrasound after 3 months', '2024-02-09'),
(410, 310, 210, 110, 'Mild Insomnia & Stress', 'Tab Zolpidem 5mg (5 days only)', 'Practice sleep hygiene and meditation', '2024-02-10');

INSERT INTO bills VALUES 
(501, 301, 201, 800.0, 320.0, 1120.0, 50.0, 1070.0, 'Paid', '2024-02-01'),
(502, 302, 202, 1000.0, 180.0, 1180.0, 0.0, 1180.0, 'Paid', '2024-02-02'),
(503, 303, 203, 750.0, 240.0, 990.0, 40.0, 950.0, 'Paid', '2024-02-03'),
(504, 304, 204, 600.0, 150.0, 750.0, 0.0, 750.0, 'Paid', '2024-02-04'),
(505, 305, 205, 500.0, 290.0, 790.0, 0.0, 790.0, 'Paid', '2024-02-05'),
(506, 306, 206, 450.0, 110.0, 560.0, 0.0, 560.0, 'Paid', '2024-02-06'),
(507, 307, 207, 550.0, 160.0, 710.0, 0.0, 710.0, 'Paid', '2024-02-07'),
(508, 308, 208, 850.0, 310.0, 1160.0, 60.0, 1100.0, 'Paid', '2024-02-08'),
(509, 309, 209, 1200.0, 450.0, 1650.0, 100.0, 1550.0, 'Pending', NULL),
(510, 310, 210, 700.0, 200.0, 900.0, 0.0, 900.0, 'Pending', NULL);

INSERT INTO audit_logs (table_name, action_type, record_id, details) VALUES 
('patients', 'INSERT', 201, 'Patient Rahul Verma registered'),
('patients', 'INSERT', 202, 'Patient Sneha Krishnan registered'),
('doctors', 'INSERT', 101, 'Dr. Ramesh Sharma profile created'),
('appointments', 'INSERT', 301, 'Appointment 301 scheduled'),
('appointments', 'UPDATE', 301, 'Appointment 301 marked Completed'),
('bills', 'INSERT', 501, 'Bill 501 generated for Rs. 1070'),
('bills', 'UPDATE', 501, 'Bill 501 paid by cash'),
('appointments', 'UPDATE', 313, 'Appointment 313 cancelled by patient'),
('appointments', 'UPDATE', 315, 'Patient did not arrive for appointment 315'),
('departments', 'UPDATE', 1, 'Head doctor linked to Cardiology');

-- ============================================================================
-- PROCEDURES & TRIGGERS (DELIMITER)
-- ============================================================================

DELIMITER //

CREATE PROCEDURE proc_schedule_appointment(
    IN p_app_id INT,
    IN p_pat_id INT,
    IN p_doc_id INT,
    IN p_date DATE,
    IN p_time VARCHAR(10),
    IN p_desc VARCHAR(200)
)
BEGIN
    DECLARE v_pat_cnt INT DEFAULT 0;
    DECLARE v_doc_cnt INT DEFAULT 0;
    DECLARE v_conflict INT DEFAULT 0;

    SELECT COUNT(*) INTO v_pat_cnt FROM patients WHERE patient_id = p_pat_id;
    IF v_pat_cnt = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient ID not found';
    END IF;

    SELECT COUNT(*) INTO v_doc_cnt FROM doctors WHERE doctor_id = p_doc_id AND status = 'Active';
    IF v_doc_cnt = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Doctor is not available';
    END IF;

    SELECT COUNT(*) INTO v_conflict FROM appointments 
    WHERE doctor_id = p_doc_id AND app_date = p_date AND app_time = p_time AND status = 'Scheduled';

    IF v_conflict > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Time slot already taken';
    END IF;

    INSERT INTO appointments (app_id, patient_id, doctor_id, app_date, app_time, status, problem_desc)
    VALUES (p_app_id, p_pat_id, p_doc_id, p_date, p_time, 'Scheduled', p_desc);

    INSERT INTO audit_logs (table_name, action_type, record_id, details)
    VALUES ('appointments', 'PROC_BOOK', p_app_id, CONCAT('Booked appointment ', p_app_id));
END //

CREATE PROCEDURE proc_generate_bill(
    IN p_bill_id INT,
    IN p_app_id INT,
    IN p_med_charge DECIMAL(8,2),
    IN p_discount DECIMAL(8,2)
)
BEGIN
    DECLARE v_pat_id INT;
    DECLARE v_doc_id INT;
    DECLARE v_fee DECIMAL(8,2);
    DECLARE v_total DECIMAL(8,2);
    DECLARE v_net DECIMAL(8,2);

    SELECT patient_id, doctor_id INTO v_pat_id, v_doc_id FROM appointments WHERE app_id = p_app_id;
    SELECT fee INTO v_fee FROM doctors WHERE doctor_id = v_doc_id;

    SET v_total = v_fee + IFNULL(p_med_charge, 0);
    SET v_net = GREATEST(0, v_total - IFNULL(p_discount, 0));

    UPDATE appointments SET status = 'Completed' WHERE app_id = p_app_id;

    INSERT INTO bills (bill_id, app_id, patient_id, doctor_fee, medicine_fee, total_amt, discount, net_amt, payment_status, payment_date)
    VALUES (p_bill_id, p_app_id, v_pat_id, v_fee, IFNULL(p_med_charge, 0), v_total, IFNULL(p_discount, 0), v_net, 'Paid', CURRENT_DATE);

    INSERT INTO audit_logs (table_name, action_type, record_id, details)
    VALUES ('bills', 'PROC_BILL', p_bill_id, CONCAT('Bill ', p_bill_id, ' generated'));
END //

CREATE FUNCTION func_doctor_revenue(p_doc_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(10,2) DEFAULT 0.00;
    SELECT IFNULL(SUM(b.net_amt), 0.00) INTO v_total
    FROM bills b
    JOIN appointments a ON b.app_id = a.app_id
    WHERE a.doctor_id = p_doc_id AND b.payment_status = 'Paid';
    RETURN v_total;
END //

CREATE FUNCTION func_patient_visits(p_pat_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_cnt INT DEFAULT 0;
    SELECT COUNT(*) INTO v_cnt FROM appointments WHERE patient_id = p_pat_id AND status = 'Completed';
    RETURN v_cnt;
END //

CREATE TRIGGER trg_cancel_appointment
AFTER UPDATE ON appointments
FOR EACH ROW
BEGIN
    IF NEW.status = 'Cancelled' AND OLD.status != 'Cancelled' THEN
        INSERT INTO audit_logs (table_name, action_type, record_id, details)
        VALUES ('appointments', 'CANCEL', NEW.app_id, CONCAT('Appointment ', NEW.app_id, ' cancelled'));
    END IF;
END //

DELIMITER ;
