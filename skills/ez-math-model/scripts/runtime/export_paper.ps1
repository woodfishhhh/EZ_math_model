[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$WorkDir,
  [string]$PaperOutput
)

$ErrorActionPreference = 'Stop'

function ConvertTo-PdfLiteral {
  param([string]$Text)
  $builder = New-Object System.Text.StringBuilder
  foreach ($ch in $Text.ToCharArray()) {
    $code = [int][char]$ch
    if ($ch -eq '\') {
      [void]$builder.Append('\\')
    } elseif ($ch -eq '(') {
      [void]$builder.Append('\(')
    } elseif ($ch -eq ')') {
      [void]$builder.Append('\)')
    } elseif ($code -lt 32 -or $code -gt 126) {
      [void]$builder.Append('?')
    } else {
      [void]$builder.Append($ch)
    }
  }
  $builder.ToString()
}

function New-SimplePdf {
  param(
    [Parameter(Mandatory=$true)]
    [string]$TextPath,
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
  )

  $rawLines = Get-Content -LiteralPath $TextPath -Encoding UTF8 -ErrorAction Stop
  if (-not $rawLines) { $rawLines = @('') }

  $wrapped = New-Object System.Collections.Generic.List[string]
  foreach ($line in $rawLines) {
    $current = [string]$line
    if ($current.Length -eq 0) {
      $wrapped.Add('')
      continue
    }
    while ($current.Length -gt 92) {
      $wrapped.Add($current.Substring(0, 92))
      $current = $current.Substring(92)
    }
    $wrapped.Add($current)
  }

  $linesPerPage = 48
  $pageCount = [Math]::Max(1, [int][Math]::Ceiling($wrapped.Count / $linesPerPage))
  $fontId = 3 + ($pageCount * 2)
  $objects = @{}

  $objects[1] = '<< /Type /Catalog /Pages 2 0 R >>'
  $kids = New-Object System.Collections.Generic.List[string]

  for ($pageIndex = 0; $pageIndex -lt $pageCount; $pageIndex++) {
    $pageId = 3 + ($pageIndex * 2)
    $contentId = $pageId + 1
    $kids.Add("$pageId 0 R")

    $content = New-Object System.Text.StringBuilder
    [void]$content.AppendLine('BT')
    [void]$content.AppendLine('/F1 10 Tf')
    [void]$content.AppendLine('50 790 Td')
    [void]$content.AppendLine('13 TL')

    $start = $pageIndex * $linesPerPage
    $end = [Math]::Min($start + $linesPerPage - 1, $wrapped.Count - 1)
    for ($i = $start; $i -le $end; $i++) {
      $literal = ConvertTo-PdfLiteral $wrapped[$i]
      [void]$content.AppendLine("($literal) Tj")
      [void]$content.AppendLine('T*')
    }

    [void]$content.AppendLine('ET')
    $contentText = $content.ToString()
    $contentLength = [System.Text.Encoding]::ASCII.GetByteCount($contentText)
    $objects[$pageId] = "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 $fontId 0 R >> >> /Contents $contentId 0 R >>"
    $objects[$contentId] = "<< /Length $contentLength >>`nstream`n$contentText`nendstream"
  }

  $objects[2] = "<< /Type /Pages /Kids [$($kids -join ' ')] /Count $pageCount >>"
  $objects[$fontId] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>'

  $pdf = New-Object System.Text.StringBuilder
  [void]$pdf.Append("%PDF-1.4`n")
  $offsets = @{}
  for ($id = 1; $id -le $fontId; $id++) {
    $offsets[$id] = [System.Text.Encoding]::ASCII.GetByteCount($pdf.ToString())
    [void]$pdf.Append("$id 0 obj`n$($objects[$id])`nendobj`n")
  }
  $xrefOffset = [System.Text.Encoding]::ASCII.GetByteCount($pdf.ToString())
  [void]$pdf.Append("xref`n0 $($fontId + 1)`n")
  [void]$pdf.Append("0000000000 65535 f `n")
  for ($id = 1; $id -le $fontId; $id++) {
    [void]$pdf.Append(('{0:0000000000} 00000 n ' -f $offsets[$id]) + "`n")
  }
  [void]$pdf.Append("trailer`n<< /Size $($fontId + 1) /Root 1 0 R >>`nstartxref`n$xrefOffset`n%%EOF`n")

  [System.IO.File]::WriteAllBytes($OutputPath, [System.Text.Encoding]::ASCII.GetBytes($pdf.ToString()))
}

$wd = (Resolve-Path -LiteralPath $WorkDir).Path
if (-not $PaperOutput) {
  $pathsFile = Join-Path $wd 'project_paths.json'
  if (Test-Path $pathsFile) {
    $paths = Get-Content -Raw -LiteralPath $pathsFile | ConvertFrom-Json
    $PaperOutput = $paths.paper_output
  } else {
    $PaperOutput = Join-Path $wd 'paper_export'
  }
}
New-Item -ItemType Directory -Force -Path $PaperOutput | Out-Null

$paperMd = Join-Path $wd 'paper.md'
if (-not (Test-Path $paperMd)) {
  throw "paper.md not found in $wd"
}

$outMd = Join-Path $PaperOutput 'paper.md'
$outDocx = Join-Path $PaperOutput 'paper.docx'
$outTxt = Join-Path $PaperOutput 'paper.txt'
$outPdf = Join-Path $PaperOutput 'paper.pdf'

Copy-Item -LiteralPath $paperMd -Destination $outMd -Force

$pandoc = Get-Command pandoc -ErrorAction SilentlyContinue
if ($pandoc) {
  Push-Location $wd
  try {
    & pandoc 'paper.md' --from gfm+tex_math_dollars+pipe_tables --to docx --output $outDocx --resource-path .
    & pandoc 'paper.md' --from gfm --to plain --output $outTxt --resource-path .
    $pdfErrFile = [System.IO.Path]::GetTempFileName()
    $oldErrorActionPreference = $ErrorActionPreference
    try {
      $ErrorActionPreference = 'Continue'
      & pandoc 'paper.md' --from gfm+tex_math_dollars+pipe_tables --to pdf --output $outPdf --resource-path . 2> $pdfErrFile
      if ($LASTEXITCODE -ne 0) {
        $pdfError = (Get-Content -Raw -LiteralPath $pdfErrFile -ErrorAction SilentlyContinue).Trim()
      }
    } finally {
      $ErrorActionPreference = $oldErrorActionPreference
      Remove-Item -LiteralPath $pdfErrFile -Force -ErrorAction SilentlyContinue
    }
  } finally {
    Pop-Location
  }
} else {
  Copy-Item -LiteralPath $paperMd -Destination $outTxt -Force
  $pandocMissing = $true
}

if (-not (Test-Path $outDocx)) {
  $existingDocx = Join-Path $wd 'paper.docx'
  if (Test-Path $existingDocx) { Copy-Item -LiteralPath $existingDocx -Destination $outDocx -Force }
}

if (-not (Test-Path $outPdf)) {
  try {
    $pdfSource = if (Test-Path $outTxt) { $outTxt } else { $paperMd }
    New-SimplePdf -TextPath $pdfSource -OutputPath $outPdf
    $pdfFallback = $true
  } catch {
    $pdfFallbackError = $_.Exception.Message
  }
}

$result = [ordered]@{
  paper_md = (Test-Path $outMd)
  paper_docx = (Test-Path $outDocx)
  paper_txt = (Test-Path $outTxt)
  paper_pdf = (Test-Path $outPdf)
  output_dir = (Resolve-Path -LiteralPath $PaperOutput).Path
  pandoc_available = [bool]$pandoc
}
if ($pdfError) { $result.pdf_error = $pdfError }
if ($pdfFallback) { $result.pdf_fallback = 'simple text-only PDF' }
if ($pdfFallbackError) { $result.pdf_fallback_error = $pdfFallbackError }
if ($pandocMissing) { $result.error = 'pandoc not available; only markdown/text fallback produced' }

$result | ConvertTo-Json -Depth 4
