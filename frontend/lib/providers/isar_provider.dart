import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../services/categorization_service.dart';
import '../services/scheduler_service.dart';

final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [CategoryOverrideSchema, PlannedTransactionSchema],
    directory: dir.path,
  );
});

final categorizationServiceProvider = Provider.family<CategorizationService, Isar>((ref, isar) {
  return CategorizationService(isar);
});
