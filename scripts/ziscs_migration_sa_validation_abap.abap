*&---------------------------------------------------------------------*
*& Report  Z_SA_VALIDATION
*&---------------------------------------------------------------------*
*& Validation report for ZISCS_MIGRATION_SA (mock4)
*& Compare rule counts against source table data
*& ABAP 7.4 compatible version
*&---------------------------------------------------------------------*
REPORT z_sa_validation NO STANDARD PAGE HEADING LINE-SIZE 120.

* Parameters
PARAMETERS: p_keydat TYPE datum DEFAULT '20260309',
            p_month  TYPE numc2 DEFAULT 14.

* Variables
DATA: lv_pastdate      TYPE sy-datum,
      lv_r1_sa TYPE p,
      lv_r1_ca TYPE p,
      lv_r2_sa TYPE p,
      lv_r2_ca TYPE p,
      lv_r4_sa TYPE p,
      lv_r4_ca TYPE p,
      lv_total_sa TYPE p,
      lv_total_ca TYPE p,
      lv_dist_sa TYPE p,
      lv_dist_ca TYPE p.

* Internal tables for deduplicated counts
TYPES: BEGIN OF ty_vertrag,
         vertrag TYPE ever-vertrag,
       END OF ty_vertrag,
       BEGIN OF ty_vkont,
         vkont TYPE fkkvkp-vkont,
       END OF ty_vkont.

DATA: lt_all_sa TYPE STANDARD TABLE OF ty_vertrag,
      lt_all_ca TYPE STANDARD TABLE OF ty_vkont.

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
  WRITE: / '   ZISCS_MIGRATION_SA - VALIDATION REPORT'.
  WRITE: / '============================================================'.
  WRITE: / 'Program:    ZISCS_MIGRATION_SA_MOCK4'.
  WRITE: / 'Key Date:   ', lv_current_date.
  WRITE: / 'Past Date:  ', lv_pastdate, ' (keydate - p_month months)'.
  WRITE: / 'Lookback:   ', p_month, ' months (was 24 in old version)'.
  WRITE: / '============================================================'.
  SKIP.

*---------------------------------------------------------------------*
* Rule 1: Active Contracts
*   Source: ever WHERE auszdat > keydate
*   SA (vertrag) dedup + CA (vkont) dedup
*---------------------------------------------------------------------*
  SELECT COUNT( DISTINCT ever~vertrag ) INTO lv_r1_sa
    FROM ever
    WHERE ever~auszdat > lv_current_date
      AND ever~vkonto IN ( SELECT vkont FROM fkkvkp ).

  SELECT COUNT( DISTINCT ever~vkonto ) INTO lv_r1_ca
    FROM ever
    WHERE ever~auszdat > lv_current_date.

* Collect for deduplication
  SELECT DISTINCT ever~vertrag AS vertrag INTO TABLE lt_all_sa
    FROM ever
    WHERE ever~auszdat > lv_current_date
      AND ever~vkonto IN ( SELECT vkont FROM fkkvkp ).

  SELECT DISTINCT ever~vkonto AS vkont INTO TABLE lt_all_ca
    FROM ever
    WHERE ever~auszdat > lv_current_date.

  WRITE: / 'Rule 1: Active Contracts (auszdat > keydate)'.
  WRITE: / '  SA Count (distinct vertrag): ', lv_r1_sa.
  WRITE: / '  CA Count (distinct vkonto):  ', lv_r1_ca.
  SKIP.

*---------------------------------------------------------------------*
* Rule 2: Inactive Contracts for lookback period
*   Source: ever WHERE auszdat <= keydate AND auszdat >= pastdate
*   Note: UD1K936190 changed from 2yr fixed to p_month configurable
*---------------------------------------------------------------------*
  SELECT COUNT( DISTINCT ever~vertrag ) INTO lv_r2_sa
    FROM ever
    WHERE ever~auszdat <= lv_current_date
      AND ever~auszdat >= lv_pastdate
      AND ever~vkonto IN ( SELECT vkont FROM fkkvkp ).

  SELECT COUNT( DISTINCT ever~vkonto ) INTO lv_r2_ca
    FROM ever
    WHERE ever~auszdat <= lv_current_date
      AND ever~auszdat >= lv_pastdate.

* Collect for deduplication
  SELECT DISTINCT ever~vertrag AS vertrag APPENDING TABLE lt_all_sa
    FROM ever
    WHERE ever~auszdat <= lv_current_date
      AND ever~auszdat >= lv_pastdate
      AND ever~vkonto IN ( SELECT vkont FROM fkkvkp ).

  SELECT DISTINCT ever~vkonto AS vkont APPENDING TABLE lt_all_ca
    FROM ever
    WHERE ever~auszdat <= lv_current_date
      AND ever~auszdat >= lv_pastdate.

  WRITE: / 'Rule 2: Inactive Contracts (auszdat <= keydate AND >= pastdate)'.
  WRITE: / '  SA Count (distinct vertrag): ', lv_r2_sa.
  WRITE: / '  CA Count (distinct vkonto):  ', lv_r2_ca.
  SKIP.

*---------------------------------------------------------------------*
* Rule 3: Write-off / Write-in Transactions
*   Status: REMOVED by UD1K936697 (Log#0005, 28.04.2026)
*   Was: hvorg IN ('0630','ZWOF','ZWOS') AND (augst = ' ' OR augst = '9')
*   Original f_get_rul3 is now commented out in source
*---------------------------------------------------------------------*
  WRITE: / 'Rule 3: Write-off / Write-in Transactions'.
  WRITE: / '  Status: REMOVED (UD1K936697, 28.04.2026)'.
  WRITE: / '  Was: hvorg IN (0630, ZWOF, ZWOS) AND (augst = space OR 9)'.
  lv_r4_sa = 0.
  lv_r4_ca = 0.
  SKIP.

*---------------------------------------------------------------------*
* Rule 4: Outstanding Balance
*   Source: dfkkop WHERE augst = ' ' AND augrs <> '2'
*   Joined with ever + fkkvkp for vkont filter
*---------------------------------------------------------------------*
  SELECT COUNT( DISTINCT dfkkop~vkont ) INTO lv_r4_ca
    FROM dfkkop
    INNER JOIN ever ON dfkkop~vkont = ever~vkonto
    INNER JOIN fkkvkp ON dfkkop~vkont = fkkvkp~vkont
    WHERE dfkkop~augst = ' '
      AND dfkkop~augrs <> '2'.

* For SA - need vertrag from ever
  SELECT COUNT( DISTINCT ever~vertrag ) INTO lv_r4_sa
    FROM dfkkop
    INNER JOIN ever ON dfkkop~vkont = ever~vkonto
    INNER JOIN fkkvkp ON dfkkop~vkont = fkkvkp~vkont
    WHERE dfkkop~augst = ' '
      AND dfkkop~augrs <> '2'.

* Collect for deduplication
  SELECT DISTINCT dfkkop~vkont AS vkont APPENDING TABLE lt_all_ca
    FROM dfkkop
    INNER JOIN ever ON dfkkop~vkont = ever~vkonto
    INNER JOIN fkkvkp ON dfkkop~vkont = fkkvkp~vkont
    WHERE dfkkop~augst = ' '
      AND dfkkop~augrs <> '2'.

  SELECT DISTINCT ever~vertrag AS vertrag APPENDING TABLE lt_all_sa
    FROM dfkkop
    INNER JOIN ever ON dfkkop~vkont = ever~vkonto
    INNER JOIN fkkvkp ON dfkkop~vkont = fkkvkp~vkont
    WHERE dfkkop~augst = ' '
      AND dfkkop~augrs <> '2'.

  WRITE: / 'Rule 4: Outstanding Balance (augst = space, augrs <> 2)'.
  WRITE: / '  SA Count (distinct vertrag): ', lv_r4_sa.
  WRITE: / '  CA Count (distinct vkonto):  ', lv_r4_ca.
  SKIP.

*---------------------------------------------------------------------*
* Calculate distinct totals
*---------------------------------------------------------------------*
  SORT lt_all_sa BY vertrag.
  DELETE ADJACENT DUPLICATES FROM lt_all_sa COMPARING vertrag.
  lv_dist_sa = LINES( lt_all_sa ).

  SORT lt_all_ca BY vkont.
  DELETE ADJACENT DUPLICATES FROM lt_all_ca COMPARING vkont.
  lv_dist_ca = LINES( lt_all_ca ).

* Sum of rule counts
  lv_total_sa = lv_r1_sa + lv_r2_sa + lv_r4_sa.
  lv_total_ca = lv_r1_ca + lv_r2_ca + lv_r4_ca.

*---------------------------------------------------------------------*
* Summary
*---------------------------------------------------------------------*
  SKIP.
  WRITE: / '============================================================'.
  WRITE: / '                    SUMMARY'.
  WRITE: / '============================================================'.
  WRITE: / '                        SA (Contracts)    CA (Contract Accts)'.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'Rule 1 (Active):      ', lv_r1_sa CENTERED(20), lv_r1_ca.
  WRITE: / 'Rule 2 (Inactive):    ', lv_r2_sa CENTERED(20), lv_r2_ca.
  WRITE: / 'Rule 3 (Write-off):   REMOVED (UD1K936697)'.
  WRITE: / 'Rule 4 (Outstanding):  ', lv_r4_sa CENTERED(20), lv_r4_ca.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'Sum (rules 1+2+4):    ', lv_total_sa CENTERED(20), lv_total_ca.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'DISTINCT (dedup):     ', lv_dist_sa CENTERED(20), lv_dist_ca.
  WRITE: / '============================================================'.
  SKIP.
  WRITE: / 'NOTES:'.
  WRITE: / '  - Rule 3 removed in UD1K936697 (28-Apr-2026)'.
  WRITE: / '  - Lookback period is p_month (default 14 months)'.
  WRITE: / '  - Old version used fixed 24-month lookback.'.
  WRITE: / '  - Selection screen S_VKO (contract account filter) not'.
  WRITE: / '    applied in this standalone validation (run with auth).'.
  WRITE: / '============================================================'.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*& Report  Z_SA_VALIDATION - ABAP KEY FINDINGS vs RTM
*&---------------------------------------------------------------------*
* Validation findings comparing program to RTM documentation:
*
* Document found: TD-SA Deposit-Transform&Load-CUSTOMER-CUST_IT4_CONV_04
* URL: /spaces/ENLIGHT/pages/958595075/
*
* Program UDs:
*   UD1K935861 (22.05.2025) - Initial version
*   UD1K935965 (12.08.2025) - Key date as input
*   UD1K935973 (15.08.2025) - New file output
*   UD1K936120 (23.09.2025) - Rule 3rd/4th correction
*   UD1K936122 (23.09.2025) - Rule correction follow-up
*   UD1K936190 (16.10.2025) - Current date logic, lookback configurable
*   UD1K936697 (28.04.2026) - Rule 3 removal
*
* Key deviations from original rules:
*   1. Rule 3 (write-off/write-in) REMOVED in UD1K936697
*   2. Lookback changed from fixed 24 months to configurable p_month (default 14)
*   3. Key date changed from sy-datum to p_keydat parameter
*
* Cross-validation issues identified:
*   - F_WRTIE_COUNT has copy-paste bug: rule 2 and rule 4
*     assign lw_rule1-vkonto instead of their own vkonto
*   - gt_rule4_ca populated from gt_rule1_ca (LOOP AT gt_rule1_ca
*     for both rule1 AND rule4 dedup tables)
*   - lit_vkont collected from gt_rule1_ca twice (rules 1 and 4)
*   - CSV output uses same counter lv_counter for file splitting
*     but resets only when packet size exceeded
*&---------------------------------------------------------------------*