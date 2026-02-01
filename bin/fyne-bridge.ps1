# fyne-bridge.ps1
# Bridge tra file locale e Kimi (Antigravity) Web Agent

param (
    [Parameter(Mandatory=$true)]
    [string]$File,
    
    [string]$Context = "code-review"
)

# Verifica esistenza file
if (-not (Test-Path $File)) {
    Write-Host "Errore: File '$File' non trovato." -ForegroundColor Red
    exit 1
}

# Leggi contenuto e copia nella clipboard
try {
    $content = Get-Content -Path $File -Raw
    Set-Clipboard -Value $content
    Write-Host "✓ Contenuto di '$File' copiato negli appunti." -ForegroundColor Green
}
catch {
    Write-Host "Errore durante la lettura del file o copia negli appunti." -ForegroundColor Red
    exit 1
}

# Costruisci URL (Assumendo che ANTIGRAVITY_PROJECT sia impostato nell'ambiente o default)
$projectName = if ($env:ANTIGRAVITY_PROJECT) { $env:ANTIGRAVITY_PROJECT } else { "fyne-finance" }
$url = "https://www.kimi.com/agent?project=$projectName&context=$Context"

# Apri browser
Write-Host "Apertura Kimi Agent per analisi..." -ForegroundColor Cyan
Start-Process $url

Write-Host "→ Incolla il contenuto (Ctrl+V) nella chat di Kimi." -ForegroundColor Yellow
