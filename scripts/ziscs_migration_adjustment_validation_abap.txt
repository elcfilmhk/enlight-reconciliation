*&---------------------------------------------------------------------*
*& Report  Z_ADJUSTMENT_VALIDATION
*&---------------------------------------------------------------------*
*& Validation report for ZISCS_MIGRATION_ADJUSTMENT_M4
*& Compare rule counts against source table data
*& ABAP 7.4 compatible version
*&---------------------------------------------------------------------*
REPORT z_adjustment_validation NO STANDARD PAGE HEADING LINE-SIZE 120.

* Parameters
PARAMETERS: p_keydat TYPE datum DEFAULT '20251027',
            p_month  TYPE numc2 DEFAULT 14,
            p_pkt    TYPE numc10 DEFAULT '100000'.

* Variables
DATA: gv_total        TYPE i,
      gv_reversed     TYPE i,
      gv_frozen       TYPE i,
      gv_rule1_ca     TYPE i,
      gv_rule2_ca     TYPE i,
      gv_rule3_ca     TYPE i.

* Internal tables
TYPES: BEGIN OF ty_opbel,
         opbel TYPE dfkkko-opbel,
       END OF ty_opbel.

DATA: lt_rule1 TYPE STANDARD TABLE OF ty_opbel,
      lt_rule2 TYPE STANDARD TABLE OF ty_opbel,
      lt_rule3 TYPE STANDARD TABLE OF ty_opbel,
      lt_all   TYPE STANDARD TABLE OF ty_opbel.

START-OF-SELECTION.

* Calculate past date
  DATA(lv_current_date) = p_keydat.
  IF lv_current_date IS INITIAL.
    lv_current_date = '20251027'.  " Default from program
  ENDIF.

  DATA: lv_past_date TYPE sy-datum.
  CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
    EXPORTING
      date      = lv_current_date
      days      = 0
      months    = p_month
      signum    = '-'
      years     = 0
    IMPORTING
      calc_date = lv_past_date.

  WRITE: / '============================================================'.
  WRITE: / '   ZISCS_MIGRATION_ADJUSTMENT_M4 - VALIDATION REPORT'.
  WRITE: / '============================================================'.
  WRITE: / 'Program:    ZISCS_MIGRATION_ADJUSTMENT_M4'.
  WRITE: / 'Latest UD:  UD1K936545 (09.03.2026) - M3.5 logic update'.
  WRITE: / 'Key Date:   ', lv_current_date.
  WRITE: / 'Past Date:  ', lv_past_date, ' (keydate - p_month months)'.
  WRITE: / 'Lookback:   ', p_month, ' months'.
  WRITE: / '============================================================'.
  SKIP.

*---------------------------------------------------------------------*
* Build exclusion list for blart (same as program)
*   Exclude: P*, MC, MQ, HC, HQ, AM, WS, ZW, WO, IP, RT
*---------------------------------------------------------------------*
  SELECT blart
    FROM tfk003
    INTO TABLE @DATA(lt_blart_excl)
    WHERE blart NOT LIKE 'P%'
      AND blart NOT IN ('MC', 'MQ', 'HC', 'HQ', 'AM',
                        'WS', 'ZW', 'WO', 'IP', 'RT').

  DATA: lt_blart TYPE STANDARD TABLE OF tfk003-blart.
  LOOP AT lt_blart_excl INTO DATA(ls_excl).
    APPEND ls_excl-blart TO lt_blart.
  ENDLOOP.

*---------------------------------------------------------------------*
* Rule 1: Non-TP documents
*   Condition: blart IN lt_blart AND hvorg NOT IN ('0100','0200','0300')
*   Source table: DFKKKO LEFT JOIN DFKKOP
*   Dedup by: opbel
*---------------------------------------------------------------------*
  SELECT a~opbel
    FROM dfkkko AS a
    LEFT JOIN dfkkop AS b ON a~opbel = b~opbel
    INTO TABLE @lt_rule1
    WHERE a~blart IN @lt_blart
      AND b~hvorg NOT IN ('0100', '0200', '0300')
      AND a~cpudt >= @lv_past_date
      AND NOT ( b~xanza = 'X' AND b~stakz = 'H' )
      AND NOT ( b~xanza = 'X' AND b~augrs = '2' )
      AND a~blart <> 'TP'.

  DELETE ADJACENT DUPLICATES FROM lt_rule1 COMPARING opbel.
  gv_rule1_ca = LINES( lt_rule1 ).

  APPEND LINES OF lt_rule1 TO lt_all.

  WRITE: / 'Rule 1: Non-TP documents (blart IN list, hvorg NOT IN 0100/0200/0300)'.
  WRITE: / '  Excluded blart: P*, MC, MQ, HC, HQ, AM, WS, ZW, WO, IP, RT'.
  WRITE: / '  Count (distinct opbel): ', gv_rule1_ca.
  SKIP.

*---------------------------------------------------------------------*
* Rule 2: TP documents with specific hvorg/tvorg
*   Condition: blart = 'TP' AND augst = '' AND
*              (hvorg = 'ZWOS' AND tvorg = '0010' OR
*               hvorg = 'ZWOF' AND tvorg = '0010' OR
*               hvorg = 'ZWOF' AND tvorg = '0020')
*   Source table: DFKKKO LEFT JOIN DFKKOP
*   Dedup by: opbel
*---------------------------------------------------------------------*
  SELECT a~opbel
    FROM dfkkko AS a
    LEFT JOIN dfkkop AS b ON a~opbel = b~opbel
    INTO TABLE @lt_rule2
    WHERE a~blart = 'TP'
      AND b~augst = ''
      AND ( ( b~hvorg = 'ZWOS' AND b~tvorg = '0010' ) OR
            ( b~hvorg = 'ZWOF' AND b~tvorg = '0010' ) OR
            ( b~hvorg = 'ZWOF' AND b~tvorg = '0020' ) )
      AND a~cpudt >= @lv_past_date
      AND NOT ( b~xanza = 'X' AND b~stakz = 'H' )
      AND NOT ( b~xanza = 'X' AND b~augrs = '2' ).

  DELETE ADJACENT DUPLICATES FROM lt_rule2 COMPARING opbel.
  gv_rule2_ca = LINES( lt_rule2 ).

  APPEND LINES OF lt_rule2 TO lt_all.

  WRITE: / 'Rule 2: TP documents (special hvorg/tvorg combo)'.
  WRITE: / '  Condition: blart=TP AND augst=space AND'.
  WRITE: / '    (hvorg=ZWOS+tvorg=0010 OR'.
  WRITE: / '     hvorg=ZWOF+tvorg=0010 OR'.
  WRITE: / '     hvorg=ZWOF+tvorg=0020)'.
  WRITE: / '  Count (distinct opbel): ', gv_rule2_ca.
  SKIP.

*---------------------------------------------------------------------*
* Rule 3: TP documents NOT in special hvorg/tvorg combo
*   Condition: blart = 'TP' AND NOT (Rule 2 conditions)
*   Source table: DFKKKO LEFT JOIN DFKKOP
*   Dedup by: opbel
*---------------------------------------------------------------------*
  SELECT a~opbel
    FROM dfkkko AS a
    LEFT JOIN dfkkop AS b ON a~opbel = b~opbel
    INTO TABLE @lt_rule3
    WHERE a~blart = 'TP'
      AND NOT ( ( b~hvorg = 'ZWOS' AND b~tvorg = '0010' ) OR
                ( b~hvorg = 'ZWOF' AND b~tvorg = '0010' ) OR
                ( b~hvorg = 'ZWOF' AND b~tvorg = '0020' ) )
      AND a~cpudt >= @lv_past_date
      AND NOT ( b~xanza = 'X' AND b~stakz = 'H' )
      AND NOT ( b~xanza = 'X' AND b~augrs = '2' ).

  DELETE ADJACENT DUPLICATES FROM lt_rule3 COMPARING opbel.
  gv_rule3_ca = LINES( lt_rule3 ).

  APPEND LINES OF lt_rule3 TO lt_all.

  WRITE: / 'Rule 3: TP documents (NOT in Rule 2 combo)'.
  WRITE: / '  Condition: blart=TP AND NOT (ZWOS/0010, ZWOF/0010, ZWOF/0020)'.
  WRITE: / '  Count (distinct opbel): ', gv_rule3_ca.
  SKIP.

*---------------------------------------------------------------------*
* Common exclusions (applied in all rules)
*   - cpudt >= lv_past_date
*   - NOT (xanza = 'X' AND stakz = 'H')
*   - NOT (xanza = 'X' AND augrs = '2')
*---------------------------------------------------------------------*
  WRITE: / '============================================================'.
  WRITE: / '               COMMON EXCLUSIONS'.
  WRITE: / '============================================================'.
  WRITE: / '  - Document date (cpudt) >= ', lv_past_date.
  WRITE: / '  - NOT (xanza=X AND stakz=H)  [frozen + hard block]'.
  WRITE: / '  - NOT (xanza=X AND augrs=2)  [frozen + auto reversal]'.
  WRITE: / '============================================================'.
  SKIP.

*---------------------------------------------------------------------*
* Summary
*---------------------------------------------------------------------*
  SORT lt_all BY opbel.
  DELETE ADJACENT DUPLICATES FROM lt_all COMPARING opbel.
  DATA(gv_distinct) = LINES( lt_all ).

  gv_total    = gv_rule1_ca + gv_rule2_ca + gv_rule3_ca.
  gv_reversed = gv_total.  "storb not initial
  gv_frozen   = 0.         "storb is initial - requires storb join

  SKIP.
  WRITE: / '============================================================'.
  WRITE: / '                    SUMMARY'.
  WRITE: / '============================================================'.
  WRITE: / '                         Count (distinct opbel)'.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'Rule 1 (Non-TP):         ', gv_rule1_ca.
  WRITE: / 'Rule 2 (TP special):      ', gv_rule2_ca.
  WRITE: / 'Rule 3 (TP other):       ', gv_rule3_ca.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'Total (rules 1+2+3):     ', gv_total.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'DISTINCT (all rules):    ', gv_distinct.
  WRITE: / '============================================================'.
  SKIP.
  WRITE: / 'NOTES:'.
  WRITE: / '  - Program UD1K936545 adds augst, hvorg, tvorg fields (Log#0005)'.
  WRITE: / '  - Rules 1,2,3 are combined in single SELECT with OR logic'.
  WRITE: / '  - Dedup key includes: opbel, blart, storb, vkont, hvorg (m4)'.
  WRITE: / '  - storb field determines Reversed vs Frozen in output loop'.
  WRITE: / '  - WS, ZW, WO, IP, RT excluded via lt_blart (Log#0003)'.
  WRITE: / '  - AM excluded (Log#0001, UD1K936178)'.
  WRITE: / '============================================================'.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*& Report  Z_ADJUSTMENT_VALIDATION - ABAP KEY FINDINGS vs RTM
*&---------------------------------------------------------------------*
* Validation findings comparing program to RTM documentation:
*
* Program UDs:
*   UD1K936055 (11.09.2025) - Initial Implementation
*   UD1K936178 (15.10.2025) - Exclude AM type document
*   UD1K936267 (10.11.2025) - MOCK changes
*   UD1K936390 (09.12.2025) - New doc type TB inclusion logic
*   UD1K936545 (09.03.2026) - Logic update for M3.5
*
* RTM Doc: TD-ADJUSTMENT Primary-Extract & Cleanse-CUSTOMER-CUST_IT2_ (835846145)
*
* Program Rules vs RTM:
*   Rule 1: Non-TP documents with hvorg NOT IN (0100,0200,0300)
*   Rule 2: TP documents with special ZWOS/ZWOF + tvorg combo
*   Rule 3: TP documents NOT in Rule 2 combo
*
* Key observations:
*   - Program combines 3 rules in single SELECT with OR conditions
*   - DPAYH/DPAYP join happens AFTER main fetch (for payment info)
*   - Dedup includes hvorg in m4 (changed from m3)
*   - storb field in output used for Reversed/Frozen count
*
* Deviation from SA program pattern:
*   - Adjustment uses opbel (document) as dedup key, not vkont
*   - Rules are NOT mutually exclusive in SELECT - OR can overlap
*   - hvorg filter applies to Rule 1 only
*
* Cross-validation note:
*   - gt_main = all records including DPAYH join
*   - gt_file = passed to CSV export (includes dedup logic)
*   - Final loop counts: storb IS INITIAL = frozen, else = reversed
*&---------------------------------------------------------------------*