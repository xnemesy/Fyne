# Fyne - Zero-Knowledge Financial Intelligence

Fyne è un'applicazione di personal finance premium costruita su un'architettura **Zero-Knowledge**. Priorità assoluta alla privacy, estetica sofisticata e insights in tempo reale senza mai esporre i propri dati finanziari al server in chiaro.

## 🚀 Funzionalità & Stato (v1.1.0-stable)
- **Dinamiche MoneyWiz**: Gestione del saldo atomica e precisa. Le spese sono evidenziate in rosso e i saldi dei conti si aggiornano istantaneamente al salvataggio delle transazioni.
- **Neo-Minimalist Editorial UI**: Estetica di alto livello ispirata al design editoriale. Palette core: Paper White (`#FBFBF9`), Deep Sage Green (`#4A6741`), Red Alert (`#D63031`).
- **Zero-Knowledge Architecture**: I dati finanziari vengono cifrati localmente (AES-256 per inserimenti manuali, RSA per sync bancario). Nessun dato sensibile tocca il server non cifrato.
- **Privacy Mode**: Funzione "Shield" integrata per oscurare i dati sensibili con un effetto blur cinematografico.
- **Insights Avanzati**: Analisi del patrimonio netto (Net Worth) con grafici interattivi e calcolo storico basato sul registro transazioni.
- **Supporto OCR**: Scansione intelligente degli scontrini per l'inserimento rapido.

## 🛠️ Struttura del Progetto
- `/frontend`: Applicazione Flutter. Utilizza **Riverpod** per la gestione dello stato e **Cryptography** per la sicurezza on-device.
- `/backend`: Server Node.js/Express. Gestisce la sincronizzazione dei dati cifrati e l'integrazione bancaria (GoCardless/Nordigen).
- `/infrastructure`: Script di deployment per Google Cloud (Run & SQL).

## 📱 Getting Started (Frontend)
1. **Configurazione**:
   ```bash
   cd frontend
   flutter pub get
   ```
2. **iOS Build**:
   - Assicurarsi di aver eseguito `pod install` nella cartella `ios`.
   - Il progetto è configurato per gestire automaticamente i link non-modulari per framework come TensorFlow e MLKit.
   - Bundle ID: `app.fyne.ios`.

## 🛡️ Handover & Sicurezza (Per Sviluppatori)
- **Encryption Flow**: Utilizzare sempre `CryptoService` prima di qualsiasi chiamata API che coinvolga importi o descrizioni. 
- **Atomic Updates**: Quando si salva una transazione manuale, calcolare sempre il `encryptedNewBalance` lato client per mantenere la coerenza del saldo senza che il server debba decifrare i dati.
- **Theme**: Rispettare rigorosamente il sistema di font (Lora per i titoli/numeri grandi, Inter per i dati tecnici).

---
**Privacy First**: Fyne NON collega l'identità dell'utente ai dati finanziari. Tutte le funzionalità di "Intelligence" avvengono sul silicio locale dell'utente.
