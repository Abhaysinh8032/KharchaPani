// lib/features/records/presentation/providers/record_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/record_model.dart';
import '../../data/record_repository.dart';

final recordRepositoryProvider = Provider<RecordRepository>((_) => RecordRepository());

/// Selected month for all screens
final selectedMonthProvider = StateProvider<DateTime>(
  (_) => DateTime(DateTime.now().year, DateTime.now().month));

/// Records for selected month — invalidated after every write
final monthRecordsProvider = FutureProvider.autoDispose<List<FinancialRecord>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref.read(recordRepositoryProvider).getForMonth(month.year, month.month);
});

/// All records (for export)
final allRecordsProvider = FutureProvider<List<FinancialRecord>>(
  (ref) => ref.read(recordRepositoryProvider).getAll());

/// Monthly totals derived from records
final monthlySummaryProvider = Provider.autoDispose<({double income, double expense, double total})>((ref) {
  final records = ref.watch(monthRecordsProvider);
  return records.when(
    data: (list) {
      double income = 0, expense = 0;
      for (final r in list) {
        if (r.type == RecordType.income) income += r.amount;
        if (r.type == RecordType.expense) expense += r.amount;
      }
      return (income: income, expense: expense, total: income - expense);
    },
    loading: () => (income: 0.0, expense: 0.0, total: 0.0),
    error: (_, __) => (income: 0.0, expense: 0.0, total: 0.0),
  );
});

/// Category breakdown for analysis (expense OR income)
final expenseBreakdownProvider = Provider.autoDispose<Map<String, _CatBreakdown>>((ref) {
  final records = ref.watch(monthRecordsProvider);
  return records.when(
    data: (list) => _buildBreakdown(list, RecordType.expense),
    loading: () => {},
    error: (_, __) => {},
  );
});

final incomeBreakdownProvider = Provider.autoDispose<Map<String, _CatBreakdown>>((ref) {
  final records = ref.watch(monthRecordsProvider);
  return records.when(
    data: (list) => _buildBreakdown(list, RecordType.income),
    loading: () => {},
    error: (_, __) => {},
  );
});

Map<String, _CatBreakdown> _buildBreakdown(List<FinancialRecord> list, RecordType type) {
  final map = <String, _CatBreakdown>{};
  for (final r in list) {
    if (r.type != type) continue;
    final key = r.categoryName ?? 'Other';
    map[key] = _CatBreakdown(
      name: key,
      icon: r.categoryIcon ?? 'category',
      color: r.categoryColor ?? 0xFFE53935,
      amount: (map[key]?.amount ?? 0) + r.amount,
    );
  }
  final sorted = Map.fromEntries(
    map.entries.toList()..sort((a, b) => b.value.amount.compareTo(a.value.amount)));
  return sorted;
}

class _CatBreakdown {
  final String name, icon;
  final int color;
  final double amount;
  _CatBreakdown({required this.name, required this.icon,
    required this.color, required this.amount});
}

// Re-export for other files
typedef CatBreakdown = _CatBreakdown;
