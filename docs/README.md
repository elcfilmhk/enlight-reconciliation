# ENLIGHT Migration Objects - Validation Scripts

Validation scripts for ZISCS_MIGRATION_* programs.

## Execution Phases

### Phase 2 (Asset/Location Hierarchy)
1. device - Device/Meter count (UD1K936264)
2. premise - Premise count (UD1K936264)
3. servicepoint_1 - Service Point count (UD1K936202)

## Available Scripts

| Object | Program UD | ABAP Validation Script |
|--------|------------|-------------------------|
| accounts | UD1K936281 | ziscs_migration_accounts_validation_abap.txt |
| **device** | UD1K936264 | ziscs_migration_device_validation_abap.txt |
| **premise** | UD1K936264 | ziscs_migration_premise_validation_abap.txt |
| **servicepoint_1** | UD1K936202 | ziscs_migration_servicepoint_1_validation_abap.txt |

## Structure

```
enlight-reconciliation/
├── docs/
│   ├── README.md
│   └── ziscs_migration_accounts_validation_template.md
├── scripts/
│   ├── ziscs_migration_accounts_validation_abap.txt
│   ├── ziscs_migration_accounts_validation_queries.txt
│   ├── ziscs_migration_accounts_validation.py
│   ├── ziscs_migration_device_validation_abap.txt       # NEW
│   ├── ziscs_migration_premise_validation_abap.txt     # NEW
│   └── ziscs_migration_servicepoint_1_validation_abap.txt  # NEW
└── .gitignore
```

## Usage

### Run ABAP Validation Report
1. Copy `*_validation_abap.txt` to SAP SE38
2. Create program with matching name (e.g., `Z_DEVICE_VALIDATION`)
3. Activate and execute
4. Compare output with migration program

### Example: Device Validation
```
SE38 → Z_DEVICE_VALIDATION → Execute
Compare: Rule 1 count vs Device program Rule 1 output
```

## Rules Summary

### device (UD1K936264)
- Rule 1: All meters in service (EGERH)
- Rule 2: Inactive meters (SCRA/LOST/LTDA status)

### premise (UD1K936264)
- Rule 1: Active Premise (EVBS)
- Rule 2: Premise with recent changes

### servicepoint_1 (UD1K936202)
- Rule 1: Active Service Point (EANL)
- SP with Device assigned