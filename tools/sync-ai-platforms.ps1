<#
.SYNOPSIS
    Syncs AI configuration from .github/ (source of truth) to platform-specific directories.

.DESCRIPTION
    Copies and transforms content from GitHub Copilot format to Claude Code and Gemini formats.
    No symlinks required — everything is copied with platform-appropriate frontmatter and paths.

    Source of truth (.github/):
      skills/                         -> plugins/ai-toolkit/skills/ (verbatim)
      prompts/*.prompt.md             -> plugins/ai-toolkit/commands/*.md, .claude/commands/*.md, .agents/workflows/*.md
      agents/*.agent.md               -> plugins/ai-toolkit/agents/*.md, .claude/agents/*.md
      instructions/*.instructions.md  -> .claude/rules/*.md, .agents/rules/*.md, plugins/ai-toolkit/rules/*.md
      copilot-instructions.md         -> (stays at .github/)

    The plugin folder is the single generated bundle (installed by Claude Code,
    Codex, and Antigravity via their respective manifests).

    Most content is emitted twice: once into the plugin bundle and once at repo level
    (.claude/, .agents/), so a repo that vendors this one works at project scope with
    nothing installed. The Claude plugin build uses ${CLAUDE_PLUGIN_ROOT} paths, which
    resolve only under an installed plugin; the .claude/ build uses repo-level paths.

    Two outputs are repo-level only, because plugins cannot carry them at all:
    .claude/rules/ (Claude has no rules component) and .agents/workflows/
    (Antigravity has no workflows component).

    In consumer repos using this as a submodule (.ai/), also copies:
      .ai/.github/*                   -> .github/*

.PARAMETER BasePath
    Root of the repository. Defaults to the script's grandparent directory.

.PARAMETER SourcePath
    Path to the AI template source. Defaults to BasePath itself (for the base repo).
    For consumer repos, set this to ".ai" to copy from the submodule.

.EXAMPLE
    # Base repo (lillian): sync from .github/ to .claude/ and .agents/
    .\tools\sync-ai-platforms.ps1

    # Consumer repo: sync from submodule
    .\.ai\tools\sync-ai-platforms.ps1 -BasePath "." -SourcePath ".ai"
#>
param(
    [string]$BasePath = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)),
    [string]$SourcePath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- Helpers ---

function Parse-Frontmatter {
    param([string]$Content)

    if ($Content -match "(?s)^---\r?\n(.*?)\r?\n---\r?\n(.*)$") {
        $yaml = $Matches[1]
        $body = $Matches[2]
    } else {
        return @{ Frontmatter = @{}; Body = $Content }
    }

    # Simple YAML parser for our known structures
    $fm = [ordered]@{}
    $currentKey = $null
    $currentList = $null

    foreach ($line in ($yaml -split "`n")) {
        $line = $line.TrimEnd("`r")

        # List item under current key
        if ($line -match "^\s+-\s+(.+)$" -and $currentKey) {
            if ($null -eq $currentList) { $currentList = @() }
            $currentList += $Matches[1].Trim().Trim('"').Trim("'")
            continue
        }

        # Flush previous list
        if ($currentKey -and $currentList) {
            $fm[$currentKey] = $currentList
            $currentList = $null
        }

        # Key-value pair
        if ($line -match "^(\w[\w-]*):\s*(.*)$") {
            $currentKey = $Matches[1]
            $value = $Matches[2].Trim().Trim('"').Trim("'")
            if ($value -eq "") {
                # Next lines might be a list
                $currentList = @()
            } else {
                $fm[$currentKey] = $value
                $currentKey = $null
            }
        }

        # Nested object (handoffs, etc.) - skip complex structures
        if ($line -match "^\s+\w+:" -and $line -notmatch "^\s+-") {
            # Part of a nested object, skip
        }
    }

    # Flush final list
    if ($currentKey -and $currentList) {
        $fm[$currentKey] = $currentList
    }

    return @{ Frontmatter = $fm; Body = $body }
}

function Format-Frontmatter {
    param([System.Collections.Specialized.OrderedDictionary]$Fields)

    if ($Fields.Count -eq 0) { return "" }

    $lines = @("---")
    foreach ($key in $Fields.Keys) {
        $val = $Fields[$key]
        if ($val -is [array]) {
            $lines += "${key}:"
            foreach ($item in $val) {
                $lines += "  - `"$item`""
            }
        } else {
            # Quote strings that contain special chars
            if ($val -match "[:#\[\]{},>|&!%@]" -or $val -match "^\s" -or $val -match "\s$") {
                $lines += "${key}: `"$val`""
            } else {
                $lines += "${key}: $val"
            }
        }
    }
    $lines += "---"
    return ($lines -join "`n")
}

function Write-SyncedFile {
    param(
        [string]$Path,
        [string]$FrontmatterText,
        [string]$Body
    )

    $dir = Split-Path -Parent $Path
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }

    $content = if ($FrontmatterText) {
        "$FrontmatterText`n$Body"
    } else {
        $Body
    }

    # Normalize line endings to LF
    $content = $content -replace "`r`n", "`n"

    [System.IO.File]::WriteAllText($Path, $content, [System.Text.UTF8Encoding]::new($false))
}

# --- Path Rewriting ---

# Rewrites .github/ references in body content to platform-native paths.
# Each platform gets its own rewriter because the same content is emitted more
# than once: a plugin build (${CLAUDE_PLUGIN_ROOT} paths, resolved only when
# installed) and a repo-level build (.claude/, .agents/) that works at project
# scope. References to .github/ sources are left intact where the target has no
# native equivalent — those dirs are symlinked into consumer repos, so the paths
# stay resolvable there.

function Rewrite-PathsForClaudeRules {
    param([string]$Body)

    # Cross-references between rules stay repo-local
    $Body = $Body -replace '\.github/instructions/(\w[\w-]*)\.instructions\.md', '.claude/rules/$1.md'
    $Body = $Body -replace '\.github/instructions/([^`\s]*?)\.instructions\.md', '.claude/rules/$1.md'
    $Body = $Body -replace '\.github/instructions/', '.claude/rules/'

    # Shared files
    $Body = $Body -replace '\.github/copilot-instructions\.md', 'CLAUDE.md'
    return $Body
}

function Rewrite-PathsForClaudePlugin {
    param([string]$Body)

    # Plugin content references its own components via ${CLAUDE_PLUGIN_ROOT}
    # (resolved at runtime by Claude Code) so paths work from the install cache.
    $Body = $Body -replace '\.github/skills/', '$${CLAUDE_PLUGIN_ROOT}/skills/'
    $Body = $Body -replace '\.github/agents/(\w[\w-]*)\.agent\.md', '$${CLAUDE_PLUGIN_ROOT}/agents/$1.md'
    $Body = $Body -replace '\.github/agents/([^`\s]*?)\.agent\.md', '$${CLAUDE_PLUGIN_ROOT}/agents/$1.md'
    $Body = $Body -replace '\.github/agents/', '$${CLAUDE_PLUGIN_ROOT}/agents/'
    $Body = $Body -replace '\.github/prompts/(\w[\w-]*)\.prompt\.md', '$${CLAUDE_PLUGIN_ROOT}/commands/$1.md'
    $Body = $Body -replace '\.github/prompts/([^`\s]*?)\.prompt\.md', '$${CLAUDE_PLUGIN_ROOT}/commands/$1.md'
    $Body = $Body -replace '\.github/prompts/', '$${CLAUDE_PLUGIN_ROOT}/commands/'

    # Rules are repo-level (plugins cannot ship them)
    $Body = $Body -replace '\.github/instructions/(\w[\w-]*)\.instructions\.md', '.claude/rules/$1.md'
    $Body = $Body -replace '\.github/instructions/([^`\s]*?)\.instructions\.md', '.claude/rules/$1.md'
    $Body = $Body -replace '\.github/instructions/', '.claude/rules/'

    # Shared files
    $Body = $Body -replace '\.github/copilot-instructions\.md', 'CLAUDE.md'
    return $Body
}

function Rewrite-PathsForClaudeProject {
    param([string]$Body)

    # Project-scope twin of Rewrite-PathsForClaudePlugin. Same content, but
    # ${CLAUDE_PLUGIN_ROOT} does not exist outside an installed plugin, so every
    # reference points at the repo-level location Claude Code actually reads.
    # `.github/skills/` is left alone: it is symlinked into consumer repos and
    # resolves there (same reasoning as Rewrite-PathsForAntigravityProject).
    $Body = $Body -replace '\.github/agents/(\w[\w-]*)\.agent\.md', '.claude/agents/$1.md'
    $Body = $Body -replace '\.github/agents/([^`\s]*?)\.agent\.md', '.claude/agents/$1.md'
    $Body = $Body -replace '\.github/agents/', '.claude/agents/'
    $Body = $Body -replace '\.github/prompts/(\w[\w-]*)\.prompt\.md', '.claude/commands/$1.md'
    $Body = $Body -replace '\.github/prompts/([^`\s]*?)\.prompt\.md', '.claude/commands/$1.md'
    $Body = $Body -replace '\.github/prompts/', '.claude/commands/'
    $Body = $Body -replace '\.github/instructions/(\w[\w-]*)\.instructions\.md', '.claude/rules/$1.md'
    $Body = $Body -replace '\.github/instructions/([^`\s]*?)\.instructions\.md', '.claude/rules/$1.md'
    $Body = $Body -replace '\.github/instructions/', '.claude/rules/'

    # Shared files
    $Body = $Body -replace '\.github/copilot-instructions\.md', 'CLAUDE.md'
    return $Body
}

function Rewrite-PathsForAntigravityProject {
    param([string]$Body)

    # Prompts become workflows; skills/instructions refs keep their .github/
    # source paths (Antigravity has no repo-level copies of those anymore —
    # skills and rules ship inside the plugin).
    $Body = $Body -replace '\.github/prompts/(\w[\w-]*)\.prompt\.md', '.agents/workflows/$1.md'
    $Body = $Body -replace '\.github/prompts/([^`\s]*?)\.prompt\.md', '.agents/workflows/$1.md'
    $Body = $Body -replace '\.github/prompts/', '.agents/workflows/'

    # Shared files (AGENTS.md is read natively by Antigravity since v1.20.5)
    $Body = $Body -replace '\.github/copilot-instructions\.md', 'AGENTS.md'
    return $Body
}

function Rewrite-PathsForAntigravityPlugin {
	param([string]$Body)

	$Body = Rewrite-PathsForAntigravityProject $Body
	$Body = $Body -replace '\.github/skills/', '../skills/'
	return $Body
}

# --- Tool Mapping (Copilot -> Claude) ---

$ToolMap = @{
    "read"    = @("Read", "Glob", "Grep")
    "search"  = @("Grep", "Glob")
    "web"     = @("WebFetch", "WebSearch")
    "vscode"  = @("Read", "Glob", "Grep", "Edit", "Write")
    "execute" = @("Bash")
    "edit"    = @("Edit", "Write")
    "agent"   = @("Agent")
    "todo"    = @("TodoWrite")
}

function Map-ToolsToClaudeFormat {
    param([array]$CopilotTools)

    $claudeTools = [System.Collections.Generic.List[string]]::new()
    foreach ($tool in $CopilotTools) {
        $tool = $tool.Trim()
        if ($tool.StartsWith("mcp__")) {
            # MCP tools pass through as-is
            $claudeTools.Add($tool)
        } elseif ($ToolMap.ContainsKey($tool)) {
            foreach ($mapped in $ToolMap[$tool]) {
                if (-not $claudeTools.Contains($mapped)) {
                    $claudeTools.Add($mapped)
                }
            }
        }
    }
    return $claudeTools.ToArray()
}

# --- Directory Copy Helper ---

function Copy-DirectoryClean {
    param(
        [string]$Source,
        [string]$Destination
    )

	if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
		throw "Required source directory is missing: $Source"
	}

    # Remove existing target (whether directory or symlink)
    if (Test-Path $Destination) {
        $item = Get-Item $Destination -Force
        if ($item.LinkType) {
            # Remove symlink without following it
            $item.Delete()
        } else {
            Remove-Item $Destination -Recurse -Force
        }
    }

    Copy-Item -Path $Source -Destination $Destination -Recurse -Force
    return (Get-ChildItem $Destination -Recurse -File | Measure-Object).Count
}

# --- Main Sync Logic ---

$stats = @{ Instructions = 0; Prompts = 0; Agents = 0; Skills = 0; GithubFiles = 0 }
$BasePath = [System.IO.Path]::GetFullPath($BasePath)

# Resolve source: either BasePath itself (base repo) or a submodule path.
if ([string]::IsNullOrWhiteSpace($SourcePath)) {
	$srcRoot = $BasePath
}
else {
	$srcRoot = Join-Path $BasePath $SourcePath
}
$srcGithub = Join-Path $srcRoot ".github"

if (-not (Test-Path $srcGithub)) {
	Write-Error "Source .github/ not found at: $srcGithub"
	exit 1
}

$sourceSkillsRoot = Join-Path $srcGithub "skills"
if (-not (Test-Path -LiteralPath $sourceSkillsRoot -PathType Container)) {
	throw "Required source directory is missing: $sourceSkillsRoot"
}
foreach ($skillDirectory in Get-ChildItem -LiteralPath $sourceSkillsRoot -Directory) {
	if (-not (Test-Path -LiteralPath (Join-Path $skillDirectory.FullName "SKILL.md") -PathType Leaf)) {
		throw "Skill '$($skillDirectory.Name)' is missing its top-level SKILL.md."
	}
}
foreach ($skillFile in Get-ChildItem -LiteralPath $sourceSkillsRoot -Recurse -File -Filter "*.md") {
	if ($skillFile.FullName -eq (Join-Path $sourceSkillsRoot "INDEX.md")) { continue }
	if ([System.IO.File]::ReadAllText($skillFile.FullName) -match '\.github/skills/') {
		throw "Verbatim plugin skill '$($skillFile.FullName)' contains a repo-root-only path. Use a file-relative path."
	}
}

Write-Host "Syncing AI platform configs ..." -ForegroundColor Cyan
Write-Host "  Source: $srcGithub" -ForegroundColor DarkGray
Write-Host "  Target: $BasePath" -ForegroundColor DarkGray

# --- 0. Consumer repo: copy .github/ content from submodule ---

if (-not [string]::IsNullOrWhiteSpace($SourcePath)) {
	$targetGithub = Join-Path $BasePath ".github"
	New-Item -ItemType Directory -Force -Path $targetGithub | Out-Null

	foreach ($directoryName in @("skills", "agents", "instructions", "prompts")) {
		$sourceDirectory = Join-Path $srcGithub $directoryName
		if (Test-Path $sourceDirectory) {
			$stats.GithubFiles += Copy-DirectoryClean $sourceDirectory (Join-Path $targetGithub $directoryName)
		}
	}

	foreach ($fileName in @("copilot-instructions.md", "CONTRIBUTING.md")) {
		$sourceFile = Join-Path $srcGithub $fileName
		if (Test-Path $sourceFile) {
			Copy-Item -Path $sourceFile -Destination (Join-Path $targetGithub $fileName) -Force
			$stats.GithubFiles++
		}
	}

	foreach ($fileName in @("CLAUDE.md", "AGENTS.md")) {
		$sourceFile = Join-Path $srcRoot $fileName
		if (Test-Path $sourceFile) {
			Copy-Item -Path $sourceFile -Destination (Join-Path $BasePath $fileName) -Force
			$stats.GithubFiles++
		}
	}

	Write-Host "  .github/ content copied from submodule ($($stats.GithubFiles) files)" -ForegroundColor DarkGray
}

# Use the target .github/ as the source for all transforms.
$srcGithub = Join-Path $BasePath ".github"

# --- 0.5. Generated bundle root ---

# The plugin folder is the single generated bundle: Claude Code, Codex, and
# Antigravity each install it via their own manifest (.claude-plugin/plugin.json,
# .codex-plugin/plugin.json, plugin.json). Outside the plugin, only what plugins
# cannot deliver is generated: .claude/rules/ and .agents/workflows/.
$pluginRoot = Join-Path $BasePath "plugins\ai-toolkit"
if (-not (Test-Path $pluginRoot)) {
    New-Item -ItemType Directory -Force -Path $pluginRoot | Out-Null
    Write-Host "  plugins/ai-toolkit/ created (was missing)" -ForegroundColor Yellow
}

# --- 0.5 Generate skill catalogs from frontmatter (DRY: no hand-maintained lists) ---
#
# Runs BEFORE the plugin copy so the plugin ships the freshly generated INDEX.md.
#
# INDEX.md's per-skill entries and README.md's Available Skills bullets are
# generated from each SKILL.md's frontmatter between marker comments.
# Edit the frontmatter, not the generated blocks.

function Replace-GeneratedBlock {
	param(
		[string]$Path,
		[string]$Begin,
		[string]$End,
		[string]$NewContent,
		[bool]$Required = $true
	)
	if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
		if (-not $Required) { return $false }
		throw "Required generated-block host is missing: $Path"
	}
	$text = [System.IO.File]::ReadAllText($Path)
	$pattern = "(?s)" + [regex]::Escape($Begin) + ".*?" + [regex]::Escape($End)
	$matches = [regex]::Matches($text, $pattern)
	$beginCount = [regex]::Matches($text, [regex]::Escape($Begin)).Count
	$endCount = [regex]::Matches($text, [regex]::Escape($End)).Count
	if ($matches.Count -ne 1 -or $beginCount -ne 1 -or $endCount -ne 1) {
		if (-not $Required) { return $false }
		throw "Expected exactly one ordered generated block in $Path"
	}
	$replacement = "$Begin`n$NewContent$End"
	$text = [regex]::Replace($text, $pattern, { param($match) $replacement })
    $text = $text -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($Path, $text, [System.Text.UTF8Encoding]::new($false))
    return $true
}

$skillsRoot = Join-Path $srcGithub "skills"
$catalog = @()
if (Test-Path $skillsRoot) {
    foreach ($dir in (Get-ChildItem $skillsRoot -Directory | Sort-Object Name)) {
        $skillFile = Join-Path $dir.FullName "SKILL.md"
        if (-not (Test-Path $skillFile)) { continue }
        $fm = (Parse-Frontmatter (Get-Content $skillFile -Raw)).Frontmatter
        $catalog += [pscustomobject]@{
            Name          = $dir.Name
            AppliesTo     = if ($fm.Contains("applies_to")) { @($fm["applies_to"]) -join ", " } else { "" }
            MandatoryWhen = if ($fm.Contains("mandatory_when")) { @($fm["mandatory_when"]) } else { @() }
            Triggers      = if ($fm.Contains("triggers")) { @($fm["triggers"]) } else { @() }
            Note          = if ($fm.Contains("note")) { $fm["note"] } else { "" }
            Summary       = if ($fm.Contains("summary")) { $fm["summary"] } elseif ($fm.Contains("description")) { $fm["description"] } else { "" }
        }
    }
}

# INDEX.md skills section
$indexBlock = ""
foreach ($s in $catalog) {
    $indexBlock += "`n## $($s.Name)`n"
    $indexBlock += "- Path: ``$($s.Name)/SKILL.md```n"
    if ($s.AppliesTo)              { $indexBlock += "- Applies to: $($s.AppliesTo)`n" }
    if (@($s.MandatoryWhen).Count -gt 0) {
        $indexBlock += "- Mandatory when:`n"
        foreach ($m in @($s.MandatoryWhen)) { $indexBlock += "  - $m`n" }
    }
    if (@($s.Triggers).Count -gt 0) {
        $indexBlock += "- Triggers:`n"
        foreach ($t in @($s.Triggers)) { $indexBlock += "  - `"$t`"`n" }
    }
    if ($s.Note)                   { $indexBlock += "- Note: $($s.Note)`n" }
    $indexBlock += "`n---`n"
}
$indexPath = Join-Path $skillsRoot "INDEX.md"
$stats.IndexGenerated = Replace-GeneratedBlock $indexPath "<!-- BEGIN GENERATED SKILLS (edit SKILL.md frontmatter, not this block) -->" "<!-- END GENERATED SKILLS -->" $indexBlock

# README.md Available Skills list
$readmeBlock = ""
foreach ($s in $catalog) {
    $readmeBlock += "- **$($s.Name)**: $($s.Summary)`n"
}
$readmePath = Join-Path $BasePath "README.md"
$readmeBlockRequired = [string]::IsNullOrWhiteSpace($SourcePath)
$stats.ReadmeGenerated = Replace-GeneratedBlock $readmePath "<!-- BEGIN GENERATED SKILLS LIST (sync-ai-platforms.ps1) -->" "<!-- END GENERATED SKILLS LIST -->" $readmeBlock $readmeBlockRequired

# --- 1. Skills -> plugin skills/ (verbatim copy) ---
#
# SKILL.md is the cross-platform Agent Skills standard (agentskills.io):
# the same file is consumed unmodified by Claude Code, Codex, Copilot, and
# Antigravity. No transform needed.

$stats.Skills += Copy-DirectoryClean (Join-Path $srcGithub "skills") (Join-Path $pluginRoot "skills")

# --- 2. Instructions -> .claude/rules/ (Claude) + .agents/rules/ + plugin rules/ (Antigravity) ---
#
# Rules cannot ride in a Claude plugin, so they stay repo-level for Claude.
# Antigravity plugins DO support a rules/ component (Claude ignores the dir), but
# the same content is also emitted to .agents/rules/ so project scope works with
# no plugin installed — and so every .agents/ symlink resolves inside .agents/.

$srcDir = Join-Path $srcGithub "instructions"
$claudeDir = Join-Path $BasePath ".claude\rules"
$antigravityRulesDir = Join-Path $BasePath ".agents\rules"
$pluginRulesDir = Join-Path $pluginRoot "rules"

if (-not (Test-Path -LiteralPath $srcDir -PathType Container)) { throw "Required source directory is missing: $srcDir" }
if (Test-Path $claudeDir) { Get-ChildItem $claudeDir -Filter "*.md" | Remove-Item -Force }
if (Test-Path $antigravityRulesDir) { Get-ChildItem $antigravityRulesDir -Filter "*.md" | Remove-Item -Force }
if (Test-Path $pluginRulesDir) { Get-ChildItem $pluginRulesDir -Filter "*.md" | Remove-Item -Force }

if (Test-Path $srcDir) {
    foreach ($file in Get-ChildItem $srcDir -Filter "*.instructions.md") {
        $parsed = Parse-Frontmatter (Get-Content $file.FullName -Raw)
        $cleanName = $file.Name -replace "\.instructions\.md$", ".md"

        # Normalize applyTo: Copilot's documented format is a single string
        # (comma-separated for multiple globs); Claude wants a list.
        $applyToList = $null
        if ($parsed.Frontmatter.Contains("applyTo")) {
            $applyToList = $parsed.Frontmatter["applyTo"]
            if ($applyToList -is [string]) { $applyToList = @($applyToList -split '\s*,\s*') }
            if ($applyToList -isnot [array]) { $applyToList = @($applyToList) }
        }

        # Claude: applyTo -> paths
        $claudeFm = [ordered]@{}
        if ($null -ne $applyToList) {
            $claudeFm["paths"] = $applyToList
        }
        Write-SyncedFile (Join-Path $claudeDir $cleanName) (Format-Frontmatter $claudeFm) (Rewrite-PathsForClaudeRules $parsed.Body)

        # Antigravity: applyTo -> activation mode (always_on for catch-all globs, glob trigger otherwise)
        $antigravityFm = [ordered]@{}
        if ($null -ne $applyToList) {
            $applyTo = $applyToList
            if ($applyTo -contains "**") {
                $antigravityFm["trigger"] = "always_on"
            } else {
                $antigravityFm["trigger"] = "glob"
                $antigravityFm["globs"] = ($applyTo -join ", ")
            }
        }
		$projectBody = Rewrite-PathsForAntigravityProject $parsed.Body
		$pluginBody = if ($cleanName -eq "generated-output.md") {
			$projectBody
		}
		else {
			Rewrite-PathsForAntigravityPlugin $parsed.Body
		}
		Write-SyncedFile (Join-Path $pluginRulesDir $cleanName) (Format-Frontmatter $antigravityFm) $pluginBody
		Write-SyncedFile (Join-Path $antigravityRulesDir $cleanName) (Format-Frontmatter $antigravityFm) $projectBody

        $stats.Instructions++
    }
}

# --- 3. Prompts -> plugin commands/ + .claude/commands/ (Claude) + .agents/workflows/ (Antigravity) ---
#
# Antigravity plugins have no workflows component, so workflows stay repo-level.
# Claude gets both variants: the plugin build (${CLAUDE_PLUGIN_ROOT} paths) and a
# repo-level build, so /commands work whether or not the plugin is installed.

$srcDir = Join-Path $srcGithub "prompts"
$pluginCommandsDir = Join-Path $pluginRoot "commands"
$claudeCommandsDir = Join-Path $BasePath ".claude\commands"
$antigravityDir = Join-Path $BasePath ".agents\workflows"

if (-not (Test-Path -LiteralPath $srcDir -PathType Container)) { throw "Required source directory is missing: $srcDir" }
if (Test-Path $pluginCommandsDir) { Get-ChildItem $pluginCommandsDir -Filter "*.md" | Remove-Item -Force }
if (Test-Path $claudeCommandsDir) { Get-ChildItem $claudeCommandsDir -Filter "*.md" | Remove-Item -Force }
if (Test-Path $antigravityDir) { Get-ChildItem $antigravityDir -Filter "*.md" | Remove-Item -Force }

if (Test-Path $srcDir) {
    foreach ($file in Get-ChildItem $srcDir -Filter "*.prompt.md") {
        $parsed = Parse-Frontmatter (Get-Content $file.FullName -Raw)
        $cleanName = $file.Name -replace "\.prompt\.md$", ".md"

        # Claude: keep description, drop mode
        $claudeFm = [ordered]@{}
        if ($parsed.Frontmatter.Contains("description")) {
            $claudeFm["description"] = $parsed.Frontmatter["description"]
        }
        Write-SyncedFile (Join-Path $pluginCommandsDir $cleanName) (Format-Frontmatter $claudeFm) (Rewrite-PathsForClaudePlugin $parsed.Body)
        Write-SyncedFile (Join-Path $claudeCommandsDir $cleanName) (Format-Frontmatter $claudeFm) (Rewrite-PathsForClaudeProject $parsed.Body)

        # Antigravity workflows: keep description, drop mode (invoked as /name)
        $antigravityFm = [ordered]@{}
        if ($parsed.Frontmatter.Contains("description")) {
            $antigravityFm["description"] = $parsed.Frontmatter["description"]
        }
		Write-SyncedFile (Join-Path $antigravityDir $cleanName) (Format-Frontmatter $antigravityFm) (Rewrite-PathsForAntigravityProject $parsed.Body)

        $stats.Prompts++
    }
}

# --- 4. Agents -> plugin agents/ + .claude/agents/ (with frontmatter + tools transform) ---
#
# Same two-variant reasoning as prompts above: the plugin build for installed use,
# a repo-level build so personas resolve at project scope without the plugin.

$srcDir = Join-Path $srcGithub "agents"
$pluginAgentsDir = Join-Path $pluginRoot "agents"
$claudeAgentsDir = Join-Path $BasePath ".claude\agents"

if (-not (Test-Path -LiteralPath $srcDir -PathType Container)) { throw "Required source directory is missing: $srcDir" }
if (Test-Path $pluginAgentsDir) { Get-ChildItem $pluginAgentsDir -Filter "*.md" | Remove-Item -Force }
if (Test-Path $claudeAgentsDir) { Get-ChildItem $claudeAgentsDir -Filter "*.md" | Remove-Item -Force }

if (Test-Path $srcDir) {
    foreach ($file in Get-ChildItem $srcDir -Filter "*.agent.md") {
        $parsed = Parse-Frontmatter (Get-Content $file.FullName -Raw)
        $cleanName = $file.Name -replace "\.agent\.md$", ".md"

        $claudeFm = [ordered]@{}

        # name: lowercase
        if ($parsed.Frontmatter.Contains("name")) {
            $claudeFm["name"] = $parsed.Frontmatter["name"].ToLower()
        }

        # description: keep
        if ($parsed.Frontmatter.Contains("description")) {
            $claudeFm["description"] = $parsed.Frontmatter["description"]
        }

        # tools: map to Claude tool names
        if ($parsed.Frontmatter.Contains("tools")) {
            $tools = $parsed.Frontmatter["tools"]
            if ($tools -is [string]) { $tools = @($tools) }
            $claudeTools = Map-ToolsToClaudeFormat $tools
            if ($claudeTools.Count -gt 0) {
                $claudeFm["tools"] = $claudeTools
            }
        }

        # skills: pass through
        if ($parsed.Frontmatter.Contains("skills")) {
            $skills = $parsed.Frontmatter["skills"]
            if ($skills -is [string]) { $skills = @($skills) }
            $claudeFm["skills"] = $skills
        }

        # Drop: handoffs (Copilot-only)

        Write-SyncedFile (Join-Path $pluginAgentsDir $cleanName) (Format-Frontmatter $claudeFm) (Rewrite-PathsForClaudePlugin $parsed.Body)
        Write-SyncedFile (Join-Path $claudeAgentsDir $cleanName) (Format-Frontmatter $claudeFm) (Rewrite-PathsForClaudeProject $parsed.Body)

        $stats.Agents++
    }
}

# Installed plugin guidance must not depend on Lillian's repository-root paths.
foreach ($directory in @($pluginRulesDir, $pluginCommandsDir, $pluginAgentsDir)) {
	foreach ($file in Get-ChildItem -LiteralPath $directory -Recurse -File -Filter "*.md") {
		if ($file.FullName -eq (Join-Path $pluginRulesDir "generated-output.md")) { continue }
		if ([System.IO.File]::ReadAllText($file.FullName) -match '\.github/skills/') {
			throw "Generated plugin file '$($file.FullName)' contains a repo-root-only path."
		}
	}
}

# --- Summary ---

Write-Host ""
Write-Host "Sync complete:" -ForegroundColor Green
Write-Host "  Skills -> plugin:          $($stats.Skills) files" -ForegroundColor White
Write-Host "  Instructions -> Rules:     $($stats.Instructions) files (.claude/rules + .agents/rules + plugin rules)" -ForegroundColor White
Write-Host "  Prompts -> Commands:       $($stats.Prompts) files (plugin + .claude/commands + .agents/workflows)" -ForegroundColor White
Write-Host "  Agents -> Personas:        $($stats.Agents) files (plugin + .claude/agents)" -ForegroundColor White
if ($stats.GithubFiles -gt 0) {
	Write-Host "  .github/ (from submodule): $($stats.GithubFiles) files" -ForegroundColor White
}
if ($stats.Skills -eq 0) {
    Write-Host "  WARNING: no skills copied into the plugin" -ForegroundColor Yellow
}
Write-Host "  Skill catalog:             INDEX.md generated=$($stats.IndexGenerated), README list generated=$($stats.ReadmeGenerated) ($($catalog.Count) skills)" -ForegroundColor White
Write-Host ""
Write-Host "Targets updated:" -ForegroundColor DarkGray
Write-Host "  .claude/{rules,commands,agents}/   .agents/{rules,workflows}/" -ForegroundColor DarkGray
Write-Host "  plugins/ai-toolkit/{skills,commands,agents,rules}/" -ForegroundColor DarkGray
