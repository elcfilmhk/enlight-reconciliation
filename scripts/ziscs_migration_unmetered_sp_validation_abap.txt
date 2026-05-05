*&---------------------------------------------------------------------*
*& Report  Z_UNMETERED_SP_VALIDATION
*&---------------------------------------------------------------------*
*& Validation report for ZISCS_MIGRATION_UNMETERED_SP
*& Compare rule counts against source table data
*& ABAP 7.4 compatible version
*&---------------------------------------------------------------------*
REPORT z_unmetered_sp_validation NO STANDARD PAGE HEADING LINE-SIZE 120.

* Parameters
PARAMETERS: p_keydt  TYPE datum DEFAULT '20260309',
            p_auszdt TYPE datum DEFAULT '20260309',
            p_month  TYPE numc2 DEFAULT 24,
            p_pkt   TYPE numc10 DEFAULT '100000'.

* Work variables
DATA: gv_key_date TYPE sy-datum,
      gv_moveout  TYPE sy-datum.

* Counters
DATA: lv_r1_ca  TYPE p,
      lv_r1_sp  TYPE p,
      lv_r1_contr TYPE p,
      lv_total_ca TYPE p,
      lv_total_sp TYPE p.

* Internal tables
TYPES: BEGIN OF ty_raw,
         vkonto  TYPE ever-vkonto,
         vertrag TYPE ever-vertrag,
         anlage  TYPE ever-anlage,
       END OF ty_raw.

DATA: lt_raw TYPE STANDARD TABLE OF ty_raw,
      lt_output TYPE STANDARD TABLE OF ty_raw.

*---------------------------------------------------------------------*
* Start-of-selection
*---------------------------------------------------------------------*
START-OF-SELECTION.

* Determine key date
  DATA(lv_current_key) = p_keydt.
  IF lv_current_key IS INITIAL.
    lv_current_key = sy-datum.
  ENDIF.

* Determine move-out date
  DATA(lv_current_ausz) = p_auszdt.
  IF lv_current_ausz IS INITIAL.
    lv_current_ausz = sy-datum.
  ENDIF.

* Program hard-codes p_month = 24 for both calculations
  DATA(lv_month_used) = 24.

* Calculate key_date = keydt - 24 months
  CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
    EXPORTING
      date      = lv_current_key
      days      = 0
      months    = lv_month_used
      signum    = '-'
      years     = 0
    IMPORTING
      calc_date = gv_key_date.

* Calculate moveout = auszdt - 24 months
  CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
    EXPORTING
      date      = lv_current_ausz
      days      = 0
      months    = lv_month_used
      signum    = '-'
      years     = 0
    IMPORTING
      calc_date = gv_moveout.

  WRITE: / '============================================================'.
  WRITE: / '   ZISCS_MIGRATION_UNMETERED_SP - VALIDATION REPORT'.
  WRITE: / '============================================================'.
  WRITE: / 'Program UD:     UD1K936493'.
  WRITE: / 'Key Date:       ', lv_current_key.
  WRITE: / 'Move-out Date:  ', lv_current_ausz.
  WRITE: / 'Lookback:       ', lv_month_used, ' months (hard-coded in program)'.
  WRITE: / 'Key Date Calc:  ', gv_key_date, ' (key_date = keydt - 24mo)'.
  WRITE: / 'Moveout Calc:   ', gv_moveout,  ' (moveout = auszdt - 24mo)'.
  WRITE: / '============================================================'.
  SKIP.

*---------------------------------------------------------------------*
* Rule 1: Unmetered SP Selection
*   Source: ever + eanlh (inner join)
*   Filter: ever.auszdat >= gv_moveout
*           eanlh.ableinh = 'UNMETER'
*           EXISTS ettifb WHERE anlage=ever.anlage
*             AND bis >= gv_key_date
*             AND operand <> ''
*   Deduplication: vkonto + anlage (adjacent duplicates)
*   Counters: CA (distinct vkonto), SP (count rows), Contracts (distinct vertrag per vkoto)
*---------------------------------------------------------------------*

* Main selection - matches program exactly
  SELECT ever~vkonto
         ever~vertrag
         ever~anlage
    INTO TABLE lt_raw
    FROM ever
    INNER JOIN eanlh
      ON ever~anlage = eanlh~anlage
    WHERE ever~auszdat GE gv_moveout
      AND eanlh~ableinh = 'UNMETER'
      AND EXISTS (
          SELECT *
            FROM ettifb
            WHERE ettifb~anlage = ever~anlage
              AND ettifb~bis GE gv_key_date
              AND ettifb~operand <> '' ).

* Dedup vkonto + anlage (same as program: DELETE ADJACENT DUPLICATES FROM gt_raw COMPARING vkonto anlage)
  SORT lt_raw BY vkonto anlage.
  DELETE ADJACENT DUPLICATES FROM lt_raw COMPARING vkonto anlage.

* CA count (distinct vkonto)
  DATA: lt_ca TYPE STANDARD TABLE OF ever-vkonto.
  SELECT DISTINCT vkonto AS vkonto
    INTO TABLE lt_ca
    FROM ever
    INNER JOIN eanlh
      ON ever~anlage = eanlh~anlage
    WHERE ever~auszdat GE gv_moveout
      AND eanlh~ableinh = 'UNMETER'
      AND EXISTS (
          SELECT *
            FROM ettifb
            WHERE ettifb~anlage = ever~anlage
              AND ettifb~bis GE gv_key_date
              AND ettifb~operand <> '' ).

  lv_r1_ca = LINES( lt_ca ).

* SP count = rows after dedup
  lv_r1_sp = LINES( lt_raw ).

* Contract count per CA - match program logic
*   Program: INSERT vertrag INTO TABLE lt_contract per group
*            gs_output-contract_cnt = LINES( lt_contract )
  DATA: lv_r1_contr TYPE i.
  DATA: lt_contract TYPE STANDARD TABLE OF ever-vertrag.

* Group by vkonto and count distinct vertrag per vkonto
  DATA: lt_vkonto_dist TYPE STANDARD TABLE OF ever-vkonto.
  SELECT DISTINCT vkonto
    INTO TABLE lt_vkonto_dist
    FROM ever
    INNER JOIN eanlh
      ON ever~anlage = eanlh~anlage
    WHERE ever~auszdat GE gv_moveout
      AND eanlh~ableinh = 'UNMETER'
      AND EXISTS (
          SELECT *
            FROM ettifb
            WHERE ettifb~anlage = ever~anlage
              AND ettifb~bis GE gv_key_date
              AND ettifb~operand <> '' ).

  LOOP AT lt_vkonto_dist INTO DATA(lv_vkonto_val).
    SELECT COUNT( DISTINCT vertrag )
      FROM ever
      WHERE vkonto = lv_vkonto_val
      AND vertrag IN (
          SELECT vertrag FROM ever
          WHERE vkonto = lv_vkonto_val
            AND anlage IN (
                SELECT anlage FROM eanlh
                WHERE ableinh = 'UNMETER'
            )
      ).
    " Simplified: count distinct vertrag for this vkonto
    SELECT COUNT( DISTINCT ever~vertrag ) INTO DATA(lv_contr_cnt)
      FROM ever
      INNER JOIN eanlh ON ever~anlage = eanlh~anlage
      WHERE ever~vkonto = lv_vkonto_val
        AND eanlh~ableinh = 'UNMETER'
        AND ever~auszdat GE gv_moveout
        AND EXISTS (
            SELECT * FROM ettifb
            WHERE ettifb~anlage = ever~anlage
              AND ettifb~bis GE gv_key_date
              AND ettifb~operand <> '' ).
    lv_r1_contr = lv_r1_contr + lv_contr_cnt.
  ENDLOOP.

  WRITE: / 'Rule 1: Unmetered Service Points (auszdat >= moveout)'.
  WRITE: / '  CA Count (distinct vkonto):   ', lv_r1_ca.
  WRITE: / '  SP Count (vkonto+anlage dedup):', lv_r1_sp.
  WRITE: / '  Contract Count (distinct vertrag per vkonto):', lv_r1_contr.
  SKIP.

*---------------------------------------------------------------------*
* Summary
*---------------------------------------------------------------------*
  lv_total_ca = lv_r1_ca.
  lv_total_sp = lv_r1_sp.

  SKIP.
  WRITE: / '============================================================'.
  WRITE: / '                    SUMMARY'.
  WRITE: / '============================================================'.
  WRITE: / '                           CA        SP        Contracts'.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'Rule 1 (Unmetered SP):   ', lv_r1_ca CENTERED(10), lv_r1_sp CENTERED(10), lv_r1_contr.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'Total:                   ', lv_total_ca CENTERED(10), lv_total_sp CENTERED(10).
  WRITE: / '============================================================'.
  SKIP.
  WRITE: / 'NOTES:'.
  WRITE: / '  - Program UD1K936493 (single UD on file)'.
  WRITE: / '  - Lookback is hard-coded to 24 months (both key_date and moveout)'.
  WRITE: / '  - Selection: ever + eanlh inner join, ableinh = UNMETER'.
  WRITE: / '  - ettifb check: bis >= gv_key_date AND operand <> ''''(space)'.
  WRITE: / '  - Dedup: vkonto + anlage (adjacent duplicates)'.
  WRITE: / '  - Contracts counted as distinct vertrag per vkonto group'.
  WRITE: / '  - CSV export: packet size default 100000, file split supported'.
  WRITE: / '============================================================'.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*& Report  Z_UNMETERED_SP_VALIDATION - ABAP KEY FINDINGS vs RTM
*&---------------------------------------------------------------------*
* Validation findings comparing program to RTM documentation:
*
* Document: TD-Unmetered & Public Lighting-Extract & Cleanse
*           CUSTOMER-CUST_IT2_CONV_ (page 1253769226)
*
* Program UDs:
*   UD1K936493 (single UD on file)
*
* Program Logic Summary:
*   Rule 1 - Unmetered SP:
*     - Select from ever + eanlh (inner join on anlage)
*     - Filter: ever.auszdat >= moveout (auszdt - 24 months)
*     - Filter: eanlh.ableinh = 'UNMETER'
*     - Filter: EXISTS ettifb WHERE anlage matches AND bis >= key_date AND operand <> space
*     - Dedup: vkonto + anlage
*     - Output: CA count, SP count, Contract count
*
* Deviations/Issues Observed:
*   1. p_month parameter is defined but NEVER USED - program hard-codes 24
*      (line: p_month = 24 overrides parameter value)
*   2. Key date and moveout use DIFFERENT input dates:
*      - gv_key_date = keydt - 24 months
*      - gv_moveout  = auszdt - 24 months
*      Both look back 24 months, but from potentially different reference dates
*   3. No separate RTM rules - program implements single unified selection
*   4. No distinction between unmetered SP and public lighting in program
*   5. The ettifb EXISTS check requires operand <> space - this may miss
*      some SPs where operand is initial but configuration still applies
*
* Cross-validation with SA program:
*   - SA validation found bugs in F_WRTIE_COUNT (copy-paste assignments)
*   - Unmetered SP program is simpler (no multi-rule structure) but has
*     hard-coded p_month = 24 overriding the parameter
*&---------------------------------------------------------------------*