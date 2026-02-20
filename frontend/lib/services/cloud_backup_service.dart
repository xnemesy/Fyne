import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CloudBackupService {
  final _storage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Carica un file di backup cifrato su Firebase Cloud Storage.
  Future<void> uploadBackup(String localPath) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Utente non autenticato");

    final file = File(localPath);
    if (!await file.exists()) throw Exception("File di backup non trovato");

    final fileName = p.basename(localPath);
    final storagePath = 'backups/${user.uid}/$fileName';
    final ref = _storage.ref().child(storagePath);

    debugPrint("[CloudBackup] Inizio upload di $fileName...");

    try {
      // 1. Upload su Cloud Storage
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(
          contentType: 'application/octet-stream',
          customMetadata: {
            'uid': user.uid,
            'exported_at': DateTime.now().toIso8601String(),
          },
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // 2. Registra metadati su Firestore per facile indicizzazione
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .doc(fileName)
          .set({
        'fileName': fileName,
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        'size': await file.length(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint("[CloudBackup] Upload completato con successo.");
    } catch (e) {
      debugPrint("[CloudBackup] Errore durante l'upload: $e");
      rethrow;
    }
  }

  /// Recupera la lista dei backup disponibili per l'utente corrente.
  Future<List<Map<String, dynamic>>> listBackups() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('backups')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Scarica un backup da Cloud Storage in un file locale temporaneo.
  Future<String> downloadBackup(String storagePath, String localPath) async {
    final ref = _storage.ref().child(storagePath);
    final file = File(localPath);

    if (await file.exists()) await file.delete();

    await ref.writeToFile(file);
    return file.path;
  }

  /// Elimina un backup sia da Storage che da Firestore.
  Future<void> deleteBackup(String fileName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final storagePath = 'backups/${user.uid}/$fileName';
    
    // Elimina da Storage
    try {
      await _storage.ref().child(storagePath).delete();
    } catch (e) {
      debugPrint("[CloudBackup] Avviso: Impossibile eliminare da Storage (potrebbe non esistere): $e");
    }

    // Elimina da Firestore
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('backups')
        .doc(fileName)
        .delete();
  }
}

final cloudBackupServiceProvider = Provider((ref) => CloudBackupService());
