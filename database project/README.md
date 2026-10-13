# Hospital Management System (HMS)
**BCSE302L - Database Systems Course Project**  
**Student:** Kankanala Havish Kumar | **Reg. No:** 24BYB0057 | **Project Mode:** Individual Project  

A complete relational database project for hospital appointment booking, clinical consultation recording, discharge billing, and audit tracking.

---

## Files in this Project

```
database project/
├── medicare_app.py               # Main Python application (Interactive Menu)
├── run_demo.py                   # Automated demo script for quick evaluation
├── sql/
│   ├── oracle_plsql_system.sql   # Complete script for Oracle LiveSQL / SQL Developer
│   └── mysql_system.sql          # Complete script for MySQL Workbench
├── docs/
│   ├── BCSE302L_Project_Report.md# 10-section formal project report
│   └── Viva_Questions_Guide.md  # Viva preparation questions and answers
└── README.md
```

---

## How to Run

### 1. Interactive Menu
Open your terminal in this directory and run:
```powershell
python medicare_app.py
```
This opens an interactive menu where you can view tables, run specific queries (1 to 15), book appointments, generate bills, test triggers, and run cursors.

### 2. Automated Run (For Faculty Demo)
To run all tests and queries in one go:
```powershell
python run_demo.py
```

### 3. Oracle LiveSQL / MySQL
* **Oracle:** Copy and paste the contents of `sql/oracle_plsql_system.sql` into **Oracle LiveSQL**.
* **MySQL:** Run `sql/mysql_system.sql` in **MySQL Workbench**.
