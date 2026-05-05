#!/usr/bin/env python3
"""
Validation Script for ZISCS_MIGRATION_ACCOUNTS_MC4A (UD1K936711)

This script validates the extraction logic by running equivalent queries
against the CCMS database and comparing results.

Usage:
    python3 validate_account_extraction.py [--key-date YYYYMMDD] [--months N]
"""

import sqlite3
import argparse
from datetime import datetime, timedelta
from tabulate import tabulate

# Configuration
CCMS_DB = "/home/vboxuser/CCMS/ccms_master.db"  # Adjust if different
KEY_DATE = "20251027"
MONTHS = 24

def parse_date(date_str):
    """Convert YYYYMMDD string to datetime"""
    return datetime.strptime(date_str, "%Y%m%d")

def calculate_past_date(key_date_str, months):
    """Calculate past date based on key date and month offset"""
    key_date = parse_date(key_date_str)
    past_date = key_date - timedelta(days=months * 30)  # Approximate
    return past_date.strftime("%Y%m%d")

def connect_db(db_path):
    """Connect to CCMS database"""
    try:
        conn = sqlite3.connect(db_path)
        return conn
    except sqlite3.Error as e:
        print(f"❌ Database connection failed: {e}")
        return None

def validate_rule_1_active_accounts(conn, key_date):
    """
    Rule 1: Count active accounts with valid contracts in CCMS
    Logic: EVER.AUSZDAT >= key_date
    """
    query = f"""
    SELECT COUNT(DISTINCT e.vkonto) as ca_count,
           COUNT(DISTINCT f.gpart) as bp_count
    FROM ever e
    INNER JOIN fkkvkp f ON e.vkonto = f.vkont
    WHERE e.auszdat >= '{key_date}'
    """
    cursor = conn.execute(query)
    result = cursor.fetchone()
    return {"ca": result[0] if result else 0, "bp": result[1] if result else 0}

def validate_rule_2_inactive_accounts(conn, key_date, past_date):
    """
    Rule 2: Count inactive accounts with move-out date within N months
    Logic: EVER.AUSZDAT <= key_date AND >= past_date
    """
    query = f"""
    SELECT COUNT(DISTINCT e.vkonto) as ca_count,
           COUNT(DISTINCT f.gpart) as bp_count
    FROM ever e
    INNER JOIN fkkvkp f ON e.vkonto = f.vkont
    WHERE e.auszdat <= '{key_date}'
      AND e.auszdat >= '{past_date}'
    """
    cursor = conn.execute(query)
    result = cursor.fetchone()
    return {"ca": result[0] if result else 0, "bp": result[1] if result else 0}

def validate_rule_3_write_off(conn):
    """
    Rule 3: Count accounts with valid write-off and write-in transactions
    Logic: DFKKOP.HVORG IN ('0630','ZWOF','ZWOS') AND (AUGST=space OR AUGST='9')
    Note: augst=space means 'open' status, augst='9' means 'blocked'
    """
    query = """
    SELECT COUNT(DISTINCT f.vkont) as ca_count,
           COUNT(DISTINCT f.gpart) as bp_count
    FROM dfkkop d
    INNER JOIN fkkvkp f ON d.vkont = f.vkont
    WHERE d.hvorg IN ('0630', 'ZWOF', 'ZWOS')
      AND (d.augst = ' ' OR d.augst = '9')
    """
    cursor = conn.execute(query)
    result = cursor.fetchone()
    return {"ca": result[0] if result else 0, "bp": result[1] if result else 0}

def validate_rule_4_outstanding(conn):
    """
    Rule 4: Count accounts with outstanding balance
    Logic: DFKKOP.AUGST = space AND AUCRS NE '2'
    Note: In MC4A, augrs check was removed (Log#0015)
    """
    query = """
    SELECT COUNT(DISTINCT f.vkont) as ca_count,
           COUNT(DISTINCT f.gpart) as bp_count
    FROM dfkkop d
    INNER JOIN fkkvkp f ON d.vkont = f.vkont
    WHERE d.augst = ' '
    """
    cursor = conn.execute(query)
    result = cursor.fetchone()
    return {"ca": result[0] if result else 0, "bp": result[1] if result else 0}

def validate_rule_9_shutdown(conn):
    """
    Rule 9: Count CA for shut down charge and Main charge
    Logic: DFKKOP.HVORG IN ('ZMNS','ZSHD') AND (AUGST=space OR AUGST='9')
    """
    query = """
    SELECT COUNT(DISTINCT f.vkont) as ca_count,
           COUNT(DISTINCT f.gpart) as bp_count
    FROM dfkkop d
    INNER JOIN fkkvkp f ON d.vkont = f.vkont
    WHERE d.hvorg IN ('ZMNS', 'ZSHD')
      AND (d.augst = ' ' OR d.augst = '9')
    """
    cursor = conn.execute(query)
    result = cursor.fetchone()
    return {"ca": result[0] if result else 0, "bp": result[1] if result else 0}

def validate_rule_13_account_manager(conn):
    """
    Rule 13: Count BP with Account Manager assigned
    Logic: FKKVKP.ZZACCTMNGR NE space
    """
    query = """
    SELECT COUNT(DISTINCT f.zzacctmngr) as bp_count
    FROM fkkvkp f
    WHERE f.zzacctmngr IS NOT NULL
      AND TRIM(f.zzacctmngr) != ''
    """
    cursor = conn.execute(query)
    result = cursor.fetchone()
    return {"ca": 0, "bp": result[0] if result else 0}

def validate_rule_14_zstaff(conn):
    """
    Rule 14: Count ZSTAFF BP not in FKKVKP
    Logic: BUT000 + BUT0ID (type='ZSTAFF') + ZISCSALLOW (inactive <> 'X')
    """
    query = """
    SELECT COUNT(DISTINCT b.partner) as bp_count
    FROM but000 b
    INNER JOIN but0id i ON b.partner = i.partner
    INNER JOIN ziscsallow z ON i.idnumber = z.emp_id
    WHERE z.inactive != 'X'
      AND z.parent_id != ' '
      AND i.type = 'ZSTAFF'
    """
    cursor = conn.execute(query)
    result = cursor.fetchone()
    return {"ca": 0, "bp": result[0] if result else 0}

def validate_rule_15_group_bill(conn):
    """
    Rule 15: Count Group Bill Accounts
    Logic: FKKVK.VKTYP = '02'
    """
    query = """
    SELECT COUNT(DISTINCT f.vkont) as ca_count,
           COUNT(DISTINCT f.gpart) as bp_count
    FROM fkkvk v
    INNER JOIN fkkvkp f ON v.vkont = f.vkont
    WHERE v.vktyp = '02'
    """
    cursor = conn.execute(query)
    result = cursor.fetchone()
    return {"ca": result[0] if result else 0, "bp": result[1] if result else 0}

def validate_rule_16_enlight_flagged(conn):
    """
    Rule 16: Count BP/CA flagged for ENLIGHT conversion
    Logic: ZISCSBREMARK.SHORT_TEXT = 'ENLIGHTDATACONVERSION'
           OR ZISCSCAREMARK.SHORT_TEXT = 'ENLIGHTDATACONVERSION'
    """
    query = """
    SELECT COUNT(DISTINCT bp) as bp_count
    FROM ziscsbpremark
    WHERE short_text = 'ENLIGHTDATACONVERSION'
    UNION ALL
    SELECT COUNT(DISTINCT f.gpart)
    FROM ziscscaremark c
    LEFT JOIN fkkvkp f ON c.ca = f.vkont
    WHERE c.short_text = 'ENLIGHTDATACONVERSION'
    """
    cursor = conn.execute(query)
    results = cursor.fetchall()
    bp_count = sum(r[0] for r in results if r[0])
    return {"ca": 0, "bp": bp_count}

def validate_rule_17_per_relationships(conn):
    """
    Rule 17: Count Person-Person relationships
    Logic: BUT050.PARTNER2 NE '' AND RELTYP NE 'ZDUP'
    """
    query = """
    SELECT COUNT(DISTINCT partner2) as bp_count
    FROM but050
    WHERE partner2 IS NOT NULL
      AND TRIM(partner2) != ''
      AND reltyp != 'ZDUP'
    """
    cursor = conn.execute(query)
    result = cursor.fetchone()
    return {"ca": 0, "bp": result[0] if result else 0}

def run_validation(db_path, key_date, months):
    """Run all validation rules and display results"""
    print(f"\n{'='*70}")
    print(f"📊 Account Extraction Validation Report")
    print(f"{'='*70}")
    print(f"Key Date: {key_date}")
    print(f"Lookback Period: {months} months")
    past_date = calculate_past_date(key_date, months)
    print(f"Past Date: {past_date}")
    print(f"Database: {db_path}")
    print(f"{'='*70}\n")

    conn = connect_db(db_path)
    if not conn:
        return

    # Define rules to validate
    rules = [
        ("Rule 1: Active Accounts", validate_rule_1_active_accounts),
        ("Rule 2: Inactive Accounts", validate_rule_2_inactive_accounts),
        ("Rule 3: Write-off/Write-in", validate_rule_3_write_off),
        ("Rule 4: Outstanding Balance", validate_rule_4_outstanding),
        ("Rule 9: Shutdown/Main Charge", validate_rule_9_shutdown),
        ("Rule 13: Account Manager", validate_rule_13_account_manager),
        ("Rule 14: ZSTAFF BP", validate_rule_14_zstaff),
        ("Rule 15: Group Bill", validate_rule_15_group_bill),
        ("Rule 16: ENLIGHT Flagged", validate_rule_16_enlight_flagged),
        ("Rule 17: PER-PER Relations", validate_rule_17_per_relationships),
    ]

    results = []
    for name, func in rules:
        try:
            if "inactive" in name.lower():
                result = func(conn, key_date, past_date)
            else:
                result = func(conn)
            results.append({
                "Rule": name,
                "CA Count": result["ca"],
                "BP Count": result["bp"]
            })
            status = "✅"
        except Exception as e:
            results.append({
                "Rule": name,
                "CA Count": "ERROR",
                "BP Count": str(e)
            })
            status = "❌"

    # Display results
    print(tabulate(results, headers="keys", tablefmt="grid"))
    
    # Summary
    total_ca = sum(r["CA Count"] for r in results if isinstance(r["CA Count"], int))
    total_bp = sum(r["BP Count"] for r in results if isinstance(r["BP Count"], int))
    
    print(f"\n{'='*70}")
    print(f"📈 Summary")
    print(f"{'='*70}")
    print(f"Total CA across all rules: {total_ca}")
    print(f"Total BP across all rules: {total_bp}")
    print(f"{'='*70}\n")

    # Note about deduplication
    print("⚠️  NOTE: These are raw counts per rule.")
    print("   The program deduplicates across ALL rules for final totals.")
    print("   One BP/CA may appear in multiple rules.")
    print(f"{'='*70}\n")

    conn.close()

def main():
    parser = argparse.ArgumentParser(description="Validate ZISCS_MIGRATION_ACCOUNTS extraction")
    parser.add_argument("--db", default=CCMS_DB, help="Path to CCMS database")
    parser.add_argument("--key-date", default=KEY_DATE, help="Key date (YYYYMMDD)")
    parser.add_argument("--months", type=int, default=MONTHS, help="Lookback months")
    
    args = parser.parse_args()
    run_validation(args.db, args.key_date, args.months)

if __name__ == "__main__":
    main()