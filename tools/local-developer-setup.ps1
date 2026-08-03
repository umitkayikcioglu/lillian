#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
param(
    [ValidateNotNullOrEmpty()]
    [string]$Lillian = $PSScriptRoot,

    [ValidateNotNullOrEmpty()]
    [string]$RepositoryUrl = "https://github.com/umitkayikcioglu/lillian.git",

    [switch]$SkipRepositoryUpdate,

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

if ([string]::IsNullOrWhiteSpace($HOME)) {
    throw "HOME yolu belirlenemedi."
}

$Utf8NoBom = [System.Text.UTF8Encoding]::new($false, $true)
$Lillian = [System.IO.Path]::GetFullPath($Lillian)
$HomePath = [System.IO.Path]::GetFullPath($HOME)

$LillianSkills = Join-Path $Lillian ".github\skills"
$LillianPrompts = Join-Path $Lillian ".github\prompts"
$UserSkills = Join-Path $HomePath ".agents\skills"
$CodexHome = Join-Path $HomePath ".codex"
$GlobalAgents = Join-Path $CodexHome "AGENTS.md"

$BeginMarker = "<!-- BEGIN LILLIAN GLOBAL -->"
$EndMarker = "<!-- END LILLIAN GLOBAL -->"
$PromptWrapperMarkerName = ".lillian-prompt-wrapper"
$PromptManifestName = ".lillian-managed-prompts.json"
$ManagerName = "local-developer-setup.ps1"

function Get-NormalizedPath {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    return [System.IO.Path]::TrimEndingDirectorySeparator(
        [System.IO.Path]::GetFullPath($Path)
    )
}

function Test-SamePath {
    param(
        [Parameter(Mandatory)]
        [string]$First,

        [Parameter(Mandatory)]
        [string]$Second
    )

    return [string]::Equals(
        (Get-NormalizedPath -Path $First),
        (Get-NormalizedPath -Path $Second),
        [System.StringComparison]::OrdinalIgnoreCase
    )
}

function Assert-ImmediateChildPath {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Parent
    )

    $normalizedPath = Get-NormalizedPath -Path $Path
    $normalizedParent = Get-NormalizedPath -Path $Parent
    $actualParent = Split-Path -Parent $normalizedPath

    if (-not (Test-SamePath -First $actualParent -Second $normalizedParent)) {
        throw "Yol beklenen klasörün doğrudan altında değil: $normalizedPath"
    }
}

function Test-ReparsePoint {
    param(
        [Parameter(Mandatory)]
        [System.IO.FileSystemInfo]$Item
    )

    return [bool](
        $Item.LinkType -or
        ($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
    )
}

function Assert-SafeDestinationRoot {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$TrustedRoot
    )

    $normalizedPath = Get-NormalizedPath -Path $Path
    $normalizedRoot = Get-NormalizedPath -Path $TrustedRoot
    $prefix = $normalizedRoot + [System.IO.Path]::DirectorySeparatorChar

    if (-not $normalizedPath.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Hedef HOME klasörünün dışında: $normalizedPath"
    }

    $relativePath = [System.IO.Path]::GetRelativePath($normalizedRoot, $normalizedPath)
    $current = $normalizedRoot

    foreach ($segment in $relativePath -split '[\\/]') {
        $current = Join-Path $current $segment
        $item = Get-Item -LiteralPath $current -Force -ErrorAction SilentlyContinue

        if ($null -ne $item -and (Test-ReparsePoint -Item $item)) {
            throw "Hedef yol reparse point üzerinden geçiyor: $current"
        }
    }
}

function Assert-MarkdownSafePath {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (
        $Path.IndexOf([char]0x60) -ge 0 -or
        $Path.Contains("`r") -or
        $Path.Contains("`n") -or
        $Path.Contains("{{")
    ) {
        throw "Yol güvenli Markdown üretimi için desteklenmeyen karakter içeriyor: $Path"
    }
}

function Assert-Command {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "'$Name' komutu bulunamadı."
    }
}

function Get-LinkTargetPath {
    param(
        [Parameter(Mandatory)]
        [System.IO.FileSystemInfo]$Item
    )

    $target = [string]$Item.Target

    if ([string]::IsNullOrWhiteSpace($target)) {
        return $null
    }

    if (-not [System.IO.Path]::IsPathFullyQualified($target)) {
        $target = Join-Path $Item.DirectoryName $target
    }

    return Get-NormalizedPath -Path $target
}

function Install-LillianSkills {
    param(
        [Parameter(Mandatory)]
        [string]$SourceRoot,

        [Parameter(Mandatory)]
        [string]$DestinationRoot,

        [switch]$Force
    )

    New-Item -ItemType Directory -Force -Path $DestinationRoot | Out-Null

    $linked = 0
    $overwritten = 0
    $skipped = 0
    $names = [System.Collections.Generic.List[string]]::new()

    foreach ($skill in Get-ChildItem -LiteralPath $SourceRoot -Directory | Sort-Object Name) {
        [void]$names.Add($skill.Name)
        $source = $skill.FullName
        $target = Join-Path $DestinationRoot $skill.Name
        Assert-ImmediateChildPath -Path $target -Parent $DestinationRoot

        $existing = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue

        if ($null -ne $existing) {
            if (Test-ReparsePoint -Item $existing) {
                $linkTarget = Get-LinkTargetPath -Item $existing

                if ($null -ne $linkTarget -and (Test-SamePath -First $linkTarget -Second $source)) {
                    Write-Host "Skill zaten bağlı: $($skill.Name)" -ForegroundColor DarkGreen
                    $linked++
                    continue
                }
                else {
                    if (-not $Force) {
                        Write-Warning "Skill atlandı; aynı isimde kullanıcıya ait bağlantı mevcut: $target"
                        $skipped++
                        continue
                    }
                }
            }
            elseif (-not $Force) {
                Write-Warning "Skill atlandı; aynı isimde gerçek klasör mevcut: $target"
                $skipped++
                continue
            }

            $stagedPath = Join-Path $DestinationRoot ".$($skill.Name).lillian-stage-$([guid]::NewGuid().ToString('N'))"
            Assert-ImmediateChildPath -Path $stagedPath -Parent $DestinationRoot
            New-Item -ItemType Junction -Path $stagedPath -Target $source | Out-Null

            try {
                Replace-DirectoryAtomically `
                    -StagedPath $stagedPath `
                    -TargetPath $target `
                    -Parent $DestinationRoot
            }
            finally {
                if (Test-Path -LiteralPath $stagedPath) {
                    Remove-Item -LiteralPath $stagedPath -Force
                }
            }

            Write-Host "Skill üzerine yazıldı: $($skill.Name)" -ForegroundColor Yellow
            $linked++
            $overwritten++
            continue
        }

        New-Item -ItemType Junction -Path $target -Target $source | Out-Null
        Write-Host "Skill bağlandı: $($skill.Name)" -ForegroundColor Green
        $linked++
    }

    return [pscustomobject]@{
        Linked      = $linked
        Overwritten = $overwritten
        Skipped     = $skipped
        Names       = $names.ToArray()
    }
}


function Get-PromptDescription {
    param(
        [Parameter(Mandatory)]
        [string]$Content,

        [Parameter(Mandatory)]
        [string]$Fallback
    )

    if ($Content -match "(?s)\A---[ \t]*\r?\n(.*?)\r?\n---[ \t]*(?:\r?\n|\z)") {
        $frontmatter = $Matches[1]

        if ($frontmatter -match "(?m)^[ \t]*description[ \t]*:[ \t]*(.*?)[ \t]*$") {
            $value = $Matches[1].Trim()

            if ($value -in @("|", "|-", "|+", ">", ">-", ">+")) {
                return $Fallback
            }

            if (
                $value.Length -ge 2 -and
                (($value[0] -eq '"' -and $value[-1] -eq '"') -or
                ($value[0] -eq "'" -and $value[-1] -eq "'"))
            ) {
                $value = $value.Substring(1, $value.Length - 2)
            }

            if (-not [string]::IsNullOrWhiteSpace($value)) {
                return $value
            }
        }
    }

    return $Fallback
}

function ConvertTo-YamlSingleQuoted {
    param(
        [Parameter(Mandatory)]
        [string]$Value
    )

    return "'" + ($Value -replace "'", "''") + "'"
}

function New-PromptMarkerContent {
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath
    )

    return [ordered]@{
        Version = 1
        Manager = $ManagerName
        Source  = (Get-NormalizedPath -Path $SourcePath)
    } | ConvertTo-Json -Compress
}

function Test-PromptMarker {
    param(
        [Parameter(Mandatory)]
        [string]$MarkerPath,

        [Parameter(Mandatory)]
        [string]$ExpectedSource,

        [switch]$AllowLegacy
    )

    $markerItem = Get-Item -LiteralPath $MarkerPath -Force -ErrorAction SilentlyContinue

    if ($null -eq $markerItem -or $markerItem.PSIsContainer -or (Test-ReparsePoint -Item $markerItem)) {
        return $false
    }

    $content = [System.IO.File]::ReadAllText($markerItem.FullName, $Utf8NoBom)
    $expectedPath = Get-NormalizedPath -Path $ExpectedSource

    try {
        $marker = $content | ConvertFrom-Json -ErrorAction Stop

        return (
            $marker.Version -eq 1 -and
            $marker.Manager -eq $ManagerName -and
            (Test-SamePath -First ([string]$marker.Source) -Second $expectedPath)
        )
    }
    catch {
        if ($AllowLegacy) {
            $legacy = "Managed by local-developer-setup.ps1 from: " + $expectedPath.Replace("\", "/")
            return $content -eq $legacy
        }

        return $false
    }
}

function Read-TextFileWithFormat {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $reader = [System.IO.StreamReader]::new($Path, $Utf8NoBom, $true)

    try {
        $content = $reader.ReadToEnd()
        $encoding = $reader.CurrentEncoding
    }
    finally {
        $reader.Dispose()
    }

    $newLine = if ($content.Contains("`r`n")) { "`r`n" } else { "`n" }

    return [pscustomobject]@{
        Content  = $content
        Encoding = $encoding
        NewLine  = $newLine
    }
}

function Write-TextFileAtomically {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Content,

        [Parameter(Mandatory)]
        [System.Text.Encoding]$Encoding
    )

    $parent = Split-Path -Parent $Path
    $fileName = Split-Path -Leaf $Path
    $temporaryPath = Join-Path $parent ".$fileName.lillian-stage-$([guid]::NewGuid().ToString('N'))"
    $backupPath = "$temporaryPath.backup"
    Assert-ImmediateChildPath -Path $temporaryPath -Parent $parent

    try {
        [System.IO.File]::WriteAllText($temporaryPath, $Content, $Encoding)

        if (Test-Path -LiteralPath $Path) {
            $existing = Get-Item -LiteralPath $Path -Force

            if ($existing.PSIsContainer -or (Test-ReparsePoint -Item $existing)) {
                throw "Yönetilen dosya normal bir dosya değil: $Path"
            }

            [System.IO.File]::Replace($temporaryPath, $Path, $backupPath, $true)
            [System.IO.File]::Delete($backupPath)
        }
        else {
            [System.IO.File]::Move($temporaryPath, $Path)
        }
    }
    finally {
        [System.IO.File]::Delete($temporaryPath)
    }
}

function Replace-DirectoryAtomically {
    param(
        [Parameter(Mandatory)]
        [string]$StagedPath,

        [Parameter(Mandatory)]
        [string]$TargetPath,

        [Parameter(Mandatory)]
        [string]$Parent
    )

    Assert-ImmediateChildPath -Path $StagedPath -Parent $Parent
    Assert-ImmediateChildPath -Path $TargetPath -Parent $Parent

    if (-not (Test-Path -LiteralPath $TargetPath)) {
        Move-Item -LiteralPath $StagedPath -Destination $TargetPath
        return
    }

    $backupPath = Join-Path $Parent ".$(Split-Path -Leaf $TargetPath).lillian-backup-$([guid]::NewGuid().ToString('N'))"
    Assert-ImmediateChildPath -Path $backupPath -Parent $Parent
    Move-Item -LiteralPath $TargetPath -Destination $backupPath

    try {
        Move-Item -LiteralPath $StagedPath -Destination $TargetPath
    }
    catch {
        Move-Item -LiteralPath $backupPath -Destination $TargetPath
        throw
    }

    $backupItem = Get-Item -LiteralPath $backupPath -Force

    if (Test-ReparsePoint -Item $backupItem) {
        Remove-Item -LiteralPath $backupPath -Force
    }
    else {
        Remove-Item -LiteralPath $backupPath -Recurse -Force
    }
}

function Read-PromptManifest {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue

    if ($null -eq $item) {
        return @()
    }

    if ($item.PSIsContainer -or (Test-ReparsePoint -Item $item)) {
        throw "Prompt manifest normal bir dosya değil: $Path"
    }

    $manifest = [System.IO.File]::ReadAllText($Path, $Utf8NoBom) | ConvertFrom-Json -ErrorAction Stop

    if ($manifest.Version -ne 1 -or $manifest.Manager -ne $ManagerName) {
        throw "Prompt manifest sahipliği doğrulanamadı: $Path"
    }

    return @($manifest.Entries)
}

function Install-LillianPromptWrappers {
    param(
        [Parameter(Mandatory)]
        [string]$PromptRoot,

        [Parameter(Mandatory)]
        [string]$DestinationRoot,

        [Parameter(Mandatory)]
        [string]$LillianMarkdownPath,

        [string[]]$ProtectedSkillNames = @(),

        [switch]$Force
    )

    New-Item -ItemType Directory -Force -Path $DestinationRoot | Out-Null

    $manifestPath = Join-Path $DestinationRoot $PromptManifestName
    Assert-ImmediateChildPath -Path $manifestPath -Parent $DestinationRoot
    $previousEntries = Read-PromptManifest -Path $manifestPath
    $created = 0
    $updated = 0
    $overwritten = 0
    $skipped = 0
    $names = [System.Collections.Generic.List[string]]::new()
    $managedEntries = [System.Collections.Generic.List[object]]::new()
    $expectedNames = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $protectedNames = [System.Collections.Generic.HashSet[string]]::new(
        $ProtectedSkillNames,
        [System.StringComparer]::OrdinalIgnoreCase
    )

    foreach ($prompt in Get-ChildItem -LiteralPath $PromptRoot -Filter "*.prompt.md" -File | Sort-Object Name) {
        $name = $prompt.Name -replace "\.prompt\.md$", ""

        if ($name -notmatch "^[a-z0-9][a-z0-9-]*$") {
            Write-Warning "Prompt adı Codex skill adı olarak uygun değil; atlandı: $($prompt.Name)"
            $skipped++
            continue
        }

        if ($protectedNames.Contains($name)) {
            Write-Warning "Prompt wrapper atlandı; aynı isimde Lillian skill mevcut: $name"
            $skipped++
            continue
        }

        [void]$expectedNames.Add($name)

        $target = Join-Path $DestinationRoot $name
        Assert-ImmediateChildPath -Path $target -Parent $DestinationRoot
        $markerFile = Join-Path $target $PromptWrapperMarkerName
        $existing = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
        $wasManagedWrapper = $false
        $wasOverwritten = $false
        $sourceContent = [System.IO.File]::ReadAllText($prompt.FullName, $Utf8NoBom)
        $description = Get-PromptDescription `
            -Content $sourceContent `
            -Fallback "Run the Lillian '$name' workflow against the active repository."

        $yamlDescription = ConvertTo-YamlSingleQuoted -Value $description
        $promptSourcePath = Get-NormalizedPath -Path $prompt.FullName
        $promptMarkdownPath = $promptSourcePath.Replace("\", "/")

        if ($null -ne $existing) {
            if (Test-ReparsePoint -Item $existing) {
                if (-not $Force) {
                    Write-Warning "Prompt wrapper atlandı; aynı isimde gerçek skill mevcut: $name"
                    $skipped++
                    continue
                }

                $wasOverwritten = $true
            }
            elseif (Test-PromptMarker -MarkerPath $markerFile -ExpectedSource $promptSourcePath -AllowLegacy) {
                $wasManagedWrapper = $true
            }
            elseif (-not $Force) {
                Write-Warning "Prompt wrapper atlandı; aynı isimde kullanıcıya ait skill mevcut: $target"
                $skipped++
                continue
            }
            else {
                $wasOverwritten = $true
            }
        }

        $wrapper = @"
---
name: $name
description: $yamlDescription
---

# Lillian prompt: $name

Source prompt:

``$promptMarkdownPath``

When this skill is invoked:

1. Read the source prompt completely before taking action.
2. Ignore Copilot-only frontmatter keys such as ``mode`` and Copilot tool names.
3. Apply the prompt body to the active repository and current user request.
4. Resolve Lillian-relative references as follows:
   - ``.github/agents/`` -> ``$LillianMarkdownPath/.github/agents/``
   - ``.github/instructions/`` -> ``$LillianMarkdownPath/.github/instructions/``
   - ``.github/skills/`` -> ``$LillianMarkdownPath/.github/skills/``
   - ``.github/prompts/`` -> ``$LillianMarkdownPath/.github/prompts/``
   - ``.github/CONTRIBUTING.md`` -> ``$LillianMarkdownPath/.github/CONTRIBUTING.md``
5. Read and prioritize repository-local ``AGENTS.override.md`` and ``AGENTS.md``.
6. Treat ``$LillianMarkdownPath`` as read-only unless Lillian is the active
   workspace and the user explicitly requests a Lillian change.
7. Preserve approval gates, output contracts, verification requirements, and
   stop conditions from the source prompt.
8. Use the rest of the invocation as task context.
"@

        $stagedPath = Join-Path $DestinationRoot ".$name.lillian-stage-$([guid]::NewGuid().ToString('N'))"
        Assert-ImmediateChildPath -Path $stagedPath -Parent $DestinationRoot
        New-Item -ItemType Directory -Path $stagedPath | Out-Null

        try {
            [System.IO.File]::WriteAllText(
                (Join-Path $stagedPath "SKILL.md"),
                ($wrapper -replace "`r`n", "`n"),
                $Utf8NoBom
            )

            [System.IO.File]::WriteAllText(
                (Join-Path $stagedPath $PromptWrapperMarkerName),
                (New-PromptMarkerContent -SourcePath $promptSourcePath),
                $Utf8NoBom
            )

            Replace-DirectoryAtomically `
                -StagedPath $stagedPath `
                -TargetPath $target `
                -Parent $DestinationRoot
        }
        finally {
            if (Test-Path -LiteralPath $stagedPath) {
                Remove-Item -LiteralPath $stagedPath -Recurse -Force
            }
        }

        $managedEntries.Add([ordered]@{
            Name   = $name
            Source = $promptSourcePath
        })

        if ($wasOverwritten) {
            Write-Host "Prompt üzerine yazıldı : $name" -ForegroundColor Yellow
            $overwritten++
        }
        elseif ($wasManagedWrapper) {
            Write-Host "Prompt güncellendi    : $name" -ForegroundColor DarkGreen
            $updated++
        }
        else {
            Write-Host "Prompt skill oluşturuldu: $name" -ForegroundColor Green
            $created++
        }

        $names.Add($name)
    }

    foreach ($entry in $previousEntries) {
        $name = [string]$entry.Name
        $source = [string]$entry.Source

        if ($name -notmatch "^[a-z0-9][a-z0-9-]*$" -or $expectedNames.Contains($name)) {
            continue
        }

        $target = Join-Path $DestinationRoot $name
        Assert-ImmediateChildPath -Path $target -Parent $DestinationRoot
        $existing = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue

        if ($null -eq $existing) {
            continue
        }

        $markerFile = Join-Path $target $PromptWrapperMarkerName

        if (
            (Test-ReparsePoint -Item $existing) -or
            (-not (Test-PromptMarker -MarkerPath $markerFile -ExpectedSource $source))
        ) {
            Write-Warning "Eski prompt silinmedi; sahipliği doğrulanamadı: $target"
            continue
        }

        Remove-Item -LiteralPath $target -Recurse -Force
        Write-Host "Eski prompt kaldırıldı: $name" -ForegroundColor Yellow
    }

    $manifestContent = [ordered]@{
        Version = 1
        Manager = $ManagerName
        Entries = $managedEntries.ToArray()
    } | ConvertTo-Json -Depth 4

    Write-TextFileAtomically `
        -Path $manifestPath `
        -Content (($manifestContent -replace "`r`n", "`n") + "`n") `
        -Encoding $Utf8NoBom

    return [pscustomobject]@{
        Created     = $created
        Updated     = $updated
        Overwritten = $overwritten
        Skipped     = $skipped
        Names       = $names.ToArray()
    }
}

function Set-ManagedTextBlock {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Begin,

        [Parameter(Mandatory)]
        [string]$End,

        [Parameter(Mandatory)]
        [string]$Block
    )

    if (Test-Path -LiteralPath $Path) {
        $file = Read-TextFileWithFormat -Path $Path
        $existingContent = $file.Content
        $encoding = $file.Encoding
        $newLine = $file.NewLine
    }
    else {
        $existingContent = ""
        $encoding = $Utf8NoBom
        $newLine = "`n"
    }

    $normalizedBlock = ($Block -replace "`r`n|`r|`n", $newLine)
    $pattern =
        "(?ms)" +
        [regex]::Escape($Begin) +
        ".*?" +
        [regex]::Escape($End)

    $matches = [regex]::Matches($existingContent, $pattern)

    if ($matches.Count -gt 0) {
        $first = $matches[0]
        $before = $existingContent.Substring(0, $first.Index)
        $after = $existingContent.Substring($first.Index + $first.Length)
        $after = [regex]::Replace($after, $pattern, "")
        $updatedContent = $before + $normalizedBlock + $after
    }
    elseif ([string]::IsNullOrWhiteSpace($existingContent)) {
        $updatedContent = $normalizedBlock + $newLine
    }
    else {
        $separator = if ($existingContent.EndsWith($newLine + $newLine)) {
            ""
        }
        elseif ($existingContent.EndsWith($newLine)) {
            $newLine
        }
        else {
            $newLine + $newLine
        }

        $updatedContent = $existingContent + $separator + $normalizedBlock + $newLine
    }

    Write-TextFileAtomically -Path $Path -Content $updatedContent -Encoding $encoding
}

function Normalize-GitRemoteUrl {
    param(
        [Parameter(Mandatory)]
        [string]$Url
    )

    return $Url.Trim().TrimEnd('/').TrimEnd('\')
}

function Invoke-GitCommand {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments,

        [Parameter(Mandatory)]
        [string]$FailureMessage
    )

    $output = & git @Arguments 2>&1

    if ($LASTEXITCODE -ne 0) {
        $detail = ($output | ForEach-Object { $_.ToString() }) -join "`n"
        throw "$FailureMessage`n$detail"
    }

    return (($output | ForEach-Object { $_.ToString() }) -join "`n").Trim()
}

function Assert-GitRepository {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$ExpectedRemote
    )

    $repositoryRoot = Invoke-GitCommand `
        -Arguments @("-C", $Path, "rev-parse", "--show-toplevel") `
        -FailureMessage "Git repository kökü doğrulanamadı: $Path"

    if (-not (Test-SamePath -First $repositoryRoot -Second $Path)) {
        throw "Lillian yolu repository kökü değil: $Path"
    }

    $origin = Invoke-GitCommand `
        -Arguments @("-C", $Path, "remote", "get-url", "origin") `
        -FailureMessage "Git origin doğrulanamadı: $Path"

    if (-not [string]::Equals(
        (Normalize-GitRemoteUrl -Url $origin),
        (Normalize-GitRemoteUrl -Url $ExpectedRemote),
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Git origin beklenen repository ile eşleşmiyor. Beklenen: $ExpectedRemote; bulunan: $origin"
    }
}

Assert-Command -Name "git"
Assert-SafeDestinationRoot -Path $UserSkills -TrustedRoot $HomePath
Assert-SafeDestinationRoot -Path $CodexHome -TrustedRoot $HomePath
Assert-MarkdownSafePath -Path $Lillian
Assert-MarkdownSafePath -Path $UserSkills

if (-not $PSCmdlet.ShouldProcess(
    "$Lillian ve $HomePath altındaki Codex kullanıcı yapılandırması",
    "Lillian repository ve kullanıcı kapsamındaki skill/talimatları güncelle"
)) {
    return
}

if (Test-Path -LiteralPath (Join-Path $Lillian ".git")) {
    Assert-GitRepository -Path $Lillian -ExpectedRemote $RepositoryUrl

    if (-not $SkipRepositoryUpdate) {
        Write-Host "Lillian güncelleniyor..." -ForegroundColor Cyan
        $pullOutput = Invoke-GitCommand `
            -Arguments @("-C", $Lillian, "pull", "--ff-only") `
            -FailureMessage "Lillian güncellenemedi. Local değişiklikleri ve branch durumunu kontrol edin: $Lillian"

        if (-not [string]::IsNullOrWhiteSpace($pullOutput)) {
            Write-Host $pullOutput
        }
    }
}
elseif (Test-Path -LiteralPath $Lillian) {
    throw "Lillian yolu mevcut fakat Git repository değil: $Lillian"
}
else {
    Write-Host "Lillian klonlanıyor..." -ForegroundColor Cyan
    $parent = Split-Path -Parent $Lillian
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $clonePath = Join-Path $parent ".$([System.IO.Path]::GetFileName($Lillian)).lillian-clone-$([guid]::NewGuid().ToString('N'))"
    Assert-ImmediateChildPath -Path $clonePath -Parent $parent

    try {
        [void](Invoke-GitCommand `
            -Arguments @("clone", "--", $RepositoryUrl, $clonePath) `
            -FailureMessage "Lillian repository klonlanamadı.")
        Assert-GitRepository -Path $clonePath -ExpectedRemote $RepositoryUrl
        Move-Item -LiteralPath $clonePath -Destination $Lillian
    }
    finally {
        if (Test-Path -LiteralPath $clonePath) {
            Remove-Item -LiteralPath $clonePath -Recurse -Force
        }
    }
}

$LillianSkills = Join-Path $Lillian ".github\skills"
$LillianPrompts = Join-Path $Lillian ".github\prompts"

if (-not (Test-Path -LiteralPath $LillianSkills -PathType Container)) {
    throw "Lillian skills klasörü bulunamadı: $LillianSkills"
}

if (-not (Test-Path -LiteralPath $LillianPrompts -PathType Container)) {
    throw "Lillian prompts klasörü bulunamadı: $LillianPrompts"
}

New-Item -ItemType Directory -Force -Path $CodexHome | Out-Null

# Tüm Lillian skill'lerini Codex kullanıcı kapsamına bağla.
# AGENTS.md ve prompt wrapper yolları için slash kullan.
$LillianMarkdownPath = $Lillian.Replace("\", "/")
$UserSkillsMarkdownPath = $UserSkills.Replace("\", "/")

$skillResult = Install-LillianSkills `
    -SourceRoot $LillianSkills `
    -DestinationRoot $UserSkills `
    -Force:$Force

$promptResult = Install-LillianPromptWrappers `
    -PromptRoot $LillianPrompts `
    -DestinationRoot $UserSkills `
    -LillianMarkdownPath $LillianMarkdownPath `
    -ProtectedSkillNames $skillResult.Names `
    -Force:$Force

$promptCatalog = if ($promptResult.Names.Count -gt 0) {
    ($promptResult.Names | ForEach-Object { "- ``$" + $_ + "``" }) -join "`n"
}
else {
    "- No prompt workflows were installed."
}

$AgentsTemplate = @'
<!-- BEGIN LILLIAN GLOBAL -->

# Global Lillian Configuration

Lillian source repository:

`{{LILLIAN}}`

Codex user-scope skills:

`{{USER_SKILLS}}`

## Platform model

This configuration targets the VS Code Codex extension.

- `.github/skills/` are installed as native Codex user-scope skills.
- `.github/prompts/` are converted into Codex-compatible skill wrappers.
- `.github/copilot-instructions.md` provides orchestration through this global file.
- `.github/CONTRIBUTING.md` provides engineering standards through this global file.
- `.github/instructions/` are selected by `applyTo` because Codex has no native
  Copilot instruction-file surface.
- `.github/agents/` are read explicitly because Codex has no native Copilot
  persona-file surface.

Do not run Lillian `tools/sync-ai-platforms.ps1` for this setup. Its generated
Claude and Antigravity outputs are not VS Code Codex inputs.

Do not place Lillian content in `.codex/config.toml`; it is machine configuration.

## Scope and precedence

Apply these defaults to software engineering work in every repository.

Instruction precedence, from highest to lowest:

1. The closest repository-local `AGENTS.override.md`.
2. The closest repository-local `AGENTS.md`.
3. Repository-specific standards and conventions.
4. Lillian `.github/CONTRIBUTING.md`.
5. Matching Lillian `.github/instructions/*.instructions.md`.
6. These global defaults.

Never replace an established repository convention silently. Identify conflicts
and request approval before introducing a different testing, UI, database,
infrastructure, naming, or solution-structure standard.

## Mandatory Lillian sources

For every non-trivial software development task, read and apply:

- `{{LILLIAN}}/.github/copilot-instructions.md`
- `{{LILLIAN}}/.github/CONTRIBUTING.md`

Before planning, creating, reviewing, testing, or modifying source files:

1. Inspect `{{LILLIAN}}/.github/instructions/`.
2. Read every `*.instructions.md` file whose `applyTo` glob matches the files
   involved in the task.
3. Treat an instruction with `applyTo: "**"` as always applicable.
4. Continue to apply the selected instructions throughout the task.
5. If an instruction conflicts with repository-local rules, the repository-local
   rule wins.

Codex does not natively load Copilot path-scoped instruction files. This
selection procedure is therefore mandatory.

## Skills

Lillian skills are installed at user scope and are available in every repository.

- Use a skill when explicitly invoked with `$skill-name`.
- A matching skill may also be selected implicitly when its trigger clearly
  matches the task.
- Read the complete `SKILL.md` before applying a skill.
- Follow the skill's prerequisites, required inputs, mandatory conditions,
  output contract, and validation steps.

## Prompt workflows

Lillian `.github/prompts/*.prompt.md` files are exposed as user-scope Codex
skill wrappers:

{{PROMPT_CATALOG}}

Rules:

- Invoke a prompt workflow with `$prompt-name`.
- Each wrapper reads the current source prompt from Lillian before acting.
- Copilot-specific `mode` and tool frontmatter are ignored.
- Prompt approval gates, source references, output contracts, verification
  requirements, and stop conditions still apply.
- Work targets the active repository; Lillian remains a read-only source.

## Workflow

For non-trivial work:

1. Analyze the active repository and its local instructions.
2. Enter plan mode.
3. Produce an actionable plan and acceptance criteria.
4. Obtain explicit approval before changing workflow roles when Lillian's
   sequential workflow is being used.
5. Implement only after required planning and design gates are satisfied.
6. Verify with the appropriate build, test, lint, migration, security, and
   operational checks.
7. Do not mark the work complete without verification evidence.

Follow the detailed orchestration in:

`{{LILLIAN}}/.github/copilot-instructions.md`

The full workflow can also be invoked with `$agent-workflow`.

## Workflow roles

When a Lillian role is requested, read and follow its complete definition:

- Planner:
  `{{LILLIAN}}/.github/agents/workflow-planner.agent.md`
- Architect:
  `{{LILLIAN}}/.github/agents/workflow-architect.agent.md`
- Designer:
  `{{LILLIAN}}/.github/agents/workflow-designer.agent.md`
- DBA:
  `{{LILLIAN}}/.github/agents/workflow-dba.agent.md`
- Developer:
  `{{LILLIAN}}/.github/agents/workflow-developer.agent.md`
- Reviewer:
  `{{LILLIAN}}/.github/agents/workflow-reviewer.agent.md`
- Tester:
  `{{LILLIAN}}/.github/agents/workflow-tester.agent.md`
- Documenter:
  `{{LILLIAN}}/.github/agents/workflow-documenter.agent.md`

Each role must produce its expected output and stop. Do not hand off
automatically to the next role without explicit user approval.

## Task management and self-improvement

Apply Lillian's task-management rules to non-trivial implementation work:

- Maintain the implementation plan in `<active-repository>/tasks/todo.md`.
- Use checkable work items and update progress as work proceeds.
- Add a review/results section when the work is completed.
- When the user corrects an implementation, decision, or recurring behavior,
  record the reusable lesson in `<active-repository>/tasks/lessons.md`.

Do not create or update these files for:

- Simple questions.
- Read-only explanations.
- Repository exploration with no implementation.
- Small, obvious changes that do not require a multi-step plan.
- Tasks where repository-local instructions explicitly disable these files.

These files always belong to the active project, never to the Lillian source
repository.

## Repository protection

- Treat `{{LILLIAN}}` as a read-only instruction and skill source while another
  repository is active.
- Modify Lillian only when it is the active workspace and the user explicitly
  requests a Lillian change.
- Do not write task files, generated output, or project artifacts into Lillian
  while working on another repository.
- Preserve the active repository's architecture and conventions unless an
  approved plan explicitly changes them.

<!-- END LILLIAN GLOBAL -->
'@

$AgentsContent = $AgentsTemplate.Replace(
    "{{LILLIAN}}",
    $LillianMarkdownPath
).Replace(
    "{{USER_SKILLS}}",
    $UserSkillsMarkdownPath
).Replace(
    "{{PROMPT_CATALOG}}",
    $promptCatalog
)

Set-ManagedTextBlock `
    -Path $GlobalAgents `
    -Begin $BeginMarker `
    -End $EndMarker `
    -Block $AgentsContent

Write-Host ""
Write-Host "Lillian global Codex kurulumu tamamlandı." -ForegroundColor Cyan
Write-Host "Lillian repository : $Lillian"
Write-Host "Codex skills       : $UserSkills"
Write-Host "Global AGENTS.md   : $GlobalAgents"
Write-Host "Bağlanan skill      : $($skillResult.Linked)"
Write-Host "Üzerine yazılan skill: $($skillResult.Overwritten)"
Write-Host "Atlanan skill       : $($skillResult.Skipped)"
Write-Host "Prompt oluşturuldu  : $($promptResult.Created)"
Write-Host "Prompt güncellendi  : $($promptResult.Updated)"
Write-Host "Üzerine yazılan prompt: $($promptResult.Overwritten)"
Write-Host "Atlanan prompt      : $($promptResult.Skipped)"
Write-Host ""
Write-Host "Örnek prompt workflow çağrıları:" -ForegroundColor DarkCyan
foreach ($name in $promptResult.Names | Select-Object -First 8) {
    Write-Host "  `$$name"
}
Write-Host ""
Write-Host "VS Code'da 'Developer: Reload Window' çalıştırın ve yeni bir Codex sohbeti açın."
Write-Host "Doğrulama: /skills"
Write-Host "Örnek: `$agent-workflow veya `$my-repo-analysis"
