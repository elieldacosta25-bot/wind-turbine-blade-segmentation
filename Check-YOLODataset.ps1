param (
    [string]$folderPath
)

function Check-Annotations {
    param ($labelsPath, $setName, [ref]$problems)
    $txtFiles = Get-ChildItem -Path $labelsPath -Filter '*.txt' -File -ErrorAction SilentlyContinue
    foreach ($file in $txtFiles) {
        $filePath = $file.FullName
        $lines = Get-Content $filePath
        $lineNum = 0
        foreach ($line in $lines) {
            $lineNum++
            $cleanLine = $line -replace '[,;]',' ' -replace '\s+', ' ' -replace '^\s+|\s+$', ''
            if ([string]::IsNullOrWhiteSpace($cleanLine)) { continue }
            $parts = $cleanLine -split ' '
            $numbers = @()
            foreach ($p in $parts) {
                $tmp = 0
                if ([double]::TryParse($p, [ref]$tmp)) { $numbers += $tmp }
            }
            $numValues = $numbers.Count
            if ($numValues -eq 5) {
                $problems.Value += [pscustomobject]@{
                    Pasta = $setName
                    Imagem = $file.Name
                    Descricao = "Bounding Box found at line ${lineNum}: ${line}"
                }
            } elseif ($numValues -ge 7 -and ($numValues % 2 -eq 1)) {
                # Segmentação válida, ignorar
            }
        }
    }
}

if (-not $folderPath) {
    Write-Host "Arraste a pasta do dataset como parâmetro para este script." -ForegroundColor Red
    exit
}

# PERSONALIZE OS CAMINHOS ABAIXO CONFORME ESTRUTURA ROOT/labels/train, val, test
$sets = @(
    @{name="train"; path=(Join-Path $folderPath "labels/train")},
    @{name="val"; path=(Join-Path $folderPath "labels/val")},
    @{name="test"; path=(Join-Path $folderPath "labels/test")}
)

$problemsList = @()
foreach ($set in $sets) {
    Check-Annotations -labelsPath $set.path -setName $set.name -problems ([ref]$problemsList)
}

if ($problemsList.Count -eq 0) {
    Write-Host "SUCESSO! Nenhum bbox encontrado, dataset pronto para segmentação YOLOv8." -ForegroundColor Green
} else {
    Write-Host "Total de arquivos com inconsistências: $($problemsList.Count)" -ForegroundColor Yellow
    $csvFile = Join-Path $folderPath 'PROBLEMAS_YOLO.csv'
    $problemsList | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8
    Write-Host "Arquivo PROBLEMAS_YOLO.csv gerado em:" -ForegroundColor Cyan
    Write-Host $csvFile
}
