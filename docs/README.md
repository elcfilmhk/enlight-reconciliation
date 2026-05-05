# ENLIGHT Migration Objects - Validation & Reconciliation

Validation scripts and comparison tools for ENLIGHT migration programs (ZISCS_MIGRATION_*).

## Purpose
- Validate migration program outputs against RTM documentation
- Create ABAP validation reports for SAP SE38
- Compare program results vs validation data
- Identify missing/mismatch CA-BP with root cause diagnosis

## Repository Structure

```
enlight-reconciliation/
├── docs/
│   ├── README.md              # This file
│   ├── PHASE3_PLAN.md         # Phase-by-phase project plan
│   └── ziscs_migration_<obj>_validation_template.md
├── scripts/
│   ├── ziscs_migration_accounts_validation_abap.txt    # ABAP for SE38
│   ├── ziscs_migration_device_validation_abap.txt
│   ├── ziscs_migration_premise_validation_abap.txt
│   ├── ziscs_migration_sp_mock3_validation_abap.txt
│   ├── compare_accounts.ipynb          # Jupyter for comparison
│   ├── compare_accounts.py              # CLI comparison tool
│   └── compare_rules_detail.py          # Rule-by-rule detail
└── validation_reports/                  # Generated outputs
```

## Phase Status

| Phase | Objects | Status | Notes |
|-------|---------|--------|-------|
| 1 | accounts | ✅ Done | UD1K936711, 82% RTM coverage |
| 2 | device, premise, servicepoint | ✅ Done | UD1K936264/UD1K936723 |
| 3 | sa, financial_tran, adjustment, contractoption, payplan | 📋 In Progress | Assigned to main, work, jbot3, jbot4 |
| 4 | eeus, fuel_switching, fit_rate | ⏳ Pending |
| 5 | alipay_wechat, read_object, estimate_read, unmetered_sp | ⏳ Pending |

## How to Use

### 1. Run Validation in SAP (SE38)
1. Copy `*_validation_abap.txt` to SAP SE38
2. Create program with matching name (e.g., `Z_ACCOUNT_VALIDATION`)
3. Activate and execute
4. Compare output with migration program counts

### 2. Compare Program vs Validation
1. Export program CSV output
2. Run comparison script:
```bash
python compare_rules_detail.py program.csv --rule 1
python compare_accounts.py program.csv --check 1234567890
```
3. Or use Jupyter notebook for interactive analysis

### 3. Find Missing CA/BP
```bash
python compare_rules_detail.py program.csv --check <CA_NUMBER>
```
Output shows:
- Which rule the CA belongs to (or "NOT FOUND")
- If missing, indicates COUNTING_PROGRAM vs VALIDATION_PROBLEM

## Documentation

- [PHASE3_PLAN.md](docs/PHASE3_PLAN.md) - Detailed project plan with agent assignments
- [Comparison Guide](scripts/compare_accounts.ipynb) - Jupyter notebook for rule-by-rule comparison

## Agent Assignments

| Agent | Objects | Phase |
|-------|---------|-------|
| main | sa, financial_tran | 3 |
| work | adjustment, payplan | 3 |
| jbot3 | contractoption | 3 |
| jbot4 | RTM docs comparison | 3 |

## Update Procedure

When program logic changes:
1. Get new UD number
2. Update validation ABAP report
3. Re-run comparison tool
4. Document changes in PHASE3_PLAN.md
5. Commit to GitHub

## Links

- **Repo:** https://github.com/elcfilmhk/enlight-reconciliation
- **RTM Docs:** docs_master.db (Confluence ENLIGHT space)
- **CCMS Source:** /home/vboxuser/CCMS/ziscs_migration_*/

---

*Last Updated: 2026-05-05*