# ENLIGHT Account Extraction - Validation Template

Use this template to record and compare validation results.

## Parameters

| Parameter | Value |
|-----------|-------|
| Key Date | 20251027 |
| Lookback Months | 24 |
| Program Version | MC4A (UD1K936711) |

---

## Rule Comparison Table

| Rule | Description | Validation Report CA | Validation Report BP | MC4A Output CA | MC4A Output BP | Match? |
|------|-------------|----------------------|---------------------|----------------|---------------|--------|
| 1 | Active Accounts | | | | | |
| 2 | Inactive (24mo) | | | | | |
| 3 | Write-off/Write-in | | | | | |
| 4 | Outstanding Balance | | | | | |
| 9 | Shutdown/Main Charge | | | | | |
| 13 | Account Manager | - | | - | | |
| 14 | ZSTAFF BP | - | | - | | |
| 15 | Group Bill | | | | | |
| 16 | ENLIGHT Flagged | | | | | |
| 17 | PER-PER Relations | - | | - | | |

---

## Summary

| Metric | Value |
|--------|-------|
| Total CA (Validation) | |
| Total CA (MC4A) | |
| Difference | |
| Total BP (Validation) | |
| Total BP (MC4A) | |
| Difference | |

---

## Notes

- If CA counts match but BP counts differ → Check deduplication logic
- If Rule 4 shows higher than expected → augrs NE '2' filter was removed in MC4A
- If Rule 15/17 differ → Check FKKVK.VKTYP and BUT050.RELTYP values

---

## Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Technical | | | |
| Functional | | | |
| Approval | | | |