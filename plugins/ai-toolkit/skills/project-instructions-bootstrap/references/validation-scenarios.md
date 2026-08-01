# Project Instructions Bootstrap Validation Scenarios

Use these scenarios as the minimum validation matrix for `project-instructions-bootstrap`. Each scenario should be checked against the skill behavior before requesting review.

| Scenario | Given | When | Then | Expected Result |
|----------|-------|------|------|-----------------|
| Missing target files | Neither `.github/CONTRIBUTING.md` nor `.github/copilot-instructions.md` exists | The capability runs with valid destination paths and sufficient discovery | Both candidates are composed in memory before writing | Both files are created, UTF-8 without BOM, LF line endings, one trailing newline |
| Empty target files | Both targets exist as empty real files | The capability runs | Marker validation finds no markers | Managed blocks are appended using the minimum separator |
| Valid marker update | Both targets contain one valid matching managed block | The capability runs | Only inner managed content is replaced | Manual text outside blocks remains unchanged |
| Existing file without markers | One or both targets contain manual content and no markers | The capability runs | Existing text is preserved | A managed block is appended after the minimum readable separator |
| Begin-only marker | A target has a begin marker without a matching end marker | The capability runs | Marker validation fails | No files are written |
| End-only marker | A target has an end marker without a matching begin marker | The capability runs | Marker validation fails | No files are written |
| Duplicate marker | A target has duplicate begin or end markers outside code fences | The capability runs | Marker validation fails | No files are written |
| Nested marker | A target has nested managed markers outside code fences | The capability runs | Marker validation fails | No files are written |
| Reversed marker | A target has an end marker before a begin marker | The capability runs | Marker validation fails | No files are written |
| Wrong-target marker | `CONTRIBUTING.md` contains `COPILOT INSTRUCTIONS` markers or the reverse | The capability runs | Marker validation fails | No files are written |
| Marker text in code fence | Marker-like text appears inside a Markdown fenced code block | The capability scans markers | Code-fenced marker text is ignored | Only real marker lines outside fences are considered |
| Ambiguous code fence | Markdown fence state cannot be determined safely | The capability scans markers | Marker validation is ambiguous | No files are written |
| CRLF existing file | An existing target uses CRLF line endings | The managed block is inserted or replaced | The block uses CRLF | The full file is not normalized to LF |
| LF existing file | An existing target uses LF line endings | The managed block is inserted or replaced | The block uses LF | The full file is not normalized to CRLF |
| Existing file without trailing newline | Existing manual content has no trailing newline | A block is appended | The capability adds only the minimum separator | Existing trailing-newline behavior is preserved where possible |
| `.github` directory symlink | `.github` is a symbolic link | Preflight validates destination chain | Path safety fails | No files are written |
| `.github` Windows junction or reparse point | `.github` is a junction or reparse-point-backed path | Preflight validates destination chain | Path safety fails | No files are written |
| Target-file symlink | Either target file is a symlink | Preflight validates target files | Path safety fails | No files are written |
| Target path escapes root | A resolved target path escapes the repository root | Preflight canonicalizes paths | Path safety fails | No files are written |
| One valid target and one invalid target | One target is safe and the other is unsafe or malformed | Two-target preflight runs | Preflight fails | Zero writes occur |
| Second physical write failure | First replace succeeds and second replace fails | Safe write fallback runs | Rollback is attempted for the first file | Final report states rollback success or partial update requiring manual intervention |
| .NET-only repository | Repository has `.sln` or `.csproj` and no Node manifests | Discovery runs | .NET profile activates | Only .NET durable standards and verified .NET commands are generated |
| React-only repository | Package manifest declares `react` and no Angular or .NET evidence | Discovery runs | React profile activates | React guidance is included without Angular or .NET guidance |
| Angular-only repository | `angular.json` or `@angular/core` exists and no React or .NET evidence | Discovery runs | Angular profile activates | Version-neutral Angular guidance is included |
| .NET plus React repository | Repo has `.sln` or `.csproj` and a package scope declaring `react` | Discovery runs | .NET and React profiles activate by scope | Commands remain scoped with working directories |
| Multi-application monorepo | Repo has multiple declared workspaces or independent manifests | Discovery runs | Scopes are separated | Commands are not collapsed into one root command |
| Conflicting package-manager declarations | `packageManager` conflicts with lock files or CI | Package-manager resolution runs | Declaration wins if valid; conflict is reported | No script translation occurs |
| Stale multiple lock files | Multiple lock files exist in one scope without a deterministic declaration | Package-manager resolution runs | Manager is ambiguous | No manager-specific verified commands are generated for that scope |
| Nested workspace with different manager | Root workspace has one manager and standalone nested project has another valid manager | Discovery scopes projects | Managers are selected per scope | Commands preserve each scope's manager |
| Supporting evidence without definitive evidence | Only extensions, CI commands, directories, Dockerfiles, or framework-like file names exist | Evidence evaluation runs | Profiles do not activate | Supporting-only signals are reported as ambiguity |
| `global.json` without solution or project | Repo contains `global.json` but no `.sln` or `.csproj` | Evidence evaluation runs | .NET profile does not activate | `global.json` is reported as supporting-only evidence |
| Unresolved command configuration | A profile activates but no declared command exists | Command resolution runs | No verified command is emitted | Unresolved recommendation appears only in execution report |
| Ambiguous stack evidence | Signals conflict or never reach definitive evidence | Evidence evaluation runs | Ambiguity is reported | No unsupported profile is selected |
| Execution report separation | Discovery finds evidence, rejected profiles, and ambiguities | Candidates are composed | Target files receive durable content only | Full evidence report is excluded from generated files |
| Second execution no content diff | Capability runs twice with unchanged repository inputs | Second run composes candidates | Candidate content matches existing files | No content diff is produced |
| Second sync no generated diff | `tools/sync-ai-platforms.ps1` runs twice after implementation | Second sync runs | Generated outputs are already current | No additional generated diff is produced |
