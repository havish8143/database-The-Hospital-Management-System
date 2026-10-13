# BCSE302L - Database Systems: Viva Questions & Answers
**Student:** Kankanala Havish Kumar | **Reg. No:** 24BYB0057 | **Project Mode:** Individual Project

Use this guide to prepare for your viva during Review I, Review II, and Review III evaluations.

---

## Review I: Database Design & ER Modeling

### Q1: What is your project topic and why did you choose it?
**Answer:**  
"My project is a Hospital Management System. I chose it because hospital workflows have clear real-world entities (departments, doctors, patients, appointments, medical records, and billing) that require foreign key constraints, slot validations, and audit logs."

### Q2: How did you ensure your schema is in 3NF?
**Answer:**  
"All attributes have atomic values, so it is in 1NF. There are no partial dependencies because all non-key columns depend on the entire primary key, satisfying 2NF. For 3NF, we removed transitive dependencies. For example, department block and phone extensions are stored in the `departments` table rather than being repeated inside `doctors` or `appointments`."

### Q3: What is the relationship between Appointments, Medical Records, and Bills?
**Answer:**  
"An appointment has a 1-to-1 relationship with both medical records and bills. We enforced this using a `UNIQUE` constraint on `app_id` in both the `medical_records` and `bills` tables. This guarantees that each appointment has at most one consultation record and one invoice, preventing duplicate billing."

---

## Review II: SQL Implementation & PL/SQL

### Q4: What constraints did you use in your tables?
**Answer:**  
"We used:
* **Primary Key:** On every table (`dept_id`, `doctor_id`, `patient_id`, etc.).
* **Foreign Key with ON DELETE CASCADE:** To maintain referential integrity between parent and child tables.
* **CHECK Constraints:** To ensure fees and amounts are non-negative, and to restrict statuses to allowed values like `'Scheduled'`, `'Completed'`, `'Cancelled'`.
* **UNIQUE Constraints:** On doctor and patient phone numbers, email IDs, and department names.
* **NOT NULL:** On all required fields."

### Q5: What is the difference between your stored procedures and stored functions?
**Answer:**  
"Our procedures (`proc_schedule_appointment` and `proc_generate_bill`) perform DML operations—they insert rows, update appointment statuses, and write to the audit log. Our functions (`func_doctor_revenue` and `func_patient_visits`) are deterministic; they take an ID, perform a calculation, and return a single scalar value without modifying table data."

### Q6: Why did you use an explicit Cursor?
**Answer:**  
"SQL usually works on entire sets at once. In `cursor_process_pending_bills`, we used an explicit cursor to loop row-by-row through pending bills. This lets us print patient contact details individually, calculate the running total of unpaid dues, and write a reminder entry into the audit log for each overdue patient."

### Q7: Explain your triggers and when they execute.
**Answer:**  
"We have two triggers:
1. `trg_cancel_appointment`: An AFTER UPDATE trigger on `appointments`. When an appointment's status is changed to `'Cancelled'`, it automatically inserts a record into `audit_logs`.
2. `trg_calc_bill_net`: A trigger on `bills` that automatically calculates `total_amt = doctor_fee + medicine_fee` and sets `net_amt = total_amt - discount` whenever a bill is inserted."

---

## Review III: Real-World Transactions & Python Connectivity

### Q8: How does your Python application connect to the database?
**Answer:**  
"We used Python's built-in `sqlite3` library using the standard DB-API interface. We enabled foreign keys using `PRAGMA foreign_keys = ON;`. The user chooses an option from the menu, the Python function runs the parameterized SQL query, and the results are fetched and displayed in a formatted table."

### Q9: How do you prevent double-booking of doctors?
**Answer:**  
"In our booking procedure, before inserting a new row, we run a query:
`SELECT COUNT(*) FROM appointments WHERE doctor_id = ? AND app_date = ? AND app_time = ? AND status = 'Scheduled'`.
If the count is greater than 0, the procedure returns an error message saying that the doctor already has an appointment at that time."

### Q10: Walk through the billing transaction.
**Answer:**  
"When an appointment finishes:
1. `proc_generate_bill` fetches the doctor's consultation fee from `doctors`.
2. It adds the medicine charges and subtracts any discount.
3. It updates the appointment status to `'Completed'`.
4. It inserts the bill with status `'Paid'` and logs the entry into `audit_logs`."
