# Runbook: [Title]

## Metadata

**Last Updated:** [YYYYMMDD]
**Severity:** [SEV-1 | SEV-2 | SEV-3]
**Response Time:** [Time-to-acknowledge expectation, e.g., "within 15 min for SEV-1"]
**Owner:** [Name]

## Symptom

*What does this look like to the on-call engineer? Alert name, error message, customer-reported behavior — the trigger that brought them to this runbook.*

[Description of the symptom or alert that this runbook addresses]

## Purpose

[Brief description of what this runbook addresses. What underlying problem does it solve?]

## Prerequisites

- [Required access or permissions]
- [Required tools or CLI access]
- [Required knowledge or documentation to review first]

## Diagnosis

*Confirm the issue and identify the cause before jumping to mitigation. Run these checks first to make sure you're addressing the right problem.*

### 1. [Diagnostic step]

```pwsh
[diagnostic command]
```

**Look for:** [What output indicates the issue is real / what indicates it isn't]

### 2. [Diagnostic step]

```pwsh
[diagnostic command]
```

**Look for:** [What output confirms the cause]

## Mitigation Steps

> **Note:** Use PowerShell syntax in all shell commands. Do not use Unix-style commands like `grep`.

### 1. [First Step Title]

[Description of what this step accomplishes]

```pwsh
[command to run]
```

**Expected output:** [What you should see if successful]

### 2. [Second Step Title]

[Description]

```pwsh
[command to run]
```

**Expected output:** [What you should see]

### 3. [Third Step Title]

[Description]

```pwsh
[command to run]
```

**Expected output:** [What you should see]

### 4. Verify Resolution

[How to confirm the issue is resolved]

```pwsh
[verification command]
```

**Expected output:** [What success looks like]

### 5. Check Monitoring

- Visit: `[Grafana/monitoring URL]`
- Navigate to: `[Dashboard path]`
- Verify: [What to look for]

## Rollback Plan

If the resolution does not work or makes things worse:

1. [Rollback step 1]
   ```pwsh
   [rollback command]
   ```

2. [Rollback step 2]

3. Escalate to on-call engineer

## Escalation

| Condition | Contact | Method |
|-----------|---------|--------|
| If unresolved after 15 minutes | [Team/Person] | [Slack/PagerDuty] |
| If data loss suspected | [Team/Person] | [Method] |
| If customer-facing impact | [Team/Person] | [Method] |

## Contact

- **Primary:** [Name] (`@handle` on Slack)
- **Backup:** [Team] (`#channel`)

## References

- [Link to related runbook]
- [Link to architecture documentation]
- [Link to service README]

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| [YYYYMMDD] | [Name] | Initial version |
