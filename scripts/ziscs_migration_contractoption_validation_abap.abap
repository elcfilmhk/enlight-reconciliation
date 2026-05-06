*&---------------------------------------------------------------------*
*& Report  Z_CO_VALIDATION
*&---------------------------------------------------------------------*
*& Validation report for ZISCS_MIGRATION_CONTRACTOPTION
*& Compare rule counts against source table data
*& ABAP 7.4 compatible version
*&---------------------------------------------------------------------*
REPORT z_co_validation NO STANDARD PAGE HEADING LINE-SIZE 120.

* Parameters
PARAMETERS: p_keydat TYPE datum DEFAULT '20260309'.

* Constants
CONSTANTS: lc_date_2yr TYPE sy-datum VALUE '20240101'.

* Variables
DATA: lv_ci_active        TYPE p,
      lv_ci_inactive      TYPE p,
      lv_ci_completed     TYPE p,
      lv_ci_cancelled     TYPE p,
      lv_ssr_active       TYPE p,
      lv_ssr_cust         TYPE p,
      lv_ssr_notreq       TYPE p,
      lv_ssr_completed    TYPE p,
      lv_ssr_cancelled    TYPE p.

* Internal tables
TYPES: BEGIN OF ty_ci,
         drcustno TYPE zzadr_custno,
         refca    TYPE vkont_kk,
       END OF ty_ci.

DATA: lt_ci_active_all TYPE STANDARD TABLE OF ty_ci,
      lt_ci_inactive_all TYPE STANDARD TABLE OF ty_ci,
      lt_ci_completed_all TYPE STANDARD TABLE OF ty_ci,
      lt_ci_cancelled_all TYPE STANDARD TABLE OF ty_ci.

START-OF-SELECTION.

  DATA(lv_current_date) = p_keydat.
  IF lv_current_date IS INITIAL.
    lv_current_date = sy-datum.
  ENDIF.

  WRITE: / '============================================================'.
  WRITE: / '   ZISCS_MIGRATION_CONTRACTOPTION - VALIDATION REPORT'.
  WRITE: / '============================================================'.
  WRITE: / 'Program:    ZISCS_MIGRATION_CONTRACTOPTION'.
  WRITE: / 'Key Date:   ', lv_current_date.
  WRITE: / '2yr Date:   ', lc_date_2yr, ' (fixed lookback)'.
  WRITE: / '============================================================'.
  SKIP.

*=====================================================================*
* C&I RTM 1 - ACTIVE C&I Program Enrollment
*   Table: zisdmadrdrcusttp
*   Condition: agreement_exp_dt >= p_keydat
*   Deduplication: DISTINCT drcustno, refca
*=====================================================================*
  SELECT COUNT( DISTINCT drcustno || refca ) INTO lv_ci_active
    FROM zisdmadrdrcusttp
    WHERE agreement_exp_dt >= lv_current_date.

  SELECT DISTINCT drcustno AS drcustno, refca AS refca
    INTO TABLE lt_ci_active_all
    FROM zisdmadrdrcusttp
    WHERE agreement_exp_dt >= lv_current_date.

  WRITE: / 'C&I RTM 1 - ACTIVE C&I Program Enrollment'.
  WRITE: / '  Table:      zisdmadrdrcusttp'.
  WRITE: / '  Condition:  agreement_exp_dt >= p_keydat'.
  WRITE: / '  Count:      ', lv_ci_active.
  SKIP.

*=====================================================================*
* C&I RTM 2 - INACTIVE C&I Program Enrollment (2 years history)
*   Table: zisdmadrdrcusttp
*   Condition: agreement_exp_dt < p_keydat AND agreement_exp_dt >= '20240101'
*   Deduplication: DISTINCT drcustno, refca
*=====================================================================*
  SELECT COUNT( DISTINCT drcustno || refca ) INTO lv_ci_inactive
    FROM zisdmadrdrcusttp
    WHERE agreement_exp_dt < lv_current_date
      AND agreement_exp_dt >= lc_date_2yr.

  SELECT DISTINCT drcustno AS drcustno, refca AS refca
    APPENDING TABLE lt_ci_inactive_all
    FROM zisdmadrdrcusttp
    WHERE agreement_exp_dt < lv_current_date
      AND agreement_exp_dt >= lc_date_2yr.

  WRITE: / 'C&I RTM 2 - INACTIVE C&I Program Enrollment (2yr history)'.
  WRITE: / '  Table:      zisdmadrdrcusttp'.
  WRITE: / '  Condition:  agreement_exp_dt < p_keydat'.
  WRITE: / '             AND agreement_exp_dt >= 20240101'.
  WRITE: / '  Count:      ', lv_ci_inactive.
  SKIP.

*=====================================================================*
* C&I RTM 3 - 2 years COMPLETED Event
*   Tables: zisdmadrdrcusttp (a) INNER JOIN ziscs_ci_cust (b)
*           INNER JOIN zisceventmaster (c)
*   Condition: event_date >= '20240101' AND status = 'COMPLETED'
*   Deduplication: DISTINCT drcustno, refca
*=====================================================================*
  SELECT COUNT( DISTINCT a~drcustno || a~refca ) INTO lv_ci_completed
    FROM zisdmadrdrcusttp AS a
    INNER JOIN ziscs_ci_cust AS b ON a~drcustno = b~drcustno
    INNER JOIN zisceventmaster AS c ON b~eventname = c~event_id
    WHERE c~event_date >= lc_date_2yr
      AND c~status = 'COMPLETED'.

  SELECT DISTINCT a~drcustno AS drcustno, a~refca AS refca
    APPENDING TABLE lt_ci_completed_all
    FROM zisdmadrdrcusttp AS a
    INNER JOIN ziscs_ci_cust AS b ON a~drcustno = b~drcustno
    INNER JOIN zisceventmaster AS c ON b~eventname = c~event_id
    WHERE c~event_date >= lc_date_2yr
      AND c~status = 'COMPLETED'.

  WRITE: / 'C&I RTM 3 - 2 years COMPLETED Event'.
  WRITE: / '  Tables:     zisdmadrdrcusttp > ziscs_ci_cust > zisceventmaster'.
  WRITE: / '  Condition:  event_date >= 20240101 AND status = COMPLETED'.
  WRITE: / '  Count:      ', lv_ci_completed.
  SKIP.

*=====================================================================*
* C&I RTM 4 - 2 years CANCELLED Event
*   Tables: zisdmadrdrcusttp (a) INNER JOIN ziscs_ci_cust (b)
*           INNER JOIN zisceventmaster (c)
*   Condition: event_date >= '20240101' AND status = 'CANCELLED'
*   Deduplication: DISTINCT drcustno, refca
*=====================================================================*
  SELECT COUNT( DISTINCT a~drcustno || a~refca ) INTO lv_ci_cancelled
    FROM zisdmadrdrcusttp AS a
    INNER JOIN ziscs_ci_cust AS b ON a~drcustno = b~drcustno
    INNER JOIN zisceventmaster AS c ON b~eventname = c~event_id
    WHERE c~event_date >= lc_date_2yr
      AND c~status = 'CANCELLED'.

  SELECT DISTINCT a~drcustno AS drcustno, a~refca AS refca
    APPENDING TABLE lt_ci_cancelled_all
    FROM zisdmadrdrcusttp AS a
    INNER JOIN ziscs_ci_cust AS b ON a~drcustno = b~drcustno
    INNER JOIN zisceventmaster AS c ON b~eventname = c~event_id
    WHERE c~event_date >= lc_date_2yr
      AND c~status = 'CANCELLED'.

  WRITE: / 'C&I RTM 4 - 2 years CANCELLED Event'.
  WRITE: / '  Tables:     zisdmadrdrcusttp > ziscs_ci_cust > zisceventmaster'.
  WRITE: / '  Condition:  event_date >= 20240101 AND status = CANCELLED'.
  WRITE: / '  Count:      ', lv_ci_cancelled.
  SKIP.

*=====================================================================*
* SSR RTM 1 - ACTIVE / Opt-In SSR Program Enrollment
*   Table: ziscsssr
*   Condition: (opt_out_date IS INITIAL OR opt_out_date = space
*               OR opt_out_date = '00000000' OR opt_out_date >= p_keydat)
*   Note: Program also filters: opt_in_date IS NOT NULL AND opt_in_date <> space
*   Deduplication: DISTINCT vkont
*=====================================================================*
  SELECT COUNT( DISTINCT vkont ) INTO lv_ssr_active
    FROM ziscsssr
    WHERE opt_in_date IS NOT NULL
      AND opt_in_date <> ' '
      AND ( opt_out_date IS INITIAL
           OR opt_out_date = ' '
           OR opt_out_date = '00000000'
           OR opt_out_date+0(8) >= lv_current_date ).

  WRITE: / 'SSR RTM 1 - ACTIVE / Opt-In SSR Program Enrollment'.
  WRITE: / '  Table:      ziscsssr'.
  WRITE: / '  Condition:  opt_in_date IS NOT NULL'.
  WRITE: / '             AND (opt_out_date = 00000000/space'.
  WRITE: / '                  OR opt_out_date >= p_keydat)'.
  WRITE: / '  Count:      ', lv_ssr_active.
  SKIP.

*=====================================================================*
* SSR RTM 2A - Cancelled enrollments with Opt-Out reason "Customer Request"
*   Table: ziscsssr
*   Condition: opt_out_date <> '99991231' AND endres = '4'
*   Deduplication: DISTINCT vkont
*=====================================================================*
  SELECT COUNT( DISTINCT vkont ) INTO lv_ssr_cust
    FROM ziscsssr
    WHERE opt_in_date IS NOT NULL
      AND opt_in_date <> ' '
      AND opt_out_date+0(8) <> '99991231'
      AND opt_out_date+0(8) >= lc_date_2yr
      AND endres = '4'.

  WRITE: / 'SSR RTM 2A - Cancelled enrollments Opt-Out Customer Request'.
  WRITE: / '  Table:      ziscsssr'.
  WRITE: / '  Condition:  opt_out_date <> 99991231'.
  WRITE: / '             AND opt_out_date >= 20240101'.
  WRITE: / '             AND endres = 4'.
  WRITE: / '  Count:      ', lv_ssr_cust.
  SKIP.

*=====================================================================*
* SSR RTM 2B - Cancelled enrollments NOT "Customer Request"
*   Table: ziscsssr
*   Condition: opt_out_date >= '20240101' AND endres <> '4'
*   Deduplication: DISTINCT vkont
*=====================================================================*
  SELECT COUNT( DISTINCT vkont ) INTO lv_ssr_notreq
    FROM ziscsssr
    WHERE opt_in_date IS NOT NULL
      AND opt_in_date <> ' '
      AND opt_out_date+0(8) >= lc_date_2yr
      AND endres <> '4'.

  WRITE: / 'SSR RTM 2B - Cancelled enrollments NOT Customer Request'.
  WRITE: / '  Table:      ziscsssr'.
  WRITE: / '  Condition:  opt_out_date >= 20240101'.
  WRITE: / '             AND endres <> 4'.
  WRITE: / '  Count:      ', lv_ssr_notreq.
  SKIP.

*=====================================================================*
* SSR RTM 3 - 2 years COMPLETED Event
*   Tables: ziscsssr (a) INNER JOIN ziscs_ssr_cust (b)
*           INNER JOIN zisceventmaster (c)
*   Condition: event_date >= '20240101' AND status = 'COMPLETED'
*   Deduplication: DISTINCT vkont
*=====================================================================*
  SELECT COUNT( DISTINCT a~vkont ) INTO lv_ssr_completed
    FROM ziscsssr AS a
    INNER JOIN ziscs_ssr_cust AS b ON a~vkont = b~vkont
    INNER JOIN zisceventmaster AS c ON b~event_id = c~event_id
    WHERE c~event_date >= lc_date_2yr
      AND c~status = 'COMPLETED'.

  WRITE: / 'SSR RTM 3 - 2 years COMPLETED Event'.
  WRITE: / '  Tables:     ziscsssr > ziscs_ssr_cust > zisceventmaster'.
  WRITE: / '  Condition:  event_date >= 20240101 AND status = COMPLETED'.
  WRITE: / '  Count:      ', lv_ssr_completed.
  SKIP.

*=====================================================================*
* SSR RTM 4 - 2 years CANCELLED Event
*   Tables: ziscsssr (a) INNER JOIN ziscs_ssr_cust (b)
*           INNER JOIN zisceventmaster (c)
*   Condition: event_date >= '20240101' AND (status = 'CANCELLED' OR 'DELETED')
*   Deduplication: DISTINCT vkont
*=====================================================================*
  SELECT COUNT( DISTINCT a~vkont ) INTO lv_ssr_cancelled
    FROM ziscsssr AS a
    INNER JOIN ziscs_ssr_cust AS b ON a~vkont = b~vkont
    INNER JOIN zisceventmaster AS c ON b~event_id = c~event_id
    WHERE c~event_date >= lc_date_2yr
      AND ( c~status = 'CANCELLED' OR c~status = 'DELETED' ).

  WRITE: / 'SSR RTM 4 - 2 years CANCELLED/DELETED Event'.
  WRITE: / '  Tables:     ziscsssr > ziscs_ssr_cust > zisceventmaster'.
  WRITE: / '  Condition:  event_date >= 20240101'.
  WRITE: / '             AND (status = CANCELLED OR status = DELETED)'.
  WRITE: / '  Count:      ', lv_ssr_cancelled.
  SKIP.

*=====================================================================*
* Summary
*=====================================================================*
  SKIP.
  WRITE: / '============================================================'.
  WRITE: / '                    SUMMARY'.
  WRITE: / '============================================================'.
  WRITE: / '                        C&I Rules'.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'RTM 1 (Active C&I):       ', lv_ci_active.
  WRITE: / 'RTM 2 (Inactive C&I):     ', lv_ci_inactive.
  WRITE: / 'RTM 3 (C&I Completed):    ', lv_ci_completed.
  WRITE: / 'RTM 4 (C&I Cancelled):    ', lv_ci_cancelled.
  SKIP.
  WRITE: / '                        SSR Rules'.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'RTM 1 (Active SSR):       ', lv_ssr_active.
  WRITE: / 'RTM 2A (Cust Req Cancel): ', lv_ssr_cust.
  WRITE: / 'RTM 2B (Non-Cust Cancel): ', lv_ssr_notreq.
  WRITE: / 'RTM 3 (SSR Completed):    ', lv_ssr_completed.
  WRITE: / 'RTM 4 (SSR Cancelled):    ', lv_ssr_cancelled.
  WRITE: / '============================================================'.
  SKIP.
  WRITE: / 'NOTES:'.
  WRITE: / '  - Program: ZISCS_MIGRATION_CONTRACTOPTION (v1, 12.09.2025)'.
  WRITE: / '  - C&I lookback: p_keydat (keydate) and 20240101 (2yr)'.
  WRITE: / '  - SSR lookback: 20240101 (fixed 2yr)'.
  WRITE: / '  - SSR endres=4 = Customer Request opt-out reason.'.
  WRITE: / '  - Program filters SSR: opt_in_date IS NOT NULL/space.'.
  WRITE: / '  - Note: SSR RTM 2A has opt_out_date check NE 99991231.'.
  WRITE: / '    SSR RTM 2B does NOT check opt_out_date (only endres <> 4).'.
  WRITE: / '============================================================'.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*& Report  Z_CO_VALIDATION - ABAP KEY FINDINGS vs RTM
*&---------------------------------------------------------------------*
* Validation findings comparing program to RTM documentation:
*
* Document: TD-Contract Option Type (SSR and C&I)-Extract & Cleanse
*           (page 778043968)
*
* Program: ZISCS_MIGRATION_CONTRACTOPTION (initial, 12.09.2025)
*   - No UD revision log entries (initial version only)
*   - Single version found in CCMS
*
* Program Rules Summary:
*   C&I RTM 1: Active enrollment (agreement_exp_dt >= p_keydat)
*   C&I RTM 2: Inactive enrollment (agreement_exp_dt < p_keydat, >= 20240101)
*   C&I RTM 3: Completed events (event_date >= 20240101, status=COMPLETED)
*   C&I RTM 4: Cancelled events (event_date >= 20240101, status=CANCELLED)
*
*   SSR RTM 1: Active enrollment (opt_out_date=00000000/space/ge keydat)
*   SSR RTM 2A: Cancelled - Customer Request (endres=4, opt_out<>99991231)
*   SSR RTM 2B: Cancelled - NOT Customer Request (opt_out>=20240101, endres<>4)
*   SSR RTM 3: Completed events (event_date >= 20240101, status=COMPLETED)
*   SSR RTM 4: Cancelled/DELETED events (event_date >= 20240101, status=CANCELLED/DELETED)
*
* Key Observations:
*   1. Program uses fixed 2yr lookback date lc_date_2yr = '20240101'
*      (NOT configurable via p_month like SA validation)
*   2. C&I rules use p_keydat parameter for active/inactive cutoff
*   3. SSR rules use fixed '20240101' for all event-based filtering
*   4. SSR RTM 2B: Program does NOT filter opt_out_date for this rule
*      (only endres <> '4', plus the base opt_in_date filter)
*      This means SSR RTM 2B captures records with endres <> 4
*      regardless of opt_out_date value (including those with
*      opt_out_date = '00000000' or even missing opt_out_date)
*   5. DELETED status is included in SSR RTM 4 but NOT in C&I RTM 4
*   6. The program writes CSV with event_id, status, drcustno, prog_name
*      for completed/cancelled events (both C&I and SSR)
*
* Cross-validation issues identified:
*   - CI RTM 2 (inactive) in program: agreement_exp_dt >= lv_date
*     but lv_date is hardcoded '20240101', not using p_keydat as the
*     upper bound. Actually it uses: agreement_exp_dt < p_keydat
*     AND agreement_exp_dt >= '20240101' - correct.
*   - SSR RTM 2A: Has both opt_out_date NE '99991231' AND
*     opt_out_date >= '20240101' (date portion check). But the
*     opt_out_date+0(8) check against '99991231' uses string compare.
*     If opt_out_date format differs, may cause issues.
*   - The gt_file for SSR RTM 1 stores gt_ssr_active vkont but
*     the file CSV header has program column which is filled for
*     events only - not for enrollment counts
*&---------------------------------------------------------------------*
