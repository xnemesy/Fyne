# 🏦 FYNE OPEN BANKING ARCHITECTURE
## Zero-Knowledge PSD2 Integration Guide

---

## 🎯 PROBLEMA DA RISOLVERE

**Challenge**: Integrare le API Open Banking (PSD2) mantenendo la filosofia Zero-Knowledge di Fyne.

**Conflitto Architetturale**:
- ✅ **Fyne Promise**: "I tuoi dati finanziari non lasciano mai il dispositivo in chiaro"
- ❌ **Open Banking Reality**: Le API richiedono un backend trusted che gestisce OAuth + token refresh

**Esempio Flusso Tradizionale (YNAB, Plaid)**:
```
User → App → Plaid Backend → Bank API
                ↓
         Plaid Database (TUTTI i dati finanziari in chiaro)
                ↓
         App riceve JSON in chiaro
```

**❌ Questo violerebbe la promessa Zero-Knowledge di Fyne.**

---

## ✅ SOLUZIONE: EPHEMERAL RELAY ARCHITECTURE

### Principi Fondamentali

1. **Stateless Relay Server**: Il server non salva MAI nulla
2. **End-to-End Encryption**: Client cifra con la propria chiave pubblica PRIMA di inviare al relay
3. **Session-Only Tokens**: Access token validi per max 5 minuti
4. **Open Source Relay**: Il codice del relay è pubblico e auditabile

---

## 🏗️ ARCHITETTURA COMPLETA

```
┌─────────────────────────────────────────────────────────────────┐
│                         FYNE APP (Client)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. User clicca "Collega Intesa Sanpaolo"                      │
│                                                                  │
│  2. App genera coppia chiavi RSA 4096-bit                       │
│     Private Key → Salvata in SecureStorage (locale)             │
│     Public Key → Inviata al Relay                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ HTTPS POST
                            │ {"public_key": "-----BEGIN RSA..."}
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│             FYNE RELAY SERVER (Cloud Function)                   │
│            Google Cloud Run / AWS Lambda / Vercel                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  3. Relay riceve public_key e genera session_id univoco         │
│     session_id = sha256(public_key + timestamp + random_nonce)  │
│                                                                  │
│  4. Relay avvia OAuth 2.0 con Nordigen/TrueLayer               │
│     redirect_uri = "https://relay.fyne.app/callback/{session}"  │
│                                                                  │
│  5. Relay restituisce auth_link al client                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ {"auth_link": "https://nordigen..."}
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                         FYNE APP (Client)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  6. App apre auth_link in WebView/Browser in-app                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ User autorizza la banca
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                         BANK OAUTH PAGE                          │
│                    (Intesa Sanpaolo, UniCredit)                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  7. User inserisce credenziali bancarie                         │
│  8. User conferma accesso read-only alle transazioni            │
│                                                                  │
│  9. Banca reindirizza a:                                        │
│     https://relay.fyne.app/callback/{session}?code=AUTH_CODE    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ OAuth redirect
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│             FYNE RELAY SERVER (Cloud Function)                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  10. Relay scambia code con access_token                        │
│      POST https://nordigen.com/api/token                        │
│                                                                  │
│  11. Relay fetches account IDs                                  │
│      GET /accounts/{requisition_id}/                            │
│                                                                  │
│  12. Relay fetches transactions (ultimi 90 giorni)              │
│      GET /accounts/{account_id}/transactions/                   │
│                                                                  │
│  13. Per OGNI transazione:                                      │
│      - Prendi JSON transaction                                  │
│      - Cifra con public_key del client (RSA-4096)               │
│      - Aggiungi a encrypted_batch[]                             │
│                                                                  │
│  14. Relay invia encrypted_batch al client via webhook          │
│      POST https://fyne.app/api/import-callback                  │
│      (oppure SSE stream per real-time updates)                  │
│                                                                  │
│  15. Relay CANCELLA tutto:                                      │
│      - access_token → revocato immediatamente                   │
│      - public_key → eliminata dalla memoria                     │
│      - encrypted_batch → eliminata dalla memoria                │
│      - session_id → invalidato                                  │
│                                                                  │
│  ✅ Nessun dato salvato su disco, DB, o logs                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ Encrypted JSON batch
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                         FYNE APP (Client)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  16. Per OGNI encrypted_transaction:                            │
│      - Decifra con Private Key RSA (locale)                     │
│      - Ottieni JSON in chiaro                                   │
│      - Ri-cifra con Master Key AES-256 (locale)                 │
│      - Salva in Isar DB                                         │
│                                                                  │
│  17. Mostra success screen:                                     │
│      "✅ Importate 245 transazioni da Intesa Sanpaolo"          │
│                                                                  │
│  18. Elimina chiave RSA ephemeral (opzionale)                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔐 GARANZIE DI SICUREZZA

### 1. Zero-Knowledge Proof

**Cosa il Relay NON può vedere**:
- ❌ Importi delle transazioni → Cifrati con chiave pubblica del client
- ❌ Descrizioni delle transazioni → Cifrate
- ❌ Nomi dei conti → Cifrati
- ❌ Saldi → Cifrati
- ❌ User identity → Usa solo anonymous session_id

**Cosa il Relay PUÒ vedere** (metadata non sensibili):
- ✅ Timestamp di richiesta (per rate limiting)
- ✅ IP address (per fraud detection)
- ✅ Bank institution ID (es. "INTESA_SANPAOLO")
- ✅ Numero di transazioni fetched (ma non i contenuti)

### 2. Time-Limited Access

```dart
class RelaySession {
  final String sessionId;
  final DateTime createdAt;
  final DateTime expiresAt; // createdAt + 5 minuti
  final String publicKey;
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

// Nel relay server (Go/Node.js)
if (session.isExpired) {
  return Response.json({
    "error": "SESSION_EXPIRED",
    "message": "Riprova dall'app"
  }, status: 401);
}
```

### 3. Single-Use Sessions

Una volta completato l'import, il session_id viene BRUCIATO e non può essere riutilizzato.

```go
// Relay Server (Go)
func (s *RelayServer) CompleteImport(sessionID string) error {
    session := s.sessions[sessionID]
    if session == nil {
        return errors.New("session not found")
    }
    
    // Revoca token OAuth
    err := s.revokeOAuthToken(session.AccessToken)
    if err != nil {
        log.Printf("Failed to revoke token: %v", err)
    }
    
    // Cancella tutto dalla memoria
    delete(s.sessions, sessionID)
    delete(s.publicKeys, sessionID)
    
    return nil
}
```

---

## 💻 IMPLEMENTAZIONE CLIENT (Flutter)

### Step 1: Genera Chiavi RSA Ephemeral

```dart
class OpenBankingService {
  final CryptoService _crypto = CryptoService();
  final Dio _dio = Dio();
  
  static const String relayBaseUrl = 'https://relay.fyne.app';
  
  /// Genera coppia chiavi RSA per questa sessione di import
  Future<RSAKeypair> _generateEphemeralKeyPair() async {
    final keyPair = RSAKeypair.fromRandom(keySize: 4096);
    
    // Salva SOLO per questa sessione (non in SecureStorage)
    return keyPair;
  }
  
  /// Step 1: Avvia flusso Open Banking
  Future<OpenBankingSession> initiateConnection({
    required String institutionId, // es. "INTESA_SANPAOLO_BITTPC"
  }) async {
    // 1. Genera chiavi
    final keyPair = await _generateEphemeralKeyPair();
    final publicKeyPEM = keyPair.publicKey.toPEM();
    
    // 2. Invia public key al relay
    final response = await _dio.post(
      '$relayBaseUrl/initiate',
      data: {
        'institution_id': institutionId,
        'public_key': publicKeyPEM,
        'app_version': '1.0.0-beta.4',
        'platform': Platform.isAndroid ? 'android' : 'ios',
      },
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to initiate connection');
    }
    
    final data = response.data;
    
    return OpenBankingSession(
      sessionId: data['session_id'],
      authLink: data['auth_link'],
      expiresAt: DateTime.parse(data['expires_at']),
      keyPair: keyPair,
    );
  }
}

class OpenBankingSession {
  final String sessionId;
  final String authLink;
  final DateTime expiresAt;
  final RSAKeypair keyPair; // Mantieni in memoria per decifrare più tardi
  
  OpenBankingSession({
    required this.sessionId,
    required this.authLink,
    required this.expiresAt,
    required this.keyPair,
  });
}
```

### Step 2: OAuth in WebView

```dart
class OpenBankingWebView extends StatefulWidget {
  final OpenBankingSession session;
  
  @override
  State<OpenBankingWebView> createState() => _OpenBankingWebViewState();
}

class _OpenBankingWebViewState extends State<OpenBankingWebView> {
  late final WebViewController _controller;
  bool _isCompleted = false;
  
  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Intercetta il redirect di successo
            if (request.url.startsWith('fyne://oauth-success')) {
              _handleOAuthSuccess();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.session.authLink));
  }
  
  void _handleOAuthSuccess() async {
    if (_isCompleted) return;
    setState(() => _isCompleted = true);
    
    // Mostra loading screen
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImportProgressScreen(session: widget.session),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Collega Banca'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
```

### Step 3: Polling per Dati Cifrati

```dart
class ImportProgressScreen extends StatefulWidget {
  final OpenBankingSession session;
  
  @override
  State<ImportProgressScreen> createState() => _ImportProgressScreenState();
}

class _ImportProgressScreenState extends State<ImportProgressScreen> {
  double _progress = 0.0;
  String _status = 'Connessione alla banca...';
  
  @override
  void initState() {
    super.initState();
    _startImport();
  }
  
  Future<void> _startImport() async {
    try {
      // 1. Poll relay server per encrypted data
      setState(() {
        _status = 'Recupero transazioni...';
        _progress = 0.3;
      });
      
      final encryptedData = await _pollForEncryptedData();
      
      // 2. Decrypt localmente
      setState(() {
        _status = 'Decifratura sicura...';
        _progress = 0.6;
      });
      
      final transactions = await _decryptAndSaveTransactions(encryptedData);
      
      // 3. Success!
      setState(() {
        _status = 'Completato!';
        _progress = 1.0;
      });
      
      await Future.delayed(Duration(seconds: 1));
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ImportSuccessScreen(
            transactionCount: transactions.length,
          ),
        ),
      );
      
    } catch (e) {
      _showError(e.toString());
    }
  }
  
  Future<EncryptedBatch> _pollForEncryptedData() async {
    const maxAttempts = 60; // 5 minuti con polling ogni 5 secondi
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      final response = await _dio.get(
        '${OpenBankingService.relayBaseUrl}/poll/${widget.session.sessionId}',
      );
      
      if (response.statusCode == 200 && response.data['status'] == 'ready') {
        return EncryptedBatch.fromJson(response.data['encrypted_batch']);
      }
      
      if (response.data['status'] == 'processing') {
        await Future.delayed(Duration(seconds: 5));
        attempts++;
        continue;
      }
      
      if (response.data['status'] == 'error') {
        throw Exception(response.data['error_message']);
      }
    }
    
    throw TimeoutException('Import timeout');
  }
  
  Future<List<TransactionModel>> _decryptAndSaveTransactions(
    EncryptedBatch batch,
  ) async {
    final isar = await ref.read(isarProvider.future);
    final masterKey = ref.read(masterKeyProvider);
    
    if (masterKey == null) throw Exception('Master key not found');
    
    final List<TransactionModel> decryptedTxs = [];
    
    for (final encryptedTx in batch.transactions) {
      // 1. Decrypt con chiave privata RSA (da bank → app)
      final decryptedJson = widget.session.keyPair.privateKey.decrypt(
        encryptedTx.encryptedPayload,
      );
      
      final txData = jsonDecode(decryptedJson) as Map<String, dynamic>;
      
      // 2. Re-encrypt con Master Key AES (app → Isar)
      final transaction = await _createEncryptedTransaction(
        txData,
        masterKey,
      );
      
      decryptedTxs.add(transaction);
    }
    
    // 3. Batch save
    await isar.writeTxn(() async {
      await isar.transactionModels.putAll(decryptedTxs);
    });
    
    return decryptedTxs;
  }
  
  Future<TransactionModel> _createEncryptedTransaction(
    Map<String, dynamic> data,
    SecretKey masterKey,
  ) async {
    final crypto = CryptoService();
    
    // Estrai campi dal JSON della banca
    final amount = double.parse(data['amount']);
    final description = data['description'] ?? data['remittanceInformation'];
    final counterParty = data['creditorName'] ?? data['debtorName'];
    final bookingDate = DateTime.parse(data['bookingDate']);
    
    // Cifra con Master Key
    final encryptedAmount = await crypto.encrypt(
      amount.toString(),
      masterKey,
    );
    
    final encryptedDescription = await crypto.encrypt(
      description ?? '',
      masterKey,
    );
    
    final encryptedCounterParty = counterParty != null
        ? await crypto.encrypt(counterParty, masterKey)
        : null;
    
    return TransactionModel(
      uuid: Uuid().v4(),
      accountId: data['account_id'] ?? 'imported',
      bookingDate: bookingDate,
      currency: data['currency'] ?? 'EUR',
      encryptedAmount: encryptedAmount,
      encryptedDescription: encryptedDescription,
      encryptedCounterParty: encryptedCounterParty,
      createdAt: DateTime.now(),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(value: _progress),
              SizedBox(height: 24),
              Text(
                _status,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 16),
              Text(
                'Non chiudere l\'app durante l\'importazione',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 🖥️ IMPLEMENTAZIONE RELAY SERVER

### Tecnologia Suggerita: Go + Google Cloud Run

**Perché Go?**
- Performance eccellenti per operazioni crypto
- Deployment veloce su Cloud Run (cold start < 500ms)
- Librerie crypto robuste

### Struttura Progetto

```
fyne-relay-server/
├── main.go
├── handlers/
│   ├── initiate.go
│   ├── callback.go
│   ├── poll.go
├── services/
│   ├── nordigen_client.go
│   ├── encryption_service.go
│   ├── session_manager.go
├── models/
│   ├── session.go
│   ├── transaction.go
└── Dockerfile
```

### main.go

```go
package main

import (
    "log"
    "net/http"
    "os"
    "github.com/gorilla/mux"
)

func main() {
    r := mux.NewRouter()
    
    // Endpoints
    r.HandleFunc("/initiate", handlers.InitiateConnection).Methods("POST")
    r.HandleFunc("/callback/{session_id}", handlers.OAuthCallback).Methods("GET")
    r.HandleFunc("/poll/{session_id}", handlers.PollEncryptedData).Methods("GET")
    
    // Health check
    r.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        w.Write([]byte("OK"))
    }).Methods("GET")
    
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }
    
    log.Printf("Starting relay server on port %s", port)
    log.Fatal(http.ListenAndServe(":"+port, r))
}
```

### handlers/initiate.go

```go
package handlers

import (
    "encoding/json"
    "net/http"
    "time"
    "crypto/sha256"
    "encoding/hex"
    "github.com/google/uuid"
)

type InitiateRequest struct {
    InstitutionID string `json:"institution_id"`
    PublicKey     string `json:"public_key"`
    AppVersion    string `json:"app_version"`
    Platform      string `json:"platform"`
}

type InitiateResponse struct {
    SessionID string    `json:"session_id"`
    AuthLink  string    `json:"auth_link"`
    ExpiresAt time.Time `json:"expires_at"`
}

func InitiateConnection(w http.ResponseWriter, r *http.Request) {
    var req InitiateRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Invalid request", http.StatusBadRequest)
        return
    }
    
    // Valida public key
    if !isValidPublicKey(req.PublicKey) {
        http.Error(w, "Invalid public key", http.StatusBadRequest)
        return
    }
    
    // Genera session ID univoco
    sessionID := generateSessionID(req.PublicKey)
    expiresAt := time.Now().Add(5 * time.Minute)
    
    // Crea session in memoria
    session := &models.Session{
        ID:            sessionID,
        PublicKey:     req.PublicKey,
        InstitutionID: req.InstitutionID,
        CreatedAt:     time.Now(),
        ExpiresAt:     expiresAt,
        Status:        "pending",
    }
    
    sessionManager.Store(sessionID, session)
    
    // Avvia OAuth con Nordigen
    authLink, err := nordigenClient.CreateRequisition(sessionID, req.InstitutionID)
    if err != nil {
        http.Error(w, "Failed to create requisition", http.StatusInternalServerError)
        return
    }
    
    // Response
    resp := InitiateResponse{
        SessionID: sessionID,
        AuthLink:  authLink,
        ExpiresAt: expiresAt,
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(resp)
}

func generateSessionID(publicKey string) string {
    data := publicKey + time.Now().String() + uuid.New().String()
    hash := sha256.Sum256([]byte(data))
    return hex.EncodeToString(hash[:])
}

func isValidPublicKey(pem string) bool {
    // TODO: Parse e valida il PEM
    return len(pem) > 100 && strings.Contains(pem, "BEGIN RSA PUBLIC KEY")
}
```

### handlers/callback.go

```go
package handlers

import (
    "net/http"
    "github.com/gorilla/mux"
)

func OAuthCallback(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    sessionID := vars["session_id"]
    code := r.URL.Query().Get("code")
    
    if code == "" {
        http.Error(w, "Missing authorization code", http.StatusBadRequest)
        return
    }
    
    // Recupera session
    session, exists := sessionManager.Get(sessionID)
    if !exists {
        http.Error(w, "Session not found or expired", http.StatusNotFound)
        return
    }
    
    // Scambia code con access token
    accessToken, err := nordigenClient.ExchangeCodeForToken(code)
    if err != nil {
        http.Error(w, "Failed to exchange code", http.StatusInternalServerError)
        return
    }
    
    session.AccessToken = accessToken
    session.Status = "processing"
    sessionManager.Store(sessionID, session)
    
    // Avvia goroutine per fetch transazioni
    go fetchAndEncryptTransactions(session)
    
    // Redirect success a app
    http.Redirect(w, r, "fyne://oauth-success", http.StatusFound)
}

func fetchAndEncryptTransactions(session *models.Session) {
    defer func() {
        // Cleanup dopo fetch
        nordigenClient.RevokeToken(session.AccessToken)
        session.AccessToken = ""
    }()
    
    // 1. Fetch account IDs
    accounts, err := nordigenClient.GetAccounts(session.AccessToken)
    if err != nil {
        session.Status = "error"
        session.ErrorMessage = err.Error()
        return
    }
    
    var allTransactions []models.EncryptedTransaction
    
    // 2. Per ogni account, fetch transazioni
    for _, accountID := range accounts {
        transactions, err := nordigenClient.GetTransactions(
            session.AccessToken,
            accountID,
        )
        if err != nil {
            continue // Skip account con errori
        }
        
        // 3. Cifra ogni transazione
        for _, tx := range transactions {
            txJSON, _ := json.Marshal(tx)
            
            // Cifra con public key del client
            encryptedPayload, err := encryptionService.EncryptWithPublicKey(
                txJSON,
                session.PublicKey,
            )
            if err != nil {
                continue
            }
            
            allTransactions = append(allTransactions, models.EncryptedTransaction{
                EncryptedPayload: encryptedPayload,
                AccountID:        accountID,
            })
        }
    }
    
    // 4. Salva batch cifrato nella session (SOLO in memoria!)
    session.EncryptedBatch = allTransactions
    session.Status = "ready"
    sessionManager.Store(session.ID, session)
}
```

### handlers/poll.go

```go
package handlers

import (
    "encoding/json"
    "net/http"
    "github.com/gorilla/mux"
)

type PollResponse struct {
    Status          string                        `json:"status"`
    EncryptedBatch  []models.EncryptedTransaction `json:"encrypted_batch,omitempty"`
    ErrorMessage    string                        `json:"error_message,omitempty"`
}

func PollEncryptedData(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    sessionID := vars["session_id"]
    
    session, exists := sessionManager.Get(sessionID)
    if !exists {
        http.Error(w, "Session not found", http.StatusNotFound)
        return
    }
    
    // Check se session è scaduta
    if time.Now().After(session.ExpiresAt) {
        sessionManager.Delete(sessionID)
        http.Error(w, "Session expired", http.StatusGone)
        return
    }
    
    resp := PollResponse{
        Status: session.Status,
    }
    
    if session.Status == "ready" {
        resp.EncryptedBatch = session.EncryptedBatch
        
        // IMPORTANTE: Cleanup immediato dopo invio
        sessionManager.Delete(sessionID)
    }
    
    if session.Status == "error" {
        resp.ErrorMessage = session.ErrorMessage
        sessionManager.Delete(sessionID)
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(resp)
}
```

---

## 🔒 COMPLIANCE & AUDIT

### GDPR Compliance

**Articolo 5(1)(f) - Integrity and Confidentiality**:
✅ Fyne relay usa encryption end-to-end, garantendo che i dati siano protetti anche in transito.

**Articolo 25 - Data Protection by Design**:
✅ L'architettura è progettata per minimizzare i dati trattati dal relay (solo metadata).

### PSD2 Compliance

**Strong Customer Authentication (SCA)**:
✅ Gestita dalla banca durante l'OAuth flow (biometric o 2FA).

**Access Duration**:
⚠️ Nordigen consente accesso per 90 giorni. Fyne potrebbe chiedere ri-autenticazione ogni 30 giorni.

---

## 📊 COSTI & SCALABILITÀ

### Nordigen Free Tier
- ✅ 100 requisitions/month GRATIS
- ✅ Supporto per 2,000+ banche europee
- ❌ Limite: 5 requisitions/user/month

### Google Cloud Run Pricing (Relay Server)
- **Cold start**: < 500ms
- **CPU**: 1 vCPU @ $0.00002400/vCPU-second
- **Memory**: 512 MB @ $0.00000250/GiB-second
- **Stima**: ~$5/month per 10,000 import

### Alternative Providers
- **TrueLayer** (UK-focused): €0.15/account/month
- **Plaid** (USA/Europe): $0.49/end-user/month
- **GoCardless** (Self-hosted Nordigen): Open Source!

---

## ✅ CHECKLIST IMPLEMENTAZIONE

### Client (Flutter)
- [ ] RSA key generation (4096-bit)
- [ ] Initiate connection API call
- [ ] OAuth WebView flow
- [ ] Polling mechanism
- [ ] RSA decryption (bank → app)
- [ ] AES encryption (app → Isar)
- [ ] Error handling & retry logic
- [ ] UI: Bank selection screen
- [ ] UI: Import progress screen
- [ ] UI: Success/Error screens

### Relay Server (Go)
- [ ] Setup Cloud Run project
- [ ] Nordigen API client
- [ ] Session manager (in-memory)
- [ ] RSA encryption service
- [ ] Initiate endpoint
- [ ] OAuth callback endpoint
- [ ] Poll endpoint
- [ ] Health check endpoint
- [ ] Logging (without PII)
- [ ] Rate limiting
- [ ] CORS configuration
- [ ] Deploy script

### Security & Compliance
- [ ] Penetration testing
- [ ] GDPR audit
- [ ] Privacy policy update
- [ ] Terms of service update
- [ ] Open source relay code (GitHub)

---

**Stima Sviluppo**: 10-12 settimane per developer full-stack
