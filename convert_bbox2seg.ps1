param (
    [string]$root
)

# Função para converter bbox para segmento retangular (polígono)
function Convert-Bbox-To-Seg {
    param (
        [string]$labelFile,
        [string]$outFile
    )
    $lines = Get-Content $labelFile
    $newLines = @()
    foreach ($line in $lines) {
        $clean = $line -replace '\s+', ' ' -replace '^\s+|\s+$', ''
        if ([string]::IsNullOrWhiteSpace($clean)) { continue }
        $parts = $clean -split ' '
        if ($parts.Count -eq 5) {
            # Conversão bbox para segment
            $cls = $parts[0]
            $x = [double]$parts[1]
            $y = [double]$parts[2]
            $w = [double]$parts[3]
            $h = [double]$parts[4]
            $x1 = $x - $w/2
            $y1 = $y - $h/2
            $x2 = $x + $w/2
            $y2 = $y - $h/2
            $x3 = $x + $w/2
            $y3 = $y + $h/2
            $x4 = $x - $w/2
            $y4 = $y + $h/2
            $segment = "$cls $x1 $y1 $x2 $y2 $x3 $y3 $x4 $y4"
            $newLines += $segment
        } else {
            # Já está em segmentação, mantém a linha original
            $newLines += $line
        }
    }
    Set-Content -Path $outFile -Value $newLines
}

# Cria uma pasta nova para salvar as anotações convertidas
$labelsIn = Join-Path $root "labels"
$labelsOut = Join-Path $root "labels_segment"
if (-not (Test-Path $labelsOut)) { New-Item -ItemType Directory -Path $labelsOut | Out-Null }

$sets = @("train", "val", "test")
foreach ($set in $sets) {
    $src = Join-Path $labelsIn $set
    $dst = Join-Path $labelsOut $set
    if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Path $dst | Out-Null }
    $txtFiles = Get-ChildItem -Path $src -Filter '*.txt' -File -ErrorAction SilentlyContinue
    foreach ($file in $txtFiles) {
        $outFile = Join-Path $dst $file.Name
        Convert-Bbox-To-Seg -labelFile $file.FullName -outFile $outFile
    }
    Write-Host "$($txtFiles.Count) arquivos convertidos para segmentação em $set"
}

Write-Host "Conversão concluída. Anotações segmentadas na pasta labels_segment/"
Read-Host "Pressione Enter para sair" | Out-Null
