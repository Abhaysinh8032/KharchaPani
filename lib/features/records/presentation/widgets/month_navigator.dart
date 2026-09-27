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
    final month   = ref.watch(selectedMonthProvider);
    final summary = ref.watch(monthlySummaryProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
                onPressed: () => ref.read(selectedMonthProvider.notifier).state =
                    DateTime(month.year, month.month - 1),
              ),
              Expanded(
                child: Text(Formatters.monthYear(month),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                onPressed: () => ref.read(selectedMonthProvider.notifier).state =
                    DateTime(month.year, month.month + 1),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              _Stat('EXPENSE', summary.expense, AppColors.expense, neg: true),
              _Stat('INCOME', summary.income, AppColors.income),
              _Stat('TOTAL', summary.total,
                  summary.total >= 0 ? AppColors.income : AppColors.expense,
                  neg: summary.total < 0),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool neg;
  const _Stat(this.label, this.amount, this.color, {this.neg = false});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          '${neg && amount != 0 ? "-" : ""}₹${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}
