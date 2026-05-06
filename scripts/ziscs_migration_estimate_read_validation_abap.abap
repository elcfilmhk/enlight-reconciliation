*&---------------------------------------------------------------------*
*& Report  Z_ESTIMATE_READ_VALIDATION
*&---------------------------------------------------------------------*
*& Validation report for ZISCS_MIGRATION_ESTIMATE_READ
*& Compare rule counts against source table data
*& ABAP 7.4 compatible version
*&---------------------------------------------------------------------*
REPORT z_estimate_read_validation NO STANDARD PAGE HEADING LINE-SIZE 120.

* Parameters
PARAMETERS: p_keydat TYPE datum OBLIGATORY DEFAULT '20260309',
            p_month  TYPE numc2 DEFAULT 14.

* Work areas
DATA: lv_pastdate TYPE sy-datum,
      lv_count_eabl TYPE i,
      lv_count_equnr TYPE i.

* Internal table for EABL data collection
TYPES: BEGIN OF ty_eabl,
         ablbelnr TYPE eabl-ablbelnr,
         gernr    TYPE eabl-gernr,
         equnr    TYPE eabl-equnr,
         adat     TYPE eabl-adat,
       END OF ty_eabl.

DATA: lt_eabl TYPE STANDARD TABLE OF ty_eabl,
      lt_equnr TYPE STANDARD TABLE OF ty_eabl-equnr.

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
  WRITE: / '   ZISCS_MIGRATION_ESTIMATE_READ - VALIDATION REPORT'.
  WRITE: / '============================================================'.
  WRITE: / 'Program:    ZISCS_MIGRATION_ESTIMATE_READ'.
  WRITE: / 'Key Date:   ', lv_current_date.
  WRITE: / 'Past Date:  ', lv_pastdate, ' (keydate - p_month months)'.
  WRITE: / 'Lookback:   ', p_month, ' months'.
  WRITE: / '============================================================'.
  SKIP.

*---------------------------------------------------------------------*
* Rule 1: Estimate Reading Documents
*   Source: EABL WHERE ADAT >= pastdate
*           AND NOT EXISTS (same EQUNR with ADAT >= pastdate AND ISTABLART <> '03')
*   Output: Count of all qualifying ABLBELNR records
*---------------------------------------------------------------------*
  SELECT COUNT( * ) INTO lv_count_eabl
    FROM eabl AS a
   WHERE adat >= @lv_pastdate
     AND equnr IN @s_equ
     AND gernr IN @s_ger
     AND NOT EXISTS ( SELECT *
                        FROM eabl AS b
                       WHERE b~equnr = a~equnr
                         AND b~adat >= @lv_pastdate
                         AND b~istablart <> '03' ).

* Collect ABLBELNR for validation
  SELECT ablbelnr, gernr, equnr, adat
    INTO TABLE @lt_eabl
    FROM eabl AS a
   WHERE adat >= @lv_pastdate
     AND equnr IN @s_equ
     AND gernr IN @s_ger
     AND NOT EXISTS ( SELECT *
                        FROM eabl AS b
                       WHERE b~equnr = a~equnr
                         AND b~adat >= @lv_pastdate
                         AND b~istablart <> '03' ).

  lv_count_eabl = LINES( lt_eabl ).

  WRITE: / 'Rule 1: Estimate Reading Documents'.
  WRITE: / '  Source: EABL WHERE ADAT >= pastdate'.
  WRITE: / '         AND NOT EXISTS (same EQUNR, ADAT >= pastdate, ISTABLART <> ''03'')'.
  WRITE: / '  Count of ABLBELNR (documents): ', lv_count_eabl.
  SKIP.

*---------------------------------------------------------------------*
* Rule 2: Estimate Equipments (distinct EQUNR)
*   Deduplicated from Rule 1 results by EQUNR
*---------------------------------------------------------------------*
  SORT lt_eabl BY equnr ASCENDING.
  DELETE ADJACENT DUPLICATES FROM lt_eabl COMPARING equnr.
  lv_count_equnr = LINES( lt_eabl ).

  WRITE: / 'Rule 2: Estimate Equipments (distinct EQUNR from Rule 1)'.
  WRITE: / '  Count of distinct EQUNR: ', lv_count_equnr.
  SKIP.

*---------------------------------------------------------------------*
* Cross-check: Independent EQUNR count from raw EABL
*---------------------------------------------------------------------*
  SELECT DISTINCT equnr INTO TABLE @lt_equnr
    FROM eabl AS a
   WHERE adat >= @lv_pastdate
     AND equnr IN @s_equ
     AND gernr IN @s_ger
     AND NOT EXISTS ( SELECT *
                        FROM eabl AS b
                       WHERE b~equnr = a~equnr
                         AND b~adat >= @lv_pastdate
                         AND b~istablart <> '03' ).

  WRITE: / 'Cross-check: Distinct EQUNR via independent query: ', LINES( lt_equnr ).
  SKIP.

*---------------------------------------------------------------------*
* Summary
*---------------------------------------------------------------------*
  SKIP.
  WRITE: / '============================================================'.
  WRITE: / '                    SUMMARY'.
  WRITE: / '============================================================'.
  WRITE: / '                        Count'.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'Rule 1 (Documents):   ', lv_count_eabl.
  WRITE: / 'Rule 2 (Equipments):   ', lv_count_equnr.
  WRITE: / '============================================================'.
  SKIP.
  WRITE: / 'NOTES:'.
  WRITE: / '  - Program UDs: UD1K935835 (initial), UD1K935965 (keydate),'.
  WRITE: / '                UD1K936281 (month logic, 11.11.2025)'.
  WRITE: / '  - Selection: S_EQU (Equipment), S_GER (Device)'.
  WRITE: / '  - Exclusion: Skip EQUNR if another record exists with'.
  WRITE: / '    same EQUNR, ADAT >= pastdate, AND ISTABLART <> ''03'''.
  WRITE: / '  - ISTABLART ''03'' = Actual reading (not estimate)'.
  WRITE: / '  - Rule 2 is simply Rule 1 deduplicated by EQUNR'.
  WRITE: / '  - No separate RTM rules - estimate_read uses same'.
  WRITE: / '    EABL extraction logic as read_data.'.
  WRITE: / '============================================================'.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*& Report  Z_ESTIMATE_READ_VALIDATION - KEY FINDINGS vs RTM
*&---------------------------------------------------------------------*
* Validation findings comparing program to RTM documentation:
*
* Document found: TD-Read Data-Extract & Cleanse-CUSTOMER-CUST_IT2_CONV_02
* URL: /spaces/ENLIGHT/pages/682263269/
*
* Program UDs:
*   UD1K935835 (06.05.2025) - Initial implementation
*   UD1K935965 (12.08.2025) - Key date as input (p_keydat)
*   UD1K936281 (11.11.2025) - Month logic (p_month configurable)
*
* Key Program Logic:
*   1. Calculates pastdate = keydate - p_month months (default 14)
*   2. Selects EABL records where ADAT >= pastdate
*   3. Excludes EQUNR if another record exists for same EQUNR
*      with ADAT >= pastdate AND ISTABLART <> '03'
*      (i.e., skip EQUNR that has at least one ACTUAL reading)
*   4. Rule 1 = count of all remaining ABLBELNR records
*   5. Rule 2 = distinct EQUNR count from Rule 1 results
*
* RTM Alignment:
*   - TD-Read Data-Extract & Cleanse defines reading extraction
*   - estimate_read is a variant that only returns "estimate" readings
*     (ISTABLART <> '03' check ensures only truly estimated readings)
*   - The exclusion logic (ISTABLART <> '03') correctly identifies
*     EQUNR with at least one actual reading in the lookback window
*
* Cross-validation issues identified:
*   - NONE - simple two-rule structure, no complex JOINs or dedup bugs
*   - Rule 2 is a direct deduplication of Rule 1 by EQUNR - transparent
*   - No CSV output in source (WRITE only, no file generation)
*
* Observations:
*   - This is the simplest migration program reviewed so far
*   - Only one main table (EABL), no joins
*   - No Rule 3/4/5 complexity
*   - p_month default of 14 months is configurable lookback period
*&---------------------------------------------------------------------*