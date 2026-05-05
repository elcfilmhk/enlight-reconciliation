# ENLIGHT Migration Objects Validation - Project Plan

## Objective
Validate all ENLIGHT migration programs (ZISCS_MIGRATION_*) against **RTM Data Extraction** documentation, create validation ABAP reports, comparison tools, and document the process for future reference.

## ⚠️ IMPORTANT: Always Use Data Extraction TD
**We must ALWAYS compare against Data Extraction TD docs, NOT Transform & Load TD docs.**

| Phase | Objects | Status |
|-------|---------|--------|
| Phase 1 | accounts | ✅ Done |
| Phase 2 | device, premise, servicepoint | ✅ Done |
| **Phase 3** | **sa, financial_tran, adjustment, contractoption, payplan** | 📋 **In Progress** |
| Phase 4 | eeus, fuel_switching, fit_rate |
| Phase 5 | alipay_wechat, read_object, estimate_read, unmetered_sp |

---

## RTM Documentation Reference (Data Extraction)

### Phase 1 & 2 Completed Docs
| Object | Data Extraction TD | Transform & Load TD (Reference Only) |
|--------|---------------------|-------------------------------------|
| accounts | TD-Account_DataExtraction (633733126) | TD-Account_Transform&Load (610566145) |
| device | TD-Device_DataExtraction (635568142) | TD-Device_Transform&Load (624132213) |
| premise | TD-Premise_DataExtraction (633733351) | TD-Premise_Transform&Load (637698049) |
| servicepoint | TD-ServicePoint_DataExtraction (642417966) | TD-ServicePoint_Transform&Load (624132227) |

### Phase 3 Data Extraction Docs
| Object | Data Extraction TD | Page ID |
|--------|-------------------|---------|
| **sa** | TD-SA Deposit-Extract & Cleanse-CUSTOMER-CUST_IT4_CONV_04 | 945258700 |
| **sa** | TD-Service Agreement-Extract & Cleanse-CUSTOMER-CUST_IT2_CONV_03 | 707297676 |
| **financial_tran** | TD-Financial Transaction (FT)-Extract & Cleanse-CUSTOMER-CUST_IT2_CONV_11 | 906821764 |
| **adjustment** | TD-ADJUSTMENT Primary-Extract & Cleanse-CUSTOMER-CUST_IT2_ | 835846145 |
| **contractoption** | TD-Contract Option Type (SSR and C&I)-Extract & Cleanse-CUSTOMER-CUST_IT2_CONV_09 | 778043968 |
| **payplan** | TD-PayPlan-Extract & Cleanse-CUSTOMER-CUST_IT2_CONV_ | 943064714 |

---

## All ENLIGHT Data Extraction Documents

```
TD-Account_DataExtraction&Cleansing-Customer-DM-04
TD-ADJUSTMENT Primary-Extract & Cleanse-CUSTOMER-CUST_IT2_
TD-Billing Data-Bill Segment-Extract & Cleanse-CUSTOMER-CUST_IT2_CONV_05
TD-Billing Data-Bill-Extract & Cleanse-CUSTOMER-CUST_IT2_CONV_04
TD-Contract Option Type (SSR and C&I)-Extract & Cleanse-CUSTOMER-CUST_IT2_CONV_09
TD-Customer Contact-Extract & Cleanse-CUSTOMER-CUST_IT4_CON
TD-Device & Device Config_DataExtraction&Cleansing-Customer-DM-01
TD-Electrical Equipment Upgrade Scheme (EEUS) -Extract & Cleanse-CUSTOMER-CUST_IT2_CONV_
TD-Energy Audit-Extract& Cleanse-CUSTOMER-CUST_DM_CX_01
TD-Financial Transaction (FT)-Extract & Cleanse-CUSTOMER-CUST_IT2_CONV_11
TD-Fuel Switching- Extract& Cleanse-CUSTOMER-CUST-CUST_DM_CX_03
TD-Measuring Component_DataExtraction&Cleansing-Customer-DM-05
TD-Payment Data-Extract & Cleanse-CUSTOMER-CUST_IT2_CONV_06
TD-PayPlan-Extract & Cleanse-CUSTOMER-CUST_IT2_CONV_
TD-Person_DataExtraction&Cleansing-Customer-DM-03
TD-Premise_DataExtraction&Cleansing-Customer-DM-02
TD-Read Data-Extract & Cleanse-CUSTOMER-CUST_IT2_CONV_02
TD-SA Deposit-Extract & Cleanse-CUSTOMER-CUST_IT4_CONV_04
TD-Service Agreement-Extract & Cleanse-CUSTOMER-CUST_IT2_CONV_03
TD-Service Agreement/Service Point-Extract & Cleanse-CUSTOMER-CUST_IT2_CONV_03
TD-Service Point_DataExtraction&Cleansing-Customer-DM-06
TD-Unmetered & Public Lighting-Extract & Cleanse-CUSTOMER-CUST_IT2_CONV_
TD-Write Off-Extract & Cleanse-CUSTOMER-CUST_IT2_CONV_
```

---

## Phase 3: Contract & Financial (📋 In Progress)

### 3.1 Service Agreement (sa)
| Item | Details |
|------|---------|
| Program | `ziscs_migration_sa` / `ziscs_migration_sa_mock3` / `ziscs_migration_sa_mock4` |
| Latest UD | UD1K936697 |
| RTM Doc (Extract) | TD-SA Deposit-Extract & Cleanse (945258700) / TD-Service Agreement-Extract & Cleanse (707297676) |
| RTM Doc (Transform - ref only) | TD-SA Deposit-Transform&Load (958595075) |
| Validation Script | `ziscs_migration_sa_validation_abap.txt` |
| Assigned Agent | main |
| Status | ✅ SA Validation ABAP created (with bugs found) |

### 3.2 Financial Transaction (financial_tran)
| Item | Details |
|------|---------|
| Program | `ziscs_migration_financial_tran` / `ziscs_migration_fin_tran_m3_5` / `ziscs_migration_fin_tran_m4` |
| Latest UD | UD1K936735 (27-Apr-2026) |
| RTM Doc (Extract) | TD-Financial Transaction (FT)-Extract & Cleanse (906821764 / 908820484) |
| Validation Script | `ziscs_migration_fin_tran_validation_abap.txt` |
| Assigned Agent | main |
| Status | ✅ Validation ABAP Created |

**Program Rules (RTM1 + RTM2):**
- **RTM1** (Log#0003 UD1K936735): Non-statistical open items (bltyp<>'2', augst='', xanza<>'X' OR augrs<>'2') PLUS statistical TP items (bltyp='2', blart='TP', hvorg IN ZWOS/ZWOF, tvorg IN 0010/0020). Dedup: opbel+vkont+vtref+opupw+opupk+opupz
- **RTM2** (Log#0001 UD1K936549): Incomplete billing plans (blart='IP', augst='', deadt='00000000'). Same dedup key.

**Key Observations:**
- UD1K936735 adds "Non-Statistical and open items without Deposit/Statistical open TP with write in/off amount"
- UD1K936703 added item fields (opupw/opupk/opupz) to dedup key
- RTM "Exclude statistical FICA" partially implemented (TP statistical items included)
- No 14-month history restriction (matches RTM scope)
- Selection on `augbd` (clearing date), not `budat` (posting date)

### 3.3 Adjustment
| Item | Details |
|------|---------|
| Program | `ziscs_migration_adjustment` / `ziscs_migration_adjustment_m3` / `ziscs_migration_adjustment_m4` |
| Latest UD | **UD1K936545** (09.03.2026) - M3.5 logic update |
| RTM Doc (Extract) | TD-ADJUSTMENT Primary-Extract & Cleanse (835846145) |
| Validation Script | `ziscs_migration_adjustment_validation_abap.txt` |
| Assigned Agent | work |
| Status | ✅ Validation ABAP created |

### 3.4 Contract Option
| Item | Details |
|------|---------|
| Program | `ziscs_migration_contractoption` |
| Latest UD | None on file (initial v1, 12.09.2025) |
| RTM Doc (Extract) | TD-Contract Option Type (SSR and C&I)-Extract & Cleanse (778043968) |
| Validation Script | `ziscs_migration_contractoption_validation_abap.txt` |
| Assigned Agent | jbot3 |
| Status | ✅ Validation ABAP created (9 rules: C&I RTM 1-4, SSR RTM 1/2A/2B/3/4) |

### 3.5 Payment Plan (payplan)
| Item | Details |
|------|---------|
| Program | `ziscs_migration_payplan` / `ziscs_migration_payplan_mock3` / `ziscs_migration_payplan_mock4` |
| Latest UD | TBC |
| RTM Doc (Extract) | TD-PayPlan-Extract & Cleanse (943064714) |
| Validation Script | TBD |
| Assigned Agent | jbot4 |
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

### Step 2: Find Data Extraction RTM Documentation
```sql
-- Query docs_master.db
SELECT title, url FROM documents 
WHERE url LIKE '%ENLIGHT%' 
  AND title LIKE '%TD-<Object>%' 
  AND title LIKE '%Extract%';
```

### Step 3: Analyze Program Logic
Review the ABAP program and identify:
- Rule numbers and descriptions
- Source tables
- Filter conditions (status, date, etc.)
- CSV output format

### Step 4: Create Validation ABAP Report
Create `ziscs_migration_<object>_validation_abap.txt`:
- Parameter: p_keydat (key date), p_month (lookback period)
- Rule-by-rule counts matching program logic
- Output: Per-rule counts and summary

### Step 5: Compare Against Data Extraction TD
- Check program rules vs RTM extraction requirements
- Flag any gaps or misalignments
- Document findings

### Step 6: Create Comparison Tool
Create Python script/notebook:
- Load program CSV export
- Compare against validation
- Identify missing/extra items
- Diagnose root cause (program vs validation issue)

### Step 7: Document Changes
Update this file with:
- Program UD used
- RTM Extract doc reference
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
| jbot4 | RTM docs comparison | Data Extraction comparison |

---

## Deliverables Per Object

1. **Validation ABAP Report** (`ziscs_migration_<obj>_validation_abap.txt`)
   - SE38 compatible
   - Rule-by-rule counts
   - Parameter support (key date, lookback)

2. **RTM Comparison Report** (Data Extraction)
   - Check program logic vs Data Extraction TD requirements
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
│   ├── abap/                     # ABAP reports for SE38
│   ├── python/                    # Comparison tools
│   ├── compare_<obj>.py          # CLI comparison
│   └── compare_<obj>.ipynb       # Jupyter notebook
└── validation_reports/          # Generated comparison outputs
```

---

## Current Status

### Completed Objects
| Object | Program UD | Validation | RTM Extract Match | Notes |
|--------|-----------|------------|-------------------|-------|
| accounts | UD1K936281 | ✅ | ✅ | Uses Data Extraction TD |
| device | UD1K936264 | ✅ | ✅ | Uses Data Extraction TD |
| premise | UD1K936264 | ✅ | ✅ | Uses Data Extraction TD |
| servicepoint | UD1K936723 | ✅ | ⏳ | Using sp_mock3 variant |

### Phase 3 In Progress

| Object | Program Found | RTM Extract Doc | Validation | Status |
|--------|--------------|-----------------|------------|--------|
| sa | ✅ UD1K936697 | ✅ 945258700 / 707297676 | ✅ Created | Issues found (bugs) |
| financial_tran | ✅ UD1K936735 | ✅ 906821764/908820484 | ✅ Created | ✅ Done |
| adjustment | ✅ UD1K936545 | ✅ Created | ⏳ | Pending |
| contractoption | ✅ initial v1 | ✅ 778043968 | ✅ Created | ⏳ RTM comparison pending |
| payplan | ✅ | ✅ 943064714 | ⏳ | Pending |

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

## RTM Document Naming Convention

| Type | Keyword | Example |
|------|---------|---------|
| **Data Extraction** | `Extract` / `DataExtraction` | TD-Account_DataExtraction&Cleansing |
| **Transform & Load** | `Transform&Load` | TD-Account_Transform&Load-DM-CONV-04 |

**Always use Data Extraction TD for validation!** Transform & Load TD is for reference only.

---

*Last Updated: 2026-05-05*
*Maintained by: JBot Main Agent*
*Repo: https://github.com/elcfilmhk/enlight-reconciliation*