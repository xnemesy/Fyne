# Banking Abstraction Layer (Backend)

## Overview
This service acts as the "Layer di Astrazione Bancaria" (Banking Abstraction Layer) for the Fyne project. It is designed with a **Zero-Knowledge** architecture to ensure maximum security for banking data.

## Features
- **AES-256-CBC Encryption**: Sensitive data is encrypted at the application level before being stored in PostgreSQL.
- **Firebase Auth**: Secure user authentication and token verification.
- **Private Network**: Accessible only via VPC, ensuring the database is never exposed to the public internet.

## Security (Zero-Knowledge)
Following the `system_blueprint.md`:
1. The backend performs encryption using a master key (or derived key).
2. The database stores only encrypted blobs for sensitive fields.
3. Decryption keys should ideally be remains with the client or securely managed via KMS.

## Quick Start
1. Ensure the Google Cloud infrastructure is provisioned.
2. Deploy to Cloud Run:
   ```bash
   gcloud run deploy banking-abstraction-layer --source .
   ```

## API Reference
- `GET /`: Health check.
- `GET /api/user/profile`: Protected user profile (requires Firebase ID Token).
- `GET /health/db`: Database connectivity check.
