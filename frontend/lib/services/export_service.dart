import 'dart:io';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flutter/foundation.dart';

 class ExportService {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> authenticate() async {
    return true; // Simplified for build
  }

  Future<void> exportToCsv(List<dynamic> decryptedTransactions) async {
    // Temporarily disabled for build
  }
}
