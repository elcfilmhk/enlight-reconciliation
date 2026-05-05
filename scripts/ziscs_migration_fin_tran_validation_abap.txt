*&---------------------------------------------------------------------*
*& Report  Z_FIN_TRAN_VALIDATION
*&---------------------------------------------------------------------*
*& Validation report for ZISCS_MIGRATION_FIN_TRAN_M4
*& Compare rule counts against source table data
*& ABAP 7.4 compatible version
*&---------------------------------------------------------------------*
REPORT z_fin_tran_validation NO STANDARD PAGE HEADING LINE-SIZE 120.

* Parameters
PARAMETERS: p_keydat TYPE sy-datum DEFAULT '20260309'.

* Variables
DATA: lv_r1_count TYPE i,
      lv_r1_amount TYPE p DECIMALS 2,
      lv_r2_count TYPE i,
      lv_r2_amount TYPE p DECIMALS 2,
      lv_r1_distinct TYPE i,
      lv_r2_distinct TYPE i.

* Internal tables for deduplicated counts
TYPES: BEGIN OF ty_rtm1_key,
         opbel TYPE dfkkko-opbel,
         vkont TYPE dfkkop-vkont,
         vtref TYPE dfkkop-vtref,
         opupw TYPE opupw_kk,
         opupk TYPE opupk_kk,
         opupz TYPE opupz_kk,
       END OF ty_rtm1_key,
       BEGIN OF ty_rtm2_key,
         opbel TYPE dfkkko-opbel,
         vkont TYPE dfkkop-vkont,
         vtref TYPE dfkkop-vtref,
         opupw TYPE opupw_kk,
         opupk TYPE opupk_kk,
         opupz TYPE opupz_kk,
       END OF ty_rtm2_key,
       BEGIN OF ty_rtm2_full,
         opbel TYPE dfkkko-opbel,
         vkont TYPE dfkkop-vkont,
         vtref TYPE dfkkop-vtref,
         budat TYPE dfkkop-budat,
         augbd TYPE dfkkop-augbd,
         betrw TYPE dfkkop-betrw,
         opupw TYPE opupw_kk,
         opupk TYPE opupk_kk,
         opupz TYPE opupz_kk,
         rpnum TYPE fkk_instpln_head-rpnum,
         deadt TYPE fkk_instpln_head-deadt,
       END OF ty_rtm2_full.

DATA: lt_rtm1_keys TYPE STANDARD TABLE OF ty_rtm1_key,
      lt_rtm2_keys TYPE STANDARD TABLE OF ty_rtm2_key,
      lt_rtm2_raw  TYPE STANDARD TABLE OF ty_rtm2_full.

START-OF-SELECTION.

  DATA(lv_current_date) = p_keydat.
  IF lv_current_date IS INITIAL.
    lv_current_date = sy-datum.
  ENDIF.

  WRITE: / '============================================================'.
  WRITE: / '   ZISCS_MIGRATION_FIN_TRAN_M4 - VALIDATION REPORT'.
  WRITE: / '============================================================'.
  WRITE: / 'Program:    ZISCS_MIGRATION_FIN_TRAN_M4'.
  WRITE: / 'Key Date:  ', lv_current_date.
  WRITE: / 'RTM Doc:    TD-Financial Transaction (FT)-Extract & Cleanse'.
  WRITE: / '            906821764 (Transform & Load)'.
  WRITE: / '============================================================'.
  SKIP.

*&---------------------------------------------------------------------*
* RTM1: Open FICA Items (Non-Statistical + Statistical TP items)
*
* Program Logic (Log#0003 by AP88981 - UD1K936735):
*   ( a~bltyp <> '2' AND b~augst = '' AND ( b~xanza <> 'X' OR b~augrs <> '2' ) )
*        OR
*   ( a~bltyp = '2' AND b~augst = '' AND a~blart = 'TP' AND
*     ( ( b~hvorg = 'ZWOS' AND b~tvorg = '0010' ) OR
*       ( b~hvorg = 'ZWOF' AND b~tvorg = '0010' ) OR
*       ( b~hvorg = 'ZWOF' AND b~tvorg = '0020' ) ) )
*
* Key: opbel, vkont, vtref, opupw, opupk, opupz (dedup on item level)
* RTM label in program: 'RTM1'
*&---------------------------------------------------------------------*

  SELECT a~opbel,
         b~vkont,
         b~vtref,
         b~budat,
         b~augbd,
         b~betrw,
         b~opupw,
         b~opupk,
         b~opupz
    FROM dfkkko AS a
    LEFT JOIN dfkkop AS b ON a~opbel = b~opbel
    WHERE b~augbd <= @lv_current_date
      AND ( ( a~bltyp <> '2' AND b~augst = '' AND ( b~xanza <> 'X' OR b~augrs <> '2' ) ) )
    INTO TABLE @DATA(lt_rtm1_cond1).

  SELECT a~opbel,
         b~vkont,
         b~vtref,
         b~budat,
         b~augbd,
         b~betrw,
         b~opupw,
         b~opupk,
         b~opupz
    FROM dfkkko AS a
    LEFT JOIN dfkkop AS b ON a~opbel = b~opbel
    WHERE b~augbd <= @lv_current_date
      AND ( a~bltyp = '2' AND b~augst = '' AND a~blart = 'TP' AND
            ( ( b~hvorg = 'ZWOS' AND b~tvorg = '0010' ) OR
              ( b~hvorg = 'ZWOF' AND b~tvorg = '0010' ) OR
              ( b~hvorg = 'ZWOF' AND b~tvorg = '0020' ) ) )
    INTO TABLE @DATA(lt_rtm1_cond2).

* Combine and deduplicate RTM1
  APPEND LINES OF lt_rtm1_cond2 TO lt_rtm1_cond1.
  SORT lt_rtm1_cond1 BY opbel vkont vtref opupw opupk opupz.
  DELETE ADJACENT DUPLICATES FROM lt_rtm1_cond1
    COMPARING opbel vkont vtref opupw opupk opupz.

* Collect distinct keys
  SELECT DISTINCT opbel, vkont, vtref, opupw, opupk, opupz
    INTO TABLE lt_rtm1_keys
    FROM dfkkko AS a
    LEFT JOIN dfkkop AS b ON a~opbel = b~opbel
    WHERE b~augbd <= @lv_current_date
      AND ( ( a~bltyp <> '2' AND b~augst = '' AND ( b~xanza <> 'X' OR b~augrs <> '2' ) ) )
    INTO CORRESPONDING FIELDS OF TABLE @lt_rtm1_keys.

  SELECT DISTINCT opbel, vkont, vtref, opupw, opupk, opupz
    APPENDING TABLE lt_rtm1_keys
    FROM dfkkko AS a
    LEFT JOIN dfkkop AS b ON a~opbel = b~opbel
    WHERE b~augbd <= @lv_current_date
      AND ( a~bltyp = '2' AND b~augst = '' AND a~blart = 'TP' AND
            ( ( b~hvorg = 'ZWOS' AND b~tvorg = '0010' ) OR
              ( b~hvorg = 'ZWOF' AND b~tvorg = '0010' ) OR
              ( b~hvorg = 'ZWOF' AND b~tvorg = '0020' ) ) ).

  SORT lt_rtm1_keys BY opbel vkont vtref opupw opupk opupz.
  DELETE ADJACENT DUPLICATES FROM lt_rtm1_keys
    COMPARING opbel vkont vtref opupw opupk opupz.

  lv_r1_count = lines( lt_rtm1_keys ).

* Sum amounts from deduplicated rows
  LOOP AT lt_rtm1_cond1 INTO DATA(ls_r1).
    lv_r1_amount = lv_r1_amount + ls_r1-betrw.
  ENDLOOP.

  WRITE: / 'Rule RTM1: Open FICA Items (Non-Statistical + Statistical TP)'.
  WRITE: / '  Distinct Count (opbel+vkont+vtref+opupw+opupk+opupz): ', lv_r1_count.
  WRITE: / '  Total Amount: ', lv_r1_amount CURRENCY 'HKD'.
  SKIP.

*&---------------------------------------------------------------------*
* RTM2: Incomplete Billing Plan Items
*
* Program Logic (Log#0001 by TB88379):
*   dfkkko~blart = 'IP'
*   dfkkop~augst = ''
*   fkk_instpln_head~deadt = '00000000'
*
* Key: opbel, vkont, vtref, opupw, opupk, opupz (same dedup key as RTM1)
* RTM label in program: 'RTM2'
*&---------------------------------------------------------------------*

  SELECT dfkkko~opbel,
         dfkkop~vkont,
         dfkkop~vtref,
         dfkkop~budat,
         dfkkop~augbd,
         dfkkop~betrw,
         dfkkop~opupw,
         dfkkop~opupk,
         dfkkop~opupz,
         fkk_instpln_head~rpnum,
         fkk_instpln_head~deadt
    FROM dfkkko
    LEFT JOIN dfkkop ON dfkkko~opbel = dfkkop~opbel
    LEFT JOIN fkk_instpln_head ON dfkkko~opbel = fkk_instpln_head~rpnum
    WHERE dfkkko~blart = 'IP'
      AND dfkkop~augst = ''
      AND fkk_instpln_head~deadt = '00000000'
    INTO TABLE lt_rtm2_raw.

* Deduplicate by same key
  SORT lt_rtm2_raw BY opbel vkont vtref opupw opupk opupz.
  DELETE ADJACENT DUPLICATES FROM lt_rtm2_raw
    COMPARING opbel vkont vtref opupw opupk opupz.

* Collect distinct keys
  SELECT DISTINCT dfkkko~opbel AS opbel,
                  dfkkop~vkont AS vkont,
                  dfkkop~vtref AS vtref,
                  dfkkop~opupw AS opupw,
                  dfkkop~opupk AS opupk,
                  dfkkop~opupz AS opupz
    FROM dfkkko
    LEFT JOIN dfkkop ON dfkkko~opbel = dfkkop~opbel
    LEFT JOIN fkk_instpln_head ON dfkkko~opbel = fkk_instpln_head~rpnum
    WHERE dfkkko~blart = 'IP'
      AND dfkkop~augst = ''
      AND fkk_instpln_head~deadt = '00000000'
    INTO TABLE @lt_rtm2_keys.

  lv_r2_count = lines( lt_rtm2_keys ).

* Sum amounts
  LOOP AT lt_rtm2_raw INTO DATA(ls_r2).
    lv_r2_amount = lv_r2_amount + ls_r2-betrw.
  ENDLOOP.

  WRITE: / 'Rule RTM2: Incomplete Billing Plan Items (blart=IP, deadt=blank)'.
  WRITE: / '  Distinct Count (opbel+vkont+vtref+opupw+opupk+opupz): ', lv_r2_count.
  WRITE: / '  Total Amount: ', lv_r2_amount CURRENCY 'HKD'.
  SKIP.

*---------------------------------------------------------------------*
* Total (combined RTM1 + RTM2, deduped across both)
*---------------------------------------------------------------------*
  DATA: lt_all_keys TYPE STANDARD TABLE OF ty_rtm1_key.

  APPEND LINES OF lt_rtm1_keys TO lt_all_keys.
  APPEND LINES OF lt_rtm2_keys TO lt_all_keys.
  SORT lt_all_keys BY opbel vkont vtref opupw opupk opupz.
  DELETE ADJACENT DUPLICATES FROM lt_all_keys
    COMPARING opbel vkont vtref opupw opupk opupz.
  DATA(lv_total_count) = lines( lt_all_keys ).

  DATA(lv_total_amount) = lv_r1_amount + lv_r2_amount.

*---------------------------------------------------------------------*
* Summary
*---------------------------------------------------------------------*
  SKIP.
  WRITE: / '============================================================'.
  WRITE: / '                    SUMMARY'.
  WRITE: / '============================================================'.
  WRITE: / '                         Count            Amount (HKD)'.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'RTM1 (Open FICA Items): ', lv_r1_count CENTERED(20),
         lv_r1_amount CURRENCY 'HKD'.
  WRITE: / 'RTM2 (Incomplete BP):   ', lv_r2_count CENTERED(20),
         lv_r2_amount CURRENCY 'HKD'.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'Total (RTM1 + RTM2):    ', lv_total_count CENTERED(20),
         lv_total_amount CURRENCY 'HKD'.
  WRITE: / '============================================================'.
  SKIP.
  WRITE: / 'NOTES:'.
  WRITE: / '  - Program: ZISCS_MIGRATION_FIN_TRAN_M4 (UD1K936735)'.
  WRITE: / '  - RTM1 rule (Log#0003): Open items excluding statistical'.
  WRITE: / '    docs (bltyp<>2), plus TP statistical items with'.
  WRITE: / '    hvorg=ZWOS/ZWOF and specific tvorg codes (0010/0020).'.
  WRITE: / '  - RTM2 rule (Log#0001): Incomplete billing plans (blart=IP, deadt=00000000).'.
  WRITE: / '  - Dedup key: opbel+vkont+vtref+opupw+opupk+opupz (item level).'.
  WRITE: / '  - Key date (p_keydat) restricts augbd <= keydate.'.
  WRITE: / '  - UD1K936735 (27-Apr-2026): Fetch Non-Statistical and open'.
  WRITE: / '    items without Deposit/Statistical open TP with write in/off.'.
  WRITE: / '  - UD1K936703 (21-Apr-2026): Add Item fields to file.'.
  WRITE: / '  - UD1K936549 (10-Mar-2026): M3.5 and M4 changes.'.
  WRITE: / '============================================================'.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*& Report  Z_FIN_TRAN_VALIDATION - KEY FINDINGS vs RTM
*&---------------------------------------------------------------------*
* Validation findings comparing ZISCS_MIGRATION_FIN_TRAN_M4 to RTM:
*
* RTM Doc: TD-Financial Transaction (FT)-Extract & Cleanse
* URL: /spaces/ENLIGHT/pages/908820484/TD-Financial+Transaction-Transform+Load
* (Page 906821764 refers to the Transform & Load doc in docs.db)
*
* Program UDs (latest first):
*   UD1K936735 (27.04.2026) - Log#0003: Non-Statistical + open TP write-in/off
*   UD1K936703 (21.04.2026) - Log#0002: Add Item fields (opupw/opupk/opupz)
*   UD1K936549 (10.03.2026) - Log#0001: M3.5 and M4 changes
*   UD1K936190 (16.10.2025) - Initial version (implied)
*
* RTM Scope vs Program Implementation:
*
*   RTM Scope (Conversion Scope):
*     1. All Open Items / Receivables in CCMS FICA
*     2. NOT restricted to 14 months history
*     3. Exclude statistical FICA documents
*
*   Program Implementation:
*     - RTM1: Captures non-statistical open items (bltyp<>'2') with
*       augst='' and (xanza<>'X' OR augrs<>'2'), plus statistical TP
*       items (bltyp='2', blart='TP') with hvorg IN (ZWOS,ZWOF) and
*       specific tvorg codes (0010,0020). Restricted to augbd <= keydate.
*     - RTM2: Captures incomplete billing plans (blart='IP', deadt='00000000')
*       with augst=''.
*
* Observations:
*   1. The "Exclude statistical FICA documents" RTM requirement is
*      partially implemented - statistical docs ARE included when
*      bltyp='2' AND blart='TP' with specific hvorg/tvorg codes.
*      This is UD1K936735 logic (Log#0003).
*   2. The 14-month history restriction does NOT apply in the program
*      (augbd <= keydate only, no lower bound).
*   3. Item fields (opupw/opupk/opupz) added in UD1K936703 change
*      the dedup key from (opbel+vkont+vtref) to item-level.
*   4. Program selects augbd <= p_keydat (cleared posting date before keydate),
*      which differs from some other programs that use budat (posting date).
*&---------------------------------------------------------------------*
