[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$WorkDir,
  [string]$ProjectRoot,
  [string]$OutputRoot,
  [string]$ZipPath
)

$ErrorActionPreference = 'Stop'

function Get-RelativePathCompat {
  param(
    [Parameter(Mandatory=$true)]
    [string]$BasePath,
    [Parameter(Mandatory=$true)]
    [string]$TargetPath
  )
  $baseFull = [System.IO.Path]::GetFullPath($BasePath)
  $separator = [System.IO.Path]::DirectorySeparatorChar
  if (-not $baseFull.EndsWith([string]$separator)) {
    $baseFull = $baseFull + $separator
  }
  $baseUri = New-Object System.Uri($baseFull)
  $targetUri = New-Object System.Uri([System.IO.Path]::GetFullPath($TargetPath))
  [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace('\', '/')
}

$wd = Resolve-Path -LiteralPath $WorkDir
if (-not (Test-Path $wd -PathType Container)) {
  throw "workdir not found: $WorkDir"
}

$pathsFile = Join-Path $wd 'project_paths.json'
if (Test-Path $pathsFile) {
  $paths = Get-Content -Raw -LiteralPath $pathsFile | ConvertFrom-Json
  if (-not $ProjectRoot) { $ProjectRoot = $paths.project_root }
  if (-not $OutputRoot) { $OutputRoot = $paths.output_root }
}
if (-not $ProjectRoot) { $ProjectRoot = Split-Path -Parent (Split-Path -Parent $wd) }
if (-not $OutputRoot) { $OutputRoot = Join-Path $ProjectRoot 'output' }

$attachmentFolderName = -join ([char[]](0x9644,0x4EF6,0x6587,0x4EF6,0x5939))
$qualityReportName = (-join ([char[]](0x8D28,0x91CF,0x68C0,0x67E5,0x62A5,0x544A))) + '.md'
$diagnosticsName = (-join ([char[]](0x5931,0x8D25,0x8BCA,0x65AD))) + '.md'
$paperOutput = Join-Path $OutputRoot 'paper'
$sourceOutput = Join-Path $OutputRoot 'source code'
$attachmentsOutput = Join-Path $OutputRoot $attachmentFolderName
foreach ($dir in @($OutputRoot, $paperOutput, $sourceOutput, $attachmentsOutput)) {
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

try {
  foreach ($dir in @($paperOutput, $sourceOutput, $attachmentsOutput)) {
    Get-ChildItem -LiteralPath $dir -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
  }
  $oldManifest = Join-Path $OutputRoot 'manifest.json'
  if (Test-Path $oldManifest) { Remove-Item -LiteralPath $oldManifest -Force }

  $exportScript = Join-Path $PSScriptRoot 'export_paper.ps1'
  if ((Test-Path $exportScript) -and (Test-Path (Join-Path $wd 'paper.md'))) {
    $exportRaw = & $exportScript -WorkDir $wd -PaperOutput $paperOutput
    if ($exportRaw) {
      $exportResult = $exportRaw | ConvertFrom-Json
    }
  }

  if ($exportResult) {
    $exportNotes = New-Object System.Collections.Generic.List[string]
    if ($exportResult.pdf_fallback) {
      $exportNotes.Add("- PDF fallback used: $($exportResult.pdf_fallback)")
    }
    if ($exportResult.pdf_error) {
      $exportNotes.Add("- PDF engine error: $($exportResult.pdf_error)")
    }
    if (-not $exportResult.paper_docx) {
      $exportNotes.Add("- DOCX export missing")
    }
    if (-not $exportResult.paper_pdf) {
      $exportNotes.Add("- PDF export missing")
    }
    if ($exportNotes.Count -gt 0) {
      $diagFile = Join-Path $wd 'diagnostics.md'
      Add-Content -LiteralPath $diagFile -Value ("`n## Packaging export notes`n" + ($exportNotes -join "`n")) -Encoding UTF8
    }
  }

  $srcDir = Join-Path $wd 'src'
  if (Test-Path $srcDir) {
    Copy-Item -Recurse -LiteralPath $srcDir -Destination (Join-Path $sourceOutput 'src') -Force
  }
  foreach ($f in @('requirements.txt','config.yaml','README_RUN.md')) {
    $sf = Join-Path $wd $f
    if (Test-Path $sf) { Copy-Item -LiteralPath $sf -Destination (Join-Path $sourceOutput $f) -Force }
  }

  foreach ($d in @('results','figures','attachments')) {
    $sd = Join-Path $wd $d
    if (Test-Path $sd) {
      Copy-Item -Recurse -LiteralPath $sd -Destination (Join-Path $attachmentsOutput $d) -Force
    }
  }
  foreach ($c in @(
    @{ src = 'quality_report.md'; dst = $qualityReportName },
    @{ src = 'diagnostics.md'; dst = $diagnosticsName },
    @{ src = 'README.md'; dst = 'README.md' },
    @{ src = 'artifact_manifest.json'; dst = 'artifact_manifest.runtime.json' },
    @{ src = 'run_state.json'; dst = 'run_state.json' }
  )) {
    $s = Join-Path $wd $c.src
    if (Test-Path $s) { Copy-Item -LiteralPath $s -Destination (Join-Path $attachmentsOutput $c.dst) -Force }
  }

  $taskId = Split-Path -Leaf $wd
  $runStateFile = Join-Path $wd 'run_state.json'
  $runMode = 'unknown'
  $setupStatus = 'unknown'
  if (Test-Path $runStateFile) {
    $runState = Get-Content -Raw -LiteralPath $runStateFile | ConvertFrom-Json
    $runMode = $runState.run_mode
    $setupStatus = $runState.setup_status
  }

  $artifacts = @()
  foreach ($item in Get-ChildItem -Path $OutputRoot -Recurse -File) {
    $relativePath = Get-RelativePathCompat -BasePath $ProjectRoot -TargetPath $item.FullName
    $type = switch -Regex ($relativePath) {
      '^output/paper/paper\.md$' { 'paper_md'; break }
      '^output/paper/paper\.docx$' { 'paper_docx'; break }
      '^output/paper/paper\.txt$' { 'paper_txt'; break }
      '^output/paper/paper\.pdf$' { 'paper_pdf'; break }
      '^output/source code/' { 'source_code'; break }
      '/figures/' { 'figure'; break }
      '/results/' { 'result'; break }
      default { 'attachment' }
    }
    $artifacts += [ordered]@{
      path = $relativePath
      type = $type
      source = ''
      stage = 'packaging'
      formal = ($runMode -eq 'formal')
      verified = $true
      created_at = (Get-Date -Format 'o')
      notes = ''
    }
  }
  $artifacts += [ordered]@{
    path = 'output/manifest.json'
    type = 'manifest'
    source = ''
    stage = 'packaging'
    formal = ($runMode -eq 'formal')
    verified = $true
    created_at = (Get-Date -Format 'o')
    notes = ''
  }
  $artifacts += [ordered]@{
    path = 'output.zip'
    type = 'project_zip'
    source = 'project_root'
    stage = 'packaging'
    formal = ($runMode -eq 'formal')
    verified = $true
    created_at = (Get-Date -Format 'o')
    notes = 'Contains project root contents except output.zip itself'
  }
  $manifest = [ordered]@{
    task_id = $taskId
    run_mode = $runMode
    setup_status = $setupStatus
    artifacts = $artifacts
  }
  $manifestJson = $manifest | ConvertTo-Json -Depth 8
  $manifestJson | Set-Content -LiteralPath (Join-Path $OutputRoot 'manifest.json') -Encoding UTF8
  $manifestJson | Set-Content -LiteralPath (Join-Path $wd 'artifact_manifest.json') -Encoding UTF8

  if (-not $ZipPath) { $ZipPath = Join-Path $ProjectRoot 'output.zip' }
  $zip = $ZipPath
  if (Test-Path $zip) { Remove-Item -Force $zip }
  $runtimeZip = Join-Path $wd 'deliverable.zip'
  if (Test-Path $runtimeZip) { Remove-Item -LiteralPath $runtimeZip -Force }
  $zipFullPath = [System.IO.Path]::GetFullPath($zip)
  $zipItems = Get-ChildItem -LiteralPath $ProjectRoot -Force | Where-Object {
    [System.IO.Path]::GetFullPath($_.FullName) -ne $zipFullPath
  }
  if (-not $zipItems) {
    throw "project root has no files to package: $ProjectRoot"
  }
  Compress-Archive -LiteralPath $zipItems.FullName -DestinationPath $zip -Force
  Copy-Item -LiteralPath $zip -Destination (Join-Path $wd 'deliverable.zip') -Force
  Write-Output $zip
}
finally {
  # no temporary staging directory is used; output/ is the canonical deliverable tree
}
