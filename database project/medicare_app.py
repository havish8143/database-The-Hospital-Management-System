#!/usr/bin/env python3
"""
BCSE302L - Database Systems Course Project
Topic: Hospital Management System (HMS)
Student: Kankanala Havish Kumar | Reg. No: 24BYB0057
Individual Course Project Evaluation
"""

import sqlite3
import os

DB_NAME = "hospital.db"

def get_connection():
    conn = sqlite3.connect(DB_NAME)
    conn.execute("PRAGMA foreign_keys = ON;")
    return conn

def print_table(headers, rows):
    if not rows:
        print("  (No records found)")
        return
    
    col_w = [len(str(h)) for h in headers]
    for row in rows:
        for i, val in enumerate(row):
            txt = str(val) if val is not None else "NULL"
            if len(txt) > col_w[i]:
                col_w[i] = len(txt)
                
    border = "+-" + "-+-".join("-" * w for w in col_w) + "-+"
    print(border)
    hdr_row = "| " + " | ".join(f"{str(h):<{col_w[i]}}" for i, h in enumerate(headers)) + " |"
    print(hdr_row)
    print(border)
    for row in rows:
        line = "| " + " | ".join(f"{str(v if v is not None else 'NULL'):<{col_w[i]}}" for i, v in enumerate(row)) + " |"
        print(line)
    print(border)

def init_db():
    conn = get_connection()
    cur = conn.cursor()

    cur.executescript("""
    DROP TABLE IF EXISTS audit_logs;
    DROP TABLE IF EXISTS bills;
    DROP TABLE IF EXISTS medical_records;
    DROP TABLE IF EXISTS appointments;
    DROP TABLE IF EXISTS patients;
    DROP TABLE IF EXISTS doctors;
    DROP TABLE IF EXISTS departments;

    -- 1. Departments table
    CREATE TABLE departments (
        dept_id         INTEGER PRIMARY KEY,
        dept_name       TEXT NOT NULL UNIQUE,
        block_name      TEXT NOT NULL,
        contact_ext     TEXT NOT NULL,
        head_doctor_id  INTEGER
    );

    -- 2. Doctors table
    CREATE TABLE doctors (
        doctor_id       INTEGER PRIMARY KEY,
        doc_name        TEXT NOT NULL,
        specialization  TEXT NOT NULL,
        dept_id         INTEGER NOT NULL,
        phone           TEXT NOT NULL UNIQUE,
        email           TEXT NOT NULL UNIQUE,
        fee             REAL NOT NULL CHECK(fee >= 0),
        status          TEXT NOT NULL DEFAULT 'Active' CHECK(status IN ('Active', 'On Leave', 'Retired')),
        FOREIGN KEY (dept_id) REFERENCES departments(dept_id) ON DELETE CASCADE
    );

    -- 3. Patients table
    CREATE TABLE patients (
        patient_id      INTEGER PRIMARY KEY,
        patient_name    TEXT NOT NULL,
        dob             TEXT NOT NULL,
        gender          TEXT NOT NULL CHECK(gender IN ('Male', 'Female', 'Other')),
        blood_group     TEXT NOT NULL CHECK(blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
        phone           TEXT NOT NULL UNIQUE,
        emergency_phone TEXT NOT NULL,
        city            TEXT NOT NULL,
        registered_on   TEXT NOT NULL DEFAULT (DATE('now'))
    );

    -- 4. Appointments table
    CREATE TABLE appointments (
        app_id          INTEGER PRIMARY KEY,
        patient_id      INTEGER NOT NULL,
        doctor_id       INTEGER NOT NULL,
        app_date        TEXT NOT NULL,
        app_time        TEXT NOT NULL,
        status          TEXT NOT NULL DEFAULT 'Scheduled' CHECK(status IN ('Scheduled', 'Completed', 'Cancelled', 'No-Show')),
        problem_desc    TEXT NOT NULL,
        created_at      TEXT NOT NULL DEFAULT (DATETIME('now')),
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
        FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE
    );

    -- 5. Medical Records table
    CREATE TABLE medical_records (
        record_id       INTEGER PRIMARY KEY,
        app_id          INTEGER NOT NULL UNIQUE,
        patient_id      INTEGER NOT NULL,
        doctor_id       INTEGER NOT NULL,
        diagnosis       TEXT NOT NULL,
        prescription    TEXT NOT NULL,
        notes           TEXT,
        entry_date      TEXT NOT NULL DEFAULT (DATE('now')),
        FOREIGN KEY (app_id) REFERENCES appointments(app_id) ON DELETE CASCADE,
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
        FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE
    );

    -- 6. Bills table
    CREATE TABLE bills (
        bill_id         INTEGER PRIMARY KEY,
        app_id          INTEGER NOT NULL UNIQUE,
        patient_id      INTEGER NOT NULL,
        doctor_fee      REAL NOT NULL CHECK(doctor_fee >= 0),
        medicine_fee    REAL NOT NULL DEFAULT 0.0 CHECK(medicine_fee >= 0),
        total_amt       REAL NOT NULL CHECK(total_amt >= 0),
        discount        REAL NOT NULL DEFAULT 0.0 CHECK(discount >= 0),
        net_amt         REAL NOT NULL CHECK(net_amt >= 0),
        payment_status  TEXT NOT NULL DEFAULT 'Pending' CHECK(payment_status IN ('Pending', 'Paid', 'Refunded')),
        payment_date    TEXT,
        FOREIGN KEY (app_id) REFERENCES appointments(app_id) ON DELETE CASCADE,
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE
    );

    -- 7. Audit logs table
    CREATE TABLE audit_logs (
        log_id          INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name      TEXT NOT NULL,
        action_type     TEXT NOT NULL,
        record_id       INTEGER NOT NULL,
        action_time     TEXT NOT NULL DEFAULT (DATETIME('now')),
        details         TEXT NOT NULL
    );

    -- Trigger 1: Log when an appointment is cancelled
    CREATE TRIGGER trg_cancel_appointment
    AFTER UPDATE OF status ON appointments
    FOR EACH ROW
    WHEN NEW.status = 'Cancelled' AND OLD.status != 'Cancelled'
    BEGIN
        INSERT INTO audit_logs (table_name, action_type, record_id, details)
        VALUES ('appointments', 'CANCEL', NEW.app_id, 'Appointment ' || NEW.app_id || ' cancelled for patient ID ' || NEW.patient_id);
    END;

    -- Trigger 2: Recalculate bill total and net amount on insert
    CREATE TRIGGER trg_calc_bill_net
    AFTER INSERT ON bills
    BEGIN
        UPDATE bills 
        SET total_amt = doctor_fee + medicine_fee,
            net_amt = MAX(0.0, (doctor_fee + medicine_fee) - discount)
        WHERE bill_id = NEW.bill_id;
    END;
    """)

    # Populate sample records (at least 10 records per table)
    cur.executescript("""
    -- 10 Departments
    INSERT INTO departments VALUES (1, 'Cardiology', 'Block A', '101', 101);
    INSERT INTO departments VALUES (2, 'Neurology', 'Block B', '102', 102);
    INSERT INTO departments VALUES (3, 'Orthopedics', 'Block A', '103', 103);
    INSERT INTO departments VALUES (4, 'Pediatrics', 'Block C', '104', 104);
    INSERT INTO departments VALUES (5, 'Dermatology', 'Block D', '105', 105);
    INSERT INTO departments VALUES (6, 'General Medicine', 'Block A', '106', 106);
    INSERT INTO departments VALUES (7, 'ENT', 'Block C', '107', 107);
    INSERT INTO departments VALUES (8, 'Gastroenterology', 'Block B', '108', 108);
    INSERT INTO departments VALUES (9, 'Oncology', 'Block E', '109', 109);
    INSERT INTO departments VALUES (10, 'Psychiatry', 'Block D', '110', 110);

    -- 10 Doctors
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

    -- 12 Patients
    INSERT INTO patients VALUES (201, 'Rahul Verma', '1998-04-12', 'Male', 'B+', '9789123401', '9789123499', 'Vellore', '2024-01-05');
    INSERT INTO patients VALUES (202, 'Sneha Krishnan', '1995-11-20', 'Female', 'O+', '9789123402', '9789123498', 'Katpadi', '2024-01-08');
    INSERT INTO patients VALUES (203, 'Manoj Kumar', '1982-07-15', 'Male', 'A+', '9789123403', '9789123497', 'Chennai', '2024-01-14');
    INSERT INTO patients VALUES (204, 'Divya Balaji', '2001-02-28', 'Female', 'AB+', '9789123404', '9789123496', 'Ranipet', '2024-01-22');
    INSERT INTO patients VALUES (205, 'Vigneshwaran S', '1976-09-04', 'Male', 'O-', '9789123405', '9789123495', 'Vellore', '2024-02-01');
    INSERT INTO patients VALUES (206, 'Pooja Hegde', '1999-06-18', 'Female', 'A-', '9789123406', '9789123494', 'Bengaluru', '2024-02-10');
    INSERT INTO patients VALUES (207, 'Karthik Raja', '1988-12-09', 'Male', 'B+', '9789123407', '9789123493', 'Chittoor', '2024-02-15');
    INSERT INTO patients VALUES (208, 'Lakshmi Ammal', '1955-03-30', 'Female', 'O+', '9789123408', '9789123492', 'Vellore', '2024-02-20');
    INSERT INTO patients VALUES (209, 'Goutham Menon', '2003-10-05', 'Male', 'B-', '9789123409', '9789123491', 'Katpadi', '2024-03-01');
    INSERT INTO patients VALUES (210, 'Swathi Raman', '1993-08-25', 'Female', 'AB-', '9789123410', '9789123490', 'Kanchipuram', '2024-03-05');
    INSERT INTO patients VALUES (211, 'Siddharth Rao', '1980-01-19', 'Male', 'A+', '9789123411', '9789123489', 'Chennai', '2024-03-12');
    INSERT INTO patients VALUES (212, 'Nandhini Devi', '1968-05-14', 'Female', 'O+', '9789123412', '9789123488', 'Vellore', '2024-03-18');

    -- 15 Appointments
    INSERT INTO appointments VALUES (301, 201, 101, '2024-02-01', '10:00 AM', 'Completed', 'Chest tightness during walking', '2024-01-30 09:15:00');
    INSERT INTO appointments VALUES (302, 202, 102, '2024-02-02', '11:00 AM', 'Completed', 'Severe migraine on right side', '2024-01-31 10:20:00');
    INSERT INTO appointments VALUES (303, 203, 103, '2024-02-03', '02:30 PM', 'Completed', 'Left knee pain after gym workout', '2024-02-01 11:00:00');
    INSERT INTO appointments VALUES (304, 204, 104, '2024-02-04', '04:00 PM', 'Completed', 'High fever and cold since 2 days', '2024-02-02 12:45:00');
    INSERT INTO appointments VALUES (305, 205, 105, '2024-02-05', '10:30 AM', 'Completed', 'Dry skin patches on arms', '2024-02-03 14:10:00');
    INSERT INTO appointments VALUES (306, 206, 106, '2024-02-06', '09:30 AM', 'Completed', 'Routine full body health check', '2024-02-04 15:00:00');
    INSERT INTO appointments VALUES (307, 207, 107, '2024-02-07', '11:30 AM', 'Completed', 'Ear blockage and throat pain', '2024-02-05 09:30:00');
    INSERT INTO appointments VALUES (308, 208, 108, '2024-02-08', '03:00 PM', 'Completed', 'Stomach burning and acidity', '2024-02-06 10:00:00');
    INSERT INTO appointments VALUES (309, 209, 109, '2024-02-09', '12:00 PM', 'Completed', 'Follow up for biopsy review', '2024-02-07 11:30:00');
    INSERT INTO appointments VALUES (310, 210, 110, '2024-02-10', '05:00 PM', 'Completed', 'Trouble sleeping and anxiety', '2024-02-08 14:00:00');
    INSERT INTO appointments VALUES (311, 211, 101, '2024-03-20', '10:00 AM', 'Scheduled', 'BP routine checkup', '2024-03-15 09:00:00');
    INSERT INTO appointments VALUES (312, 212, 103, '2024-03-21', '03:00 PM', 'Scheduled', 'Joint stiffness in morning', '2024-03-16 11:00:00');
    INSERT INTO appointments VALUES (313, 201, 106, '2024-03-22', '09:00 AM', 'Cancelled', 'Viral fever follow up cancelled', '2024-03-17 12:00:00');
    INSERT INTO appointments VALUES (314, 203, 101, '2024-03-23', '10:30 AM', 'Scheduled', 'ECG report consultation', '2024-03-18 10:00:00');
    INSERT INTO appointments VALUES (315, 205, 108, '2024-03-24', '04:00 PM', 'No-Show', 'Endoscopy follow up', '2024-03-19 14:00:00');

    -- 10 Medical Records
    INSERT INTO medical_records VALUES (401, 301, 201, 101, 'Stable Angina', 'Tab Sorbitrate 5mg, Tab Atorva 10mg', 'Treadmill test suggested', '2024-02-01');
    INSERT INTO medical_records VALUES (402, 302, 202, 102, 'Migraine without aura', 'Tab Vasograin SOS, Tab Naprosyn 250mg', 'Avoid bright lights and caffeine', '2024-02-02');
    INSERT INTO medical_records VALUES (403, 303, 203, 103, 'Knee Meniscus strain', 'Tab Zerodol-P BD, Volini spray', 'Ice compression and rest for 5 days', '2024-02-03');
    INSERT INTO medical_records VALUES (404, 304, 204, 104, 'Viral Pharyngitis', 'Syp Paracetamol 250mg, Syp TusQ-D', 'Drink warm water and rest', '2024-02-04');
    INSERT INTO medical_records VALUES (405, 305, 205, 105, 'Mild Psoriasis', 'Betnovate-N cream, Moisturex lotion', 'Apply lotion after bathing', '2024-02-05');
    INSERT INTO medical_records VALUES (406, 306, 206, 106, 'Normal vitals', 'Multivitamin Becosules OD for 15 days', 'Healthy diet and 30 min walk', '2024-02-06');
    INSERT INTO medical_records VALUES (407, 307, 207, 107, 'Otitis media (Ear infection)', 'Ciplox ear drops 3 drops TDS, Tab Amox 500mg', 'Keep ear dry while bathing', '2024-02-07');
    INSERT INTO medical_records VALUES (408, 308, 208, 108, 'Hyperacidity / GERD', 'Tab Pan-D 40mg before food, Gelusil syrup', 'Avoid oily and spicy dinner', '2024-02-08');
    INSERT INTO medical_records VALUES (409, 309, 209, 109, 'Benign cyst under observation', 'Tab Shelcal 500mg OD', 'Review ultrasound after 3 months', '2024-02-09');
    INSERT INTO medical_records VALUES (410, 310, 210, 110, 'Mild Insomnia & Stress', 'Tab Zolpidem 5mg (5 days only)', 'Practice sleep hygiene and meditation', '2024-02-10');

    -- 10 Bills
    INSERT INTO bills VALUES (501, 301, 201, 800.0, 320.0, 1120.0, 50.0, 1070.0, 'Paid', '2024-02-01');
    INSERT INTO bills VALUES (502, 302, 202, 1000.0, 180.0, 1180.0, 0.0, 1180.0, 'Paid', '2024-02-02');
    INSERT INTO bills VALUES (503, 303, 203, 750.0, 240.0, 990.0, 40.0, 950.0, 'Paid', '2024-02-03');
    INSERT INTO bills VALUES (504, 304, 204, 600.0, 150.0, 750.0, 0.0, 750.0, 'Paid', '2024-02-04');
    INSERT INTO bills VALUES (505, 305, 205, 500.0, 290.0, 790.0, 0.0, 790.0, 'Paid', '2024-02-05');
    INSERT INTO bills VALUES (506, 306, 206, 450.0, 110.0, 560.0, 0.0, 560.0, 'Paid', '2024-02-06');
    INSERT INTO bills VALUES (507, 307, 207, 550.0, 160.0, 710.0, 0.0, 710.0, 'Paid', '2024-02-07');
    INSERT INTO bills VALUES (508, 308, 208, 850.0, 310.0, 1160.0, 60.0, 1100.0, 'Paid', '2024-02-08');
    INSERT INTO bills VALUES (509, 309, 209, 1200.0, 450.0, 1650.0, 100.0, 1550.0, 'Pending', NULL);
    INSERT INTO bills VALUES (510, 310, 210, 700.0, 200.0, 900.0, 0.0, 900.0, 'Pending', NULL);

    -- 10 Audit logs
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
    """)

    conn.commit()
    conn.close()
    print("[+] Database initialized successfully with tables and records.")

# -----------------------------------------------------------------------------
# PL/SQL Logics (Procedures, Functions, Cursor)
# -----------------------------------------------------------------------------

def proc_schedule_appointment(app_id, pat_id, doc_id, date_str, time_str, problem):
    """Procedure 1: Checks patient and doctor, verifies slot, then books appointment."""
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute("SELECT COUNT(*) FROM patients WHERE patient_id = ?", (pat_id,))
        if cur.fetchone()[0] == 0:
            return False, f"Patient ID {pat_id} does not exist in records."

        cur.execute("SELECT status FROM doctors WHERE doctor_id = ?", (doc_id,))
        doc = cur.fetchone()
        if not doc or doc[0] != 'Active':
            return False, f"Doctor ID {doc_id} is currently unavailable or inactive."

        # Check if the doctor already has a booking at that time
        cur.execute("""
            SELECT COUNT(*) FROM appointments 
            WHERE doctor_id = ? AND app_date = ? AND app_time = ? AND status = 'Scheduled'
        """, (doc_id, date_str, time_str))
        if cur.fetchone()[0] > 0:
            return False, f"Slot conflict: Doctor already has an appointment at {date_str} {time_str}."

        cur.execute("""
            INSERT INTO appointments (app_id, patient_id, doctor_id, app_date, app_time, status, problem_desc)
            VALUES (?, ?, ?, ?, ?, 'Scheduled', ?)
        """, (app_id, pat_id, doc_id, date_str, time_str, problem))

        cur.execute("""
            INSERT INTO audit_logs (table_name, action_type, record_id, details)
            VALUES ('appointments', 'PROC_BOOK', ?, ?)
        """, (app_id, f"Appointment {app_id} booked for patient {pat_id} with doctor {doc_id}"))

        conn.commit()
        return True, f"Appointment #{app_id} booked successfully."
    except Exception as e:
        conn.rollback()
        return False, str(e)
    finally:
        conn.close()

def proc_generate_bill(bill_id, app_id, med_charge, disc):
    """Procedure 2: Marks appointment completed and creates bill."""
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute("SELECT patient_id, doctor_id, status FROM appointments WHERE app_id = ?", (app_id,))
        app = cur.fetchone()
        if not app:
            return False, f"Appointment #{app_id} not found."
        
        pat_id, doc_id, _ = app

        # Check if bill already exists
        cur.execute("SELECT COUNT(*) FROM bills WHERE app_id = ?", (app_id,))
        if cur.fetchone()[0] > 0:
            return False, f"Bill already generated for appointment #{app_id}."

        # Get doctor fee
        cur.execute("SELECT fee FROM doctors WHERE doctor_id = ?", (doc_id,))
        doc_fee = cur.fetchone()[0]

        total = doc_fee + med_charge
        net = max(0.0, total - disc)

        # Update appointment status
        cur.execute("UPDATE appointments SET status = 'Completed' WHERE app_id = ?", (app_id,))

        # Insert bill
        cur.execute("""
            INSERT INTO bills (bill_id, app_id, patient_id, doctor_fee, medicine_fee, total_amt, discount, net_amt, payment_status, payment_date)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Paid', DATE('now'))
        """, (bill_id, app_id, pat_id, doc_fee, med_charge, total, disc, net))

        cur.execute("""
            INSERT INTO audit_logs (table_name, action_type, record_id, details)
            VALUES ('bills', 'PROC_BILL', ?, ?)
        """, (bill_id, f"Bill #{bill_id} generated for App #{app_id}. Net: Rs. {net}"))

        conn.commit()
        return True, f"Bill #{bill_id} generated successfully. Net: Rs.{net}"
    except Exception as e:
        conn.rollback()
        return False, str(e)
    finally:
        conn.close()

def func_doctor_revenue(doc_id):
    """Function 1: Returns total revenue generated by a doctor."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT COALESCE(SUM(b.net_amt), 0.0)
        FROM bills b
        JOIN appointments a ON b.app_id = a.app_id
        WHERE a.doctor_id = ? AND b.payment_status = 'Paid'
    """, (doc_id,))
    total = cur.fetchone()[0]
    conn.close()
    return total

def func_patient_visits(pat_id):
    """Function 2: Returns completed visit count for a patient."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) FROM appointments WHERE patient_id = ? AND status = 'Completed'", (pat_id,))
    count = cur.fetchone()[0]
    conn.close()
    return count

def cursor_process_pending_bills():
    """Cursor: Row-by-row processing of unpaid bills to log payment reminders."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT b.bill_id, p.patient_name, p.phone, b.net_amt
        FROM bills b
        JOIN patients p ON b.patient_id = p.patient_id
        WHERE b.payment_status = 'Pending'
    """)
    records = cur.fetchall()
    
    total_due = 0.0
    processed = []
    for bill_id, name, phone, amt in records:
        total_due += amt
        # Log to audit table
        cur.execute("""
            INSERT INTO audit_logs (table_name, action_type, record_id, details)
            VALUES ('bills', 'REMINDER', ?, ?)
        """, (bill_id, f"Payment reminder logged for {name} ({phone}) - Rs. {amt}"))
        processed.append((bill_id, name, phone, f"Rs. {amt:.2f}"))

    conn.commit()
    conn.close()
    return processed, total_due

# -----------------------------------------------------------------------------
# 15 Meaningful SQL Queries (Requirement)
# -----------------------------------------------------------------------------

SQL_QUERIES = [
    (1, "View full appointment details with Patient, Doctor, and Department", """
        SELECT a.app_id, p.patient_name, d.doc_name, dep.dept_name, a.app_date, a.app_time, a.status
        FROM appointments a
        JOIN patients p ON a.patient_id = p.patient_id
        JOIN doctors d ON a.doctor_id = d.doctor_id
        JOIN departments dep ON d.dept_id = dep.dept_id
        ORDER BY a.app_id;
    """),
    (2, "Department revenue summary where total collected is at least Rs. 1000", """
        SELECT dep.dept_name, COUNT(b.bill_id) AS total_bills, 
               PRINTF('Rs. %.2f', SUM(b.net_amt)) AS total_revenue
        FROM bills b
        JOIN appointments a ON b.app_id = a.app_id
        JOIN doctors d ON a.doctor_id = d.doctor_id
        JOIN departments dep ON d.dept_id = dep.dept_id
        WHERE b.payment_status = 'Paid'
        GROUP BY dep.dept_name
        HAVING SUM(b.net_amt) >= 1000;
    """),
    (3, "Doctors whose consultation fee is higher than average fee of their department", """
        SELECT d.doctor_id, d.doc_name, d.specialization, d.fee, dep.dept_name
        FROM doctors d
        JOIN departments dep ON d.dept_id = dep.dept_id
        WHERE d.fee > (
            SELECT AVG(d2.fee) FROM doctors d2 WHERE d2.dept_id = d.dept_id
        );
    """),
    (4, "List patients and their completed visit count using subquery", """
        SELECT p.patient_id, p.patient_name, p.city, p.blood_group,
               (SELECT COUNT(*) FROM appointments a WHERE a.patient_id = p.patient_id AND a.status = 'Completed') AS total_visits
        FROM patients p
        ORDER BY total_visits DESC;
    """),
    (5, "Patients who have never booked an appointment in Cardiology department", """
        SELECT patient_id, patient_name, phone, city
        FROM patients
        WHERE patient_id NOT IN (
            SELECT a.patient_id 
            FROM appointments a 
            JOIN doctors d ON a.doctor_id = d.doctor_id
            WHERE d.dept_id = 1
        );
    """),
    (6, "Hospital overall billing aggregates (Total, Discounts, Average)", """
        SELECT COUNT(bill_id) AS paid_bills,
               PRINTF('Rs. %.2f', SUM(total_amt)) AS gross_billed,
               PRINTF('Rs. %.2f', SUM(discount)) AS total_discounts,
               PRINTF('Rs. %.2f', SUM(net_amt)) AS net_revenue,
               PRINTF('Rs. %.2f', AVG(net_amt)) AS avg_bill_amt
        FROM bills
        WHERE payment_status = 'Paid';
    """),
    (7, "Department details with doctor count using LEFT JOIN", """
        SELECT dep.dept_id, dep.dept_name, dep.block_name, COUNT(d.doctor_id) AS doc_count
        FROM departments dep
        LEFT JOIN doctors d ON dep.dept_id = d.dept_id
        GROUP BY dep.dept_id, dep.dept_name, dep.block_name;
    """),
    (8, "Patients categorized by age bracket using CASE statement", """
        SELECT patient_id, patient_name, dob, city,
               CASE 
                   WHEN dob <= '1975-01-01' THEN 'Senior'
                   WHEN dob BETWEEN '1975-01-02' AND '1995-12-31' THEN 'Adult'
                   ELSE 'Young Adult'
               END AS age_category
        FROM patients;
    """),
    (9, "Doctors who diagnosed cardiac or migraine conditions using EXISTS", """
        SELECT d.doctor_id, d.doc_name, d.specialization
        FROM doctors d
        WHERE EXISTS (
            SELECT 1 FROM medical_records mr 
            WHERE mr.doctor_id = d.doctor_id 
              AND (mr.diagnosis LIKE '%Angina%' OR mr.diagnosis LIKE '%Migraine%')
        );
    """),
    (10, "Top 3 doctors by total collected revenue", """
        SELECT d.doctor_id, d.doc_name, d.specialization,
               PRINTF('Rs. %.2f', SUM(b.net_amt)) AS total_earned
        FROM doctors d
        JOIN appointments a ON d.doctor_id = a.doctor_id
        JOIN bills b ON a.app_id = b.app_id
        WHERE b.payment_status = 'Paid'
        GROUP BY d.doctor_id, d.doc_name, d.specialization
        ORDER BY SUM(b.net_amt) DESC
        LIMIT 3;
    """),
    (11, "Combined medical record with prescription and billed amount", """
        SELECT mr.record_id, p.patient_name, d.doc_name, mr.diagnosis, mr.prescription, 
               PRINTF('Rs. %.2f', b.net_amt) AS net_bill, b.payment_status
        FROM medical_records mr
        JOIN patients p ON mr.patient_id = p.patient_id
        JOIN doctors d ON mr.doctor_id = d.doctor_id
        JOIN bills b ON mr.app_id = b.app_id
        ORDER BY mr.record_id;
    """),
    (12, "Department names with their Head of Department doctor details", """
        SELECT dep.dept_name, dep.block_name, dep.contact_ext,
               d.doc_name AS head_doctor, d.phone AS doctor_phone
        FROM departments dep
        JOIN doctors d ON dep.head_doctor_id = d.doctor_id;
    """),
    (13, "Pending bills that are greater than the average bill amount", """
        SELECT b.bill_id, b.app_id, p.patient_name, p.phone, 
               PRINTF('Rs. %.2f', b.net_amt) AS due_amt, b.payment_status
        FROM bills b
        JOIN patients p ON b.patient_id = p.patient_id
        WHERE b.payment_status = 'Pending'
          AND b.net_amt > (SELECT AVG(net_amt) FROM bills);
    """),
    (14, "Patient count grouped by Gender and Blood Group", """
        SELECT gender, blood_group, COUNT(*) AS count
        FROM patients
        GROUP BY gender, blood_group
        ORDER BY gender, count DESC;
    """),
    (15, "Appointment status count and percentage share", """
        SELECT status, COUNT(*) AS count,
               PRINTF('%.1f%%', COUNT(*) * 100.0 / (SELECT COUNT(*) FROM appointments)) AS percentage
        FROM appointments
        GROUP BY status;
    """)
]

def run_single_query(qid):
    q = next((item for item in SQL_QUERIES if item[0] == qid), None)
    if not q:
        print("Invalid query number.")
        return
    _, desc, sql = q
    print(f"\n--- Query {qid}: {desc} ---")
    print("SQL:")
    print(sql.strip() + "\n")
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(sql)
    rows = cur.fetchall()
    hdrs = [d[0] for d in cur.description]
    print_table(hdrs, rows)
    conn.close()

# -----------------------------------------------------------------------------
# 5 Real-World Transactions
# -----------------------------------------------------------------------------

def demo_tx1():
    print("\n--- Transaction 1: Patient Registration & Appointment Booking ---")
    # Step 1: Register patient
    conn = get_connection()
    cur = conn.cursor()
    new_pat_id = 213
    new_app_id = 316
    cur.execute("DELETE FROM appointments WHERE app_id = ?", (new_app_id,))
    cur.execute("DELETE FROM patients WHERE patient_id = ?", (new_pat_id,))
    
    cur.execute("""
        INSERT INTO patients (patient_id, patient_name, dob, gender, blood_group, phone, emergency_phone, city)
        VALUES (?, 'Kavitha S', '1997-09-12', 'Female', 'O+', '9789123499', '9789123480', 'Vellore')
    """, (new_pat_id,))
    conn.commit()
    conn.close()
    print(f"Step 1: Patient #{new_pat_id} (Kavitha S) inserted into patients table.")

    # Step 2: Call booking procedure
    ok, msg = proc_schedule_appointment(
        app_id=new_app_id,
        pat_id=new_pat_id,
        doc_id=104, # Dr. Anitha Reddy (Pediatrics)
        date_str="2024-04-10",
        time_str="11:00 AM",
        problem="Child routine vaccination"
    )
    print(f"Step 2: Procedure executed: {msg}")

    # Verify
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT a.app_id, p.patient_name, d.doc_name, a.app_date, a.status
        FROM appointments a
        JOIN patients p ON a.patient_id = p.patient_id
        JOIN doctors d ON a.doctor_id = d.doctor_id
        WHERE a.app_id = ?
    """, (new_app_id,))
    row = cur.fetchone()
    print_table(["App_ID", "Patient", "Doctor", "Date", "Status"], [row])
    conn.close()

def demo_tx2():
    print("\n--- Transaction 2: Doctor Consultation & Medical Record Creation ---")
    app_id = 316
    rec_id = 411
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM medical_records WHERE record_id = ?", (rec_id,))
    
    # Doctor completes appointment and writes prescription
    cur.execute("UPDATE appointments SET status = 'Completed' WHERE app_id = ?", (app_id,))
    cur.execute("""
        INSERT INTO medical_records (record_id, app_id, patient_id, doctor_id, diagnosis, prescription, notes)
        VALUES (?, ?, 213, 104, 'Routine Vaccination Given', 'Paracetamol syrup 5ml SOS if fever', 'Review after 6 months')
    """, (rec_id, app_id))
    cur.execute("INSERT INTO audit_logs (table_name, action_type, record_id, details) VALUES ('medical_records', 'INSERT', ?, 'Diagnosis recorded for App 316')", (rec_id,))
    conn.commit()

    cur.execute("SELECT record_id, app_id, diagnosis, prescription FROM medical_records WHERE record_id = ?", (rec_id,))
    print_table(["Record_ID", "App_ID", "Diagnosis", "Prescription"], [cur.fetchone()])
    conn.close()

def demo_tx3():
    print("\n--- Transaction 3: Discharge Billing with Net Amount Calculation ---")
    bill_id = 511
    app_id = 316
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM bills WHERE bill_id = ?", (bill_id,))
    conn.commit()
    conn.close()

    ok, msg = proc_generate_bill(bill_id, app_id, med_charge=120.0, disc=20.0)
    print("Result:", msg)

    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT bill_id, app_id, doctor_fee, medicine_fee, total_amt, discount, net_amt, payment_status FROM bills WHERE bill_id = ?", (bill_id,))
    print_table(["Bill_ID", "App_ID", "Doc_Fee", "Med_Fee", "Total", "Discount", "Net_Amt", "Status"], [cur.fetchone()])
    conn.close()

def demo_tx4():
    print("\n--- Transaction 4: Function Calls (Doctor Revenue & Patient History) ---")
    doc_id = 101
    pat_id = 201
    rev = func_doctor_revenue(doc_id)
    visits = func_patient_visits(pat_id)
    print(f"Revenue collected for Dr. Ramesh Sharma (ID {doc_id}): Rs. {rev:.2f}")
    print(f"Total completed visits for Rahul Verma (ID {pat_id}): {visits} visit(s)")

def demo_tx5():
    print("\n--- Transaction 5: Appointment Cancellation & Trigger Firing ---")
    app_id = 311
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("UPDATE appointments SET status = 'Cancelled' WHERE app_id = ?", (app_id,))
    conn.commit()
    print(f"Appointment #{app_id} marked as 'Cancelled'.")

    # Check audit log to show trigger fired
    cur.execute("SELECT log_id, table_name, action_type, record_id, action_time, details FROM audit_logs WHERE record_id = ? AND action_type = 'CANCEL'", (app_id,))
    row = cur.fetchone()
    print("\nAudit Log Entry inserted by Trigger:")
    print_table(["Log_ID", "Table", "Action", "Record_ID", "Timestamp", "Details"], [row])
    conn.close()

def demo_cursor():
    print("\n--- Cursor Demo: Processing Overdue / Pending Bills ---")
    records, total = cursor_process_pending_bills()
    print_table(["Bill_ID", "Patient Name", "Phone", "Amount Due"], records)
    print(f"Total Pending Receivables: Rs. {total:.2f}")
    print("[+] Audit reminders created for each pending bill.")

def demo_crud():
    print("\n--- CRUD Demonstration (INSERT, UPDATE, DELETE) ---")
    conn = get_connection()
    cur = conn.cursor()
    test_id = 999
    cur.execute("DELETE FROM patients WHERE patient_id = ?", (test_id,))

    # Insert
    cur.execute("""
        INSERT INTO patients (patient_id, patient_name, dob, gender, blood_group, phone, emergency_phone, city)
        VALUES (?, 'Test Patient', '2000-01-01', 'Male', 'O+', '9999988888', '9999988889', 'Vellore')
    """, (test_id,))
    print(f"1. INSERT: Added patient #{test_id}.")

    # Update
    cur.execute("UPDATE patients SET city = 'Chennai' WHERE patient_id = ?", (test_id,))
    cur.execute("SELECT patient_id, patient_name, city FROM patients WHERE patient_id = ?", (test_id,))
    print(f"2. UPDATE: Modified city to Chennai -> {cur.fetchone()}")

    # Delete
    cur.execute("DELETE FROM patients WHERE patient_id = ?", (test_id,))
    cur.execute("SELECT COUNT(*) FROM patients WHERE patient_id = ?", (test_id,))
    print(f"3. DELETE: Removed patient #{test_id}. Verified count: {cur.fetchone()[0]}")

    conn.commit()
    conn.close()

def view_tables():
    print("\n--- Database Tables Overview ---")
    tables = ['departments', 'doctors', 'patients', 'appointments', 'medical_records', 'bills', 'audit_logs']
    conn = get_connection()
    cur = conn.cursor()
    for t in tables:
        cur.execute(f"SELECT COUNT(*) FROM {t}")
        cnt = cur.fetchone()[0]
        cur.execute(f"SELECT * FROM {t} LIMIT 2")
        rows = cur.fetchall()
        hdrs = [d[0] for d in cur.description]
        print(f"\nTable: {t} (Total Rows: {cnt})")
        print_table(hdrs, rows)
    conn.close()

# -----------------------------------------------------------------------------
# Main Menu
# -----------------------------------------------------------------------------

def main():
    if not os.path.exists(DB_NAME):
        init_db()
        
    while True:
        print("\n" + "=" * 55)
        print("    HOSPITAL MANAGEMENT SYSTEM (BCSE302L)")
        print("    Student: Kankanala Havish Kumar | Reg: 24BYB0057")
        print("=" * 55)
        print("1. View Tables & Sample Records")
        print("2. Run Specific SQL Query (1 to 15)")
        print("3. Run All 15 SQL Queries")
        print("4. Transaction 1: Book Appointment")
        print("5. Transaction 2: Medical Consultation")
        print("6. Transaction 3: Generate Bill")
        print("7. Transaction 4: Doctor Revenue / Visit Count")
        print("8. Transaction 5: Cancel Appointment (Trigger Test)")
        print("9. Cursor: Process Pending Bills")
        print("10. Demonstrate CRUD (Insert, Update, Delete)")
        print("11. Reset / Re-populate Database")
        print("0. Exit")
        print("-" * 50)

        ch = input("Enter choice (0-11): ").strip()
        if ch == '0':
            print("Exiting application.")
            break
        elif ch == '1':
            view_tables()
        elif ch == '2':
            try:
                num = int(input("Enter query number (1-15): ").strip())
                run_single_query(num)
            except ValueError:
                print("Please enter a valid number.")
        elif ch == '3':
            for i in range(1, 16):
                run_single_query(i)
        elif ch == '4':
            demo_tx1()
        elif ch == '5':
            demo_tx2()
        elif ch == '6':
            demo_tx3()
        elif ch == '7':
            demo_tx4()
        elif ch == '8':
            demo_tx5()
        elif ch == '9':
            demo_cursor()
        elif ch == '10':
            demo_crud()
        elif ch == '11':
            init_db()
        else:
            print("Invalid choice, please try again.")

if __name__ == "__main__":
    main()
