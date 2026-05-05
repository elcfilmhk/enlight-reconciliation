# ENLIGHT Migration Objects - Validation & Reconciliation

Validation scripts and comparison tools for ENLIGHT migration programs (ZISCS_MIGRATION_*).

## ⚠️ IMPORTANT: Always Use Data Extraction TD

**We compare against Data Extraction TD docs, NOT Transform & Load TD docs.**

| TD Type | Keyword | Purpose |
|---------|---------|---------|
| **Data Extraction** ✅ | `Extract`, `DataExtraction` | Source data extraction rules - **USE THIS** |
| Transform & Load ❌ | `Transform&Load` | Target conversion logic - Reference only |

---

## Purpose
- Validate migration program outputs against **Data Extraction** RTM documentation
- Create ABAP validation reports for SAP SE38
- Compare program results vs validation data
- Identify missing/mismatch CA-BP with root cause diagnosis

## Repository Structure

```
enlight-reconciliation/
├── docs/
│   ├── README.md                # This file
│   ├── PHASE3_PLAN.md            # Phase-by-phase project plan
│   └── ziscs_migration_<obj>_validation_template.md
├── scripts/
│   ├── ziscs_migration_accounts_validation_abap.txt    # ABAP for SE38
│   ├── ziscs_migration_device_validation_abap.txt
│   ├── ziscs_migration_premise_validation_abap.txt
│   ├── ziscs_migration_sp_mock3_validation_abap.txt
│   ├── ziscs_migration_sa_validation_abap.txt
│   ├── compare_accounts.ipynb              # Jupyter for comparison
│   ├── compare_accounts.py                 # CLI comparison tool
│   └── compare_rules_detail.py             # Rule-by-rule detail
└── validation_reports/                     # Generated outputs
```

## Phase Status

| Phase | Objects | Status | RTM Extract Doc |
|-------|---------|--------|----------------|
| 1 | accounts | ✅ Done | TD-Account_DataExtraction (633733126) |
| 2 | device, premise, servicepoint | ✅ Done | TD-Device_DataExtraction, TD-Premise_DataExtraction, TD-ServicePoint_DataExtraction |
| 3 | sa, financial_tran, adjustment, contractoption, payplan | 📋 In Progress | See PHASE3_PLAN.md |
| 4 | eeus, fuel_switching, fit_rate | ⏳ Pending |
| 5 | alipay_wechat, read_object, estimate_read, unmetered_sp | ⏳ Pending |

## All Data Extraction RTM Documents (ENLIGHT)

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