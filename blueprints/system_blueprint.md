# System Blueprint: Armadio Digitale / Fyne

## Overview
This document outlines the architecture for the modern, robust, and secure successor to MoneyWiz 2026.

## Tech Stack
- **Frontend**: Multi-platform (Fyne/Go or similar based on project name, but currently focusing on backend).
- **Backend**: Node.js (Express) running on **Google Cloud Run**.
- **Database**: Managed **PostgreSQL (Cloud SQL)** with private VPC access.
- **Authentication**: **Firebase Authentication** for user identity management.

## Security Architecture
### 1. Data Encryption (AES-256)
- All sensitive banking and user data MUST be encrypted before storage.
- Storage-level encryption is handled by GCP (AES-256).
- Application-level encryption ensures data remains encrypted in transit and in the database buffers.

### 2. Zero-Knowledge Design
- The backend should not have access to the user's master password or encryption keys in plain text.
- Encryption keys are derived on the client side or managed through a secure key management system where only the user can authorize decryption.
- The "Banking Abstraction Layer" acts as an orchestrator but never "sees" the raw sensitive data if possible.

## Infrastructure
- **VPC Service Controls**: Private IP connectivity between Cloud Run and Cloud SQL.
- **Service Accounts**: Principle of least privilege for backend access to DB.
- **Managed Auth**: Firebase handles the salt, hash, and multi-factor authentication.

## Layer di Astrazione Bancaria (Banking Abstraction Layer)
- Purpose: Normalize data from various banking providers.
- Architecture: Plugin-based or provider-agnostic core.
- Scalability: Serverless deployment via Cloud Run.
