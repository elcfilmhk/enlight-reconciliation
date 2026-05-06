*&---------------------------------------------------------------------*
*& Report  Z_SERVICEPOINT_VALIDATION
*&---------------------------------------------------------------------*
*& Validation report for ZISCS_MIGRATION_SP_MOCK3 (UD1K936723)
*& Compare rule counts against source tables
*&---------------------------------------------------------------------*
REPORT z_servicepoint_validation NO STANDARD PAGE HEADING.

PARAMETERS: p_keydat TYPE datum DEFAULT '20251027',
            p_month  TYPE numc2 DEFAULT 24.

DATA: lv_pastdate TYPE sy-datum.

START-OF-SELECTION.

  CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
    EXPORTING
      date      = p_keydat
      days      = 0
      months    = p_month
      signum    = '-'
      years     = 0
    IMPORTING
      calc_date = lv_pastdate.

  WRITE: / '============================================================'.
  WRITE: / '  ZISCS_MIGRATION_SP_MOCK3 Validation (UD1K936723)'.
  WRITE: / '============================================================'.
  WRITE: / 'Key Date:  ', p_keydat, '  Past Date: ', lv_pastdate.
  WRITE: / '============================================================'.
  SKIP.

*============================================================
*  ACTIVE SERVICE POINT (Rule 1)
*  - EANL + EASTL + EGERH + EQUI (via Logical Device ID)
*  - IFLOT + EGERH (Device Collector / SP spawn point)
*============================================================

  WRITE: / '--- RULE 1: ACTIVE SERVICE POINT ---'.

* Active SP via Logical Device (EANL+EASTL+EGERH)
  SELECT COUNT( DISTINCT eanl~vstelle) INTO @DATA(lv_sp_active1)
    FROM eanl
    INNER JOIN eastl ON eanl~anlage = eastl~anlage
    INNER JOIN egerh ON eastl~logiknr = egerh~logiknr
    INNER JOIN equi  ON egerh~equnr = equi~equnr
    INNER JOIN jest  ON equi~objnr  = jest~objnr
    INNER JOIN tj30t ON jest~stat   = tj30t~estat
    WHERE eanl~loevm = ' '
      AND jest~inact = ' '
      AND tj30t~stsma = 'ZCLPP'
      AND tj30t~spras = 'E'
      AND tj30t~txt04 NOT IN ('SCRA', 'LOST', 'LTDA').

  WRITE: / 'Active SP (Logical Device): ', lv_sp_active1.

* Active SP via Device Collector (IFLOT+EGERH, kombinat='G')
  SELECT COUNT( DISTINCT iflot~prems) INTO @DATA(lv_sp_active_mock)
    FROM iflot
    INNER JOIN egerh ON iflot~tplnr = egerh~devloc
    INNER JOIN equi  ON egerh~equnr = equi~equnr
    INNER JOIN jest  ON equi~objnr  = jest~objnr
    INNER JOIN tj30t ON jest~stat   = tj30t~estat
    WHERE iflot~loevm = ' '
      AND egerh~logiknr IS NOT NULL
      AND egerh~kombinat = 'G'
      AND jest~inact = ' '
      AND tj30t~stsma = 'ZCLPP'
      AND tj30t~spras = 'E'
      AND tj30t~txt04 NOT IN ('SCRA', 'LOST', 'LTDA').

  WRITE: / 'Active SP (Device Collector): ', lv_sp_active_mock.
  SKIP.

*============================================================
*  INACTIVE SERVICE POINT (Rule 2)
*  - Demolished premise within lookback
*============================================================

  WRITE: / '--- RULE 2: INACTIVE SERVICE POINT ---'.

* Inactive SP via Logical Device
  SELECT COUNT( DISTINCT eanl~vstelle) INTO @DATA(lv_sp_inact1)
    FROM eanl
    INNER JOIN eastl ON eanl~anlage = eastl~anlage
    INNER JOIN egerh ON eastl~logiknr = egerh~logiknr
    INNER JOIN equi  ON egerh~equnr = equi~equnr
    INNER JOIN jest  ON equi~objnr  = jest~objnr
    INNER JOIN tj30t ON jest~stat   = tj30t~estat
    WHERE eanl~loevm = ' '
      AND jest~inact = ' '
      AND tj30t~stsma = 'ZCLPP'
      AND tj30t~spras = 'E'
      AND tj30t~txt04 IN ('SCRA', 'LOST', 'LTDA')
      AND jest~erdat >= @lv_pastdate.

  WRITE: / 'Inactive SP (Logical Device): ', lv_sp_inact1.

* Inactive SP via Device Collector
  SELECT COUNT( DISTINCT iflot~prems) INTO @DATA(lv_sp_inact_mock)
    FROM iflot
    INNER JOIN egerh ON iflot~tplnr = egerh~devloc
    INNER JOIN equi  ON egerh~equnr = equi~equnr
    INNER JOIN jest  ON equi~objnr  = jest~objnr
    INNER JOIN tj30t ON jest~stat   = tj30t~estat
    WHERE iflot~loevm = ' '
      AND egerh~logiknr IS NOT NULL
      AND egerh~kombinat = 'G'
      AND jest~inact = ' '
      AND tj30t~stsma = 'ZCLPP'
      AND tj30t~spras = 'E'
      AND tj30t~txt04 IN ('SCRA', 'LOST', 'LTDA')
      AND jest~erdat >= @lv_pastdate.

  WRITE: / 'Inactive SP (Device Collector): ', lv_sp_inact_mock.
  SKIP.

*============================================================
*  SP_COLLECTOR_DEVICE COUNT
*  - Device Collector devices (kombinat='G')
*============================================================

  WRITE: / '--- SP_COLLECTOR_DEVICE ---'.

  SELECT COUNT( DISTINCT egerh~equnr) INTO @DATA(lv_sp_collector)
    FROM egerh
    INNER JOIN iflot ON iflot~tplnr = egerh~devloc
    INNER JOIN equi  ON egerh~equnr = equi~equnr
    INNER JOIN jest  ON equi~objnr  = jest~objnr
    INNER JOIN tj30t ON jest~stat   = tj30t~estat
    WHERE egerh~logiknr IS NOT NULL
      AND egerh~kombinat = 'G'
      AND jest~inact = ' '
      AND tj30t~stsma = 'ZCLPP'
      AND tj30t~spras = 'E'
      AND tj30t~txt04 NOT IN ('SCRA', 'LOST', 'LTDA').

  WRITE: / 'SP Collector Device Count: ', lv_sp_collector.
  SKIP.

*============================================================
*  TOTAL SUMMARY
*============================================================

  DATA: lv_total_active  TYPE i,
        lv_total_inact   TYPE i,
        lv_total_sp      TYPE i.

  lv_total_active = lv_sp_active1 + lv_sp_active_mock.
  lv_total_inact  = lv_sp_inact1  + lv_sp_inact_mock.
  lv_total_sp     = lv_total_active + lv_total_inact.

  WRITE: / '============================================================'.
  WRITE: / '                    SUMMARY'.
  WRITE: / '============================================================'.
  WRITE: / 'ACTIVE SERVICE POINT'.
  WRITE: / '  Logical Device:          ', lv_sp_active1.
  WRITE: / '  Device Collector:         ', lv_sp_active_mock.
  WRITE: / '  Total Active:             ', lv_total_active.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'INACTIVE SERVICE POINT'.
  WRITE: / '  Logical Device:          ', lv_sp_inact1.
  WRITE: / '  Device Collector:         ', lv_sp_inact_mock.
  WRITE: / '  Total Inactive:           ', lv_total_inact.
  WRITE: / '-----------------------------------------------------------'.
  WRITE: / 'TOTAL SERVICE POINT:      ', lv_total_sp.
  WRITE: / 'SP_COLLECTOR_DEVICE:       ', lv_sp_collector.
  WRITE: / '============================================================'.

END-OF-SELECTION.