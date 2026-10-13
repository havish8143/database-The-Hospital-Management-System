#!/usr/bin/env python3
"""
BCSE302L - Database Systems Course Project
Topic: Hospital Management System
Student: Kankanala Havish Kumar | Reg. No: 24BYB0057
Individual Course Project Evaluation
"""

from medicare_app import (
    init_db,
    view_tables,
    demo_crud,
    demo_tx1,
    demo_tx2,
    demo_tx3,
    demo_tx4,
    demo_tx5,
    demo_cursor,
    run_single_query,
    SQL_QUERIES
)

def run_all():
    print("==========================================================")
    print("  BCSE302L Database Systems - Project Evaluation          ")
    print("  Student: Kankanala Havish Kumar | Reg. No: 24BYB0057    ")
    print("==========================================================\n")
    
    print("[1] Initializing Database & Populating Sample Records...")
    init_db()

    print("\n[2] Checking Tables & Constraints...")
    view_tables()

    print("\n[3] Testing Basic DML Operations (Insert, Update, Delete)...")
    demo_crud()

    print("\n[4] Executing 5 Real-World Integrated Transactions...")
    demo_tx1()
    demo_tx2()
    demo_tx3()
    demo_tx4()
    demo_tx5()

    print("\n[5] Executing Cursor Batch Operation...")
    demo_cursor()

    print("\n[6] Running 15 SQL Queries...")
    for qid, _, _ in SQL_QUERIES:
        run_single_query(qid)

    print("\n==================================================")
    print("  Demonstration completed successfully!           ")
    print("==================================================")

if __name__ == "__main__":
    run_all()
