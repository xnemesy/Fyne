import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../services/categorization_service.dart';
import '../services/scheduler_service.dart';

import '../models/transaction.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../models/categorization_rule.dart';

final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [
      TransactionModelSchema,
      AccountSchema,
      BudgetSchema,
      PlannedTransactionSchema,
      CategorizationRuleSchema,
    ],
    directory: dir.path,
  );
});
