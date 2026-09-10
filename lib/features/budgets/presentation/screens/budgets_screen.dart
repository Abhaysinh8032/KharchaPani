// lib/features/budgets/presentation/screens/budgets_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../records/presentation/providers/record_providers.dart';
import '../../../categories/data/category_model.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../data/budget_model.dart';
import '../providers/budget_providers.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final totals = ref.watch(budgetTotalsProvider);
    final month = ref.watch(selectedMonthProvider);

    return Scaffold(
      body: Column(
        children: [
          // Month nav (no summary bar needed here)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => ref
                      .read(selectedMonthProvider.notifier)
                      .state = DateTime(month.year, month.month - 1),
                  icon: const Icon(Icons.chevron_left,
                      color: AppColors.textSecondary),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_monthName(month.month)}, ${month.year}',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('TOTAL BUDGET  ',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                          Text('₹${totals.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          const Text('   |   ',
                              style: TextStyle(color: AppColors.textMuted)),
                          Text('TOTAL SPENT  ',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                          Text('₹${totals.spent.toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: totals.spent > totals.total
                                      ? AppColors.expense
                                      : AppColors.expense,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => ref
                      .read(selectedMonthProvider.notifier)
                      .state = DateTime(month.year, month.month + 1),
                  icon: const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF3A3A3A)),

          Expanded(
            child: budgetsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (budgets) {
                return _BudgetBody(
                  budgets: budgets,
                  month: month,
                  ref: ref,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        onPressed: () => _showAddBudget(context, ref, month),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddBudget(
      BuildContext context, WidgetRef ref, DateTime month) async {
    // Get un-budgeted categories
    final allCats = await ref.read(expenseCategoriesProvider.future);
    final budgetedIds = await ref
        .read(budgetRepositoryProvider)
        .getBudgetedCategoryIds(month.year, month.month);
    final available =
        allCats.where((c) => !budgetedIds.contains(c.id)).toList();

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddBudgetSheet(
        categories: available,
        onSave: (catId, amount) async {
          await ref.read(budgetRepositoryProvider).create(
                categoryId: catId,
                amount: amount,
                year: month.year,
                month: month.month,
              );
          ref.invalidate(budgetsProvider);
        },
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return names[m - 1];
  }
}

class _BudgetBody extends StatelessWidget {
  final List<Budget> budgets;
  final DateTime month;
  final WidgetRef ref;

  const _BudgetBody(
      {required this.budgets, required this.month, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'Budgeted categories: ${_monthName(month.month)}, ${month.year}',
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Currently, no budget is applied for this month. Set budget-limits for this month, or copy your budget-limits from past months.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const Divider(height: 32, color: Color(0xFF3A3A3A)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: budgets.length,
      itemBuilder: (_, i) => _BudgetTile(budget: budgets[i], ref: ref),
    );
  }

  String _monthName(int m) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return names[m - 1];
  }
}

class _BudgetTile extends StatelessWidget {
  final Budget budget;
  final WidgetRef ref;

  const _BudgetTile({required this.budget, required this.ref});

  @override
  Widget build(BuildContext context) {
    final pct = budget.spentPercent;
    final isOver = (budget.spent ?? 0) > budget.amount;
    final barColor = isOver ? AppColors.expense : AppColors.gold;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                Color(budget.categoryColor ?? 0xFFE53935).withAlpha(51),
            child: Icon(
              CategoryIcons.get(budget.categoryIcon ?? 'category'),
              color: Color(budget.categoryColor ?? 0xFFE53935),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(budget.categoryName ?? '',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500)),
                    Text(
                      '₹${(budget.spent ?? 0).toStringAsFixed(0)} / ₹${budget.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                          color: isOver
                              ? AppColors.expense
                              : AppColors.textSecondary,
                          fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: pct,
                  backgroundColor: AppColors.bgElevated,
                  color: barColor,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 2),
                Text(
                  isOver
                      ? 'Over by ₹${((budget.spent ?? 0) - budget.amount).toStringAsFixed(2)}'
                      : '₹${budget.remaining.toStringAsFixed(2)} remaining',
                  style: TextStyle(
                      color: isOver ? AppColors.expense : AppColors.textMuted,
                      fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddBudgetSheet extends StatefulWidget {
  final List<Category> categories;
  final void Function(String catId, double amount) onSave;

  const _AddBudgetSheet({required this.categories, required this.onSave});

  @override
  State<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<_AddBudgetSheet> {
  Category? _selected;
  final _amountCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Set Budget',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          DropdownButtonFormField<Category>(
            initialValue: _selected,
            dropdownColor: AppColors.bgCard,
            decoration: const InputDecoration(labelText: 'Category'),
            items: widget.categories
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.name,
                          style: const TextStyle(color: AppColors.textPrimary)),
                    ))
                .toList(),
            onChanged: (c) => setState(() => _selected = c),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Budget Amount (₹)',
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final cat = _selected;
                final amt = double.tryParse(_amountCtrl.text);
                if (cat == null || amt == null || amt <= 0) return;
                Navigator.pop(context);
                widget.onSave(cat.id, amt);
              },
              child: const Text('SAVE BUDGET'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
