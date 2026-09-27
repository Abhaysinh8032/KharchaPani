// lib/features/budgets/presentation/providers/budget_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/budget_model.dart';
import '../../data/budget_repository.dart';
import '../../../records/presentation/providers/record_providers.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((_) => BudgetRepository());

/// ✅ FIX: watches monthRecordsProvider so budgets auto-refresh when a record is added.
/// This eliminates the slow manual refresh — the moment records change, budgets recompute.
final budgetsProvider = FutureProvider.autoDispose<List<Budget>>((ref) async {
  // Watch records so this provider invalidates whenever records change
  ref.watch(monthRecordsProvider);
  final month = ref.watch(selectedMonthProvider);
  return ref.read(budgetRepositoryProvider).getForMonth(month.year, month.month);
});

final budgetTotalsProvider = Provider.autoDispose<({double total, double spent})>((ref) {
  final budgets = ref.watch(budgetsProvider);
  return budgets.when(
    data: (list) => (
      total: list.fold(0.0, (s, b) => s + b.amount),
      spent: list.fold(0.0, (s, b) => s + (b.spent ?? 0)),
    ),
    loading: () => (total: 0.0, spent: 0.0),
    error: (_, __) => (total: 0.0, spent: 0.0),
  );
});
