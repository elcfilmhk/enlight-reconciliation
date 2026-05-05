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
| **Phase 4** | **fuel_switching**, eeus, fit_rate | 📋 **In Progress** |
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
| Latest UD | UD1K936403 (Mock4, 13.11.2025) |
| RTM Doc (Extract) | TD-PayPlan-Extract & Cleanse (943064714) |
| Validation Script | `ziscs_migration_payplan_validation_abap.txt` |
| Assigned Agent | jbot4 |
| Status | ✅ Validation ABAP created |

---

## Phase 5: Alipay/WeChat Payment

### 5.3 Alipay/WeChat Payment
| Item | Details |
------|---------|
| Program | `ziscs_migration_alipay_wechat` |
| Latest UD | **UD1K936507** (18-Feb-2026) |
| Transport | UD1K936507 |
| Author | Tanya Bisht |
| RTM Doc (Extract) | TD-OIC-RealTime Payment Integration Alipay (741507092) / TD-OIC-RealTime Payment Integration WeChat (741572610) |
| RTM Doc (Ref) | TD CCS Payment Reconciliation Alipay INT368.3 (630292568), TD CCS Payment Reconciliation WeChat INT105.13.2 (631603202) |
| Validation Script | `ziscs_migration_alipay_wechat_validation_abap.txt` |
| Assigned Agent | subagent |
| Status | ✅ Validation ABAP created, bugs found |

**Program Rules:**
- **RTM 1 (Active Subscription)**: `zzstatus_sid = 'A'` AND `ever~auszdat >= fromdate` (contract end within lookback). Dedup: distinct zzsubid + vkont.
- **RTM 2 (Inactive Subscription)**: `zzstatus_sid = 'I'` AND `zzchange_date >= fromdate` AND `ever~auszdat >= fromdate`. Dedup: distinct zzsubid + vkont.

**Key Observations:**
- Source table: `ZISCS_PAYCHANSID` (zisfipaychansid) — subscription/channel mapping for Alipay and WeChat
- Uses LEFT JOIN to `ever` for contract end date (`auszdat`) filtering
- Selection screen: offic_ex, vkont, zzsubid, zzopenid, zzstatus_sid
- Program logic simple — only RTM 1 and RTM 2, no additional rules

**BUGS FOUND:**
1. **LEFT JOIN converted to INNER JOIN**: Both RTM queries use `LEFT JOIN ever ... WHERE b~auszdat >= @gv_fromdate`. In LEFT JOIN, WHERE conditions on the right table convert it to INNER JOIN semantics. Records in zisfipaychansid with no matching ever record will be excluded from counts. **FIX**: Add `AND b~vkonto IS NOT NULL` before the date filter, or change to `INNER JOIN`.
2. **s_status selection redundant in RTM1**: RTM1 hardcodes `zzstatus_sid = 'A'` but still applies `s_status` selection. This has no effect since hardcoded condition overrides selection, but it's confusing and should be cleaned up.
3. **Path separator inconsistency in export_csv**: Line 103 uses forward slash `/` but line 110 uses escaped backslash `\`. On Unix/Linux this causes path failures. **FIX**: Always use `/` or detect OS with `cl_gui_frontend_services=>get_os_version`.

**RTM Alignment:**
- TD-OIC-RealTime Payment Integration Alipay (741507092) defines account subscription flow
- TD-OIC-RealTime Payment Integration WeChat (741572610) defines WeChat equivalent
- TD CCS Payment Reconciliation docs (630292568, 631603202) cover batch posting and reconciliation
- Program covers RTM 1 (active) and RTM 2 (inactive) subscriptions correctly, but LEFT JOIN bug may cause undercount

---

## Phase 5: Estimate Read & Read Object (📋 In Progress)

### 5.1 Estimate Read
| Item | Details |
|------|---------|
| Program | `ziscs_migration_estimate_read` |
| Latest UD | UD1K936281 (11.11.2025) |
| RTM Doc (Extract) | TD-Read Data-Extract & Cleanse (682263269) |
| Validation Script | `ziscs_migration_estimate_read_validation_abap.txt` |
| Assigned Agent | subagent |
| Status | ✅ Validation ABAP created |

**Program Rules:**
- **Rule 1**: Estimate reading documents - count ABLBELNR from EABL where ADAT >= pastdate AND NOT EXISTS (same EQUNR with ADAT >= pastdate AND ISTABLART <> '03')
- **Rule 2**: Estimate equipments - distinct EQUNR from Rule 1 results

**Key Observations:**
- Simple two-rule structure (no complex JOINs)
- Only one table (EABL), no joins
- UD1K935965 added p_keydat parameter (key date input)
- UD1K936281 added p_month parameter (configurable lookback, default 14)
- Exclusion: skip EQUNR if any actual reading (ISTABLART <> '03') exists in window
- No CSV/file output - only WRITE to screen
- **No bugs found** - logic is straightforward

**RTM Alignment:**
- TD-Read Data-Extract & Cleanse (682263269) defines extraction rules
- estimate_read variant filters to only "estimate" readings
- ISTABLART '03' = Actual reading, <> '03' = Estimate reading
- Correctly excludes EQUNR with at least one actual reading in lookback window

---

### 5.2 Read Object (Meter Reads)
| Item | Details |
|------|---------|
| Program | `ziscs_migration_read_object` |
| Latest UD | UD1K936411 (12.12.2025) |
| RTM Doc (Extract) | TD-Read Data-Extract & Cleanse (682263269) |
| Validation Script | `ziscs_migration_read_object_validation_abap.txt` |
| Assigned Agent | subagent |
| Status | ✅ Validation ABAP created, bugs found |

**Program Rules:**
- **MRO-1 (MRO Received)**: EABL where `ableser NE '000'`, `ablstat NE 0`, `adat` in range → distinct EQUNR
- **MRO-2 (MRO Not Received)**: Input devices NOT in MRO-1 (input-dependent)
- **MRO-3 (Estimate Read)**: EABL where `istablart = '03' OR 'AE'` with MRO-1 filters
- **MRO-4 (MRO Document Count)**: COUNT of all EABL records (not distinct)
- **DAYEND-1**: ETDZ+EPROFASS+EPROFVALMONTH, `bis='99991231'`, `valueday` in range, any val>=0
- **INTERVAL-1**: ETDZ+EPROFASS+EPROFVAL30, `bis='99991231'`, `valueday` in range, any val>=0

**Key Observations:**
- Three radio-button modes: MRO (READ_MRO), Day End (READ_DAYEND), Interval (READ_INTERVAL)
- UD1K936411 (Log#0005): Added `ableser NE '000'` check
- UD1K936382 (Log#0004): Added `ablstat NE 0` check
- All modes use `p_keydat` (low/high) date range parameter
- Uses batch processing (500k records per batch)

**BUGS FOUND:**
1. **READ_INTERVAL**: `gs_file`/`gt_equi_*` inserts are INSIDE the `DO 48 TIMES` loop → duplicate inserts per device per non-zero interval. Since target is SORTED TABLE WITH UNIQUE KEY, duplicates silently ignored but causes performance degradation.
2. **READ_DAYEND**: Same pattern — inserts inside `DO 31 TIMES` loop.
3. **Fix needed**: Move all table inserts OUTSIDE the DO loops, guarded by the `lv_dayendprofile`/`lv_intervalprofile` flag.

**RTM Alignment:**
- TD-Read Data-Extract & Cleanse (682263269) — same TD as estimate_read
- Program aligns with extraction rules for meter reading objects

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

| Agent | Phase 3 Objects | Phase 4 Objects | Responsibility |
|-------|-----------------|-----------------|----------------|
| main | sa, financial_tran | **fuel_switching** | Program analysis, validation creation |
| work | adjustment, payplan | eeus | Program analysis, validation creation |
| jbot3 | contractoption | fit_rate | Program analysis, validation creation |
| jbot4 | RTM docs comparison | — | Data Extraction comparison |

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
| payplan | ✅ UD1K936403 | ✅ Created | ✅ RTM 943064714 | Mock4, Log#0001 adds RTM3/RTM5, blart<>IP filter |

### Phase 4 In Progress

| Object | Program Found | RTM Extract Doc | Validation | Status |
|--------|--------------|-----------------|------------|--------|
| fuel_switching | ✅ UD1K936725 | ✅ 879362238 | ✅ Created | ✅ Validation ABAP created |
| eeus | ⏳ | ⏳ | ⏳ | Pending |
| fit_rate | ⏳ | ⏳ | ⏳ | Pending |

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

### Phase 4: EEUS, Fuel Switching, Fit Rate (📋 In Progress)

#### 4.1 Electrical Equipment Upgrade Scheme (EEUS)
| Item | Details |
|------|---------|
| Program | `ziscs_migration_eeus` |
| Latest UD | UD1K936581 |
| RTM Doc (Extract) | TD-Electrical Equipment Upgrade Scheme (EEUS)-Extract & Cleanse (page 1307869185) |
| Validation Script | `ziscs_migration_eeus_validation_abap.txt` |
| Assigned Agent | subagent |
| Status | ✅ Validation ABAP created |

**Program Rules (UD1K936581 - Initial Implementation):**
- **RTM1**: All records from `ziscs_eeus_hdr` where status IN ('CO', 'CA', '17')
- Count by status: CO (Completed), CA (Cancelled), 17 (Rebate Approved)
- Dedup key: eeus_appln + vkont (adjacent duplicates)
- rtm_no hardcoded to 'RTM1'

**Key Observations:**
- Only one UD (initial implementation, 05.03.2026)
- No configurable lookback period
- Single rule only (RTM1 status counts)
- No additional RTM rules implemented
- Program has not been updated since initial release

---

#### 4.2 Fit Rate (fit_rate)
| Item | Details |
|------|---------|
| Program | `ziscs_migration_fit_rate` |
| Latest UD | UD1K936725 |
| RTM Doc (Extract) | Not found under standard TD-* naming in docs_master.db |
| Validation Script | `ziscs_migration_fit_rate_validation_abap.txt` |
| Assigned Agent | subagent |
| Status | ✅ Validation ABAP created |

**Program Rules (UD1K936501/505/530/725):**
- **Rule 1**: Completed FIT Applications (re_app_status = 'CO' OR '23')
  - Source: `zis_eec_reappln` LEFT JOIN `zis_eec_resysmtr` on re_app_no
  - Filtered by premise list from file or S_PREMI selection (gt_stg hash table)
  - Dedup: re_app_no
- **Rule 2**: Cancelled FIT Applications (re_app_status = 'CA', app_rec_date >= pastdate)
  - Same source tables as Rule 1
  - Filter: app_rec_date >= keydate - p_month months
  - Dedup: re_app_no

**Key Observations:**
- 4 UDs: UD1K936501 (perf fix), UD1K936505 (date fix), UD1K936530 (file fix), UD1K936725 (csv separator ;)
- Simpler program than SA migration - only 2 rules, no Rule 3/4
- gt_stg is HASHED TABLE for O(1) premise lookup performance
- Performance fix (Log#0001) removed FOR ALL ENTRIES, uses READ TABLE gt_stg instead
- p_month lookback applies ONLY to cancelled applications (Rule 2)
- Completed applications (Rule 1) have NO date restriction

**Bugs Found:**
1. `lt_chunk` is declared but never populated - get_fit_rate references lt_chunk-premise in commented WHERE clause
2. Both Rule1 and Rule2 file processing merge into same gt_premise_rule1 (no separate tracking)
3. write_csv uses backslash path separator `p_file\{lv_filename}` which may not work on Unix systems

**RTM Documentation Gap:**
- No Data Extraction TD found in docs_master.db for fit_rate
- Related docs exist in CXTTS1/CI spaces under "Renewable Energy (FiT)" branding
- Program uses zis_eec_reappln + zis_eec_resysmtr tables

---

### Phase 5b: Unmetered Service Point
| Item | Details |
|------|---------|
| Program | `ziscs_migration_unmetered_sp` |
| Latest UD | UD1K936493 |
| RTM Doc (Extract) | TD-Unmetered & Public Lighting-Extract & Cleanse (1253769226) |
| Validation Script | `ziscs_migration_unmetered_sp_validation_abap.txt` |
| Assigned Agent | subagent |
| Status | ✅ Validation ABAP created |

**Program Rules:**
- **Rule 1**: Unmetered SP selection (ever + eanlh inner join, ableinh='UNMETER', ettifb EXISTS with operand<>space)

**Key Observations:**
- p_month parameter is defined but NEVER USED - program hard-codes p_month = 24
- gv_key_date = keydt - 24 months, gv_moveout = auszdt - 24 months
- Dedup: vkonto + anlage (adjacent duplicates)
- ettifb check: bis >= gv_key_date AND operand <> space

---

*Last Updated: 2026-05-06*
*Maintained by: JBot Main Agent*
*Repo: https://github.com/elcfilmhk/enlight-reconciliation*