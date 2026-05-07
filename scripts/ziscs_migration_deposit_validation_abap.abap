*&---------------------------------------------------------------------*
*& Report  Z_DEPOSIT_VALIDATION
*&---------------------------------------------------------------------*
*& Validation report for ZISCS_MIGRATION_DEPOSIT_MOCK4 (UD1K936447)
*& Compare rule counts against source table data
*& ABAP 7.4 compatible version
*&---------------------------------------------------------------------*
REPORT z_deposit_validation NO STANDARD PAGE HEADING LINE-SIZE 120.

* Parameters
PARAMETERS: p_keydat TYPE sy-datum DEFAULT '20251027',
            p_month  TYPE numc2 DEFAULT 14.

* Variables
DATA: gv_key_date TYPE p0001-begda.
DATA: lv_count_r1 TYPE p,
      lv_count_r2 TYPE p,
      lv_count_r3 TYPE p.

* Internal tables for deduplication
TYPES: BEGIN OF ty_deposit,
         security TYPE fkk_sec-security,
         vtref    TYPE fkk_sec_c-vtref,
       END OF ty_deposit.

DATA: lt_r1_dedup TYPE STANDARD TABLE OF ty_deposit,
      lt_r2_dedup TYPE STANDARD TABLE OF ty_deposit,
      lt_r3_dedup TYPE STANDARD TABLE OF ty_deposit.

* Temp table for downpayment check (RTM1 post-processing)
TYPES: BEGIN OF ty_dfkkop,
         augbl TYPE dfkkop-augbl,
         opbel TYPE dfkkop-opbel,
         xanza TYPE dfkkop-xanza,
         augrs TYPE dfkkop-augrs,
       END OF ty_dfkkop.
DATA: lt_dnpayment TYPE STANDARD TABLE OF ty_dfkkop,
      lt_dnpay_h   TYPE HASHED TABLE OF ty_dfkkop WITH UNIQUE KEY opbel.

START-OF-SELECTION.

* Calculate key date (pastdate = keydat - p_month)
  CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
    EXPORTING
      date      = p_keydat
      days      = 0
      months    = p_month
      signum    = '-'
      years     = 0
    IMPORTING
      calc_date = gv_key_date.

  WRITE: / '============================================================'.
  WRITE: / '   ZISCS_MIGRATION_DEPOSIT_MOCK4 - VALIDATION REPORT'.
  WRITE: / '============================================================'.
  WRITE: / 'Key Date:     ', p_keydat.
  WRITE: / 'Past Date:    ', gv_key_date.
  WRITE: / 'Lookback:     ', p_month, ' months'.
  WRITE: / '============================================================'.
  SKIP.

*============================================================
* RTM1: Deposits WITH Clearing Document (non-reversed)
* - fkk_sec LEFT JOIN fkk_sec_c LEFT JOIN dfkkop
* - xanza = 'X', stakz = 'H', non_cash = space
* - sec_return = '00000000'
* - x_sec_rev = space OR (x_sec_rev = 'X' AND rev_reason = '')
* - augbl IS NOT INITIAL
* - Post-process: check downpayment link, clear augbl if no match
* - Dedup: security + vtref
*============================================================

  WRITE: / '--- RTM1: DEPOSITS WITH CLEARING DOCUMENT ---'.

* Get deposits with clearing doc (base selection)
  SELECT fkk~security,
         fkk_c~vtref,
         fkk~vkont,
         fkk~sec_return,
         fkk~x_sec_rev,
         dfk~augbl,
         dfk~opbel,
         dfk~stakz,
         dfk~xanza
    FROM fkk_sec AS fkk
    LEFT JOIN fkk_sec_c AS fkk_c ON fkk~security = fkk_c~security
    LEFT JOIN dfkkop AS dfk ON fkk~opbel = dfk~opbel
    WHERE fkk~vkont IN @s_vkont
      AND fkk~security IN @s_sec
      AND dfk~xanza = @abap_true
      AND dfk~stakz = 'H'
      AND fkk~non_cash = @space
      AND fkk~sec_return = '00000000'
      AND ( fkk~x_sec_rev = @space OR fkk~x_sec_rev = 'X' )
      AND dfk~augbl IS NOT NULL
    INTO TABLE @DATA(lt_rtm1_base).

* Build temp table of opbel with augbl IS NOT INITIAL (for RTM2 dedup check)
  SELECT opbel
    FROM dfkkop
    WHERE augbl IS NOT NULL
    INTO TABLE @DATA(lt_opbel_with_augbl).
  SORT lt_opbel_with_augbl BY opbel.
  DELETE ADJACENT DUPLICATES FROM lt_opbel_with_augbl COMPARING opbel.

* Apply Log#0006: rev_reason must be space for RTM1 (only apply to rows with x_sec_rev = 'X')
* Note: RTM1/RTM2 both check rev_reason = '', RTM3 does not (has its own x_sec_rev = 'X' condition)
  DELETE lt_rtm1_base WHERE x_sec_rev = 'X' AND sec_return <> '00000000'.
  DELETE lt_rtm1_base WHERE x_sec_rev = 'X' AND rev_reason IS NOT NULL AND rev_reason <> ''. "placeholder for rev_reason

* RTM1 post-process: check downpayment link
  IF lt_rtm1_base IS NOT INITIAL.
*   Get dfkkop records where opbel matches the augbl from RTM1 base records (downpayment check)
    SELECT augbl, opbel, xanza, augrs
      FROM dfkkop
      FOR ALL ENTRIES IN @lt_rtm1_base
      WHERE opbel = @lt_rtm1_base-augbl
        AND xanza = 'X'
        AND augrs = '2'
      INTO TABLE @lt_dnpayment.

    SORT lt_dnpayment BY opbel.
    DELETE ADJACENT DUPLICATES FROM lt_dnpayment COMPARING opbel.
    lt_dnpay_h = lt_dnpayment[].

*   Clear augbl if no downpayment match found
    LOOP AT lt_rtm1_base ASSIGNING FIELD-SYMBOL(<fs_r1>).
      READ TABLE lt_dnpay_h WITH KEY opbel = <fs_r1>-augbl TRANSPORTING NO FIELDS.
      IF sy-subrc NE 0.
        CLEAR <fs_r1>-augbl.  "Mark for deletion (no downpayment link)
      ENDIF.
    ENDLOOP.

*   Delete records where augbl was cleared
    DELETE lt_rtm1_base WHERE augbl IS INITIAL.
  ENDIF.

* Dedup: security + vtref
  lt_r1_dedup = VALUE #( FOR wa IN lt_rtm1_base ( security = wa-security vtref = wa-vtref ) ).
  SORT lt_r1_dedup BY security vtref.
  DELETE ADJACENT DUPLICATES FROM lt_r1_dedup COMPARING security vtref.
  lv_count_r1 = LINES( lt_r1_dedup ).

  WRITE: / '  RTM1 Count (dedup security+vtref):', lv_count_r1.
  WRITE: / '  (Base records before dedup):        ', lines( lt_rtm1_base ).
  SKIP.

*============================================================
* RTM2: Deposits WITHOUT Clearing Document
* - Same source tables
* - augbl IS INITIAL (no clearing doc)
* - opbel should NOT exist in augbl set of dfkkop (not part of a cleared payment)
* - x_sec_rev NE 'X' OR rev_reason = ''
* - Dedup: security + vtref
*============================================================

  WRITE: / '--- RTM2: DEPOSITS WITHOUT CLEARING DOCUMENT ---'.

  SELECT fkk~security,
         fkk_c~vtref,
         fkk~vkont,
         fkk~sec_return,
         fkk~x_sec_rev,
         dfk~opbel,
         dfk~stakz,
         dfk~xanza
    FROM fkk_sec AS fkk
    LEFT JOIN fkk_sec_c AS fkk_c ON fkk~security = fkk_c~security
    LEFT JOIN dfkkop AS dfk ON fkk~opbel = dfk~opbel
    WHERE fkk~vkont IN @s_vkont
      AND fkk~security IN @s_sec
      AND dfk~xanza = @abap_true
      AND dfk~stakz = 'H'
      AND fkk~non_cash = @space
      AND fkk~sec_return = '00000000'
      AND ( fkk~x_sec_rev = @space OR fkk~x_sec_rev = 'X' )
      AND dfk~augbl IS NULL
    INTO TABLE @DATA(lt_rtm2_base).

* Apply Log#0006: rev_reason must be space
  DELETE lt_rtm2_base WHERE x_sec_rev = 'X' AND rev_reason IS NOT NULL AND rev_reason <> ''.

* Filter: opbel should NOT exist in lt_opbel_with_augbl (not part of cleared payment)
  DELETE lt_rtm2_base WHERE opbel IN lt_opbel_with_augbl.

* Dedup: security + vtref
  lt_r2_dedup = VALUE #( FOR wa IN lt_rtm2_base ( security = wa-security vtref = wa-vtref ) ).
  SORT lt_r2_dedup BY security vtref.
  DELETE ADJACENT DUPLICATES FROM lt_r2_dedup COMPARING security vtref.
  lv_count_r2 = LINES( lt_r2_dedup ).

  WRITE: / '  RTM2 Count (dedup security+vtref):', lv_count_r2.
  WRITE: / '  (Base records before dedup):        ', lines( lt_rtm2_base ).
  SKIP.

*============================================================
* RTM3: Reversed Deposits (cleared then reversed)
* - Same source tables
* - augbd GE gv_key_date (clearing date within lookback)
* - x_sec_rev = 'X'
* - rev_reason = '' (Log#0006)
* - Dedup: security + vtref
*============================================================

  WRITE: / '--- RTM3: REVERSED DEPOSITS ---'.

  SELECT fkk~security,
         fkk_c~vtref,
         fkk~vkont,
         fkk~sec_return,
         fkk~x_sec_rev,
         dfk~augbd,
         dfk~opbel,
         dfk~stakz,
         dfk~xanza
    FROM fkk_sec AS fkk
    LEFT JOIN fkk_sec_c AS fkk_c ON fkk~security = fkk_c~security
    LEFT JOIN dfkkop AS dfk ON fkk~opbel = dfk~opbel
    WHERE fkk~vkont IN @s_vkont
      AND fkk~security IN @s_sec
      AND dfk~xanza = @abap_true
      AND dfk~stakz = 'H'
      AND fkk~non_cash = @space
      AND fkk~sec_return = '00000000'
      AND fkk~x_sec_rev = 'X'
      AND dfk~augbd >= @gv_key_date
    INTO TABLE @DATA(lt_rtm3_base).

* Apply Log#0006: rev_reason must be space
  DELETE lt_rtm3_base WHERE rev_reason IS NOT NULL AND rev_reason <> ''.  "placeholder for rev_reason

* Dedup: security + vtref
  lt_r3_dedup = VALUE #( FOR wa IN lt_rtm3_base ( security = wa-security vtref = wa-vtref ) ).
  SORT lt_r3_dedup BY security vtref.
  DELETE ADJACENT DUPLICATES FROM lt_r3_dedup COMPARING security vtref.
  lv_count_r3 = LINES( lt_r3_dedup ).

  WRITE: / '  RTM3 Count (dedup security+vtref):', lv_count_r3.
  WRITE: / '  (Base records before dedup):        ', lines( lt_rtm3_base ).
  SKIP.

*============================================================
* SUMMARY
*============================================================

  DATA: lv_total TYPE p.
  lv_total = lv_count_r1 + lv_count_r2 + lv_count_r3.

  SKIP.
  WRITE: / '============================================================'.
  WRITE: / '                    SUMMARY'.
  WRITE: / '============================================================'.
  WRITE: / 'RTM1 (Deposits with Clearing Doc): ', lv_count_r1.
  WRITE: / 'RTM2 (Deposits without Clearing):  ', lv_count_r2.
  WRITE: / 'RTM3 (Reversed Deposits):          ', lv_count_r3.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'TOTAL (distinct security+vtref):   ', lv_total.
  WRITE: / '============================================================'.
  WRITE: / 'Note: Dedup key = security + vtref (per program logic)'.
  WRITE: / '      RTM1 excludes deposits without downpayment link.'.
  WRITE: / '============================================================'.

END-OF-SELECTION.

*Text elements
*----------------------------------------------------------
* 001 Total count of Deposit for RTM1
* 002 Total Amount for RTM1
* 003 Total count of Deposit for RTM2
* 004 Total Amount for RTM2
* 005 Total count of Deposit for RTM3
* 006 Total Amount for RTM3

*Selection texts
*----------------------------------------------------------
* P_KEYDAT         Keydate
* P_MONTH          No of Months
* S_SEC            Security
* S_VKONT          Contract Account