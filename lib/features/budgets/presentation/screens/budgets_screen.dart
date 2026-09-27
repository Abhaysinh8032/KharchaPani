// lib/features/budgets/presentation/screens/budgets_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/formatters.dart';
import '../../../categories/data/category_model.dart';
import '../../../categories/data/category_repository.dart';
import '../../../records/presentation/providers/record_providers.dart';
import '../../data/budget_model.dart';
import '../providers/budget_providers.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final budgetsAsync = ref.watch(budgetsProvider);
    final totals = ref.watch(budgetTotalsProvider);

    return Scaffold(
      body: Column(
        children: [
          // ── Month header + totals ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: AppColors.textSecondary),
                  onPressed: () => ref
                      .read(selectedMonthProvider.notifier)
                      .state = DateTime(month.year, month.month - 1),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${Formatters.monthName(month.month)}, ${month.year}',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _MiniStat(
                              'TOTAL BUDGET',
                              '₹${totals.total.toStringAsFixed(0)}',
                              AppColors.textPrimary),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('|',
                                style: TextStyle(color: AppColors.textMuted)),
                          ),
                          _MiniStat(
                              'TOTAL SPENT',
                              '₹${totals.spent.toStringAsFixed(0)}',
                              AppColors.expense),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
                  onPressed: () => ref
                      .read(selectedMonthProvider.notifier)
                      .state = DateTime(month.year, month.month + 1),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF3A3A3A)),

          // ── Budget list ───────────────────────────────────────────────
          Expanded(
            child: budgetsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold)),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: AppColors.expense))),
              data: (budgets) {
                if (budgets.isEmpty) {
                  return _EmptyBudget(month: month);
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: budgets.length,
                  itemBuilder: (_, i) =>
                      _BudgetTile(budget: budgets[i], ref: ref),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        onPressed: () => _showSetBudget(context, ref, month),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showSetBudget(
      BuildContext context, WidgetRef ref, DateTime month) async {
    // Only show un-budgeted categories
    final allCats = await CategoryRepository().getByType(CategoryType.expense);
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
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SetBudgetSheet(
        categories: available,
        onSave: (catId, amount) async {
          await ref.read(budgetRepositoryProvider).create(
              categoryId: catId,
              amount: amount,
              year: month.year,
              month: month.month);
          ref.invalidate(budgetsProvider);
        },
      ),
    );
  }
}

// ─── Budget tile ───────────────────────────────────────────────────────────────

class _BudgetTile extends StatelessWidget {
  final Budget budget;
  final WidgetRef ref;
  const _BudgetTile({required this.budget, required this.ref});

  @override
  Widget build(BuildContext context) {
    final pct = budget.spentPercent;
    final barColor = budget.isOver ? AppColors.expense : AppColors.gold;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                Color(budget.categoryColor ?? 0xFFE53935).withAlpha(40),
            child: Icon(
              CategoryIcons.get(budget.categoryIcon ?? ''),
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
                      '₹${(budget.spent ?? 0).toStringAsFixed(0)}'
                      ' / ₹${budget.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                          color: budget.isOver
                              ? AppColors.expense
                              : AppColors.textSecondary,
                          fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppColors.bgElevated,
                    color: barColor,
                    minHeight: 7,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  budget.isOver
                      ? 'Over by ₹${((budget.spent ?? 0) - budget.amount).toStringAsFixed(2)}'
                      : '₹${budget.remaining.toStringAsFixed(2)} remaining',
                  style: TextStyle(
                      color: budget.isOver
                          ? AppColors.expense
                          : AppColors.textMuted,
                      fontSize: 11),
                ),
              ],
            ),
          ),
          // Delete budget
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.textMuted, size: 18),
            onPressed: () async {
              await ref.read(budgetRepositoryProvider).delete(budget.id);
              ref.invalidate(budgetsProvider);
            },
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────────

class _EmptyBudget extends StatelessWidget {
  final DateTime month;
  const _EmptyBudget({required this.month});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budgeted categories: '
              '${Formatters.monthName(month.month)}, ${month.year}',
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'No budget is set for this month. '
              'Tap + to set budget limits per category.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
}

// ─── Set budget sheet ──────────────────────────────────────────────────────────

class _SetBudgetSheet extends StatefulWidget {
  final List<Category> categories;
  final void Function(String catId, double amount) onSave;
  const _SetBudgetSheet({required this.categories, required this.onSave});

  @override
  State<_SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends State<_SetBudgetSheet> {
  Category? _selected;
  final _amountCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Set Budget',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<Category>(
              value: _selected,
              dropdownColor: AppColors.bgCard,
              decoration: const InputDecoration(labelText: 'Category'),
              items: widget.categories
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.name,
                          style:
                              const TextStyle(color: AppColors.textPrimary))))
                  .toList(),
              onChanged: (c) => setState(() => _selected = c),
              validator: (v) => v == null ? 'Select a category' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                  labelText: 'Budget Amount', prefixText: '₹ '),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.pop(context);
                  widget.onSave(_selected!.id, double.parse(_amountCtrl.text));
                },
                child: const Text('SAVE BUDGET'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Mini stat label ───────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      );
}
