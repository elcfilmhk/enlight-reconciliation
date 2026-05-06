*&---------------------------------------------------------------------*
*& Report  Z_READ_OBJECT_VALIDATION
*&---------------------------------------------------------------------*
*& Validation report for ZISCS_MIGRATION_READ_OBJECT
*& Compare rule counts against source table data
*& ABAP 7.4 compatible version
*&---------------------------------------------------------------------*
REPORT z_read_object_validation NO STANDARD PAGE HEADING LINE-SIZE 120.

* Parameters
PARAMETERS: p_keydat_low  TYPE datum DEFAULT '20250101',
            p_keydat_high TYPE datum DEFAULT '20251231'.

* Variables
DATA: lv_mro_r1 TYPE i,
      lv_mro_r2 TYPE i,
      lv_mro_r3 TYPE i,
      lv_mro_r4 TYPE i,
      lv_dayend_r1 TYPE i,
      lv_interval_r1 TYPE i.

* Internal tables for dedup
TYPES: BEGIN OF ty_equnr,
         equnr TYPE eabl-equnr,
       END OF ty_equnr.

DATA: lt_mro_r1 TYPE SORTED TABLE OF ty_equnr WITH UNIQUE KEY equnr,
      lt_mro_r2 TYPE SORTED TABLE OF ty_equnr WITH UNIQUE KEY equnr,
      lt_mro_r3 TYPE SORTED TABLE OF ty_equnr WITH UNIQUE KEY equnr,
      lt_dayend_r1 TYPE SORTED TABLE OF ty_equnr WITH UNIQUE KEY equnr,
      lt_interval_r1 TYPE SORTED TABLE OF ty_equnr WITH UNIQUE KEY equnr.

* Globals matched by program
DATA: gt_mro_received       TYPE SORTED TABLE OF eabl-equnr WITH UNIQUE KEY table_line,
      gt_mro_not_received   TYPE SORTED TABLE OF eabl-equnr WITH UNIQUE KEY table_line,
      gt_estimate           TYPE SORTED TABLE OF eabl-equnr WITH UNIQUE KEY table_line,
      gt_equi_dayenddevice  TYPE SORTED TABLE OF equnr WITH UNIQUE KEY table_line,
      gt_equi_dayendprofile TYPE SORTED TABLE OF eprofass-profile WITH UNIQUE KEY table_line.

* Counters
DATA: gv_mrocount       TYPE i,
      gv_mroreceived    TYPE i,
      gv_mronotreceived TYPE i,
      gv_estimate       TYPE i,
      gv_dayendread     TYPE i,
      gv_intervalread   TYPE int8.

*---------------------------------------------------------------------*
START-OF-SELECTION.

  IF p_keydat_low IS INITIAL.
    p_keydat_low = '20250101'.
  ENDIF.
  IF p_keydat_high IS INITIAL.
    p_keydat_high = '20251231'.
  ENDIF.

  WRITE: / '============================================================'.
  WRITE: / '   ZISCS_MIGRATION_READ_OBJECT - VALIDATION REPORT'.
  WRITE: / '============================================================'.
  WRITE: / 'Program:    ZISCS_MIGRATION_READ_OBJECT'.
  WRITE: / 'Key Date Range: ', p_keydat_low, ' - ', p_keydat_high.
  WRITE: / '============================================================'.
  SKIP.

*---------------------------------------------------------------------*
* Rule MRO-1: MRO Received
*   Source: EABL
*   Filters: ableser NE '000'
*            ablstat NE 0
*            adat GE p_keydat_low AND adat LE p_keydat_high
*   Program: READ_MRO form, INSERT equnr INTO gt_mro_received
*---------------------------------------------------------------------*
  SELECT COUNT( DISTINCT eabl~equnr ) INTO lv_mro_r1
    FROM eabl
    WHERE eabl~ableser NE '000'
      AND eabl~ablstat NE 0
      AND eabl~adat GE p_keydat_low
      AND eabl~adat LE p_keydat_high.

* Also collect for dedup across rules
  SELECT DISTINCT eabl~equnr AS equnr INTO TABLE lt_mro_r1
    FROM eabl
    WHERE eabl~ableser NE '000'
      AND eabl~ablstat NE 0
      AND eabl~adat GE p_keydat_low
      AND eabl~adat LE p_keydat_high.

* Build gt_mro_received (matches what program does)
  gt_mro_received = lt_mro_r1.
  gv_mroreceived = LINES( gt_mro_received ).

  WRITE: / 'Rule MRO-1: MRO Received'.
  WRITE: / '  Filters: ableser NE 000, ablstat NE 0, adat in range'.
  WRITE: / '  Count (distinct equnr): ', lv_mro_r1.
  WRITE: / '  Source: EABL'.
  SKIP.

*---------------------------------------------------------------------*
* Rule MRO-2: MRO Not Received
*   Source: Input device list minus MRO Received
*   Program: Loop at chunk, READ TABLE gt_mro_received, if not found
*            INSERT INTO gt_mro_not_received
*   Note: Depends on input device list - validation uses ALL devices
*         that exist in EABL but did NOT match MRO criteria
*---------------------------------------------------------------------*
* For validation: devices that exist but have NO MRO record in period
* This is an input-driven count, but we can approximate using all EABL
* devices where NOT (ableser NE '000' AND ablstat NE 0 AND adat in range)
  SELECT COUNT( DISTINCT eabl~equnr ) INTO lv_mro_r2
    FROM eabl
    WHERE eabl~ableser NE '000'
      AND eabl~ablstat NE 0
      AND ( eabl~adat LT p_keydat_low OR eabl~adat GT p_keydat_high ).

* Collect for dedup
  SELECT DISTINCT eabl~equnr AS equnr INTO TABLE lt_mro_r2
    FROM eabl
    WHERE eabl~ableser NE '000'
      AND eabl~ablstat NE 0
      AND ( eabl~adat LT p_keydat_low OR eabl~adat GT p_keydat_high ).

* Note: MRO Not Received is input-dependent - the program filters
* devices from the input file (S_DEVICE or S_EQUIP) and checks
* which ones are NOT in gt_mro_received.
* Validation here shows devices WITH MRO data but OUTSIDE date range.
* Real "not received" count depends on the input device list.

  WRITE: / 'Rule MRO-2: MRO Not Received (approx - input-dependent)'.
  WRITE: / '  Note: Actual count depends on input device list (S_DEVICE/S_EQUIP)'.
  WRITE: / '  Approx: devices with MRO data but outside date range = ', lv_mro_r2.
  WRITE: / '  Source: EABL (subset - input dependent)'.
  SKIP.

*---------------------------------------------------------------------*
* Rule MRO-3: Estimate Read Received
*   Source: EABL where istablart = '03' OR 'AE'
*   Filters: ableser NE '000', ablstat NE 0, adat in range
*   Program: In READ_MRO loop - INSERT equnr INTO gt_estimate
*            when istablart = '03' OR 'AE'
*---------------------------------------------------------------------*
  SELECT COUNT( DISTINCT eabl~equnr ) INTO lv_mro_r3
    FROM eabl
    WHERE eabl~ableser NE '000'
      AND eabl~ablstat NE 0
      AND eabl~adat GE p_keydat_low
      AND eabl~adat LE p_keydat_high
      AND ( eabl~istablart = '03' OR eabl~istablart = 'AE' ).

  SELECT DISTINCT eabl~equnr AS equnr INTO TABLE lt_mro_r3
    FROM eabl
    WHERE eabl~ableser NE '000'
      AND eabl~ablstat NE 0
      AND eabl~adat GE p_keydat_low
      AND eabl~adat LE p_keydat_high
      AND ( eabl~istablart = '03' OR eabl~istablart = 'AE' ).

  gt_estimate = lt_mro_r3.
  gv_estimate = LINES( gt_estimate ).

  WRITE: / 'Rule MRO-3: Estimate Read Received'.
  WRITE: / '  Filters: istablart = 03 OR AE, plus MRO-1 filters'.
  WRITE: / '  Count (distinct equnr): ', lv_mro_r3.
  WRITE: / '  Source: EABL'.
  SKIP.

*---------------------------------------------------------------------*
* Rule MRO-4: MRO Document Count
*   Source: COUNT of EABL records (not distinct equnr)
*   Program: gv_mrocount = gv_mrocount + lines(lt_mro)
*            where lt_mro is the result set from READ_MRO
*---------------------------------------------------------------------*
  SELECT COUNT( * ) INTO lv_mro_r4
    FROM eabl
    WHERE eabl~ableser NE '000'
      AND eabl~ablstat NE 0
      AND eabl~adat GE p_keydat_low
      AND eabl~adat LE p_keydat_high.

  WRITE: / 'Rule MRO-4: MRO Document Count (total records)'.
  WRITE: / '  Count (all EABL records): ', lv_mro_r4.
  WRITE: / '  Source: EABL'.
  SKIP.

*---------------------------------------------------------------------*
* Day End Profile Rules
*   Source: ETDZ + EPROFASS + EPROFVALMONTH
*   Filter: etdz~bis = '99991231'
*           valueday GE p_keydat_low AND valueday LE p_keydat_high
*           Any VAL field >= 0
*---------------------------------------------------------------------*
  SELECT COUNT( DISTINCT et~equnr ) INTO lv_dayend_r1
    FROM etdz AS et
    INNER JOIN eprofass AS ep ON et~logikzw = ep~logikzw
    INNER JOIN eprofvalmonth AS em ON ep~profile = em~profile
    WHERE et~bis = '99991231'
      AND em~valueday GE p_keydat_low
      AND em~valueday LE p_keydat_high
      AND ( em~val01 >= 0 OR em~val02 >= 0 OR em~val03 >= 0 OR
            em~val04 >= 0 OR em~val05 >= 0 OR em~val06 >= 0 OR
            em~val07 >= 0 OR em~val08 >= 0 OR em~val09 >= 0 OR
            em~val10 >= 0 OR em~val11 >= 0 OR em~val12 >= 0 OR
            em~val13 >= 0 OR em~val14 >= 0 OR em~val15 >= 0 OR
            em~val16 >= 0 OR em~val17 >= 0 OR em~val18 >= 0 OR
            em~val19 >= 0 OR em~val20 >= 0 OR em~val21 >= 0 OR
            em~val22 >= 0 OR em~val23 >= 0 OR em~val24 >= 0 OR
            em~val25 >= 0 OR em~val26 >= 0 OR em~val27 >= 0 OR
            em~val28 >= 0 OR em~val29 >= 0 OR em~val30 >= 0 OR
            em~val31 >= 0 ).

  SELECT DISTINCT et~equnr AS equnr INTO TABLE lt_dayend_r1
    FROM etdz AS et
    INNER JOIN eprofass AS ep ON et~logikzw = ep~logikzw
    INNER JOIN eprofvalmonth AS em ON ep~profile = em~profile
    WHERE et~bis = '99991231'
      AND em~valueday GE p_keydat_low
      AND em~valueday LE p_keydat_high
      AND ( em~val01 >= 0 OR em~val02 >= 0 OR em~val03 >= 0 OR
            em~val04 >= 0 OR em~val05 >= 0 OR em~val06 >= 0 OR
            em~val07 >= 0 OR em~val08 >= 0 OR em~val09 >= 0 OR
            em~val10 >= 0 OR em~val11 >= 0 OR em~val12 >= 0 OR
            em~val13 >= 0 OR em~val14 >= 0 OR em~val15 >= 0 OR
            em~val16 >= 0 OR em~val17 >= 0 OR em~val18 >= 0 OR
            em~val19 >= 0 OR em~val20 >= 0 OR em~val21 >= 0 OR
            em~val22 >= 0 OR em~val23 >= 0 OR em~val24 >= 0 OR
            em~val25 >= 0 OR em~val26 >= 0 OR em~val27 >= 0 OR
            em~val28 >= 0 OR em~val29 >= 0 OR em~val30 >= 0 OR
            em~val31 >= 0 ).

  gt_equi_dayenddevice = lt_dayend_r1.

  WRITE: / 'Rule DAYEND-1: Day End Device Count'.
  WRITE: / '  Filters: etdz~bis = 99991231, valueday in range, any val>=0'.
  WRITE: / '  Count (distinct equnr): ', lv_dayend_r1.
  WRITE: / '  Source: ETDZ + EPROFASS + EPROFVALMONTH'.
  SKIP.

*---------------------------------------------------------------------*
* Interval Profile Rules
*   Source: ETDZ + EPROFASS + EPROFVAL30
*   Filter: etdz~bis = '99991231'
*           valueday GE p_keydat_low AND valueday LE p_keydat_high
*           Any VAL field (48 fields: val0000-val2330) >= 0
*---------------------------------------------------------------------*
  SELECT COUNT( DISTINCT et~equnr ) INTO lv_interval_r1
    FROM etdz AS et
    INNER JOIN eprofass AS ep ON et~logikzw = ep~logikzw
    INNER JOIN eprofval30 AS em ON ep~profile = em~profile
    WHERE et~bis = '99991231'
      AND em~valueday GE p_keydat_low
      AND em~valueday LE p_keydat_high
      AND ( em~val0000 >= 0 OR em~val0030 >= 0 OR em~val0100 >= 0 OR
            em~val0130 >= 0 OR em~val0200 >= 0 OR em~val0230 >= 0 OR
            em~val0300 >= 0 OR em~val0330 >= 0 OR em~val0400 >= 0 OR
            em~val0430 >= 0 OR em~val0500 >= 0 OR em~val0530 >= 0 OR
            em~val0600 >= 0 OR em~val0630 >= 0 OR em~val0700 >= 0 OR
            em~val0730 >= 0 OR em~val0800 >= 0 OR em~val0830 >= 0 OR
            em~val0900 >= 0 OR em~val0930 >= 0 OR em~val1000 >= 0 OR
            em~val1030 >= 0 OR em~val1100 >= 0 OR em~val1130 >= 0 OR
            em~val1200 >= 0 OR em~val1230 >= 0 OR em~val1300 >= 0 OR
            em~val1330 >= 0 OR em~val1400 >= 0 OR em~val1430 >= 0 OR
            em~val1500 >= 0 OR em~val1530 >= 0 OR em~val1600 >= 0 OR
            em~val1630 >= 0 OR em~val1700 >= 0 OR em~val1730 >= 0 OR
            em~val1800 >= 0 OR em~val1830 >= 0 OR em~val1900 >= 0 OR
            em~val1930 >= 0 OR em~val2000 >= 0 OR em~val2030 >= 0 OR
            em~val2100 >= 0 OR em~val2130 >= 0 OR em~val2200 >= 0 OR
            em~val2230 >= 0 OR em~val2300 >= 0 OR em~val2330 >= 0 ).

  SELECT DISTINCT et~equnr AS equnr INTO TABLE lt_interval_r1
    FROM etdz AS et
    INNER JOIN eprofass AS ep ON et~logikzw = ep~logikzw
    INNER JOIN eprofval30 AS em ON ep~profile = em~profile
    WHERE et~bis = '99991231'
      AND em~valueday GE p_keydat_low
      AND em~valueday LE p_keydat_high
      AND ( em~val0000 >= 0 OR em~val0030 >= 0 OR em~val0100 >= 0 OR
            em~val0130 >= 0 OR em~val0200 >= 0 OR em~val0230 >= 0 OR
            em~val0300 >= 0 OR em~val0330 >= 0 OR em~val0400 >= 0 OR
            em~val0430 >= 0 OR em~val0500 >= 0 OR em~val0530 >= 0 OR
            em~val0600 >= 0 OR em~val0630 >= 0 OR em~val0700 >= 0 OR
            em~val0730 >= 0 OR em~val0800 >= 0 OR em~val0830 >= 0 OR
            em~val0900 >= 0 OR em~val0930 >= 0 OR em~val1000 >= 0 OR
            em~val1030 >= 0 OR em~val1100 >= 0 OR em~val1130 >= 0 OR
            em~val1200 >= 0 OR em~val1230 >= 0 OR em~val1300 >= 0 OR
            em~val1330 >= 0 OR em~val1400 >= 0 OR em~val1430 >= 0 OR
            em~val1500 >= 0 OR em~val1530 >= 0 OR em~val1600 >= 0 OR
            em~val1630 >= 0 OR em~val1700 >= 0 OR em~val1730 >= 0 OR
            em~val1800 >= 0 OR em~val1830 >= 0 OR em~val1900 >= 0 OR
            em~val1930 >= 0 OR em~val2000 >= 0 OR em~val2030 >= 0 OR
            em~val2100 >= 0 OR em~val2130 >= 0 OR em~val2200 >= 0 OR
            em~val2230 >= 0 OR em~val2300 >= 0 OR em~val2330 >= 0 ).

  WRITE: / 'Rule INTERVAL-1: Interval Device Count'.
  WRITE: / '  Filters: etdz~bis = 99991231, valueday in range, any val>=0'.
  WRITE: / '  Count (distinct equnr): ', lv_interval_r1.
  WRITE: / '  Source: ETDZ + EPROFASS + EPROFVAL30'.
  SKIP.

*---------------------------------------------------------------------*
* Summary
*---------------------------------------------------------------------*
  SKIP.
  WRITE: / '============================================================'.
  WRITE: / '                    SUMMARY'.
  WRITE: / '============================================================'.
  WRITE: / '                         Count'.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'MRO-1 MRO Received:        ', lv_mro_r1.
  WRITE: / 'MRO-2 MRO Not Received:    ', lv_mro_r2, '(approx - input-dependent)'.
  WRITE: / 'MRO-3 Estimate Read:        ', lv_mro_r3.
  WRITE: / 'MRO-4 MRO Document Count:   ', lv_mro_r4.
  WRITE: / 'DAYEND-1 Day End Devices:   ', lv_dayend_r1.
  WRITE: / 'INTERVAL-1 Interval Devices:', lv_interval_r1.
  WRITE: / '============================================================'.
  SKIP.
  WRITE: / 'NOTES:'.
  WRITE: / '  - MRO Not Received (MRO-2) is INPUT-DEPENDENT.'.
  WRITE: / '    Actual count depends on S_DEVICE file or S_EQUIP selection.'.
  WRITE: / '  - All rules use key date range from p_keydat_low to p_keydat_high.'.
  WRITE: / '  - Program version: UD1K936411 (Log#0005, 12-Dec-2025)'.
  WRITE: / '  - RTM Doc: TD-Read Data-Extract & Cleanse (682263269)'.
  WRITE: / '============================================================'.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*& Report  Z_READ_OBJECT_VALIDATION - ABAP KEY FINDINGS vs RTM
*&---------------------------------------------------------------------*
* Validation findings comparing program to RTM documentation:
*
* Document found: TD-Read Data-Extract & Cleanse (682263269)
*
* Program UDs:
*   UD1K936188 (15.10.2025) - Integer overflow fix
*   UD1K936281 (11.11.2025) - Month logic update
*   UD1K936382 (04.12.2025) - UD1K936382, ablstat in MRO check
*   UD1K936411 (12.12.2025) - ABLESER check added
*
* Key implementation details:
*   1. MRO: EABL with ableser NE '000', ablstat NE 0, adat in range
*   2. Estimate reads: EABL with istablart = '03' OR 'AE'
*   3. Day End: ETDZ+EPROFASS+EPROFVALMONTH, bis='99991231', val>=0
*   4. Interval: ETDZ+EPROFASS+EPROFVAL30, bis='99991231', val>=0
*
* BUG FOUND in READ_INTERVAL:
*   - gs_file and gt_equi_* inserts are INSIDE the 48-iteration DO loop
*   - Each device's equnr/profile gets inserted once per non-zero reading
*   - For 48 interval slots per device per day: up to 48 duplicate inserts
*   - Since target is SORTED TABLE WITH UNIQUE KEY, duplicates are ignored
*     but this is inefficient and could cause issues if key structure changes
*   - BUG LOCATION: READ_INTERVAL form, inside "DO 48 TIMES" loop
*   - FIX NEEDED: Move gt_file/gt_equi_dayenddevice/gt_equi_dayendprofile
*     inserts OUTSIDE the DO loop, after setting lv_intervalprofile=abap_true
*
* SIMILAR BUG in READ_DAYEND:
*   - gs_file and gt_equi_* inserts are inside the 31-iteration DO loop
*   - Same pattern as interval - inserts happen multiple times per device
*   - Since SORTED TABLE ignores duplicates, counts appear correct
*     but performance is impacted
*   - BUG LOCATION: READ_DAYEND form, inside "DO 31 TIMES" loop
*   - FIX NEEDED: Move inserts outside DO loop, after DO ends
*&---------------------------------------------------------------------*