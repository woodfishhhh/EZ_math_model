[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$WorkDir
)

$ErrorActionPreference = 'Stop'

$wd = Resolve-Path -LiteralPath $WorkDir
if (-not (Test-Path $wd -PathType Container)) {
  throw "workdir not found: $WorkDir"
}

$staging = New-Item -ItemType Directory -Force -Path (Join-Path $env:TEMP ("ezmm-pack-" + [guid]::NewGuid().ToString('N').Substring(0,8)))

try {
  $copies = @(
    @{ src = 'paper.md';            dst = '论文.md' }
    @{ src = 'paper.docx';          dst = '论文.docx' }
    @{ src = 'quality_report.md';   dst = '质量检查报告.md' }
    @{ src = 'diagnostics.md';      dst = '失败诊断.md' }
    @{ src = 'README.md';           dst = 'README.md' }
  )
  foreach ($c in $copies) {
    $s = Join-Path $wd $c.src
    if (Test-Path $s) {
      Copy-Item -LiteralPath $s -Destination (Join-Path $staging $c.dst) -Force
    }
  }
  foreach ($d in @('results','figures','src')) {
    $sd = Join-Path $wd $d
    if (Test-Path $sd) {
      Copy-Item -Recurse -LiteralPath $sd -Destination (Join-Path $staging $d) -Force
    }
  }

  $zip = Join-Path $wd 'deliverable.zip'
  if (Test-Path $zip) { Remove-Item -Force $zip }
  Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $zip -Force
  Write-Output $zip
}
finally {
  Remove-Item -Recurse -Force -LiteralPath $staging -ErrorAction SilentlyContinue
}
