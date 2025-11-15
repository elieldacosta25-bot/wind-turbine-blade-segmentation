# Mantém a janela aberta ao final ou em caso de erro
$ErrorActionPreference = "Stop"
try {
    # Solicita o caminho da pasta ao usuário
    Write-Host "=== Reorganizador de Dataset YOLO ===" -ForegroundColor Cyan
    $RootPath = Read-Host "Digite o caminho completo da pasta original (ex: C:\Users\Acer\Downloads\crack damage - lap damage.v3i.yolov8)"

    # Remove aspas se o usuário colar com aspas
    $RootPath = $RootPath.Trim('"').Trim()

    # Verifica se a pasta existe
    if (-not (Test-Path $RootPath)) {
        Write-Error "ERRO: A pasta não foi encontrada: $RootPath"
        Read-Host "Pressione ENTER para fechar"
        exit 1
    }

    # Define o caminho da nova pasta "dataset organizado" ao lado da original
    $ParentPath = Split-Path $RootPath -Parent
    $NewDatasetPath = Join-Path $ParentPath "dataset organizado"

    # Cria a nova estrutura de pastas
    $folders = @(
        "$NewDatasetPath\images\train",
        "$NewDatasetPath\images\valid",
        "$NewDatasetPath\images\test",
        "$NewDatasetPath\labels\train",
        "$NewDatasetPath\labels\valid",
        "$NewDatasetPath\labels\test"
    )

    foreach ($folder in $folders) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }

    Write-Host "Criando estrutura em: $NewDatasetPath" -ForegroundColor Green

    # Função para mover arquivos com feedback
    function Move-Files {
        param($Source, $Destination, $Type)
        if (Test-Path $Source) {
            $files = Get-ChildItem -Path $Source -File
            if ($files.Count -gt 0) {
                Move-Item -Path "$Source\*" -Destination $Destination -Force
                Write-Host "Movidos $($files.Count) $Type de '$Source' para '$Destination'" -ForegroundColor Yellow
            } else {
                Write-Host "Nenhum $Type encontrado em '$Source'" -ForegroundColor Gray
            }
        } else {
            Write-Host "Pasta não encontrada: $Source" -ForegroundColor DarkGray
        }
    }

    # Mover imagens
    Move-Files "$RootPath\train\images" "$NewDatasetPath\Images\train" "arquivos de imagem (train)"
    Move-Files "$RootPath\valid\images" "$NewDatasetPath\Images\valid" "arquivos de imagem (valid)"
    Move-Files "$RootPath\test\images"  "$NewDatasetPath\Images\test"  "arquivos de imagem (test)"

    # Mover labels
    Move-Files "$RootPath\train\labels" "$NewDatasetPath\labels\train" "arquivos de label (train)"
    Move-Files "$RootPath\valid\labels" "$NewDatasetPath\labels\valid" "arquivos de label (valid)"
    Move-Files "$RootPath\test\labels"  "$NewDatasetPath\labels\test"  "arquivos de label (test)"

    Write-Host "`nReorganização concluída com sucesso!" -ForegroundColor Green
    Write-Host "Nova pasta criada em: $NewDatasetPath" -ForegroundColor Cyan

} catch {
    Write-Error "`nERRO: $($_.Exception.Message)"
    Write-Host "`nStackTrace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
} finally {
    # Garante que a janela não feche
    Write-Host "`n" -ForegroundColor Magenta
    Read-Host "Pressione ENTER para fechar"
}
