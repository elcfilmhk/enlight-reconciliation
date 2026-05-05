# ZISCS_MIGRATION_ACCOUNTS_MC4A Validation

Validation scripts for ENLIGHT migration account extraction program.

## Program Info

| Field | Value |
|-------|-------|
| Program | ZISCS_MIGRATION_ACCOUNTS_MC4A |
| Latest UD | UD1K936711 (Apr 21, 2026) |
| Author | AP88981 / TB88379 |
| RTM Doc | TD-Account_Transform&Load-DM-CONV-04 |

## Structure

```
ZISCS_MIGRATION_ACCOUNTS_MC4A/
├── docs/
│   ├── README.md                                           (this file)
│   └── ziscs_migration_accounts_validation_template.md
├── scripts/
│   ├── ziscs_migration_accounts_validation_abap.txt       # ABAP for SE38
│   ├── ziscs_migration_accounts_validation_queries.txt    # SQL reference
│   └── ziscs_migration_accounts_validation.py              # Python script
└── .gitignore
```

## Rules Validated

| Rule | Description | Source Table |
|------|-------------|--------------|
| 1 | Active Accounts | EVER |
| 2 | Inactive (move-out) | EVER |
| 3 | Write-off/Write-in | DFKKOP |
| 4 | Outstanding Balance | DFKKOP |
| 9 | Shutdown/Main Charge | DFKKOP |
| 13 | Account Manager | FKKVKP |
| 14 | ZSTAFF BP | BUT000+BUT0ID+ZISCSALLOW |
| 15 | Group Bill | FKKVK |
| 16 | ENLIGHT Flagged | ZISCSBREMARK+ZISCSCAREMARK |
| 17 | PER-PER Relations | BUT050 |

## Usage

### Option 1: ABAP Report (Recommended)
1. Copy `ziscs_migration_accounts_validation_abap.txt` to SAP SE38
2. Create program `Z_VALIDATION_ACCOUNTS`
3. Activate and execute
4. Compare output with MC4A program

### Option 2: SQL Queries
1. Copy queries from `ziscs_migration_accounts_validation_queries.txt`
2. Run in SAP transaction (requires InfoSet for joins)
3. Compare results

### Option 3: Python Script
```bash
python3 ziscs_migration_accounts_validation.py --key-date 20251027 --months 24
```

## Notes

- Rule 4: `augrs NE '2'` filter removed in MC4A (Log#0015)
- Rule 15: Group Bill uses `FKKVK.VKTYP = '02'`
- Rule 17: PER-PER uses `BUT050.RELTYP NE 'ZDUP'`