// lib/features/records/presentation/providers/record_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/record_model.dart';
import '../../data/record_repository.dart';

final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  return RecordRepository();
});

// Selected month for navigation
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  return DateTime(DateTime.now().year, DateTime.now().month);
});

// Records for selected month
final monthRecordsProvider = FutureProvider.autoDispose<List<FinancialRecord>>((ref) async {
  final repo = ref.read(recordRepositoryProvider);
  final month = ref.watch(selectedMonthProvider);
  return repo.getForMonth(month.year, month.month);
});

// All records (for export)
final allRecordsProvider = FutureProvider<List<FinancialRecord>>((ref) async {
  final repo = ref.read(recordRepositoryProvider);
  return repo.getAll();
});

// Monthly summary
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

// Category breakdown for analysis
final categoryBreakdownProvider = Provider.autoDispose<Map<String, double>>((ref) {
  final records = ref.watch(monthRecordsProvider);
  return records.when(
    data: (list) {
      final map = <String, double>{};
      for (final r in list) {
        if (r.type == RecordType.expense) {
          final key = r.categoryName ?? 'Other';
          map[key] = (map[key] ?? 0) + r.amount;
        }
      }
      final sorted = Map.fromEntries(
        map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
      );
      return sorted;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});
