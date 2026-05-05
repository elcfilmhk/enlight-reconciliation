*&---------------------------------------------------------------------*
*& Report  Z_FUEL_SWITCH_VALIDATION
*&---------------------------------------------------------------------*
*& Validation report for ZISCS_MIGRATION_FUEL_SWITCH_M4
*& Compare rule counts against source table data
*& ABAP 7.4 compatible version
*&---------------------------------------------------------------------*
REPORT z_fuel_switch_validation NO STANDARD PAGE HEADING LINE-SIZE 120.

* Parameters
PARAMETERS: p_keydat TYPE datum DEFAULT '20260309',
            p_month  TYPE numc2 DEFAULT 14,
            p_docdat TYPE datum DEFAULT '20150101'.

* Tables
TABLES: vbak, vbuk, vbkd, vbap, zissdec.

* Variables
DATA: lv_pastdate TYPE sy-datum.

* Counters
DATA: lv_r1 TYPE p,
      lv_r2 TYPE p,
      lv_r3a TYPE p,
      lv_r3b TYPE p,
      lv_r4a TYPE p,
      lv_r4b TYPE p,
      lv_total TYPE p.

* Internal tables
TYPES: BEGIN OF ty_vbak,
         vbeln TYPE vbak-vbeln,
         auart TYPE vbak-auart,
         audat TYPE vbak-audat,
         vkbur TYPE vbak-vkbur,
       END OF ty_vbak.

TYPES: BEGIN OF ty_vbkd,
         vbeln TYPE vbkd-vbeln,
         vkont TYPE vbkd-vkont,
       END OF ty_vbkd.

TYPES: BEGIN OF ty_fuel,
         vbeln  TYPE vbak-vbeln,
         vkont  TYPE vbkd-vkont,
         matnr  TYPE vbap-matnr,
         vkbur  TYPE vbak-vkbur,
         fksak  TYPE vbuk-fksak,
         ci_no_of_install TYPE zissdec-ci_no_of_install,
         ec_no_of_install TYPE zissdec-ec_no_of_install,
         ci_status        TYPE zissdec-ci_status,
         ci_update_date   TYPE zissdec-ci_update_date,
         ec_update_date   TYPE zissdec-ec_update_date,
       END OF ty_fuel.

DATA: lt_vbak  TYPE STANDARD TABLE OF ty_vbak,
      lt_vbkd  TYPE STANDARD TABLE OF ty_vbkd,
      lt_fuel  TYPE STANDARD TABLE OF ty_fuel,
      lt_final TYPE STANDARD TABLE OF ty_fuel.

* Business unit range
DATA: lt_vkbur TYPE TABLE OF vkbur.
DATA: lt_matnr TYPE TABLE OF matnr.
DATA: lt_fksak TYPE TABLE OF fksak.

START-OF-SELECTION.

* Calculate past date from keydate - p_month months
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

* Populate selection ranges (mimic program initialization)
  lt_vkbur = VALUE #(
    ( sign = 'I' option = 'EQ' low = 'C81B' )
    ( sign = 'I' option = 'EQ' low = 'C81C' )
    ( sign = 'I' option = 'EQ' low = 'C81M' )
    ( sign = 'I' option = 'EQ' low = 'C81P' )
    ( sign = 'I' option = 'EQ' low = 'C81T' )
    ( sign = 'I' option = 'EQ' low = 'SME'  )
    ( sign = 'I' option = 'EQ' low = 'C82'  )
  ).

  lt_matnr = VALUE #(
    ( sign = 'I' option = 'EQ' low = '000000000098000000' )
    ( sign = 'I' option = 'EQ' low = '000000000098000001' )
  ).

  lt_fksak = VALUE #(
    ( sign = 'I' option = 'EQ' low = 'A' )
    ( sign = 'I' option = 'EQ' low = 'B' )
    ( sign = 'I' option = 'EQ' low = 'C' )
  ).

  WRITE: / '============================================================'.
  WRITE: / '   ZISCS_MIGRATION_FUEL_SWITCH_M4 - VALIDATION REPORT'.
  WRITE: / '============================================================'.
  WRITE: / 'Program:    ZISCS_MIGRATION_FUEL_SWITCH_M4'.
  WRITE: / 'Latest UD:  UD1K936725 (24.04.2026)'.
  WRITE: / 'Key Date:   ', lv_current_date.
  WRITE: / 'Doc Date:   ', p_docdat, '(audat filter)'.
  WRITE: / 'Past Date:  ', lv_pastdate, '(keydate - p_month months)'.
  WRITE: / 'Lookback:   ', p_month, ' months'.
  WRITE: / '============================================================'.
  SKIP.

*---------------------------------------------------------------------*
* Step 1: Select VBAK records (Sales Order header)
*   auart = 'ZPS'
*   vkbur IN ('C81B','C81C','C81M','C81P','C81T','SME','C82')
*   audat GE p_docdat (default 20150101)
*---------------------------------------------------------------------*
  SELECT vbak~vbeln,
         vbak~auart,
         vbak~audat,
         vbak~vkbur
    FROM vbak
    INTO TABLE lt_vbak
    WHERE vbak~auart EQ 'ZPS'
      AND vbak~vkbur IN lt_vkbur
      AND vbak~audat GE p_docdat.

  SORT lt_vbak BY vbeln.
  DELETE ADJACENT DUPLICATES FROM lt_vbak COMPARING vbeln.

  WRITE: / 'Step 1 - VBAK (Sales Order headers)'.
  WRITE: / '  Distinct Sales Orders: ', lines( lt_vbak ).
  SKIP.

*---------------------------------------------------------------------*
* Step 2: Select VBK D (Sales Order + Contract Account mapping)
*---------------------------------------------------------------------*
  IF lt_vbak IS NOT INITIAL.
    SELECT vbeln,
           vkont
      FROM vbkd
      INTO TABLE lt_vbkd
      FOR ALL ENTRIES IN lt_vbak
      WHERE vbeln = lt_vbak-vbeln.

    SORT lt_vbkd BY vbeln.
    DELETE ADJACENT DUPLICATES FROM lt_vbkd COMPARING vbeln.

    WRITE: / 'Step 2 - VBK D (Sales Order + CA mapping)'.
    WRITE: / '  Distinct mappings: ', lines( lt_vbkd ).
    SKIP.
  ENDIF.

*---------------------------------------------------------------------*
* Step 3: Select main data (VBAK+VBAP+VBUK+ZISSDEC join)
*   Business Unit filtering + material + status
*---------------------------------------------------------------------*
  IF lt_vbkd IS NOT INITIAL.
    SELECT vbak~vbeln,
           vbak~vkbur,
           vbap~matnr,
           vbuk~fksak,
           zissdec~ec_update_date,
           zissdec~ci_no_of_install,
           zissdec~ec_no_of_install,
           zissdec~ci_status,
           zissdec~ci_update_date
      FROM vbak
      INNER JOIN vbap  ON vbap~vbeln = vbak~vbeln
      INNER JOIN vbuk  ON vbuk~vbeln = vbak~vbeln
      INNER JOIN zissdec ON zissdec~ec_order_no = vbap~vbeln
                        AND zissdec~ec_order_item = vbap~posnr
      INTO TABLE lt_fuel
      FOR ALL ENTRIES IN lt_vbkd
      WHERE vbak~vbeln = lt_vbkd-vbeln
        AND vbap~matnr IN lt_matnr
        AND vbuk~fksak IN lt_fksak.

    WRITE: / 'Step 3 - Main join (VBAK+VBAP+VBUK+ZISSDEC)'.
    WRITE: / '  Total records: ', lines( lt_fuel ).
  ENDIF.

*---------------------------------------------------------------------*
* Step 4: Add vkont by joining with lt_vbkd
*---------------------------------------------------------------------*
  LOOP AT lt_fuel ASSIGNING FIELD-SYMBOL(<fs_fuel>).
    READ TABLE lt_vbkd INTO DATA(ls_vbkd) WITH KEY vbeln = <fs_fuel>-vbeln BINARY SEARCH.
    IF sy-subrc = 0.
      <fs_fuel>-vkont = ls_vbkd-vkont.
    ENDIF.
  ENDLOOP.

  WRITE: / 'Step 4 - vkont joined from VBK D'.
  WRITE: / '  Records with vkont: ', lines( lt_fuel ).
  SKIP.

*---------------------------------------------------------------------*
* RULE 1: Business (C81B/C81C/C81M/C81P/C81T/SME) + Material 98000001
*         + ec_no_of_install > 0
*         + (fksak = B OR C)
*         + ec_update_date >= gv_past_date
*---------------------------------------------------------------------*
  DATA(lt_r1) = lt_fuel.
  DELETE lt_r1 WHERE NOT (
    ( vkbur = 'C81B' OR vkbur = 'C81C' OR vkbur = 'C81M' OR
      vkbur = 'C81P' OR vkbur = 'C81T' OR vkbur = 'SME' )
    AND matnr = '000000000098000001'
    AND ec_no_of_install > 0
    AND ( fksak = 'B' OR fksak = 'C' )
    AND ec_update_date >= lv_pastdate
  ).
  SORT lt_r1 BY vbeln vkont.
  DELETE ADJACENT DUPLICATES FROM lt_r1 COMPARING vbeln vkont.
  lv_r1 = lines( lt_r1 ).

  WRITE: / 'Rule RTM1: Business + matnr=98000001 + ec_no>0 + (B|C) + ec_update>=past'.
  WRITE: / '  Count (unique vbeln+vkont): ', lv_r1.
  SKIP.

*---------------------------------------------------------------------*
* RULE 2: Business + Material 98000000
*         + ci_no_of_install > 0
*         + ((fksak = B OR C) OR (fksak = A AND ci_status = 7))
*         + ci_update_date >= gv_past_date
*---------------------------------------------------------------------*
  DATA(lt_r2) = lt_fuel.
  DELETE lt_r2 WHERE NOT (
    ( vkbur = 'C81B' OR vkbur = 'C81C' OR vkbur = 'C81M' OR
      vkbur = 'C81P' OR vkbur = 'C81T' OR vkbur = 'SME' )
    AND matnr = '000000000098000000'
    AND ci_no_of_install > 0
    AND ( ( fksak = 'B' OR fksak = 'C' )
       OR ( fksak = 'A' AND ci_status = 7 ) )
    AND ci_update_date >= lv_pastdate
  ).
  SORT lt_r2 BY vbeln vkont.
  DELETE ADJACENT DUPLICATES FROM lt_r2 COMPARING vbeln vkont.
  lv_r2 = lines( lt_r2 ).

  WRITE: / 'Rule RTM2: Business + matnr=98000000 + ci_no>0 + ((B|C) or (A and ci_status=7)) + ci_update>=past'.
  WRITE: / '  Count (unique vbeln+vkont): ', lv_r2.
  SKIP.

*---------------------------------------------------------------------*
* RULE 3A: Business + Material 98000000
*          + ci_no_of_install < 2
*          + fksak = A
*          + ci_status = 1
*---------------------------------------------------------------------*
  DATA(lt_r3a) = lt_fuel.
  DELETE lt_r3a WHERE NOT (
    ( vkbur = 'C81B' OR vkbur = 'C81C' OR vkbur = 'C81M' OR
      vkbur = 'C81P' OR vkbur = 'C81T' OR vkbur = 'SME' )
    AND matnr = '000000000098000000'
    AND ci_no_of_install < 2
    AND fksak = 'A'
    AND ci_status = 1
  ).
  SORT lt_r3a BY vbeln vkont.
  DELETE ADJACENT DUPLICATES FROM lt_r3a COMPARING vbeln vkont.
  lv_r3a = lines( lt_r3a ).

  WRITE: / 'Rule RTM3A: Business + matnr=98000000 + ci_no<2 + fksak=A + ci_status=1'.
  WRITE: / '  Count (unique vbeln+vkont): ', lv_r3a.
  SKIP.

*---------------------------------------------------------------------*
* RULE 3B: Business + Material 98000000
*          + ci_no_of_install < 2
*          + ((fksak = B OR C) OR (fksak = A AND ci_status = 7))
*          + ci_update_date >= gv_past_date
*---------------------------------------------------------------------*
  DATA(lt_r3b) = lt_fuel.
  DELETE lt_r3b WHERE NOT (
    ( vkbur = 'C81B' OR vkbur = 'C81C' OR vkbur = 'C81M' OR
      vkbur = 'C81P' OR vkbur = 'C81T' OR vkbur = 'SME' )
    AND matnr = '000000000098000000'
    AND ci_no_of_install < 2
    AND ( ( fksak = 'B' OR fksak = 'C' )
       OR ( fksak = 'A' AND ci_status = 7 ) )
    AND ci_update_date >= lv_pastdate
  ).
  SORT lt_r3b BY vbeln vkont.
  DELETE ADJACENT DUPLICATES FROM lt_r3b COMPARING vbeln vkont.
  lv_r3b = lines( lt_r3b ).

  WRITE: / 'Rule RTM3B: Business + matnr=98000000 + ci_no<2 + ((B|C) or (A and ci_status=7)) + ci_update>=past'.
  WRITE: / '  Count (unique vbeln+vkont): ', lv_r3b.
  SKIP.

*---------------------------------------------------------------------*
* RULE 4A: Residential (C82) + Material 98000000
*          + ci_no_of_install < 2
*          + fksak = A
*          + ci_status = 1
*---------------------------------------------------------------------*
  DATA(lt_r4a) = lt_fuel.
  DELETE lt_r4a WHERE NOT (
    vkbur = 'C82'
    AND matnr = '000000000098000000'
    AND ci_no_of_install < 2
    AND fksak = 'A'
    AND ci_status = 1
  ).
  SORT lt_r4a BY vbeln vkont.
  DELETE ADJACENT DUPLICATES FROM lt_r4a COMPARING vbeln vkont.
  lv_r4a = lines( lt_r4a ).

  WRITE: / 'Rule RTM4A: Residential(C82) + matnr=98000000 + ci_no<2 + fksak=A + ci_status=1'.
  WRITE: / '  Count (unique vbeln+vkont): ', lv_r4a.
  SKIP.

*---------------------------------------------------------------------*
* RULE 4B: Residential (C82) + Material 98000000
*          + ci_no_of_install < 2
*          + ci_status = 7
*          + ci_update_date >= gv_past_date
*---------------------------------------------------------------------*
  DATA(lt_r4b) = lt_fuel.
  DELETE lt_r4b WHERE NOT (
    vkbur = 'C82'
    AND matnr = '000000000098000000'
    AND ci_no_of_install < 2
    AND ci_status = 7
    AND ci_update_date >= lv_pastdate
  ).
  SORT lt_r4b BY vbeln vkont.
  DELETE ADJACENT DUPLICATES FROM lt_r4b COMPARING vbeln vkont.
  lv_r4b = lines( lt_r4b ).

  WRITE: / 'Rule RTM4B: Residential(C82) + matnr=98000000 + ci_no<2 + ci_status=7 + ci_update>=past'.
  WRITE: / '  Count (unique vbeln+vkont): ', lv_r4b.
  WRITE: / '  NOTE: audat filter removed in UD1K936725 (Log#0011)'.
  SKIP.

*---------------------------------------------------------------------*
* Summary
*---------------------------------------------------------------------*
  lv_total = lv_r1 + lv_r2 + lv_r3a + lv_r3b + lv_r4a + lv_r4b.

  SKIP.
  WRITE: / '============================================================'.
  WRITE: / '                    SUMMARY'.
  WRITE: / '============================================================'.
  WRITE: / '                        Count (unique vbeln+vkont)'.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'RTM1 (Business+EC):       ', lv_r1.
  WRITE: / 'RTM2 (Business+CI):        ', lv_r2.
  WRITE: / 'RTM3A (Business+CI+A+1):   ', lv_r3a.
  WRITE: / 'RTM3B (Business+CI+status):', lv_r3b.
  WRITE: / 'RTM4A (Resid+CI+A+1):      ', lv_r4a.
  WRITE: / 'RTM4B (Resid+CI+status):   ', lv_r4b.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'Sum (all rules):          ', lv_total.
  WRITE: / '============================================================'.
  SKIP.
  WRITE: / 'NOTES:'.
  WRITE: / '  - RTM1/RTM2/RTM3A/RTM3B apply to Business (C81B/C81C/C81M/C81P/C81T/SME)'.
  WRITE: / '  - RTM4A/RTM4B apply to Residential (C82) only.'.
  WRITE: / '  - Deduplication key: vbeln + vkont (unique Sales Order + Contract Account)'.
  WRITE: / '  - p_docdat: audat GE p_docdat (default 20150101)'.
  WRITE: / '  - Lookback: pastdate = keydate - p_month months (default 14 months)'.
  WRITE: / '  - UD1K936725 removed audat check from RTM4B (Log#0011).'.
  WRITE: / '============================================================'.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*& Report  Z_FUEL_SWITCH_VALIDATION - KEY FINDINGS vs RTM
*&---------------------------------------------------------------------*
* Program: ZISCS_MIGRATION_FUEL_SWITCH_M4
* Latest UD: UD1K936725 (24.04.2026)
* RTM Doc: TD-Fuel Switching-Extract & Cleanse-CUSTOMER-CUST_DM_CX_03 (page 879362238)
*
* Program UDs:
*   UD1K936291 (13.11.2025) - Document Date update
*   UD1K936295 (13.11.2025) - Document Date update
*   UD1K936303 (17.11.2025) - Code fixes
*   UD1K936318 (18.11.2025) - UD1K936318, Performance fix
*   UD1K936320 (19.11.2025) - UD1K936320, Performance fix
*   UD1K936334 (21.11.2025) - Range Dump fix
*   UD1K936354 (26.11.2025) - Count issue
*   UD1K936344 (28.11.2025) - Remove File & FKKVKP logic
*   UD1K936725 (24.04.2026) - RTM4 B update, remove AUDAT RTM4 B
*
* Rules Implemented:
*   RTM1: Business + material 98000001 + ec_no>0 + (B|C) + ec_update>=pastdate
*   RTM2: Business + material 98000000 + ci_no>0 + ((B|C) or (A+ci_status=7)) + ci_update>=pastdate
*   RTM3A: Business + material 98000000 + ci_no<2 + fksak=A + ci_status=1
*   RTM3B: Business + material 98000000 + ci_no<2 + ((B|C) or (A+ci_status=7)) + ci_update>=pastdate
*   RTM4A: Residential + material 98000000 + ci_no<2 + fksak=A + ci_status=1
*   RTM4B: Residential + material 98000000 + ci_no<2 + ci_status=7 + ci_update>=pastdate
*   (audat removed from RTM4B in UD1K936725)
*
* BUGS FOUND:
*
* 1. CRITICAL: lt_chunk never populated (process_batches)
*    In PERFORM process_batches, the code declares:
*      DATA lt_chunk TYPE STANDARD TABLE OF ty_stg_ca.
*    but never populates it before:
*      PERFORM perform_fuel_switching USING lt_chunk.
*    The PERFORM passes an empty table to the form.
*    Inside perform_fuel_switching, the SELECT on VBK D uses:
*      FOR ALL ENTRIES IN @lt_vbak
*      WHERE vbeln = @lt_vbak-vbeln.
*    The pt_chunk parameter is NOT actually used in the WHERE clause of
*    the VBK D SELECT (it's commented out: "vkont = @pt_chunk-vkont" is commented).
*    Impact: Low - pt_chunk filtering was already disabled in UD1K936344
*    (the FOR ALL ENTRIES uses lt_vbak instead). The lt_chunk being empty
*    has no effect on current logic, but it is dead code.
*
* 2. pt_chunk parameter not used in WHERE clause
*    In PERFORM perform_fuel_switching, the original pt_chunk-vkont filter
*    in the VBK D SELECT was commented out in UD1K936344.
*    Currently the SELECT is: FOR ALL ENTRIES IN @lt_vbak WHERE vbeln = @lt_vbak-vbeln.
*    This means ALL sales orders in lt_vbak are processed, not restricted
*    to the CA list in gt_stg_ca. This may be intentional for performance
*    but differs from earlier logic.
*
* 3. Missing date filter on ec_update_date in RTM1
*    The program checks ec_update_date GE gv_past_date for RTM1.
*    This is correct and matches the validation logic.
*
* 4. gt_stg_ca population when file not provided
*    When s_file is empty, gt_stg_ca is populated from s_vkont (selection
*    parameter for Contract Account). This is correct fallback logic.
*
*&---------------------------------------------------------------------*