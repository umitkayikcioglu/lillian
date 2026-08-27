#!/usr/bin/env pwsh
#requires -Version 7.2

<#
.SYNOPSIS
Installs Lillian into an existing repository as a local clone or a Git submodule.
.DESCRIPTION
Both modes keep AI-tool entry points and links out of the consuming repository's
commits through .gitignore. Local also ignores .ai and AI exclusion files;
Submodule records .ai and .gitmodules and leaves AI exclusion files eligible for
commits. Missing repository-owned guidance files are copied, never replaced.
Existing installations are reused without pulling updates. Conflicting paths,
tracked AI files, and implicit conversions between modes are rejected.
Existing .gitignore files must be valid UTF-8, with or without a BOM.
.PARAMETER RepositoryPath
The existing consuming Git repository root, not the Lillian checkout itself.
Defaults to the caller's current working directory.
.PARAMETER IsSubModule
Creates a tracked Git submodule when supplied. Otherwise, creates an ignored
local clone (the default).
.PARAMETER RepositoryUrl
Lillian's Git URL, or the path to a trusted local mirror (relative to the current
directory). Used to verify existing checkouts as well as to create new ones.
.PARAMETER Branch
The branch to use when creating the clone or registering the submodule.
.EXAMPLE
../lillian/tools/setup.ps1
Installs a local clone into the current repository.
.EXAMPLE
../lillian/tools/setup.ps1 -IsSubModule -WhatIf
Previews submodule setup in the current repository.
.EXAMPLE
./tools/setup.ps1 -RepositoryPath ../my-project
Uses an explicit target repository instead of the current directory.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateNotNullOrEmpty()]
    [string]$RepositoryPath = (Get-Location).Path,

    [switch]$IsSubModule,

    [ValidateNotNullOrEmpty()]
    [string]$RepositoryUrl = 'https://github.com/cilerler/lillian.git',

    [ValidateNotNullOrEmpty()]
    [string]$Branch = 'main'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$Mode = if ($IsSubModule) { 'Submodule' } else { 'Local' }

function Invoke-SetupGit {
    param(
        [string]$Directory,
        [string[]]$Arguments,
        [int[]]$AllowedExitCodes = @(0)
    )

    # Diagnostics must not refresh the index during -WhatIf. Required Git writes
    # (clone/submodule registration) still take their normal locks.
    $outputLines = @(& git --no-optional-locks -C $Directory @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -notin $AllowedExitCodes) {
        $outputText = ($outputLines | ForEach-Object { "$_" }) -join "`n"
        throw "Git failed in '$Directory' (exit $exitCode):`n$outputText"
    }

    # Native stderr warnings are diagnostics, not filenames or configuration values.
    $outputText = ($outputLines | Where-Object { $_ -isnot [Management.Automation.ErrorRecord] }) -join "`n"
    $outputLines | Where-Object { $_ -is [Management.Automation.ErrorRecord] } | ForEach-Object { Write-Verbose "Git: $_" }
    [pscustomobject]@{ ExitCode = $exitCode; Output = $outputText.TrimEnd() }
}

function Test-SetupPathIgnored {
    param([string]$Directory, [string]$Path)

    $ignored = Invoke-SetupGit $Directory @('check-ignore', '--no-index', '--quiet', '--', $Path) @(0, 1)
    if ($ignored.ExitCode -ne 0) { return $false }

    if ($Path.EndsWith('/')) {
        # A trailing slash can make Git report a CRLF blank line as an empty-pattern
        # match. Keep directory probes, but do not treat that record as an ignore rule.
        $matchedRule = Invoke-SetupGit $Directory @('check-ignore', '--no-index', '--verbose', '--', $Path) @(0, 1)
        $emptyMatchPattern = ':\d+:\t' + [regex]::Escape($Path) + '$'
        if ($matchedRule.ExitCode -ne 0 -or $matchedRule.Output -match $emptyMatchPattern) { return $false }
    }

    return $true
}

function Test-SamePath {
    param([string]$First, [string]$Second)

    $comparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    [string]::Equals(
        [IO.Path]::GetFullPath($First).TrimEnd([IO.Path]::DirectorySeparatorChar),
        [IO.Path]::GetFullPath($Second).TrimEnd([IO.Path]::DirectorySeparatorChar),
        $comparison
    )
}

function Get-SetupItem {
    param([string]$Path)
    # Get-Item also detects dangling symlinks, which Test-Path can miss.
    Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
}

function Test-SameRepositoryUrl {
    param([string]$First, [string]$Second)

    if ([IO.Path]::IsPathRooted($First) -and [IO.Path]::IsPathRooted($Second)) {
        return Test-SamePath $First $Second
    }
    $First.TrimEnd('/') -ceq $Second.TrimEnd('/')
}

function Assert-RegularPath {
    param([string]$Path, [switch]$Directory)

    $item = Get-SetupItem $Path
    if ($null -eq $item) { return }
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        $item.PSIsContainer -ne $Directory.IsPresent) {
        throw "Expected a regular $(if ($Directory) { 'directory' } else { 'file' }) at '$Path'. Existing content was not replaced."
    }
}

function Assert-ExpectedLink {
    param([string]$Path, [string]$Source)

    $item = Get-SetupItem $Path
    if ($null -eq $item) { return }
    if ($item.LinkType -ne 'SymbolicLink') {
        throw "'$Path' already exists and is not the expected symlink. Preserve or merge your content before running setup again."
    }

    $target = [string]$item.LinkTarget
    $resolvedTarget = [IO.Path]::GetFullPath($target, [IO.Path]::GetDirectoryName($Path))
    if ([IO.Path]::IsPathRooted($target) -or -not (Test-SamePath $resolvedTarget $Source)) {
        throw "'$Path' points somewhere other than the expected relative Lillian target. Existing links were not changed."
    }
}

$null = Get-Command git -ErrorAction Stop
if ([IO.Path]::IsPathRooted($RepositoryUrl) -or $RepositoryUrl -notmatch '^[^/\\]+:') {
    $mirrorItem = Get-Item -LiteralPath $RepositoryUrl -Force
    if (-not $mirrorItem.PSIsContainer) { throw 'RepositoryUrl must identify a Git URL or a local mirror directory.' }
    $RepositoryUrl = $mirrorItem.FullName.Replace('\', '/')
}
$repositoryItem = Get-Item -LiteralPath $RepositoryPath -Force
if (-not $repositoryItem.PSIsContainer) { throw 'RepositoryPath must be an existing Git repository directory.' }
$repositoryRoot = $repositoryItem.FullName
$gitRoot = (Invoke-SetupGit $repositoryRoot @('rev-parse', '--show-toplevel')).Output
if (-not (Test-SamePath $repositoryRoot $gitRoot)) {
    throw "RepositoryPath must be the repository root: '$gitRoot'."
}
if ((Test-SamePath $repositoryRoot (Split-Path -Parent $PSScriptRoot)) -or
    (Test-Path -LiteralPath (Join-Path $repositoryRoot 'tools/sync-ai-platforms.ps1'))) {
    throw 'Choose a consuming repository, not the Lillian source checkout.'
}

$vendorPath = Join-Path $repositoryRoot '.ai'
$ignorePath = Join-Path $repositoryRoot '.gitignore'
$modulesPath = Join-Path $repositoryRoot '.gitmodules'
$containerPaths = @('.github', '.claude', '.agents')
$copiedPaths = @('.github/CONTRIBUTING.md', '.github/copilot-instructions.md')
$linkSources = [ordered]@{
    'CLAUDE.md'            = 'CLAUDE.md'
    'AGENTS.md'            = 'AGENTS.md'
    '.github/skills'       = '.github/skills'
    '.github/agents'       = '.github/agents'
    '.github/instructions' = '.github/instructions'
    '.github/prompts'      = '.github/prompts'
    '.claude/skills'       = '.github/skills'
    '.claude/agents'       = '.claude/agents'
    '.claude/rules'        = '.claude/rules'
    '.claude/commands'     = '.claude/commands'
    '.agents/skills'       = '.github/skills'
    '.agents/workflows'    = '.agents/workflows'
    '.agents/rules'        = '.agents/rules'
}
$ignorePatterns = @(
    'CLAUDE.local.md', 'CLAUDE.md', 'AGENTS.md', 'GEMINI.md', '.mcp.json',
    '.github/agents', '.github/instructions', '.github/prompts', '.github/skills',
    '.claude/', '.agents/'
)
$localOnlyIgnorePatterns = @('.ai/', '.copilotignore', '.claudeignore', '.aiexclude', '.geminiignore')
if ($Mode -eq 'Local') { $ignorePatterns += $localOnlyIgnorePatterns }

Assert-RegularPath $ignorePath
Assert-RegularPath $modulesPath
Assert-RegularPath $vendorPath -Directory
foreach ($path in $containerPaths) { Assert-RegularPath (Join-Path $repositoryRoot $path) -Directory }
foreach ($path in $copiedPaths) { Assert-RegularPath (Join-Path $repositoryRoot $path) }
foreach ($entry in $linkSources.GetEnumerator()) {
    Assert-ExpectedLink (Join-Path $repositoryRoot $entry.Key) (Join-Path $vendorPath $entry.Value)
}

$personalPathspecs = @($ignorePatterns | Where-Object { $_ -ne '.ai/' } | ForEach-Object { ":(literal)$($_.TrimEnd('/'))" })
$trackedPersonalFiles = (Invoke-SetupGit $repositoryRoot (@('ls-files', '--') + $personalPathspecs)).Output
if ($trackedPersonalFiles) {
    throw "AI files are already tracked or staged. Ignore rules cannot untrack them; review their removal from the index separately:`n$trackedPersonalFiles"
}

$vendorIndex = (Invoke-SetupGit $repositoryRoot @('ls-files', '--stage', '--', '.ai')).Output
$submoduleName = $null
if (Test-Path -LiteralPath $modulesPath) {
    $moduleEntries = Invoke-SetupGit $repositoryRoot @('config', '--file', $modulesPath, '--get-regexp', '^submodule\..*\.path$') @(0, 1)
    foreach ($line in ($moduleEntries.Output -split '\r?\n')) {
        if ($line -match '^submodule\.(.+)\.path\s+(?:\./)?\.ai/?$') {
            if ($null -ne $submoduleName) { throw 'Multiple .gitmodules sections point at .ai. Resolve them before running setup.' }
            $submoduleName = $Matches[1]
        }
    }
}
$registeredSubmodule = $null -ne $submoduleName
if ($Mode -eq 'Local' -and ($vendorIndex -or $registeredSubmodule)) {
    throw '.ai is already tracked or registered as a submodule. Setup does not remove registrations or convert existing installations.'
}
if ($Mode -eq 'Submodule' -and ($vendorIndex -or $registeredSubmodule)) {
    if (-not $registeredSubmodule -or $vendorIndex -notmatch '^160000 [0-9a-f]+ 0\t\.ai$') {
        throw '.ai has an incomplete or conflicting submodule registration. Resolve its index and .gitmodules entries before running setup.'
    }
    $registeredUrl = (Invoke-SetupGit $repositoryRoot @('config', '--file', $modulesPath, '--get', "submodule.$submoduleName.url")).Output
    if (-not (Test-SameRepositoryUrl $registeredUrl $RepositoryUrl)) {
        throw 'The registered .ai submodule has a different URL. Supply its trusted URL with -RepositoryUrl or resolve the mismatch explicitly.'
    }
    $configuredUrl = Invoke-SetupGit $repositoryRoot @('config', '--get', "submodule.$submoduleName.url") @(0, 1)
    if ($configuredUrl.ExitCode -eq 0 -and -not (Test-SameRepositoryUrl $configuredUrl.Output $RepositoryUrl)) {
        throw 'The local .ai submodule URL differs from the requested URL. Review its Git configuration before initialization; setup will not change it.'
    }
}

$vendorGitItem = Get-SetupItem (Join-Path $vendorPath '.git')
$existingCheckout = $null -ne $vendorGitItem
if ($existingCheckout) {
    Assert-RegularPath (Join-Path $vendorPath '.git') -Directory:$vendorGitItem.PSIsContainer
    if ($Mode -eq 'Local' -and -not $vendorGitItem.PSIsContainer) {
        throw '.ai is not a standalone clone. Its Git metadata must be reviewed before using Local mode.'
    }
    if ($Mode -eq 'Submodule' -and -not $registeredSubmodule) {
        throw '.ai is an existing clone, not a registered submodule. Setup does not convert or replace it.'
    }
    $vendorRoot = (Invoke-SetupGit $vendorPath @('rev-parse', '--show-toplevel')).Output
    if (-not (Test-SamePath $vendorPath $vendorRoot)) { throw '.ai does not identify its own Git repository.' }
    # Compare the recorded URL; Git may use a user-configured insteadOf transport rewrite.
    $originUrl = (Invoke-SetupGit $vendorPath @('config', '--get-all', 'remote.origin.url')).Output
    if (-not (Test-SameRepositoryUrl $originUrl $RepositoryUrl)) {
        throw '.ai has a different origin. Supply its trusted URL with -RepositoryUrl or resolve the mismatch explicitly.'
    }
} elseif ((Test-Path -LiteralPath $vendorPath) -and
    @(Get-ChildItem -LiteralPath $vendorPath -Force).Count -ne 0) {
    throw '.ai is not empty and has no usable Git checkout. Existing files were not removed.'
}

if ($Mode -eq 'Submodule' -and -not $registeredSubmodule) {
    $modulesStatus = (Invoke-SetupGit $repositoryRoot @('status', '--porcelain', '--', '.gitmodules')).Output
    if ($modulesStatus) {
        throw '.gitmodules has existing changes. Commit or otherwise resolve them first; git submodule add stages that file.'
    }
}

$ignoreText = ''
$ignoreEncoding = [Text.UTF8Encoding]::new($false, $true)
if (Test-Path -LiteralPath $ignorePath) {
    $ignoreBytes = [IO.File]::ReadAllBytes($ignorePath)
    $hasBom = $ignoreBytes.Length -ge 3 -and $ignoreBytes[0] -eq 0xEF -and
        $ignoreBytes[1] -eq 0xBB -and $ignoreBytes[2] -eq 0xBF
    $ignoreEncoding = [Text.UTF8Encoding]::new($hasBom, $true)
    $textOffset = if ($hasBom) { 3 } else { 0 }
    try {
        $ignoreText = $ignoreEncoding.GetString($ignoreBytes, $textOffset, $ignoreBytes.Length - $textOffset)
    } catch [Text.DecoderFallbackException] {
        throw '.gitignore is not valid UTF-8. Review and convert its encoding explicitly before setup; its existing bytes were not changed.'
    }
}
$lineEnding = if ($ignoreText.Contains("`r`n")) { "`r`n" } elseif ($ignoreText) { "`n" } else { [Environment]::NewLine }
$managedPattern = '(?ms)^# >>> lillian >>>\r?\n.*?^# <<< lillian <<<(?:\r?\n|$)'
$managedMatches = [regex]::Matches($ignoreText, $managedPattern)
if ($managedMatches.Count -gt 1 -or
    ([regex]::Matches($ignoreText, '(?m)^# (?:>>> lillian >>>|<<< lillian <<<)\r?$').Count -ne 2 * $managedMatches.Count)) {
    throw '.gitignore contains an incomplete or duplicate Lillian managed block. Resolve it before running setup.'
}
$baseIgnoreText = [regex]::Replace($ignoreText, $managedPattern, '')
if ($Mode -eq 'Submodule') {
    # Remove previous direct Local-only rules, not unrelated patterns or negations.
    foreach ($pattern in $localOnlyIgnorePatterns) {
        $optionalSlash = if ($pattern.EndsWith('/')) { '/?' } else { '' }
        $directRule = '(?m)^/?' + [regex]::Escape($pattern.TrimEnd('/')) + $optionalSlash + '[ \t]*(?:\r?\n|$)'
        $baseIgnoreText = [regex]::Replace($baseIgnoreText, $directRule, '')
    }
}
$existingPatterns = @($baseIgnoreText -split '\r?\n' | ForEach-Object { $_.Trim() })
$missingPatterns = @($ignorePatterns | Where-Object { $existingPatterns -cnotcontains $_ })
$updatedIgnoreText = $baseIgnoreText
if ($missingPatterns.Count -gt 0) {
    # Normalize the block boundary so reruns do not accumulate blank lines.
    $updatedIgnoreText = $updatedIgnoreText.TrimEnd([char[]]"`r`n")
    if ($updatedIgnoreText) { $updatedIgnoreText += $lineEnding }
    $updatedIgnoreText += (@('', '# >>> lillian >>>', '# =========================',
        '# AI Files (managed by tools/setup.ps1)', '# =========================') +
        $missingPatterns + @('# <<< lillian <<<', '', '')) -join $lineEnding
}

if (-not $PSCmdlet.ShouldProcess($repositoryRoot, "Set up Lillian ($Mode): prepare .ai, update AI ignore rules, create relative links, and copy missing repository guidance")) {
    return
}

if ($updatedIgnoreText -cne $ignoreText) {
    [IO.File]::WriteAllText($ignorePath, $updatedIgnoreText, $ignoreEncoding)
    Write-Host 'Updated .gitignore (unrelated entries preserved).'
}
foreach ($pattern in $ignorePatterns) {
    if (-not (Test-SetupPathIgnored $repositoryRoot $pattern)) {
        throw "'$pattern' is not ignored because of another Git ignore rule. Resolve that rule and rerun setup."
    }
}
if ($Mode -eq 'Submodule') {
    foreach ($pattern in $localOnlyIgnorePatterns) {
        if (Test-SetupPathIgnored $repositoryRoot $pattern) {
            throw "'$pattern' is still ignored by another rule. Use git check-ignore -v --no-index -- $pattern to locate it; setup will not override broader ignore rules."
        }
    }
}

if (-not $existingCheckout) {
    if ($Mode -eq 'Local') {
        $null = Invoke-SetupGit $repositoryRoot @('clone', "--branch=$Branch", '--', $RepositoryUrl, '.ai')
    } elseif ($registeredSubmodule) {
        $null = Invoke-SetupGit $repositoryRoot @('submodule', 'update', '--init', '--checkout', '--', '.ai')
    } else {
        $null = Invoke-SetupGit $repositoryRoot @('submodule', 'add', "--branch=$Branch", '--', $RepositoryUrl, '.ai')
    }
    Write-Host "Prepared .ai ($Mode)."
} else {
    Write-Host 'Reusing .ai without pulling or changing its checked-out revision.'
}

$originUrl = (Invoke-SetupGit $vendorPath @('config', '--get-all', 'remote.origin.url')).Output
if (-not (Test-SameRepositoryUrl $originUrl $RepositoryUrl)) {
    throw 'The acquired .ai checkout has a different origin. Review its Git configuration; no consumer links or guidance files were created.'
}
foreach ($path in $containerPaths) { Assert-RegularPath (Join-Path $vendorPath $path) -Directory }
foreach ($sourcePath in @($linkSources.Values) + $copiedPaths) {
    $source = Join-Path $vendorPath $sourcePath
    if (-not (Test-Path -LiteralPath $source)) {
        throw "The Lillian checkout is missing '$sourcePath'. No consumer links or guidance files have been created."
    }
    Assert-RegularPath $source -Directory:($sourcePath -notlike '*.md')
}
foreach ($path in $containerPaths) {
    $null = New-Item -ItemType Directory -Path (Join-Path $repositoryRoot $path) -Force
}
foreach ($entry in $linkSources.GetEnumerator()) {
    $linkPath = Join-Path $repositoryRoot $entry.Key
    $sourcePath = Join-Path $vendorPath $entry.Value
    Assert-ExpectedLink $linkPath $sourcePath
    if ($null -ne (Get-SetupItem $linkPath)) { continue }
    $parentPath = [IO.Path]::GetDirectoryName($linkPath)
    $relativeTarget = [IO.Path]::GetRelativePath($parentPath, $sourcePath).Replace('\', '/')
    Push-Location -LiteralPath $parentPath
    try {
        $null = New-Item -ItemType SymbolicLink -Path ([IO.Path]::GetFileName($linkPath)) -Target $relativeTarget
    } catch {
        throw "Could not create '$linkPath'. On Windows, enable Developer Mode or run an elevated PowerShell. Existing files were preserved; rerun after resolving the error. $($_.Exception.Message)"
    } finally { Pop-Location }
    Write-Host "Linked $($entry.Key)."
}
foreach ($path in $copiedPaths) {
    $destinationPath = Join-Path $repositoryRoot $path
    if ($null -ne (Get-SetupItem $destinationPath)) {
        Write-Host "Preserved existing $path."
    } else {
        [IO.File]::Copy((Join-Path $vendorPath $path), $destinationPath, $false)
        Write-Host "Copied $path; review it for your repository."
    }
}

Write-Host "Lillian setup complete ($Mode). Review .gitignore and the repository-owned guidance files before committing."
if ($Mode -eq 'Submodule') {
    Write-Host 'Git stages .ai and .gitmodules when adding a submodule. Review those changes; setup does not commit them.'
    Write-Host 'VS Code can display .ai nested beneath the parent repository.'
} else {
    Write-Host '.ai and the AI-tool links remain untracked. VS Code displays the clone as a separate repository, not a submodule child.'
}
Write-Host 'No hooks, synchronization scripts, editor settings, or global Git configuration were installed or changed.'
