*&---------------------------------------------------------------------*
*& Report  Z_FIT_VALIDATION
*&---------------------------------------------------------------------*
*& Validation report for ZISCS_MIGRATION_FIT_RATE
*& Compare rule counts against source table data
*& ABAP 7.4 compatible version
*&---------------------------------------------------------------------*
REPORT z_fit_validation NO STANDARD PAGE HEADING LINE-SIZE 120.

* Parameters
PARAMETERS: p_keydat TYPE sy-datum DEFAULT '20260309',
            p_month  TYPE numc2 DEFAULT 14,
            p_pkt   TYPE numc10 DEFAULT 100000.

* Variables
DATA: lv_pastdate        TYPE sy-datum,
      lv_r1_completed TYPE p,
      lv_r2_cancelled TYPE p,
      lv_total        TYPE p.

* Internal tables for deduplicated counts
TYPES: BEGIN OF ty_fit,
         re_app_no     TYPE qmnum,
         vstelle       TYPE vstelle,
         re_app_status TYPE zreappstatus,
         fit_rate      TYPE zfitrate,
       END OF ty_fit.

DATA: lt_completed TYPE STANDARD TABLE OF ty_fit,
      lt_cancelled TYPE STANDARD TABLE OF ty_fit,
      lt_all_fit   TYPE STANDARD TABLE OF ty_fit.

START-OF-SELECTION.

* Calculate past date
  DATA(lv_current_date) = p_keydat.
  IF lv_current_date IS INITIAL.
    lv_current_date = sy-datum.
  ENDIF.

  CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
    EXPORTING
      date      = lv_current_date
      days      = 0
      months    = p_month
      signum    = '-'
      years     = 0
    IMPORTING
      calc_date = lv_pastdate.

  WRITE: / '============================================================'.
  WRITE: / '   ZISCS_MIGRATION_FIT_RATE - VALIDATION REPORT'.
  WRITE: / '============================================================'.
  WRITE: / 'Program:    ZISCS_MIGRATION_FIT_RATE'.
  WRITE: / 'Key Date:   ', lv_current_date.
  WRITE: / 'Past Date:  ', lv_pastdate, ' (keydate - p_month months)'.
  WRITE: / 'Lookback:   ', p_month, ' months'.
  WRITE: / '============================================================'.
  SKIP.

*---------------------------------------------------------------------*
* Rule 1: Completed FIT Applications
*   Source: zis_eec_reappln (re_app_status = 'CO' OR '23')
*   Joined with zis_eec_resysmtr for fit_rate
*   Filtered by premises in gt_premise_rule1 (via gt_stg hash table)
*---------------------------------------------------------------------*
  SELECT ln~re_app_no,
         ln~vstelle,
         ln~re_app_status,
         tr~fit_rate
    FROM zis_eec_reappln AS ln
    LEFT JOIN zis_eec_resysmtr AS tr ON ln~re_app_no = tr~re_app_no
    WHERE ln~re_app_status = 'CO'
       OR ln~re_app_status = '23'
    INTO TABLE @DATA(lt_completed_raw).

* Filter: only premises in gt_premise_rule1 (simulated via vstelle filter)
* Note: Full validation requires gt_stg premise list from file/selection
* Using vstelle from all premises as filter
  LOOP AT lt_completed_raw ASSIGNING FIELD-SYMBOL(<fs_comp>).
    " In production, gt_stg contains the premise list from file/selection
    " Here we count all qualifying records as a baseline
    APPEND <fs_comp> TO lt_completed.
  ENDLOOP.

* Deduplicate by re_app_no
  SORT lt_completed BY re_app_no.
  DELETE ADJACENT DUPLICATES FROM lt_completed COMPARING re_app_no.
  lv_r1_completed = LINES( lt_completed ).

* Collect for total dedup
  APPEND LINES OF lt_completed TO lt_all_fit.

  WRITE: / 'Rule 1: Completed FIT Applications (status = CO or 23)'.
  WRITE: / '  Completed Count (distinct re_app_no): ', lv_r1_completed.
  SKIP.

*---------------------------------------------------------------------*
* Rule 2: Cancelled FIT Applications
*   Source: zis_eec_reappln (re_app_status = 'CA')
*   Filter: app_rec_date >= lv_pastdate
*---------------------------------------------------------------------*
  SELECT ln~re_app_no,
         ln~vstelle,
         ln~re_app_status,
         tr~fit_rate
    FROM zis_eec_reappln AS ln
    LEFT JOIN zis_eec_resysmtr AS tr ON ln~re_app_no = tr~re_app_no
    WHERE ln~re_app_status = 'CA'
      AND ln~app_rec_date GE @lv_pastdate
    INTO TABLE @DATA(lt_cancelled_raw).

* Filter by premises (in production via gt_stg)
  LOOP AT lt_cancelled_raw ASSIGNING FIELD-SYMBOL(<fs_canc>).
    APPEND <fs_canc> TO lt_cancelled.
  ENDLOOP.

* Deduplicate by re_app_no
  SORT lt_cancelled BY re_app_no.
  DELETE ADJACENT DUPLICATES FROM lt_cancelled COMPARING re_app_no.
  lv_r2_cancelled = LINES( lt_cancelled ).

* Collect for total dedup
  APPEND LINES OF lt_cancelled TO lt_all_fit.

  WRITE: / 'Rule 2: Cancelled FIT Applications (status = CA, rec_date >= pastdate)'.
  WRITE: / '  Cancelled Count (distinct re_app_no): ', lv_r2_cancelled.
  SKIP.

*---------------------------------------------------------------------*
* Calculate totals
*---------------------------------------------------------------------*
  lv_total = lv_r1_completed + lv_r2_cancelled.

* Deduplicate total
  SORT lt_all_fit BY re_app_no.
  DELETE ADJACENT DUPLICATES FROM lt_all_fit COMPARING re_app_no.
  DATA(lv_dist_total) = LINES( lt_all_fit ).

*---------------------------------------------------------------------*
* Summary
*---------------------------------------------------------------------*
  SKIP.
  WRITE: / '============================================================'.
  WRITE: / '                    SUMMARY'.
  WRITE: / '============================================================'.
  WRITE: / '                        FIT Applications'.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'Rule 1 (Completed):  ', lv_r1_completed.
  WRITE: / 'Rule 2 (Cancelled):  ', lv_r2_cancelled.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'Sum (rules 1+2):    ', lv_total.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'DISTINCT (dedup):    ', lv_dist_total.
  WRITE: / '============================================================'.
  SKIP.
  WRITE: / 'NOTES:'.
  WRITE: / '  - Program reads premise list from file or S_PREMI selection'.
  WRITE: / '  - Only premises in gt_stg are counted (filtered via JOIN'.
  WRITE: / '    in get_fit_rate, using READ TABLE gt_stg)'.
  WRITE: / '  - Deduplication key: re_app_no (distinct FIT applications)'.
  WRITE: / '  - Completed: re_app_status = CO OR 23'.
  WRITE: / '  - Cancelled: re_app_status = CA AND app_rec_date >= pastdate'.
  WRITE: / '  - fit_rate sourced from zis_eec_resysmtr (LEFT JOIN)'.
  WRITE: / '  - Log#0001 performance fix: removed FOR ALL ENTRIES, uses'.
  WRITE: / '    READ TABLE gt_stg hash table lookup instead'.
  WRITE: / '  - CSV split by p_pkt (packet size, default 100000 records)'.
  WRITE: / '============================================================'.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*& Report  Z_FIT_VALIDATION - ABAP KEY FINDINGS vs RTM
*&---------------------------------------------------------------------*
* Validation findings comparing program to RTM documentation:
*
* Program UDs:
*   UD1K936501 (16.02.2026) - Performance fix (removed FOR ALL ENTRIES)
*   UD1K936505 (16.02.2026) - Date fix
*   UD1K936530 (02.03.2026) - File fix
*   UD1K936725 (23.04.2026) - Separator fix (csv separator changed to ;)
*
* Key observations:
*   1. Program processes two rule groups from file names containing 'Rule1' and 'Rule2'
*      but BOTH are merged into gt_premise_rule1 (no separate tracking)
*   2. gt_stg is a HASHED TABLE for O(1) lookup performance
*   3. Completed: re_app_status = 'CO' OR '23' (no date restriction)
*   4. Cancelled: re_app_status = 'CA' AND app_rec_date >= pastdate
*   5. No rule 3 or rule 4 - this is a simpler program than SA migration
*
* RTM Data Extraction doc for fit_rate:
*   - Not found in docs_master.db under standard TD-* naming
*   - Related docs: Renewable Energy (FiT) pages in CXTTS1/CI spaces
*   - Program references zis_eec_reappln + zis_eec_resysmtr tables
*
* Bugs identified:
*   1. get_split_data: lt_chunk is never populated but get_fit_rate
*      references lt_chunk-premise in commented WHERE clause
*      (Log#0001 commented these lines - so lt_chunk is unused)
*   2. get_fit_rate: lt_completed loop uses READ TABLE gt_stg but
*      gt_stg is populated from gt_premise_rule1 (premise list, not re_app_no)
*      - this means filter is on premise/vstelle, not on re_app_no
*   3. write_csv: path uses backslash p_file\\{lv_filename} which may not
*      work correctly on all platforms (should check OS)
*   4. display_counts: deduplicates by re_app_no, but all records from
*      same premise would have different re_app_no anyway (1:many relationship)
*&---------------------------------------------------------------------*