[CmdletBinding()]
param(
  [string]$WorkdirRoot = (Join-Path $PSScriptRoot '..\..\workdir'),
  [string]$Title = 'untitled',
  [string]$Language = 'zh',
  [string]$Contest = 'unknown',
  $Year,
  [string]$ProblemLetter
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $WorkdirRoot)) {
  New-Item -ItemType Directory -Force -Path $WorkdirRoot | Out-Null
}

$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$seed = "$Title|$ts|$([guid]::NewGuid())"
$sha1 = [System.Security.Cryptography.SHA1]::Create()
$bytes = [System.Text.Encoding]::UTF8.GetBytes($seed)
$hash = ($sha1.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
$shortHash = $hash.Substring(0,8)

$taskId = "$ts-$shortHash"
$taskDir = Join-Path $WorkdirRoot $taskId

foreach ($sub in @('attachments','src','results','figures')) {
  New-Item -ItemType Directory -Force -Path (Join-Path $taskDir $sub) | Out-Null
}

# Render README from template
$tpl = Join-Path $PSScriptRoot '..\..\templates\readme_workdir.md'
if (-not (Test-Path $tpl)) { throw "template not found: $tpl" }
$readme = Get-Content -Raw -LiteralPath $tpl
$replacements = @{
  '{task_id}'         = $taskId
  '{created_at}'      = (Get-Date -Format 'o')
  '{title}'           = $Title
  '{contest}'         = $Contest
  '{year}'            = ($(if ($null -ne $Year) { "$Year" } else { 'null' }))
  '{problem_letter}'  = ($(if ($ProblemLetter) { $ProblemLetter } else { 'null' }))
  '{language}'        = $Language
  '{attachment_count}' = '0'
  '{stage_01_status}' = 'pending'
  '{stage_02_status}' = 'pending'
  '{stage_03_status}' = 'pending'
  '{stage_04_status}' = 'pending'
  '{stage_05_status}' = 'pending'
  '{stage_06_status}' = 'pending'
  '{match_level}'     = 'pending'
  '{thesis_dir}'      = 'pending'
  '{template_dir}'    = 'pending'
}
foreach ($kv in $replacements.GetEnumerator()) {
  $readme = $readme.Replace($kv.Key, $kv.Value)
}
Set-Content -LiteralPath (Join-Path $taskDir 'README.md') -Value $readme -Encoding UTF8

[pscustomobject]@{
  task_id  = $taskId
  task_dir = (Resolve-Path -LiteralPath $taskDir).Path
} | ConvertTo-Json -Compress
