// lib/features/records/presentation/widgets/month_navigator.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/record_providers.dart';

class MonthNavigator extends ConsumerWidget {
  final Widget? trailing;
  const MonthNavigator({super.key, this.trailing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final summary = ref.watch(monthlySummaryProvider);

    return Column(
      children: [
        // Month navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => ref.read(selectedMonthProvider.notifier).state =
                    DateTime(month.year, month.month - 1),
                icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
              ),
              Expanded(
                child: Text(
                  Formatters.monthYear(month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => ref.read(selectedMonthProvider.notifier).state =
                    DateTime(month.year, month.month + 1),
                icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        // Summary bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              _SummaryItem('EXPENSE', summary.expense, AppColors.expense, isNegative: true),
              _SummaryItem('INCOME', summary.income, AppColors.income),
              _SummaryItem(
                'TOTAL',
                summary.total,
                summary.total >= 0 ? AppColors.income : AppColors.expense,
                isNegative: summary.total < 0,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isNegative;

  const _SummaryItem(this.label, this.amount, this.color, {this.isNegative = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            '${isNegative && amount != 0 ? "-" : ""}₹${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
