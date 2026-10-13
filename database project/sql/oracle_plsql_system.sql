-- ============================================================================
-- BCSE302L - Database Systems Course Project
-- Title: Hospital Management System
-- Student Name: Kankanala Havish Kumar | Reg. No: 24BYB0057
-- Schema & PL/SQL Implementation for Oracle Database / LiveSQL
-- ============================================================================

-- Drop existing tables
DROP TABLE audit_logs CASCADE CONSTRAINTS;
DROP TABLE bills CASCADE CONSTRAINTS;
DROP TABLE medical_records CASCADE CONSTRAINTS;
DROP TABLE appointments CASCADE CONSTRAINTS;
DROP TABLE patients CASCADE CONSTRAINTS;
DROP TABLE doctors CASCADE CONSTRAINTS;
DROP TABLE departments CASCADE CONSTRAINTS;

-- 1. Departments
CREATE TABLE departments (
    dept_id         NUMBER(4)       PRIMARY KEY,
    dept_name       VARCHAR2(50)    NOT NULL UNIQUE,
    block_name      VARCHAR2(20)    NOT NULL,
    contact_ext     VARCHAR2(10)    NOT NULL,
    head_doctor_id  NUMBER(4)
);

-- 2. Doctors
CREATE TABLE doctors (
    doctor_id       NUMBER(4)       PRIMARY KEY,
    doc_name        VARCHAR2(60)    NOT NULL,
    specialization  VARCHAR2(50)    NOT NULL,
    dept_id         NUMBER(4)       NOT NULL,
    phone           VARCHAR2(15)    NOT NULL UNIQUE,
    email           VARCHAR2(80)    NOT NULL UNIQUE,
    fee             NUMBER(8,2)     NOT NULL,
    status          VARCHAR2(20)    DEFAULT 'Active' NOT NULL,
    CONSTRAINT fk_doc_dept FOREIGN KEY (dept_id) REFERENCES departments(dept_id) ON DELETE CASCADE,
    CONSTRAINT chk_doc_fee CHECK (fee >= 0),
    CONSTRAINT chk_doc_status CHECK (status IN ('Active', 'On Leave', 'Retired'))
);

-- Foreign Key for department head doctor
ALTER TABLE departments ADD CONSTRAINT fk_dept_head 
    FOREIGN KEY (head_doctor_id) REFERENCES doctors(doctor_id) ON DELETE SET NULL;

-- 3. Patients
CREATE TABLE patients (
    patient_id      NUMBER(5)       PRIMARY KEY,
    patient_name    VARCHAR2(60)    NOT NULL,
    dob             DATE            NOT NULL,
    gender          VARCHAR2(10)    NOT NULL,
    blood_group     VARCHAR2(5)     NOT NULL,
    phone           VARCHAR2(15)    NOT NULL UNIQUE,
    emergency_phone VARCHAR2(15)    NOT NULL,
    city            VARCHAR2(50)    NOT NULL,
    registered_on   DATE            DEFAULT SYSDATE NOT NULL,
    CONSTRAINT chk_pat_gender CHECK (gender IN ('Male', 'Female', 'Other')),
    CONSTRAINT chk_pat_blood CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'))
);

-- 4. Appointments
CREATE TABLE appointments (
    app_id          NUMBER(6)       PRIMARY KEY,
    patient_id      NUMBER(5)       NOT NULL,
    doctor_id       NUMBER(4)       NOT NULL,
    app_date        DATE            NOT NULL,
    app_time        VARCHAR2(10)    NOT NULL,
    status          VARCHAR2(20)    DEFAULT 'Scheduled' NOT NULL,
    problem_desc    VARCHAR2(200)   NOT NULL,
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_app_pat FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    CONSTRAINT fk_app_doc FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    CONSTRAINT chk_app_status CHECK (status IN ('Scheduled', 'Completed', 'Cancelled', 'No-Show'))
);

-- 5. Medical Records
CREATE TABLE medical_records (
    record_id       NUMBER(6)       PRIMARY KEY,
    app_id          NUMBER(6)       NOT NULL UNIQUE,
    patient_id      NUMBER(5)       NOT NULL,
    doctor_id       NUMBER(4)       NOT NULL,
    diagnosis       VARCHAR2(200)   NOT NULL,
    prescription    VARCHAR2(300)   NOT NULL,
    notes           VARCHAR2(255),
    entry_date      DATE            DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_mr_app FOREIGN KEY (app_id) REFERENCES appointments(app_id) ON DELETE CASCADE,
    CONSTRAINT fk_mr_pat FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    CONSTRAINT fk_mr_doc FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE
);

-- 6. Bills
CREATE TABLE bills (
    bill_id         NUMBER(6)       PRIMARY KEY,
    app_id          NUMBER(6)       NOT NULL UNIQUE,
    patient_id      NUMBER(5)       NOT NULL,
    doctor_fee      NUMBER(8,2)     NOT NULL,
    medicine_fee    NUMBER(8,2)     DEFAULT 0.00 NOT NULL,
    total_amt       NUMBER(8,2)     NOT NULL,
    discount        NUMBER(8,2)     DEFAULT 0.00 NOT NULL,
    net_amt         NUMBER(8,2)     NOT NULL,
    payment_status  VARCHAR2(20)    DEFAULT 'Pending' NOT NULL,
    payment_date    DATE,
    CONSTRAINT fk_bill_app FOREIGN KEY (app_id) REFERENCES appointments(app_id) ON DELETE CASCADE,
    CONSTRAINT fk_bill_pat FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    CONSTRAINT chk_b_doc_fee CHECK (doctor_fee >= 0),
    CONSTRAINT chk_b_med_fee CHECK (medicine_fee >= 0),
    CONSTRAINT chk_b_total CHECK (total_amt >= 0),
    CONSTRAINT chk_b_net CHECK (net_amt >= 0),
    CONSTRAINT chk_b_status CHECK (payment_status IN ('Pending', 'Paid', 'Refunded'))
);

-- 7. Audit Logs
CREATE TABLE audit_logs (
    log_id          NUMBER(8)       GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    table_name      VARCHAR2(40)    NOT NULL,
    action_type     VARCHAR2(20)    NOT NULL,
    record_id       NUMBER(8)       NOT NULL,
    action_time     TIMESTAMP       DEFAULT CURRENT_TIMESTAMP NOT NULL,
    details         VARCHAR2(255)   NOT NULL
);

-- ============================================================================
-- SAMPLE DATA INSERTION (10+ records per table)
-- ============================================================================

-- Departments (10 records)
INSERT INTO departments VALUES (1, 'Cardiology', 'Block A', '101', NULL);
INSERT INTO departments VALUES (2, 'Neurology', 'Block B', '102', NULL);
INSERT INTO departments VALUES (3, 'Orthopedics', 'Block A', '103', NULL);
INSERT INTO departments VALUES (4, 'Pediatrics', 'Block C', '104', NULL);
INSERT INTO departments VALUES (5, 'Dermatology', 'Block D', '105', NULL);
INSERT INTO departments VALUES (6, 'General Medicine', 'Block A', '106', NULL);
INSERT INTO departments VALUES (7, 'ENT', 'Block C', '107', NULL);
INSERT INTO departments VALUES (8, 'Gastroenterology', 'Block B', '108', NULL);
INSERT INTO departments VALUES (9, 'Oncology', 'Block E', '109', NULL);
INSERT INTO departments VALUES (10, 'Psychiatry', 'Block D', '110', NULL);

-- Doctors (10 records)
INSERT INTO doctors VALUES (101, 'Dr. Ramesh Sharma', 'Cardiologist', 1, '9840123456', 'ramesh.sharma@hospital.org', 800.0, 'Active');
INSERT INTO doctors VALUES (102, 'Dr. Priya Swaminathan', 'Neurologist', 2, '9840234567', 'priya.s@hospital.org', 1000.0, 'Active');
INSERT INTO doctors VALUES (103, 'Dr. K. Venkatesh', 'Orthopedic Surgeon', 3, '9840345678', 'k.venkat@hospital.org', 750.0, 'Active');
INSERT INTO doctors VALUES (104, 'Dr. Anitha Reddy', 'Pediatrician', 4, '9840456789', 'anitha.reddy@hospital.org', 600.0, 'Active');
INSERT INTO doctors VALUES (105, 'Dr. Suresh Babu', 'Dermatologist', 5, '9840567890', 'suresh.babu@hospital.org', 500.0, 'Active');
INSERT INTO doctors VALUES (106, 'Dr. Meenakshi Sundaram', 'General Physician', 6, '9840678901', 'meenakshi@hospital.org', 450.0, 'Active');
INSERT INTO doctors VALUES (107, 'Dr. Harish Kumar', 'ENT Specialist', 7, '9840789012', 'harish.k@hospital.org', 550.0, 'Active');
INSERT INTO doctors VALUES (108, 'Dr. Deepa Nair', 'Gastroenterologist', 8, '9840890123', 'deepa.nair@hospital.org', 850.0, 'Active');
INSERT INTO doctors VALUES (109, 'Dr. Arun Prasad', 'Oncologist', 9, '9840901234', 'arun.prasad@hospital.org', 1200.0, 'Active');
INSERT INTO doctors VALUES (110, 'Dr. Shalini Gupta', 'Psychiatrist', 10, '9840012345', 'shalini.g@hospital.org', 700.0, 'Active');

-- Update department heads
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

-- Patients (12 records)
INSERT INTO patients VALUES (201, 'Rahul Verma', TO_DATE('1998-04-12', 'YYYY-MM-DD'), 'Male', 'B+', '9789123401', '9789123499', 'Vellore', TO_DATE('2024-01-05', 'YYYY-MM-DD'));
INSERT INTO patients VALUES (202, 'Sneha Krishnan', TO_DATE('1995-11-20', 'YYYY-MM-DD'), 'Female', 'O+', '9789123402', '9789123498', 'Katpadi', TO_DATE('2024-01-08', 'YYYY-MM-DD'));
INSERT INTO patients VALUES (203, 'Manoj Kumar', TO_DATE('1982-07-15', 'YYYY-MM-DD'), 'Male', 'A+', '9789123403', '9789123497', 'Chennai', TO_DATE('2024-01-14', 'YYYY-MM-DD'));
INSERT INTO patients VALUES (204, 'Divya Balaji', TO_DATE('2001-02-28', 'YYYY-MM-DD'), 'Female', 'AB+', '9789123404', '9789123496', 'Ranipet', TO_DATE('2024-01-22', 'YYYY-MM-DD'));
INSERT INTO patients VALUES (205, 'Vigneshwaran S', TO_DATE('1976-09-04', 'YYYY-MM-DD'), 'Male', 'O-', '9789123405', '9789123495', 'Vellore', TO_DATE('2024-02-01', 'YYYY-MM-DD'));
INSERT INTO patients VALUES (206, 'Pooja Hegde', TO_DATE('1999-06-18', 'YYYY-MM-DD'), 'Female', 'A-', '9789123406', '9789123494', 'Bengaluru', TO_DATE('2024-02-10', 'YYYY-MM-DD'));
INSERT INTO patients VALUES (207, 'Karthik Raja', TO_DATE('1988-12-09', 'YYYY-MM-DD'), 'Male', 'B+', '9789123407', '9789123493', 'Chittoor', TO_DATE('2024-02-15', 'YYYY-MM-DD'));
INSERT INTO patients VALUES (208, 'Lakshmi Ammal', TO_DATE('1955-03-30', 'YYYY-MM-DD'), 'Female', 'O+', '9789123408', '9789123492', 'Vellore', TO_DATE('2024-02-20', 'YYYY-MM-DD'));
INSERT INTO patients VALUES (209, 'Goutham Menon', TO_DATE('2003-10-05', 'YYYY-MM-DD'), 'Male', 'B-', '9789123409', '9789123491', 'Katpadi', TO_DATE('2024-03-01', 'YYYY-MM-DD'));
INSERT INTO patients VALUES (210, 'Swathi Raman', TO_DATE('1993-08-25', 'YYYY-MM-DD'), 'Female', 'AB-', '9789123410', '9789123490', 'Kanchipuram', TO_DATE('2024-03-05', 'YYYY-MM-DD'));
INSERT INTO patients VALUES (211, 'Siddharth Rao', TO_DATE('1980-01-19', 'YYYY-MM-DD'), 'Male', 'A+', '9789123411', '9789123489', 'Chennai', TO_DATE('2024-03-12', 'YYYY-MM-DD'));
INSERT INTO patients VALUES (212, 'Nandhini Devi', TO_DATE('1968-05-14', 'YYYY-MM-DD'), 'Female', 'O+', '9789123412', '9789123488', 'Vellore', TO_DATE('2024-03-18', 'YYYY-MM-DD'));

-- Appointments (15 records)
INSERT INTO appointments VALUES (301, 201, 101, TO_DATE('2024-02-01', 'YYYY-MM-DD'), '10:00 AM', 'Completed', 'Chest tightness during walking', TIMESTAMP '2024-01-30 09:15:00');
INSERT INTO appointments VALUES (302, 202, 102, TO_DATE('2024-02-02', 'YYYY-MM-DD'), '11:00 AM', 'Completed', 'Severe migraine on right side', TIMESTAMP '2024-01-31 10:20:00');
INSERT INTO appointments VALUES (303, 203, 103, TO_DATE('2024-02-03', 'YYYY-MM-DD'), '02:30 PM', 'Completed', 'Left knee pain after gym workout', TIMESTAMP '2024-02-01 11:00:00');
INSERT INTO appointments VALUES (304, 204, 104, TO_DATE('2024-02-04', 'YYYY-MM-DD'), '04:00 PM', 'Completed', 'High fever and cold since 2 days', TIMESTAMP '2024-02-02 12:45:00');
INSERT INTO appointments VALUES (305, 205, 105, TO_DATE('2024-02-05', 'YYYY-MM-DD'), '10:30 AM', 'Completed', 'Dry skin patches on arms', TIMESTAMP '2024-02-03 14:10:00');
INSERT INTO appointments VALUES (306, 206, 106, TO_DATE('2024-02-06', 'YYYY-MM-DD'), '09:30 AM', 'Completed', 'Routine full body health check', TIMESTAMP '2024-02-04 15:00:00');
INSERT INTO appointments VALUES (307, 207, 107, TO_DATE('2024-02-07', 'YYYY-MM-DD'), '11:30 AM', 'Completed', 'Ear blockage and throat pain', TIMESTAMP '2024-02-05 09:30:00');
INSERT INTO appointments VALUES (308, 208, 108, TO_DATE('2024-02-08', 'YYYY-MM-DD'), '03:00 PM', 'Completed', 'Stomach burning and acidity', TIMESTAMP '2024-02-06 10:00:00');
INSERT INTO appointments VALUES (309, 209, 109, TO_DATE('2024-02-09', 'YYYY-MM-DD'), '12:00 PM', 'Completed', 'Follow up for biopsy review', TIMESTAMP '2024-02-07 11:30:00');
INSERT INTO appointments VALUES (310, 210, 110, TO_DATE('2024-02-10', 'YYYY-MM-DD'), '05:00 PM', 'Completed', 'Trouble sleeping and anxiety', TIMESTAMP '2024-02-08 14:00:00');
INSERT INTO appointments VALUES (311, 211, 101, TO_DATE('2024-03-20', 'YYYY-MM-DD'), '10:00 AM', 'Scheduled', 'BP routine checkup', TIMESTAMP '2024-03-15 09:00:00');
INSERT INTO appointments VALUES (312, 212, 103, TO_DATE('2024-03-21', 'YYYY-MM-DD'), '03:00 PM', 'Scheduled', 'Joint stiffness in morning', TIMESTAMP '2024-03-16 11:00:00');
INSERT INTO appointments VALUES (313, 201, 106, TO_DATE('2024-03-22', 'YYYY-MM-DD'), '09:00 AM', 'Cancelled', 'Viral fever follow up cancelled', TIMESTAMP '2024-03-17 12:00:00');
INSERT INTO appointments VALUES (314, 203, 101, TO_DATE('2024-03-23', 'YYYY-MM-DD'), '10:30 AM', 'Scheduled', 'ECG report consultation', TIMESTAMP '2024-03-18 10:00:00');
INSERT INTO appointments VALUES (315, 205, 108, TO_DATE('2024-03-24', 'YYYY-MM-DD'), '04:00 PM', 'No-Show', 'Endoscopy follow up', TIMESTAMP '2024-03-19 14:00:00');

-- Medical Records (10 records)
INSERT INTO medical_records VALUES (401, 301, 201, 101, 'Stable Angina', 'Tab Sorbitrate 5mg, Tab Atorva 10mg', 'Treadmill test suggested', TO_DATE('2024-02-01', 'YYYY-MM-DD'));
INSERT INTO medical_records VALUES (402, 302, 202, 102, 'Migraine without aura', 'Tab Vasograin SOS, Tab Naprosyn 250mg', 'Avoid bright lights and caffeine', TO_DATE('2024-02-02', 'YYYY-MM-DD'));
INSERT INTO medical_records VALUES (403, 303, 203, 103, 'Knee Meniscus strain', 'Tab Zerodol-P BD, Volini spray', 'Ice compression and rest for 5 days', TO_DATE('2024-02-03', 'YYYY-MM-DD'));
INSERT INTO medical_records VALUES (404, 304, 204, 104, 'Viral Pharyngitis', 'Syp Paracetamol 250mg, Syp TusQ-D', 'Drink warm water and rest', TO_DATE('2024-02-04', 'YYYY-MM-DD'));
INSERT INTO medical_records VALUES (405, 305, 205, 105, 'Mild Psoriasis', 'Betnovate-N cream, Moisturex lotion', 'Apply lotion after bathing', TO_DATE('2024-02-05', 'YYYY-MM-DD'));
INSERT INTO medical_records VALUES (406, 306, 206, 106, 'Normal vitals', 'Multivitamin Becosules OD for 15 days', 'Healthy diet and 30 min walk', TO_DATE('2024-02-06', 'YYYY-MM-DD'));
INSERT INTO medical_records VALUES (407, 307, 207, 107, 'Otitis media (Ear infection)', 'Ciplox ear drops 3 drops TDS, Tab Amox 500mg', 'Keep ear dry while bathing', TO_DATE('2024-02-07', 'YYYY-MM-DD'));
INSERT INTO medical_records VALUES (408, 308, 208, 108, 'Hyperacidity / GERD', 'Tab Pan-D 40mg before food, Gelusil syrup', 'Avoid oily and spicy dinner', TO_DATE('2024-02-08', 'YYYY-MM-DD'));
INSERT INTO medical_records VALUES (409, 309, 209, 109, 'Benign cyst under observation', 'Tab Shelcal 500mg OD', 'Review ultrasound after 3 months', TO_DATE('2024-02-09', 'YYYY-MM-DD'));
INSERT INTO medical_records VALUES (410, 310, 210, 110, 'Mild Insomnia & Stress', 'Tab Zolpidem 5mg (5 days only)', 'Practice sleep hygiene and meditation', TO_DATE('2024-02-10', 'YYYY-MM-DD'));

-- Bills (10 records)
INSERT INTO bills VALUES (501, 301, 201, 800.0, 320.0, 1120.0, 50.0, 1070.0, 'Paid', TO_DATE('2024-02-01', 'YYYY-MM-DD'));
INSERT INTO bills VALUES (502, 302, 202, 1000.0, 180.0, 1180.0, 0.0, 1180.0, 'Paid', TO_DATE('2024-02-02', 'YYYY-MM-DD'));
INSERT INTO bills VALUES (503, 303, 203, 750.0, 240.0, 990.0, 40.0, 950.0, 'Paid', TO_DATE('2024-02-03', 'YYYY-MM-DD'));
INSERT INTO bills VALUES (504, 304, 204, 600.0, 150.0, 750.0, 0.0, 750.0, 'Paid', TO_DATE('2024-02-04', 'YYYY-MM-DD'));
INSERT INTO bills VALUES (505, 305, 205, 500.0, 290.0, 790.0, 0.0, 790.0, 'Paid', TO_DATE('2024-02-05', 'YYYY-MM-DD'));
INSERT INTO bills VALUES (506, 306, 206, 450.0, 110.0, 560.0, 0.0, 560.0, 'Paid', TO_DATE('2024-02-06', 'YYYY-MM-DD'));
INSERT INTO bills VALUES (507, 307, 207, 550.0, 160.0, 710.0, 0.0, 710.0, 'Paid', TO_DATE('2024-02-07', 'YYYY-MM-DD'));
INSERT INTO bills VALUES (508, 308, 208, 850.0, 310.0, 1160.0, 60.0, 1100.0, 'Paid', TO_DATE('2024-02-08', 'YYYY-MM-DD'));
INSERT INTO bills VALUES (509, 309, 209, 1200.0, 450.0, 1650.0, 100.0, 1550.0, 'Pending', NULL);
INSERT INTO bills VALUES (510, 310, 210, 700.0, 200.0, 900.0, 0.0, 900.0, 'Pending', NULL);

-- Audit Logs (10 records)
INSERT INTO audit_logs (table_name, action_type, record_id, details) VALUES ('patients', 'INSERT', 201, 'Patient Rahul Verma registered');
INSERT INTO audit_logs (table_name, action_type, record_id, details) VALUES ('patients', 'INSERT', 202, 'Patient Sneha Krishnan registered');
INSERT INTO audit_logs (table_name, action_type, record_id, details) VALUES ('doctors', 'INSERT', 101, 'Dr. Ramesh Sharma profile created');
INSERT INTO audit_logs (table_name, action_type, record_id, details) VALUES ('appointments', 'INSERT', 301, 'Appointment 301 scheduled');
INSERT INTO audit_logs (table_name, action_type, record_id, details) VALUES ('appointments', 'UPDATE', 301, 'Appointment 301 marked Completed');
INSERT INTO audit_logs (table_name, action_type, record_id, details) VALUES ('bills', 'INSERT', 501, 'Bill 501 generated for Rs. 1070');
INSERT INTO audit_logs (table_name, action_type, record_id, details) VALUES ('bills', 'UPDATE', 501, 'Bill 501 paid by cash');
INSERT INTO audit_logs (table_name, action_type, record_id, details) VALUES ('appointments', 'UPDATE', 313, 'Appointment 313 cancelled by patient');
INSERT INTO audit_logs (table_name, action_type, record_id, details) VALUES ('appointments', 'UPDATE', 315, 'Patient did not arrive for appointment 315');
INSERT INTO audit_logs (table_name, action_type, record_id, details) VALUES ('departments', 'UPDATE', 1, 'Head doctor linked to Cardiology');

COMMIT;

-- ============================================================================
-- PROCEDURES & FUNCTIONS
-- ============================================================================

-- Procedure 1: Book appointment with slot conflict check
CREATE OR REPLACE PROCEDURE proc_schedule_appointment (
    p_app_id     IN NUMBER,
    p_pat_id     IN NUMBER,
    p_doc_id     IN NUMBER,
    p_date_str   IN VARCHAR2,  -- Format: 'YYYY-MM-DD'
    p_time_str   IN VARCHAR2,
    p_desc       IN VARCHAR2
) AS
    v_pat_cnt    NUMBER;
    v_doc_status VARCHAR2(20);
    v_conflict   NUMBER;
    v_date       DATE;
BEGIN
    v_date := TO_DATE(p_date_str, 'YYYY-MM-DD');

    -- Check if patient exists
    SELECT COUNT(*) INTO v_pat_cnt FROM patients WHERE patient_id = p_pat_id;
    IF v_pat_cnt = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Patient ID does not exist.');
    END IF;

    -- Check doctor status
    SELECT status INTO v_doc_status FROM doctors WHERE doctor_id = p_doc_id;
    IF v_doc_status != 'Active' THEN
        RAISE_APPLICATION_ERROR(-20002, 'Doctor is not active.');
    END IF;

    -- Check if doctor is already booked at that time
    SELECT COUNT(*) INTO v_conflict FROM appointments 
    WHERE doctor_id = p_doc_id AND app_date = v_date AND app_time = p_time_str AND status = 'Scheduled';

    IF v_conflict > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Time slot conflict: Doctor already has an appointment.');
    END IF;

    -- Insert appointment
    INSERT INTO appointments (app_id, patient_id, doctor_id, app_date, app_time, status, problem_desc)
    VALUES (p_app_id, p_pat_id, p_doc_id, v_date, p_time_str, 'Scheduled', p_desc);

    INSERT INTO audit_logs (table_name, action_type, record_id, details)
    VALUES ('appointments', 'PROC_BOOK', p_app_id, 'Booked appointment ' || p_app_id || ' for patient ' || p_pat_id);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Appointment ' || p_app_id || ' scheduled successfully.');
END proc_schedule_appointment;
/

-- Procedure 2: Complete appointment and generate discharge bill
CREATE OR REPLACE PROCEDURE proc_generate_bill (
    p_bill_id    IN NUMBER,
    p_app_id     IN NUMBER,
    p_med_charge IN NUMBER,
    p_discount   IN NUMBER
) AS
    v_pat_id     NUMBER;
    v_doc_id     NUMBER;
    v_fee        NUMBER;
    v_total      NUMBER;
    v_net        NUMBER;
BEGIN
    SELECT patient_id, doctor_id INTO v_pat_id, v_doc_id 
    FROM appointments WHERE app_id = p_app_id;

    SELECT fee INTO v_fee FROM doctors WHERE doctor_id = v_doc_id;

    v_total := v_fee + NVL(p_med_charge, 0);
    v_net := v_total - NVL(p_discount, 0);
    IF v_net < 0 THEN
        v_net := 0;
    END IF;

    UPDATE appointments SET status = 'Completed' WHERE app_id = p_app_id;

    INSERT INTO bills (bill_id, app_id, patient_id, doctor_fee, medicine_fee, total_amt, discount, net_amt, payment_status, payment_date)
    VALUES (p_bill_id, p_app_id, v_pat_id, v_fee, NVL(p_med_charge, 0), v_total, NVL(p_discount, 0), v_net, 'Paid', SYSDATE);

    INSERT INTO audit_logs (table_name, action_type, record_id, details)
    VALUES ('bills', 'PROC_BILL', p_bill_id, 'Generated bill ' || p_bill_id || ' Net: ' || v_net);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Discharge bill ' || p_bill_id || ' created. Net payable: Rs.' || v_net);
END proc_generate_bill;
/

-- Function 1: Return total revenue earned by a doctor
CREATE OR REPLACE FUNCTION func_doctor_revenue (
    p_doc_id IN NUMBER
) RETURN NUMBER AS
    v_rev NUMBER := 0;
BEGIN
    SELECT NVL(SUM(b.net_amt), 0)
    INTO v_rev
    FROM bills b
    JOIN appointments a ON b.app_id = a.app_id
    WHERE a.doctor_id = p_doc_id AND b.payment_status = 'Paid';

    RETURN v_rev;
END func_doctor_revenue;
/

-- Function 2: Return total completed visits for a patient
CREATE OR REPLACE FUNCTION func_patient_visits (
    p_pat_id IN NUMBER
) RETURN NUMBER AS
    v_cnt NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_cnt
    FROM appointments
    WHERE patient_id = p_pat_id AND status = 'Completed';

    RETURN v_cnt;
END func_patient_visits;
/

-- Cursor Implementation: Loop over pending bills
CREATE OR REPLACE PROCEDURE cursor_process_pending_bills AS
    CURSOR c_bills IS
        SELECT b.bill_id, p.patient_name, p.phone, b.net_amt
        FROM bills b
        JOIN patients p ON b.patient_id = p.patient_id
        WHERE b.payment_status = 'Pending';
        
    v_id NUMBER;
    v_name VARCHAR2(60);
    v_phone VARCHAR2(15);
    v_amt NUMBER;
    v_total NUMBER := 0;
BEGIN
    OPEN c_bills;
    LOOP
        FETCH c_bills INTO v_id, v_name, v_phone, v_amt;
        EXIT WHEN c_bills%NOTFOUND;
        
        v_total := v_total + v_amt;
        DBMS_OUTPUT.PUT_LINE('Pending Bill #' || v_id || ' - Patient: ' || v_name || ' (' || v_phone || ') Due: Rs.' || v_amt);

        INSERT INTO audit_logs (table_name, action_type, record_id, details)
        VALUES ('bills', 'REMINDER', v_id, 'Payment reminder for ' || v_name || ' (Rs.' || v_amt || ')');
    END LOOP;
    CLOSE c_bills;
    DBMS_OUTPUT.PUT_LINE('Total Pending Receivables: Rs.' || v_total);
    COMMIT;
END cursor_process_pending_bills;
/

-- Trigger 1: Log cancelled appointment
CREATE OR REPLACE TRIGGER trg_cancel_appointment
AFTER UPDATE OF status ON appointments
FOR EACH ROW
WHEN (NEW.status = 'Cancelled' AND OLD.status != 'Cancelled')
BEGIN
    INSERT INTO audit_logs (table_name, action_type, record_id, details)
    VALUES ('appointments', 'CANCEL', :NEW.app_id, 'Appointment ' || :NEW.app_id || ' cancelled for patient ID ' || :NEW.patient_id);
END;
/

-- Trigger 2: Recalculate bill net amount
CREATE OR REPLACE TRIGGER trg_calc_bill_net
BEFORE INSERT OR UPDATE ON bills
FOR EACH ROW
BEGIN
    :NEW.total_amt := :NEW.doctor_fee + NVL(:NEW.medicine_fee, 0);
    :NEW.net_amt   := :NEW.total_amt - NVL(:NEW.discount, 0);
    IF :NEW.net_amt < 0 THEN
        :NEW.net_amt := 0;
    END IF;
END;
/
