# ENLIGHT Migration Objects Validation - Project Plan

## Objective
Validate all ENLIGHT migration programs (ZISCS_MIGRATION_*) against RTM documentation, create validation ABAP reports, comparison tools, and document the process for future reference.

## Scope
All ZISCS_MIGRATION_* programs in `/home/vboxuser/CCMS/`

---

## Phases Overview

| Phase | Objects | Status |
|-------|---------|--------|
| Phase 1 | accounts | ✅ Done |
| Phase 2 | device, premise, servicepoint | ✅ Done |
| **Phase 3** | **sa, financial_tran, adjustment, contractoption, payplan** | 📋 **In Progress** |
| Phase 4 | eeus, fuel_switching, fit_rate |
| Phase 5 | alipay_wechat, read_object, estimate_read, unmetered_sp |

---

## Phase 1: Accounts (✅ Complete)
- Program: `ziscs_migration_accounts_mc4a` (UD1K936711)
- Validation: `ziscs_migration_accounts_validation_abap.txt`
- RTM Doc: TD-Account_Transform&Load-DM-CONV-04 (Page 610566145)

## Phase 2: Asset/Location Hierarchy (✅ Complete)
| Object | Program UD | Validation Script | RTM Doc |
|--------|-----------|-------------------|---------|
| device | UD1K936264 | ziscs_migration_device_validation_abap.txt | TD-Device_Transform&Load-DM-CONV-01 (624132213) |
| premise | UD1K936264 | ziscs_migration_premise_validation_abap.txt | TD-Premise_Transform&Load-DM-CONV-02 (637698049) |
| servicepoint | UD1K936723 (sp_mock3) | ziscs_migration_sp_mock3_validation_abap.txt | TD-ServicePoint_Transform&Load-DM-CONV-06 (624132227) |

---

## Phase 3: Contract & Financial (📋 In Progress)

### 3.1 Service Agreement (sa)
| Item | Details |
|------|---------|
| Program | `ziscs_migration_sa` / `ziscs_migration_sa_mock3` / `ziscs_migration_sa_mock4` |
| Latest UD | UD1K936190 |
| RTM Doc | TD-SA_Transform&Load-DM-CONV-03 (need to find) |
| Validation Script | TBD |
| Assigned Agent | main |
| Status | 🔄 Reviewing program logic |

### 3.2 Financial Transaction (financial_tran)
| Item | Details |
|------|---------|
| Program | `ziscs_migration_financial_tran` / `ziscs_migration_fin_tran_m3_5` / `ziscs_migration_fin_tran_m4` |
| Latest UD | UD1K936xxx |
| RTM Doc | TD-FinTran_Transform&Load-DM-CONV (need to find) |
| Validation Script | TBD |
| Assigned Agent | work |
| Status | ⏳ Pending |

### 3.3 Adjustment
| Item | Details |
|------|---------|
| Program | `ziscs_migration_adjustment` / `ziscs_migration_adjustment_m3` / `ziscs_migration_adjustment_m4` |
| Latest UD | UD1K936178 |
| RTM Doc | TD-Adjustment_Transform&Load-DM-CONV (need to find) |
| Validation Script | TBD |
| Assigned Agent | jbot3 |
| Status | ⏳ Pending |

### 3.4 Contract Option
| Item | Details |
|------|---------|
| Program | `ziscs_migration_contractoption` |
| Latest UD | — |
| RTM Doc | TD-ContractOption_Transform&Load-DM-CONV (need to find) |
| Validation Script | TBD |
| Assigned Agent | jbot4 |
| Status | ⏳ Pending |

### 3.5 Payment Plan (payplan)
| Item | Details |
|------|---------|
| Program | `ziscs_migration_payplan` / `ziscs_migration_payplan_mock3` / `ziscs_migration_payplan_mock4` |
| Latest UD | — |
| RTM Doc | TD-PayPlan_Transform&Load-DM-CONV (need to find) |
| Validation Script | TBD |
| Assigned Agent | work |
| Status | ⏳ Pending |

---

## Step-by-Step Process for Each Object

### Step 1: Find Latest Program Version
```bash
# List all variants for an object
ls /home/vboxuser/CCMS/ziscs_migration_<object>*/

# Get UD numbers
grep -oE "UD1K[0-9]+" /home/vboxuser/CCMS/ziscs_migration_<object>/*.txt | sort -u
```

### Step 2: Find RTM Documentation
```sql
-- Query docs_master.db
SELECT title, url FROM documents 
WHERE url LIKE '%ENLIGHT%' 
  AND title LIKE '%TD-<Object>%' 
  AND title LIKE '%Transform%Load%';
```

### Step 3: Analyze Program Logic
Review the ABAP program and identify:
- Rule numbers and descriptions
- Source tables (EVER, FKKVKP, DFKKOP, etc.)
- Filter conditions (status, date, etc.)
- CSV output format

### Step 4: Create Validation ABAP Report
Create `ziscs_migration_<object>_validation_abap.txt`:
- Parameter: p_keydat (key date), p_month (lookback period)
- Rule-by-rule counts matching program logic
- Output: Per-rule counts and summary

### Step 5: Create RTM Comparison Report
Create report to compare:
- Program counts vs RTM requirements
- Flag any gaps or misalignments
- Document findings

### Step 6: Create Comparison Tool
Create Python script/notebook:
- Load program CSV export
- Load validation data
- Compare rule-by-rule
- Identify missing/extra CA-BP
- Diagnose root cause (program vs validation issue)

### Step 7: Document Changes
Update this file with:
- Program UD used
- RTM doc reference
- Validation script location
- Agent assigned
- Status
- Any gaps found

---

## Agent Assignment

| Agent | Phase 3 Objects | Responsibility |
|-------|-----------------|----------------|
| main | sa, financial_tran | Program analysis, validation creation |
| work | adjustment, payplan | Program analysis, validation creation |
| jbot3 | contractoption | Program analysis, validation creation |
| jbot4 | documentation | RTM comparison, gap analysis |

---

## Deliverables Per Object

1. **Validation ABAP Report** (`ziscs_migration_<obj>_validation_abap.txt`)
   - SE38 compatible
   - Rule-by-rule counts
   - Parameter support (key date, lookback)

2. **RTM Comparison Report**
   - Check program logic vs RTM requirements
   - Flag gaps
   - Document alignment status

3. **Comparison Tool** (`compare_<obj>.py` or `.ipynb`)
   - Parse program CSV output
   - Compare against validation
   - Identify missing/extra items
   - Diagnose root cause

4. **Documentation**
   - Update this file with findings
   - Save to GitHub repo

---

## GitHub Repository
https://github.com/elcfilmhk/enlight-reconciliation

Structure:
```
enlight-reconciliation/
├── docs/
│   ├── README.md
│   ├── PHASE3_PLAN.md           # This file
│   └── ziscs_migration_<obj>_validation_template.md
├── scripts/
│   ├── abap/                   # ABAP reports for SE38
│   ├── python/                 # Comparison tools
│   ├── compare_<obj>.py        # CLI comparison
│   └── compare_<obj>.ipynb     # Jupyter notebook
└── validation_reports/         # Generated comparison outputs
```

---

## Current Status

### Completed Objects
| Object | Program UD | Validation | RTM Match | Notes |
|--------|-----------|------------|-----------|-------|
| accounts | UD1K936711 | ✅ | ✅ | 82% RTM coverage |
| device | UD1K936264 | ✅ | ✅ | AMI as device, config separate |
| premise | UD1K936264 | ✅ | ✅ | 2yr lookback aligned |
| servicepoint | UD1K936723 | ✅ | ⏳ | Using sp_mock3 variant |

### Phase 3 In Progress

| Object | Program Found | RTM Doc Found | Validation | Status |
|--------|--------------|--------------|------------|--------|
| sa | ✅ | ⏳ | ⏳ | Reviewing |
| financial_tran | ✅ | ⏳ | ⏳ | Pending |
| adjustment | ✅ | ⏳ | ⏳ | Pending |
| contractoption | ⏳ | ⏳ | ⏳ | Pending |
| payplan | ✅ | ⏳ | ⏳ | Pending |

---

## Next Steps

### For Phase 3 - Immediate Actions

1. **SA (main)**
   - [ ] Review `ziscs_migration_sa_mock4` (latest variant)
   - [ ] Find RTM doc for SA
   - [ ] Create validation script

2. **Financial Tran (main)**
   - [ ] Review `ziscs_migration_fin_tran_m4` (latest variant)
   - [ ] Find RTM doc
   - [ ] Create validation script

3. **Adjustment (work)**
   - [ ] Review `ziscs_migration_adjustment_m4`
   - [ ] Find RTM doc
   - [ ] Create validation script

4. **Contract Option (jbot3)**
   - [ ] Check if program exists
   - [ ] Find RTM doc
   - [ ] Create validation script

5. **Payplan (jbot4)**
   - [ ] Review `ziscs_migration_payplan_mock4`
   - [ ] Find RTM doc
   - [ ] Create validation script

---

## How to Update When Logic Changes

When any migration program logic changes:

1. **Identify the change**
   - Get new UD number
   - Note what rules changed

2. **Update validation**
   - Modify ABAP validation report
   - Update comparison tool

3. **Re-run comparison**
   - Export new program CSV
   - Run comparison tool
   - Verify counts match

4. **Document in this file**
   - Update UD number
   - Note change in logic
   - Record date of change

5. **Commit to Git**
   ```bash
   cd /home/vboxuser/Desktop/diary/enlight-reconciliation
   git add -A
   git commit -m "Updated <object> validation - UD1K936xxx"
   git push origin main
   ```

---

*Last Updated: 2026-05-05*
*Maintained by: JBot Main Agent*
*Repo: https://github.com/elcfilmhk/enlight-reconciliation*