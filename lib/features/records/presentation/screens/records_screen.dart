// lib/features/records/presentation/screens/records_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/category_icons.dart';
import '../../data/record_model.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../providers/record_providers.dart';
import '../widgets/month_navigator.dart';
import 'add_record_screen.dart';

class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(monthRecordsProvider);

    return Scaffold(
      body: Column(
        children: [
          MonthNavigator(
            trailing: IconButton(
              icon:
                  const Icon(Icons.filter_list, color: AppColors.textSecondary),
              onPressed: () {},
            ),
          ),
          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (records) {
                if (records.isEmpty) {
                  return const _EmptyState();
                }
                // Group by date
                final grouped = <String, List<FinancialRecord>>{};
                for (final r in records) {
                  final key = Formatters.dayWeekday(r.date);
                  grouped.putIfAbsent(key, () => []).add(r);
                }
                return ListView.builder(
                  itemCount: grouped.length,
                  padding: const EdgeInsets.only(bottom: 100),
                  itemBuilder: (ctx, i) {
                    final dateKey = grouped.keys.elementAt(i);
                    final dayRecords = grouped[dateKey]!;
                    return _DayGroup(
                        dateKey: dateKey, records: dayRecords, ref: ref);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        onPressed: () => _openAddRecord(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openAddRecord(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddRecordScreen()),
    ).then((_) => ref.invalidate(monthRecordsProvider));
  }
}

class _DayGroup extends StatelessWidget {
  final String dateKey;
  final List<FinancialRecord> records;
  final WidgetRef ref;

  const _DayGroup(
      {required this.dateKey, required this.records, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(dateKey,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ),
        const Divider(height: 1, color: Color(0xFF3A3A3A)),
        ...records.map((r) => _RecordTile(record: r, ref: ref)),
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  final FinancialRecord record;
  final WidgetRef ref;

  const _RecordTile({required this.record, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isTransfer = record.type == RecordType.transfer;
    final isIncome = record.type == RecordType.income;
    final amountColor = isTransfer
        ? AppColors.transfer
        : isIncome
            ? AppColors.income
            : AppColors.expense;
    final amountPrefix = isTransfer
        ? ''
        : isIncome
            ? ''
            : '-';

    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.expense,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.bgCard,
            title: const Text('Delete Record',
                style: TextStyle(color: AppColors.textPrimary)),
            content: const Text('This will reverse the account balance.',
                style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppColors.textSecondary))),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete',
                      style: TextStyle(color: AppColors.expense))),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        try {
          final repo = ref.read(recordRepositoryProvider);
          await repo.delete(record.id);
          ref.invalidate(monthRecordsProvider);
          ref.invalidate(accountsProvider);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete record: $e')),
            );
          }
        }
      },
      child: GestureDetector(
        onTap: () => _editRecord(context, record, ref),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: isTransfer
              ? Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.transfer.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.swap_horiz,
                      color: AppColors.transfer, size: 22),
                )
              : Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color:
                        Color(record.categoryColor ?? 0xFFE53935).withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CategoryIcons.get(record.categoryIcon ?? 'category'),
                    color: Color(record.categoryColor ?? 0xFFE53935),
                    size: 22,
                  ),
                ),
          title: Text(
            isTransfer ? 'Transfer' : record.categoryName ?? 'Unknown',
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 15),
          ),
          subtitle: isTransfer
              ? Text(
                  '${record.accountName} → ${record.toAccountName}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                )
              : Text(
                  record.accountName ?? '',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
          trailing: Text(
            '$amountPrefix₹${record.amount.toStringAsFixed(2)}',
            style: TextStyle(
                color: amountColor, fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ),
    );
  }

  void _editRecord(
      BuildContext context, FinancialRecord record, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRecordScreen(record: record),
      ),
    ).then((_) => ref.invalidate(monthRecordsProvider));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long,
              size: 64, color: AppColors.textMuted.withAlpha(102)),
          const SizedBox(height: 16),
          const Text('No records this month',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Tap + to add your first record',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
