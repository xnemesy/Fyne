#!/bin/bash

# Script per preparare i file necessari per Windows che non sono su Git
TARGET_DIR="Fyne_Windows_Secrets"

echo "🚀 Creazione cartella di backup: $TARGET_DIR..."
mkdir -p "$TARGET_DIR/android"
mkdir -p "$TARGET_DIR/backend"
mkdir -p "$TARGET_DIR/ios"

echo "📂 Copia dei file Firebase..."
# Android
if [ -f "frontend/android/app/google-services.json" ]; then
    cp "frontend/android/app/google-services.json" "$TARGET_DIR/android/"
    echo "✅ google-services.json copiato"
else
    echo "❌ google-services.json NON trovato in frontend/android/app/"
fi

# iOS (per sicurezza)
if [ -f "frontend/ios/Runner/GoogleService-Info.plist" ]; then
    cp "frontend/ios/Runner/GoogleService-Info.plist" "$TARGET_DIR/ios/"
    echo "✅ GoogleService-Info.plist copiato"
fi

echo "📂 Copia dei file ambiente (.env)..."
# Backend
if [ -f "backend/.env" ]; then
    cp "backend/.env" "$TARGET_DIR/backend/"
    echo "✅ backend/.env copiato"
else
    echo "ℹ️  backend/.env non trovato (potrebbe non essere necessario se usi .env.example)"
fi

echo "------------------------------------------------"
echo "✅ Operazione completata!"
echo "Ora devi solo copiare la cartella '$TARGET_DIR' sul tuo PC Windows."
echo "------------------------------------------------"
