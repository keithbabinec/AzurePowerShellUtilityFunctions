# AzurePowerShellUtilityFunctions
A collection of Azure related PowerShell utility functions.

---

_v1.2 - Forked by Arian T. Kulp in May, 2021_

- Fix for crash in Send-AppInsightsExceptionTelemetry due to PowerShell exceptions not having TargetSite or StackTrace set (checks for empty value and sets defaults)
- Fix for crash due to single stack frame (fixed by coercing to array)
- Minor code cleanup (semi-colons, moved a few comments)
