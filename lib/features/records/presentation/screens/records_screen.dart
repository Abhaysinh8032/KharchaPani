// lib/features/records/presentation/screens/records_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/formatters.dart';
import '../../../accounts/presentation/providers/account_providers.dart';
import '../../data/record_model.dart';
import '../../data/record_repository.dart';
import '../providers/record_providers.dart';
import '../widgets/month_navigator.dart';
import 'package:kharchaapani/features/records/presentation/screens/add_record_screen.dart'
    hide Formatters;

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
                if (records.isEmpty) return const _EmptyState();
                final grouped = <String, List<FinancialRecord>>{};
                for (final r in records) {
                  grouped
                      .putIfAbsent(Formatters.dayWeekday(r.date), () => [])
                      .add(r);
                }
                return ListView.builder(
                  itemCount: grouped.length,
                  padding: const EdgeInsets.only(bottom: 100),
                  itemBuilder: (_, i) {
                    final key = grouped.keys.elementAt(i);
                    return _DayGroup(
                        dateKey: key, records: grouped[key]!, ref: ref);
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
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddRecordScreen()));
          ref.invalidate(monthRecordsProvider);
          ref.invalidate(accountsProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DayGroup extends StatelessWidget {
  final String dateKey;
  final List<FinancialRecord> records;
  final WidgetRef ref;
  const _DayGroup(
      {required this.dateKey, required this.records, required this.ref});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
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

class _RecordTile extends StatelessWidget {
  final FinancialRecord record;
  final WidgetRef ref;
  const _RecordTile({required this.record, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isTransfer = record.type == RecordType.transfer;
    final isIncome = record.type == RecordType.income;
    final amtColor = isTransfer
        ? AppColors.transfer
        : isIncome
            ? AppColors.income
            : AppColors.expense;
    final prefix = isTransfer
        ? ''
        : isIncome
            ? '+'
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
      confirmDismiss: (_) => showDialog<bool>(
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
      ),
      onDismissed: (_) async {
        await ref.read(recordRepositoryProvider).delete(record.id);
        ref.invalidate(monthRecordsProvider);
        ref.invalidate(accountsProvider);
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: isTransfer
            ? _circle(Icons.swap_horiz, AppColors.transfer)
            : _circle(CategoryIcons.get(record.categoryIcon ?? ''),
                Color(record.categoryColor ?? 0xFFE53935)),
        title: Text(
          isTransfer ? 'Transfer' : (record.categoryName ?? 'Unknown'),
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 15),
        ),
        subtitle: isTransfer
            ? Text('${record.accountName} → ${record.toAccountName}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12))
            : Text(record.accountName ?? '',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$prefix₹${record.amount.toStringAsFixed(2)}',
                style: TextStyle(
                    color: amtColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            if (record.notes != null && record.notes!.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(record.notes!,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _circle(IconData icon, Color color) => Container(
        width: 44,
        height: 44,
        decoration:
            BoxDecoration(color: color.withAlpha(40), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 22),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long,
                size: 64, color: AppColors.textMuted.withAlpha(80)),
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
