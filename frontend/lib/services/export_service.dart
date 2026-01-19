import 'dart:io';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flutter/foundation.dart';

 class ExportService {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> authenticate() async {
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

    if (!canAuthenticate) return false;

    try {
      return await auth.authenticate(
        localizedReason: 'Autenticati per esportare i tuoi dati finanziari in chiaro',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      debugPrint("Export Auth Error: $e");
      return false;
    }
  }

  Future<void> exportToCsv(List<dynamic> decryptedTransactions) async {
    final bool isAuthenticated = await authenticate();
    if (!isAuthenticated) return;

    List<List<dynamic>> rows = [];
    rows.add(["Data", "Descrizione", "Importo", "Categoria"]);

    for (var tx in decryptedTransactions) {
      rows.add([
        tx['bookingDate'],
        tx['decryptedDescription'],
        tx['amount'],
        tx['decryptedCategory']
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/fyne_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvData);

    // Using Share to let user save/send the file
    await Share.shareXFiles([XFile(file.path)], text: 'Esportazione dati Fyne');
  }
}
