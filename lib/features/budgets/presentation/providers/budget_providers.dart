// lib/features/budgets/presentation/providers/budget_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/budget_model.dart';
import '../../data/budget_repository.dart';
import '../../../records/presentation/providers/record_providers.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

final budgetsProvider = FutureProvider.autoDispose<List<Budget>>((ref) async {
  final repo = ref.read(budgetRepositoryProvider);
  final month = ref.watch(selectedMonthProvider);
  return repo.getForMonth(month.year, month.month);
});

final budgetTotalsProvider = Provider.autoDispose<({double total, double spent})>((ref) {
  final budgets = ref.watch(budgetsProvider);
  return budgets.when(
    data: (list) {
      final total = list.fold(0.0, (s, b) => s + b.amount);
      final spent = list.fold(0.0, (s, b) => s + (b.spent ?? 0));
      return (total: total, spent: spent);
    },
    loading: () => (total: 0.0, spent: 0.0),
    error: (_, __) => (total: 0.0, spent: 0.0),
  );
});
