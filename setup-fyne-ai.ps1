# setup-fyne-ai.ps1
# Script di configurazione ambiente Fyne AI su Windows

$WorkDir = "C:\Fyne"
$BinDir = "$WorkDir\bin"

Write-Host "Configurazione Ambiente Fyne AI..." -ForegroundColor Cyan

# 1. Verifica Prerequisiti
Write-Host "`n[1/3] Verifica Prerequisiti..."
if (Get-Command ollama -ErrorAction SilentlyContinue) {
    Write-Host "✓ Ollama trovato." -ForegroundColor Green
} else {
    Write-Host "X Ollama non trovato. Installalo da https://ollama.ai" -ForegroundColor Red
}

if (Get-Command python -ErrorAction SilentlyContinue) {
    Write-Host "✓ Python trovato." -ForegroundColor Green
    # Check Aider
    try {
        python -c "import aider" 2>$null
        Write-Host "✓ Aider sembra installato." -ForegroundColor Green
    } catch {
        Write-Host "! Aider potrebbe non essere installato. Esegui: pip install aider-chat" -ForegroundColor Yellow
    }
} else {
    Write-Host "X Python non trovato." -ForegroundColor Red
}

# 2. Configurazione Variabili Ambiente (Sessione corrente)
Write-Host "`n[2/3] Impostazione Variabili Ambiente (Sessione)..."
$env:ANTIGRAVITY_PROJECT = "fyne-finance"
Write-Host "ANTIGRAVITY_PROJECT = $env:ANTIGRAVITY_PROJECT"

# 3. Istruzioni per PATH e Alias
Write-Host "`n[3/3] Configurazione Finale" -ForegroundColor Cyan
Write-Host "Per rendere i comandi permanenti, aggiungi le seguenti righe al tuo profilo PowerShell:"
Write-Host "Esegui: notepad `$PROFILE" -ForegroundColor Gray
Write-Host "`n--- COPIA E INCOLLA IN `$PROFILE ---" -ForegroundColor White
Write-Host "
# Fyne AI Workflow
`$env:ANTIGRAVITY_PROJECT = 'fyne-finance'
`$env:PATH += ';$BinDir'

function fyne-workflow { & '$BinDir\fyne-workflow.ps1' @args }
function fyne-bridge { & '$BinDir\fyne-bridge.ps1' @args }

# Alias brevi
Set-Alias fyne fyne-workflow
" -ForegroundColor White
Write-Host "------------------------------------`n"

Write-Host "Setup completato (File creati). Configura manualmente il profilo per l'uso globale." -ForegroundColor Green
