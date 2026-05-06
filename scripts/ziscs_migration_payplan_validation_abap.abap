*&---------------------------------------------------------------------*
*& Report  Z_PAYPLAN_VALIDATION
*&---------------------------------------------------------------------*
*& Validation report for ZISCS_MIGRATION_PAYPLAN (mock4)
*& Compare rule counts against source table data
*& ABAP 7.4 compatible version
*&---------------------------------------------------------------------*
REPORT z_payplan_validation NO STANDARD PAGE HEADING LINE-SIZE 120.

* Parameters (match selection screen of ZISCS_MIGRATION_PAYPLAN_MOCK4)
PARAMETERS: p_keydat TYPE datum DEFAULT '20260309',
            p_month  TYPE numc2 DEFAULT 14.

* Variables
DATA: lv_key_date   TYPE sy-datum,
      lv_r1_count   TYPE i,
      lv_r2_count   TYPE i,
      lv_r3_count   TYPE i,
      lv_r4_count   TYPE i,
      lv_r5_count   TYPE i,
      lv_r_total    TYPE i.

* Internal tables for deduplicated counts
TYPES: BEGIN OF ty_rtm1,
         opbel TYPE dfkkko-opbel,
         vkont TYPE dfkkop-vkont,
       END OF ty_rtm1,
       BEGIN OF ty_rtm2,
         opbel TYPE dfkkko-opbel,
         vkont TYPE dfkkop-vkont,
       END OF ty_rtm2,
       BEGIN OF ty_rtm3,
         opbel TYPE dfkkko-opbel,
         vkont TYPE dfkkop-vkont,
       END OF ty_rtm3,
       BEGIN OF ty_rtm4,
         opbel TYPE dfkkko-opbel,
         vkont TYPE dfkkop-vkont,
       END OF ty_rtm4,
       BEGIN OF ty_rtm5,
         opbel TYPE dfkkko-opbel,
         vkont TYPE dfkkop-vkont,
       END OF ty_rtm5.

DATA: lt_rtm1 TYPE STANDARD TABLE OF ty_rtm1,
      lt_rtm2 TYPE STANDARD TABLE OF ty_rtm2,
      lt_rtm3 TYPE STANDARD TABLE OF ty_rtm3,
      lt_rtm4 TYPE STANDARD TABLE OF ty_rtm4,
      lt_rtm5 TYPE STANDARD TABLE OF ty_rtm5.

START-OF-SELECTION.

* Calculate key date and lookback date
  lv_key_date = p_keydat.
  IF lv_key_date IS INITIAL.
    lv_key_date = sy-datum.
  ENDIF.

  CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
    EXPORTING
      date      = lv_key_date
      days      = 0
      months    = p_month
      signum    = '-'
      years     = 0
    IMPORTING
      calc_date = DATA(lv_past_date).

  WRITE: / '============================================================'.
  WRITE: / '   ZISCS_MIGRATION_PAYPLAN_MOCK4 - VALIDATION REPORT'.
  WRITE: / '============================================================'.
  WRITE: / 'Program:    ZISCS_MIGRATION_PAYPLAN_MOCK4'.
  WRITE: / 'Key Date:   ', lv_key_date.
  WRITE: / 'Past Date:  ', lv_past_date, ' (keydate - p_month months)'.
  WRITE: / 'Lookback:   ', p_month, ' months'.
  WRITE: / '============================================================'.
  SKIP.

*---------------------------------------------------------------------*
* RTM 1: Active Installment Plan
*   Source: dfkkko (blart='IP') + dfkkop + fkk_instpln_head
*   Logic: blart='IP', deadt='00000000', augst=space
*---------------------------------------------------------------------*
  SELECT a~opbel, c~vkont
    FROM dfkkko AS a
    LEFT JOIN dfkkop AS b ON a~opbel = b~opbel
    LEFT JOIN fkk_instpln_head AS c ON a~opbel = c~rpnum
    INTO TABLE @lt_rtm1
    WHERE a~blart = 'IP'
      AND c~deadt = '00000000'
      AND b~augst = @space.

  SORT lt_rtm1 BY opbel vkont.
  DELETE ADJACENT DUPLICATES FROM lt_rtm1 COMPARING opbel vkont.
  lv_r1_count = LINES( lt_rtm1 ).

  WRITE: / 'RTM 1: Active Installment Plan'.
  WRITE: / '  Logic: blart=IP, deadt=00000000, augst=space'.
  WRITE: / '  Tables: dfkkko + dfkkop + fkk_instpln_head'.
  WRITE: / '  Count (unique opbel+vkont): ', lv_r1_count.
  SKIP.

*---------------------------------------------------------------------*
* RTM 2: Kept / Cleared Installment Plan
*   Source: dfkkko (blart='IP') + dfkkop + fkk_instpln_head
*   Logic: blart='IP', cpudt>=keydate, augst<>space, deadt='00000000'
*---------------------------------------------------------------------*
  SELECT a~opbel, c~vkont
    FROM dfkkko AS a
    LEFT JOIN dfkkop AS b ON a~opbel = b~opbel
    LEFT JOIN fkk_instpln_head AS c ON a~opbel = c~rpnum
    INTO TABLE @lt_rtm2
    WHERE a~blart = 'IP'
      AND a~cpudt >= @lv_key_date
      AND b~augst NE @space
      AND c~deadt = '00000000'.

  SORT lt_rtm2 BY opbel vkont.
  DELETE ADJACENT DUPLICATES FROM lt_rtm2 COMPARING opbel vkont.
  lv_r2_count = LINES( lt_rtm2 ).

  WRITE: / 'RTM 2: Kept / Cleared Installment Plan'.
  WRITE: / '  Logic: blart=IP, cpudt>=keydate, augst<>space, deadt=00000000'.
  WRITE: / '  Tables: dfkkko + dfkkop + fkk_instpln_head'.
  WRITE: / '  Count (unique opbel+vkont): ', lv_r2_count.
  SKIP.

*---------------------------------------------------------------------*
* RTM 3: Deactivated Installment Plan (Log#0001)
*   Source: dfkkko (blart='IP') + dfkkop + fkk_instpln_head
*   Logic: blart='IP', cpudt>=keydate, deadt<>'00000000'
*---------------------------------------------------------------------*
  SELECT dfkkko~opbel, dfkkop~vkont
    FROM dfkkko
    LEFT JOIN dfkkop ON dfkkko~opbel = dfkkop~opbel
    LEFT JOIN fkk_instpln_head ON dfkkko~opbel = fkk_instpln_head~rpnum
    INTO TABLE @lt_rtm3
    WHERE dfkkko~blart = 'IP'
      AND dfkkko~cpudt >= @lv_key_date
      AND fkk_instpln_head~deadt NE '00000000'.

  SORT lt_rtm3 BY opbel vkont.
  DELETE ADJACENT DUPLICATES FROM lt_rtm3 COMPARING opbel vkont.
  lv_r3_count = LINES( lt_rtm3 ).

  WRITE: / 'RTM 3: Deactivated Installment Plan (Log#0001)'.
  WRITE: / '  Logic: blart=IP, cpudt>=keydate, deadt<>00000000'.
  WRITE: / '  Tables: dfkkko + dfkkop + fkk_instpln_head'.
  WRITE: / '  Count (unique opbel+vkont): ', lv_r3_count.
  SKIP.

*---------------------------------------------------------------------*
* RTM 4: Non-paid Pay Extensions (Active)
*   Source: dfkkko + dfkkop
*   Logic: studt<>'00000000', augbl=space, blart<>'IP'
*---------------------------------------------------------------------*
  SELECT a~opbel, b~vkont
    FROM dfkkko AS a
    LEFT JOIN dfkkop AS b ON a~opbel = b~opbel
    INTO TABLE @lt_rtm4
    WHERE b~studt NE '00000000'
      AND b~augbl = @space
      AND a~blart NE 'IP'.

  SORT lt_rtm4 BY opbel vkont.
  DELETE ADJACENT DUPLICATES FROM lt_rtm4 COMPARING opbel vkont.
  lv_r4_count = LINES( lt_rtm4 ).

  WRITE: / 'RTM 4: Non-paid Pay Extensions (Active)'.
  WRITE: / '  Logic: studt<>00000000, augbl=space, blart<>IP'.
  WRITE: / '  Tables: dfkkko + dfkkop'.
  WRITE: / '  Count (unique opbel+vkont): ', lv_r4_count.
  SKIP.

*---------------------------------------------------------------------*
* RTM 5: Pay Extension History (14 months)
*   Source: dfkkko + dfkkop
*   Logic: studt<>'00000000', augbl<>space, faedn>=keydate, blart<>'IP'
*---------------------------------------------------------------------*
  SELECT a~opbel, b~vkont
    FROM dfkkko AS a
    LEFT JOIN dfkkop AS b ON a~opbel = b~opbel
    INTO TABLE @lt_rtm5
    WHERE b~studt NE '00000000'
      AND b~augbl NE @space
      AND b~faedn >= @lv_key_date
      AND a~blart NE 'IP'.

  SORT lt_rtm5 BY opbel vkont.
  DELETE ADJACENT DUPLICATES FROM lt_rtm5 COMPARING opbel vkont.
  lv_r5_count = LINES( lt_rtm5 ).

  WRITE: / 'RTM 5: Pay Extension History (14 months) (Log#0001)'.
  WRITE: / '  Logic: studt<>00000000, augbl<>space, faedn>=keydate, blart<>IP'.
  WRITE: / '  Tables: dfkkko + dfkkop'.
  WRITE: / '  Count (unique opbel+vkont): ', lv_r5_count.
  SKIP.

*---------------------------------------------------------------------*
* Summary
*---------------------------------------------------------------------*
  lv_r_total = lv_r1_count + lv_r2_count + lv_r3_count + lv_r4_count + lv_r5_count.

  SKIP.
  WRITE: / '============================================================'.
  WRITE: / '                    SUMMARY'.
  WRITE: / '============================================================'.
  WRITE: / '                        Count'.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'RTM 1 (Active Installment Plan):      ', lv_r1_count.
  WRITE: / 'RTM 2 (Kept/Cleared Installment Plan):', lv_r2_count.
  WRITE: / 'RTM 3 (Deactivated Installment Plan): ', lv_r3_count.
  WRITE: / 'RTM 4 (Non-paid Pay Extensions):       ', lv_r4_count.
  WRITE: / 'RTM 5 (Pay Extension History):         ', lv_r5_count.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'TOTAL (all RTMs):                      ', lv_r_total.
  WRITE: / '============================================================'.
  SKIP.
  WRITE: / 'NOTES:'.
  WRITE: / '  - Program UD: UD1K936403 (Mock4, 13.11.2025)'.
  WRITE: / '  - Log#0001 added RTM3, RTM5, blart<>IP filter'.
  WRITE: / '  - RTM4+RTM5 stored in gt_file_ext (Pay Extension CSV)'.
  WRITE: / '  - RTM1+RTM2+RTM3 stored in gt_file (Payplan CSV)'.
  WRITE: / '  - RTM3+RTM4+RTM5 used for PayExtn total count computation'.
  WRITE: / '  - gt_rtm3_temp = RTM3 + RTM4 + RTM5 for PayExtn dedup total'.
  WRITE: / '============================================================'.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*& Report  Z_PAYPLAN_VALIDATION - ABAP KEY FINDINGS vs RTM
*&---------------------------------------------------------------------*
* Validation findings comparing program to RTM documentation:
*
* Document: TD-PayPlan-Extract & Cleanse (943064714)
*
* Program UDs:
*   UD1K936403 (13.11.2025) - MOCK4 version
*
* RTM Breakdown:
*   RTM 1: Active Installment Plan (Payplan CSV)
*          blart=IP, deadt=00000000, augst=space
*   RTM 2: Kept/Cleared Installment Plan (Payplan CSV)
*          blart=IP, cpudt>=keydate, augst<>space, deadt=00000000
*   RTM 3: Deactivated Installment Plan (Payplan CSV, Log#0001)
*          blart=IP, cpudt>=keydate, deadt<>00000000
*   RTM 4: Non-paid Pay Extensions - Active (PayExtension CSV)
*          studt<>00000000, augbl=space, blart<>IP
*   RTM 5: Pay Extension History (PayExtension CSV, Log#0001)
*          studt<>00000000, augbl<>space, faedn>=keydate, blart<>IP
*
* Key observations:
*   1. Payplan category: RTM1 + RTM2 + RTM3 go to gt_file
*   2. PayExtension category: RTM4 + RTM5 go to gt_file_ext
*   3. PayExtn total count = unique opbel+vkont across RTM3+RTM4+RTM5
*   4. Log#0001 added blart<>IP filter to RTM4 and RTM5
*   5. RTM 2 excludes items already in RTM 1 (checked in build_summary)
*   6. CSV path uses forward slash in path but backslash in filename
*      construction (potential cross-platform issue)
*   7. gt_rtm3 renamed in code but SELECT still uses dfkkko alias
*      (misleading naming but logically correct)
*   8. The p_keydt parameter is used for key date input on selection
*      screen but gv_key_date is used in queries (calculated as
*      key_date - p_month months)
*&---------------------------------------------------------------------*