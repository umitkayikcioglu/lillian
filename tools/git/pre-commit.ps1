Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Regenerate and stage platform output whenever an authored input changes.

$repoRoot = (& git rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0) { throw "Unable to locate the repository root." }

function Invoke-Git {
	param([string[]]$Arguments)

	$output = @(& git -C $repoRoot @Arguments)
	if ($LASTEXITCODE -ne 0) {
		throw "Git command failed: git $($Arguments -join ' ')"
	}
	return $output
}

$sourcePrefixes = @(".github/skills/", ".github/prompts/", ".github/agents/", ".github/instructions/")

function Test-SyncInput {
	param([string]$Path)

	if ($Path -eq ".github/skills/INDEX.md") { return $false }
	if ($Path -eq "tools/sync-ai-platforms.ps1") { return $true }
	foreach ($prefix in $sourcePrefixes) {
		if ($Path.StartsWith($prefix, [System.StringComparison]::Ordinal)) { return $true }
	}
	return $false
}

$stagedPaths = @(Invoke-Git @("diff", "--cached", "--name-only", "--diff-filter=ACMRD", "--no-renames"))
$changedInputs = @($stagedPaths | Where-Object { Test-SyncInput $_ })
if ($changedInputs.Count -eq 0) {
	Write-Host "No authored AI platform input changed. Skipping sync." -ForegroundColor Gray
	exit 0
}

# The generator reads the working tree. Do not generate from changes that are
# absent from the commit being created.
$unstagedPaths = @(Invoke-Git @("diff", "--name-only", "--diff-filter=ACMRD", "--no-renames"))
$untrackedPaths = @(Invoke-Git @("ls-files", "--others", "--exclude-standard"))
$dirtyInputs = @(
	@($unstagedPaths + $untrackedPaths) |
		Where-Object { Test-SyncInput $_ } |
		Sort-Object -Unique
)
if ($dirtyInputs.Count -gt 0) {
	Write-Host "Authored AI platform inputs must be staged completely:" -ForegroundColor Red
	$dirtyInputs | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
	exit 1
}

& "$repoRoot/tools/sync-ai-platforms.ps1"
if ($LASTEXITCODE -ne 0) { throw "AI platform sync failed." }

& "$repoRoot/tools/bump-plugin-version.ps1"
if ($LASTEXITCODE -ne 0) { throw "Plugin version bump failed." }

$generatedPaths = @(
	".claude",
	".agents",
	"plugins/ai-toolkit",
	".claude-plugin/marketplace.json",
	".github/skills/INDEX.md",
	"README.md"
)
[void](Invoke-Git (@("add", "--") + $generatedPaths))

Write-Host "AI platforms synced, version bumped, and generated output staged." -ForegroundColor Green
