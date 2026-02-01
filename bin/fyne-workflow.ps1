# fyne-workflow.ps1
# Workflow manager per Fyne (Flutter) development

param (
    [Parameter(Position=0)]
    [ValidateSet("local", "cloud", "hybrid", "ask")]
    [string]$Mode = "local",

    [Parameter(Position=1)]
    [string]$Target
)

function Show-Help {
    Write-Host "Uso: fyne-workflow [mode] [target]"
    Write-Host "Modes:"
    Write-Host "  local  : Usa Aider + Ollama (Editing locale)"
    Write-Host "  cloud  : Usa Antigravity/Kimi (Analisi architettura)"
    Write-Host "  hybrid : Analisi su Kimi, implementazione su Aider"
    Write-Host "  ask    : Domanda veloce a Ollama"
}

switch ($Mode) {
    "local" {
        Write-Host "Starting Local Mode (Aider + Ollama)..." -ForegroundColor Cyan
        if ($Target) {
            aider --model ollama/deepseek-coder:6.7b --file $Target
        } else {
            aider --model ollama/deepseek-coder:6.7b
        }
    }
    "cloud" {
        Write-Host "Starting Cloud Mode (Antigravity Bridge)..." -ForegroundColor Cyan
        if (-not $Target) {
            Write-Error "Specificare un file per Cloud Mode."
            exit 1
        }
        & "$PSScriptRoot\fyne-bridge.ps1" -File $Target -Context "arch-review"
    }
    "hybrid" {
        Write-Host "Starting Hybrid Mode..." -ForegroundColor Cyan
        if (-not $Target) {
            Write-Error "Specificare un file per Hybrid Mode."
            exit 1
        }
        # 1. Manda a Kimi
        Write-Host "[Step 1] Analisi Antigravity..."
        & "$PSScriptRoot\fyne-bridge.ps1" -File $Target -Context "refactor-plan"
        
        # 2. Utente deve confermare quando ha il piano
        Read-Host "Premi INVIO quando hai copiato il piano di refactoring da Kimi..."
        
        # 3. Lancia Aider con istruzioni dall'utente (che incollerà il piano)
        Write-Host "[Step 2] Avvio Aider per implementazione..."
        Write-Host "→ Incolla il piano generato da Kimi nel prompt di Aider." -ForegroundColor Yellow
        aider --model ollama/deepseek-coder:6.7b --file $Target
    }
    "ask" {
        if (-not $Target) {
            Write-Host "Cosa vuoi chiedere a Ollama?"
            $Target = Read-Host "> "
        }
        ollama run deepseek-coder:6.7b $Target
    }
}
