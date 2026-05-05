# ENLIGHT Reconciliation

Validation scripts for ZISCS_MIGRATION_ACCOUNTS MC4A (UD1K936711) account extraction program.

## Purpose

Cross-validate the ENLIGHT migration account extraction logic against source table data.

## Scripts

### ABAP Validation Report
**File:** `scripts/abap/Z_ACCOUNT_VALIDATION.txt`

SAP SE38 report to validate extraction rules against source tables:
- Rule 1: Active Accounts
- Rule 2: Inactive Accounts
- Rule 3: Write-off/Write-in
- Rule 4: Outstanding Balance
- Rule 9: Shutdown/Main Charge
- Rule 13: Account Manager
- Rule 14: ZSTAFF BP
- Rule 15: Group Bill
- Rule 16: ENLIGHT Flagged
- Rule 17: PER-PER Relationships

### SQL Reference
**File:** `scripts/validate_account_queries.txt`

SAP SQL queries for manual cross-check (SE16N/SQ01).

### Python Validation
**File:** `scripts/python/validate_account_extraction.py`

Python script for database validation (requires CCMS .db file).

## Usage

1. **Option A:** Deploy `Z_ACCOUNT_VALIDATION.txt` in SAP SE38
2. **Option B:** Run SQL queries manually in SAP
3. **Option C:** Use Python script if database file available

## Version Info

- Program: `ZISCS_MIGRATION_ACCOUNTS_MC4A`
- Latest UD: `UD1K936711` (Apr 21, 2026)
- Author: AP88981 / TB88379

## Related Docs

- RTM: `TD-Account_Transform&Load-DM-CONV-04`
- Source: CCMS / SAP