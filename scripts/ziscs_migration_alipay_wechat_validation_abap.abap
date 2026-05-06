*&---------------------------------------------------------------------*
*& Report  ZISCS_MIGRATION_ALIPAY_WECHAT_VALIDATION
*& Validation report for ZISCS_MIGRATION_ALIPAY_WECHAT
*& Compare rule counts against source table data
*& ABAP 7.4 compatible version
*&---------------------------------------------------------------------*
REPORT ziscs_migration_alipay_wechat_validation NO STANDARD PAGE HEADING LINE-SIZE 120.

* Parameters
PARAMETERS: p_keydt  TYPE sy-datum DEFAULT sy-datum,
            p_month  TYPE t5a4a-dlymo DEFAULT 14,
            p_offic  TYPE zisfipaychansid-offic_ex OPTIONAL,
            p_vkont  TYPE zisfipaychansid-vkont OPTIONAL,
            p_subid  TYPE zisfipaychansid-zzsubid OPTIONAL,
            p_openid TYPE zisfipaychansid-zzopenid OPTIONAL,
            p_status TYPE zisfipaychansid-zzstatus_sid OPTIONAL.

* Variables
DATA: lv_keydate  TYPE sy-datum,
      lv_fromdate TYPE sy-datum,
      lv_rtm1     TYPE i,
      lv_rtm2     TYPE i,
      lv_total    TYPE i.

* Internal tables for deduplicated counts
TYPES: BEGIN OF ty_subid_vkont,
         zzsubid TYPE zisfipaychansid-zzsubid,
         vkont   TYPE zisfipaychansid-vkont,
       END OF ty_subid_vkont.

DATA: lt_all_combined TYPE STANDARD TABLE OF ty_subid_vkont.

START-OF-SELECTION.

* Key date logic
  IF p_keydt IS INITIAL.
    lv_keydate = sy-datum.
  ELSE.
    lv_keydate = p_keydt.
  ENDIF.

* Calculate (Current Date - N months)
  CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
    EXPORTING
      date      = lv_keydate
      days      = 0
      months    = p_month
      signum    = '-'
      years     = 0
    IMPORTING
      calc_date = lv_fromdate.

  WRITE: / '================================================================'.
  WRITE: / '   ZISCS_MIGRATION_ALIPAY_WECHAT - VALIDATION REPORT'.
  WRITE: / '================================================================'.
  WRITE: / 'Program:    ZISCS_MIGRATION_ALIPAY_WECHAT'.
  WRITE: / 'Author:     Tanya Bisht'.
  WRITE: / 'Key Date:   ', lv_keydate.
  WRITE: / 'From Date:  ', lv_fromdate, ' (keydate - p_month months)'.
  WRITE: / 'Lookback:   ', p_month, ' months'.
  WRITE: / 'Transport:  UD1K936507'.
  WRITE: / '================================================================'.
  SKIP.

*---------------------------------------------------------------------*
* RTM 1 - Active Subscription
*   Source: zisfipaychansid
*   Conditions:
*     - zzstatus_sid = 'A' (Active)
*     - offic_ex IN selection
*     - vkont IN selection
*     - zzsubid IN selection
*     - zzopenid IN selection
*     - zzstatus_sid IN selection
*     - b~auszdat >= lv_fromdate (EVER: contract end date in lookback)
*   Dedup: DISTINCT zzsubid + vkont (unique by Subscription ID & CA)
*---------------------------------------------------------------------*

  SELECT COUNT( DISTINCT a~zzsubid && a~vkont ) INTO lv_rtm1
    FROM zisfipaychansid AS a
    LEFT JOIN ever AS b
      ON a~vkont = b~vkonto
    WHERE a~zzstatus_sid = 'A'
      AND ( a~offic_ex = p_offic OR p_offic IS INITIAL )
      AND ( a~vkont = p_vkont OR p_vkont IS INITIAL )
      AND ( a~zzsubid = p_subid OR p_subid IS INITIAL )
      AND ( a~zzopenid = p_openid OR p_openid IS INITIAL )
      AND ( a~zzstatus_sid = p_status OR p_status IS INITIAL )
      AND b~auszdat >= lv_fromdate.

* Collect for deduplication
  SELECT DISTINCT a~zzsubid, a~vkont
    APPENDING TABLE lt_all_combined
    FROM zisfipaychansid AS a
    LEFT JOIN ever AS b
      ON a~vkont = b~vkonto
    WHERE a~zzstatus_sid = 'A'
      AND ( a~offic_ex = p_offic OR p_offic IS INITIAL )
      AND ( a~vkont = p_vkont OR p_vkont IS INITIAL )
      AND ( a~zzsubid = p_subid OR p_subid IS INITIAL )
      AND ( a~zzopenid = p_openid OR p_openid IS INITIAL )
      AND ( a~zzstatus_sid = p_status OR p_status IS INITIAL )
      AND b~auszdat >= lv_fromdate.

  WRITE: / 'RTM 1: Active Subscription'.
  WRITE: / '  Condition: zzstatus_sid = ''A'' AND ever~auszdat >= fromdate'.
  WRITE: / '  Logic: Subscription is active AND contract end date within lookback'.
  WRITE: / '  Count (SELECT DISTINCT zzsubid+''|''+vkont): ', lv_rtm1.
  SKIP.

*---------------------------------------------------------------------*
* RTM 2 - Inactive Subscription
*   Source: zisfipaychansid
*   Conditions:
*     - zzstatus_sid = 'I' (Inactive)
*     - zzchange_date >= lv_fromdate (change date within lookback)
*     - b~auszdat >= lv_fromdate (EVER: contract end date in lookback)
*     - offic_ex IN selection
*     - vkont IN selection
*     - zzsubid IN selection
*     - zzopenid IN selection
*     - zzstatus_sid IN selection
*   Dedup: DISTINCT zzsubid + vkont (unique by Subscription ID & CA)
*---------------------------------------------------------------------*

  SELECT COUNT( DISTINCT a~zzsubid && a~vkont ) INTO lv_rtm2
    FROM zisfipaychansid AS a
    LEFT JOIN ever AS b
      ON a~vkont = b~vkonto
    WHERE a~zzstatus_sid = 'I'
      AND a~zzchange_date >= lv_fromdate
      AND ( a~offic_ex = p_offic OR p_offic IS INITIAL )
      AND ( a~vkont = p_vkont OR p_vkont IS INITIAL )
      AND ( a~zzsubid = p_subid OR p_subid IS INITIAL )
      AND ( a~zzopenid = p_openid OR p_openid IS INITIAL )
      AND ( a~zzstatus_sid = p_status OR p_status IS INITIAL )
      AND b~auszdat >= lv_fromdate.

* Collect for deduplication
  SELECT DISTINCT a~zzsubid, a~vkont
    APPENDING TABLE lt_all_combined
    FROM zisfipaychansid AS a
    LEFT JOIN ever AS b
      ON a~vkont = b~vkonto
    WHERE a~zzstatus_sid = 'I'
      AND a~zzchange_date >= lv_fromdate
      AND ( a~offic_ex = p_offic OR p_offic IS INITIAL )
      AND ( a~vkont = p_vkont OR p_vkont IS INITIAL )
      AND ( a~zzsubid = p_subid OR p_subid IS INITIAL )
      AND ( a~zzopenid = p_openid OR p_openid IS INITIAL )
      AND ( a~zzstatus_sid = p_status OR p_status IS INITIAL )
      AND b~auszdat >= lv_fromdate.

  WRITE: / 'RTM 2: Inactive Subscription'.
  WRITE: / '  Condition: zzstatus_sid = ''I'' AND zzchange_date >= fromdate'.
  WRITE: / '           AND ever~auszdat >= fromdate'.
  WRITE: / '  Logic: Subscription is inactive AND change date within lookback'.
  WRITE: / '        AND contract end date within lookback'.
  WRITE: / '  Count (SELECT DISTINCT zzsubid+''|''+vkont): ', lv_rtm2.
  SKIP.

*---------------------------------------------------------------------*
* Calculate distinct total
*---------------------------------------------------------------------*
  SORT lt_all_combined BY zzsubid vkont.
  DELETE ADJACENT DUPLICATES FROM lt_all_combined COMPARING zzsubid vkont.
  DATA(lv_dist_total) = LINES( lt_all_combined ).

  lv_total = lv_rtm1 + lv_rtm2.

*---------------------------------------------------------------------*
* Summary
*---------------------------------------------------------------------*
  SKIP.
  WRITE: / '================================================================'.
  WRITE: / '                    SUMMARY'.
  WRITE: / '================================================================'.
  WRITE: / '                                          Count'.
  WRITE: / '-----------------------------------------------------------------'.
  WRITE: / 'RTM 1 (Active Subscription):    ', lv_rtm1 CENTERED(24).
  WRITE: / 'RTM 2 (Inactive Subscription):   ', lv_rtm2 CENTERED(24).
  WRITE: / '-----------------------------------------------------------------'.
  WRITE: / 'Sum (RTM1 + RTM2):              ', lv_total CENTERED(24).
  WRITE: / 'DISTINCT Total (dedup):          ', lv_dist_total CENTERED(24).
  WRITE: / '================================================================'.
  SKIP.
  WRITE: / 'NOTES:'.
  WRITE: / '  - Source table: ZISCS_PAYCHANSID (zisfipaychansid)'.
  WRITE: / '  - RTM 1 selects active subscriptions with contract end date'.
  WRITE: / '    within p_month lookback from key date.'.
  WRITE: / '  - RTM 2 selects inactive subscriptions with change date'.
  WRITE: / '    AND contract end date within p_month lookback.'.
  WRITE: / '  - Both rules dedup by zzsubid + vkont (Subscription ID + CA).'.
  WRITE: / '  - Selection screen filters (offic_ex, vkont, zzsubid, openid, status_sid)'.
  WRITE: / '    applied via optional parameters.'.
  WRITE: / '================================================================'.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*& Validation ABAP Key Findings
*&---------------------------------------------------------------------*
* Program: ZISCS_MIGRATION_ALIPAY_WECHAT
* Transport: UD1K936507 (18-Feb-2026)
* Author: Tanya Bisht
*
* RTM Rules Summary:
*   RTM 1: Active Subscription
*     - zzstatus_sid = 'A'
*     - ever~auszdat >= fromdate (keydate - p_month)
*   RTM 2: Inactive Subscription
*     - zzstatus_sid = 'I'
*     - zzchange_date >= fromdate
*     - ever~auszdat >= fromdate
*
* RTM Documentation Reference:
*   - TD-OIC-RealTime Payment Integration Alipay (741507092)
*   - TD-OIC-RealTime Payment Integration WeChat (741572610)
*   - TD CCS Payment Reconciliation Alipay INT368.3 (630292568)
*   - TD CCS Payment Reconciliation WeChat INT105.13.2 (631603202)
*
* BUGS IDENTIFIED:
*
*   1. LEFT JOIN with auszdat filter in WHERE clause
*      The program uses: LEFT JOIN ever ... WHERE b~auszdat >= @gv_fromdate
*      When using LEFT JOIN, conditions on the right table in the WHERE clause
*      convert it to an INNER JOIN effectively. This means records in
*      zisfipaychansid with no matching ever record will be excluded
*      even for RTM1 (Active Subscription).
*      FIX: Use INNER JOIN or add b~vkonto IS NOT NULL check.
*
*   2. RTM2 LEFT JOIN same issue
*      Same problem: LEFT JOIN ever ... WHERE b~auszdat >= @gv_fromdate
*      converts to INNER JOIN semantics. Inactive subscriptions with no
*      ever record will be excluded from RTM2 count.
*      FIX: Add AND b~vkonto IS NOT NULL before the date filter, or use INNER JOIN.
*
*   3. s_status selection applied to RTM1
*      RTM1 already hardcodes zzstatus_sid = 'A', but s_status selection
*      (which includes 'I' entries) is still applied.
*      This does NOT override the hardcoded = 'A' condition, so functionally
*      it has no effect. But confusing and should be removed from RTM1 WHERE.
*
*   4. export_csv path separator inconsistency
*      Line 103: lv_fullpath = |{ i_path }/{ lv_filename }| (forward slash)
*      Line 110: lv_fullpath = |{  i_path }\\{ lv_filename }| (backslash escaped)
*      This inconsistency may cause path issues depending on OS.
*      FIX: Use cl_bds_char=>replace( ) or CONDITION to use correct separator
*           based on OS, or always use '/'.
*
*   5. No error handling for OPEN DATASET failure
*      After CLOSE DATASET at line 96 (packet size exceeded), the subsequent
*      OPEN DATASET at line 99 does NOT check if the path directory exists.
*      If i_path directory is missing, this will fail.
*      FIX: Use SPLIT to verify path exists or CREATE TEXT OBJECT.
*
* CROSS-VALIDATION vs SA VALIDATION:
*   - SA program had similar LEFT JOIN bug (fixed in UD1K936190?)
*   - Alipay/WeChat program has NOT been updated to fix the LEFT JOIN issue.
*&---------------------------------------------------------------------*