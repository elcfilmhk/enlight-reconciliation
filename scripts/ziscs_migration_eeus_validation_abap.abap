*&---------------------------------------------------------------------*
*& Report  Z_EEUS_VALIDATION
*&---------------------------------------------------------------------*
*& Validation report for ZISCS_MIGRATION_EEUS
*& Compare rule counts against source table data
*& ABAP 7.4 compatible version
*&---------------------------------------------------------------------*
REPORT z_eeus_validation NO STANDARD PAGE HEADING LINE-SIZE 120.

* Parameters
PARAMETERS: p_keydat TYPE sy-datum DEFAULT '20260324',
            p_path   TYPE rlgrap-filename DEFAULT '/tmp'.

* Variables
DATA: gv_total TYPE i,
      gv_co    TYPE i,
      gv_ca    TYPE i,
      gv_17    TYPE i,
      gv_dist  TYPE i.

* Internal table for deduplication
TYPES: BEGIN OF ty_eeus_key,
         eeus_appln TYPE ziscs_eeus_hdr-eeus_appln,
         vkont      TYPE ziscs_eeus_hdr-vkont,
       END OF ty_eeus_key.

DATA: lt_all TYPE STANDARD TABLE OF ty_eeus_key.

START-OF-SELECTION.

  DATA(lv_current_date) = p_keydat.
  IF lv_current_date IS INITIAL.
    lv_current_date = sy-datum.
  ENDIF.

  WRITE: / '============================================================'.
  WRITE: / '   ZISCS_MIGRATION_EEUS - VALIDATION REPORT'.
  WRITE: / '============================================================'.
  WRITE: / 'Program:    ZISCS_MIGRATION_EEUS'.
  WRITE: / 'Key Date:   ', lv_current_date.
  WRITE: / 'UD:         UD1K936581 (Initial Implementation, 05.03.2026)'.
  WRITE: / 'RTM Doc:    TD-Electrical Equipment Upgrade Scheme (EEUS)'.
  WRITE: / '            Extract & Cleanse (page 1307869185)'.
  WRITE: / '============================================================'.
  SKIP.

*---------------------------------------------------------------------*
* EEUS Program Logic:
*   Table: ziscs_eeus_hdr
*   Filter: status IN ('CO', 'CA', '17')
*   Dedup:  eeus_appln + vkont (adjacent duplicates removed)
*   rtm_no hardcoded to 'RTM1' for all records
*---------------------------------------------------------------------*

  SELECT eeus_appln,
         vkont,
         status
    FROM ziscs_eeus_hdr
    WHERE status IN ('CO', 'CA', '17')
    INTO TABLE @DATA(lt_raw).

  IF sy-subrc <> 0.
    WRITE: / 'No data found in ziscs_eeus_hdr with status CO/CA/17.'.
    RETURN.
  ENDIF.

  SORT lt_raw BY eeus_appln vkont.
  DELETE ADJACENT DUPLICATES FROM lt_raw COMPARING eeus_appln vkont.

* Count by status
  CLEAR: gv_total, gv_co, gv_ca, gv_17.
  LOOP AT lt_raw INTO DATA(ls_raw).
    CASE ls_raw-status.
      WHEN 'CO'.
        gv_co = gv_co + 1.
      WHEN 'CA'.
        gv_ca = gv_ca + 1.
      WHEN '17'.
        gv_17 = gv_17 + 1.
    ENDCASE.

* Collect for distinct count
    APPEND VALUE #( eeus_appln = ls_raw-eeus_appln
                    vkont      = ls_raw-vkont ) TO lt_all.
  ENDLOOP.

  gv_total = gv_co + gv_ca + gv_17.

* Distinct count (same as total since dedup already applied)
  SORT lt_all BY eeus_appln vkont.
  DELETE ADJACENT DUPLICATES FROM lt_all COMPARING eeus_appln vkont.
  gv_dist = LINES( lt_all ).

  WRITE: / 'Rule RTM1: EEUS Applications by Status'.
  WRITE: / '  Completed (CO):        ', gv_co.
  WRITE: / '  Cancelled (CA):        ', gv_ca.
  WRITE: / '  Rebate Approved (17):   ', gv_17.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / '  Total (sum):            ', gv_total.
  WRITE: / '  Total (distinct key):   ', gv_dist.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / '  Raw rows selected:      ', lines( lt_raw ).
  SKIP.

*---------------------------------------------------------------------*
* Program Verification
*---------------------------------------------------------------------*
  DATA lv_match TYPE abap_bool.
  IF gv_total = gv_dist.
    WRITE: / 'VALIDATION: PASS - distinct count matches sum of rules'.
    lv_match = abap_true.
  ELSE.
    WRITE: / 'VALIDATION: WARN - distinct count differs from rule sum'.
    WRITE: / '             This may indicate duplicate eeus_appln+vkont combinations.'.
  ENDIF.
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
  WRITE: / 'Completed (CO):       ', gv_co.
  WRITE: / 'Cancelled (CA):       ', gv_ca.
  WRITE: / 'Rebate Approved (17):  ', gv_17.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'Total (sum):           ', gv_total.
  WRITE: / 'Distinct (dedup):      ', gv_dist.
  WRITE: / '============================================================'.
  SKIP.
  WRITE: / 'NOTES:'.
  WRITE: / '  - UD1K936581 is the only UD (initial implementation)'.
  WRITE: / '  - Program uses hardcoded rtm_no = ''RTM1'' for all records'.
  WRITE: / '  - Dedup key: eeus_appln + vkont (adjacent duplicates)'.
  WRITE: / '  - CSV output: EEUS Application ID;Contract Account;Status;RTM No.'.
  WRITE: / '  - No history lookback - all active CO/CA/17 records included'.
  WRITE: / '============================================================'.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*& Report  Z_EEUS_VALIDATION - ABAP KEY FINDINGS vs RTM
*&---------------------------------------------------------------------*
* Validation findings comparing program to RTM documentation:
*
* Document: TD-Electrical Equipment Upgrade Scheme (EEUS)-Extract & Cleanse
* URL page: 1307869185
*
* Program UDs:
*   UD1K936581 (05.03.2026) - Initial Implementation (Log#0000)
*
* Key observations:
*   1. Single rule only (RTM1) - counts by application status
*   2. No lookback period - all records with status CO/CA/17 included
*   3. Dedup on eeus_appln + vkont before CSV export
*   4. rtm_no hardcoded to 'RTM1' (not driven by actual RTM classification)
*   5. Only one UD - program has not been updated since initial release
*
* RTM Coverage:
*   - RTM1 (count by status) - IMPLEMENTED
*   - Additional RTM rules (if any) - NOT FOUND in current program version
*
* Comparison vs SA validation:
*   - SA has 4 rules (rule3 removed by UD1K936697)
*   - EEUS has 1 rule (RTM1 status counts)
*   - EEUS has no configurable lookback
*   - EEUS uses adjacent duplicates dedup (simpler than SA's full dedup tables)
&---------------------------------------------------------------------*