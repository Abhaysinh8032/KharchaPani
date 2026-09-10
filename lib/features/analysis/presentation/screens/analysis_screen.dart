// lib/features/analysis/presentation/screens/analysis_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../records/presentation/providers/record_providers.dart';
import '../../../records/presentation/widgets/month_navigator.dart';
import '../../../records/data/record_model.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  bool _showExpense = true;

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(monthRecordsProvider);

    return Scaffold(
      body: Column(
        children: [
          MonthNavigator(),
          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (records) {
                final filtered = records
                    .where((r) => _showExpense
                        ? r.type == RecordType.expense
                        : r.type == RecordType.income)
                    .toList();

                // Group by category
                final catMap = <String, _CatData>{};
                for (final r in filtered) {
                  final key = r.categoryName ?? 'Other';
                  catMap.putIfAbsent(
                    key,
                    () => _CatData(
                      name: key,
                      icon: r.categoryIcon ?? 'category',
                      color: Color(r.categoryColor ?? 0xFFE53935),
                      amount: 0,
                    ),
                  );
                  catMap[key] = catMap[key]!
                      .copyWith(amount: catMap[key]!.amount + r.amount);
                }

                final catList = catMap.values.toList()
                  ..sort((a, b) => b.amount.compareTo(a.amount));

                // Limit to top 20 categories for performance
                final limitedCatList = catList.take(20).toList();

                final total = catList.fold(0.0, (s, c) => s + c.amount);

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Toggle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _OverviewToggle(
                          isExpense: _showExpense,
                          onToggle: (v) => setState(() => _showExpense = v),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Donut chart
                      if (limitedCatList.isNotEmpty)
                        SizedBox(
                          height: 220,
                          child: Row(
                            children: [
                              Expanded(
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 60,
                                    sections: limitedCatList.asMap().entries.map((e) {
                                      return PieChartSectionData(
                                        color: e.value.color,
                                        value: e.value.amount,
                                        radius: 45,
                                        showTitle: false,
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              // Legend
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: limitedCatList.take(8).map((c) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: c.color,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(c.name,
                                                style: const TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize: 11),
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox(
                          height: 160,
                          child: Center(
                            child: Text('No data for this period',
                                style: TextStyle(color: AppColors.textMuted)),
                          ),
                        ),

                      const SizedBox(height: 8),
                      const Divider(color: Color(0xFF3A3A3A)),

                      // Category breakdown
                      ...limitedCatList.map((c) {
                        final pct = total > 0 ? (c.amount / total * 100) : 0.0;
                        return _CategoryRow(cat: c, pct: pct, total: total);
                      }),
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CatData {
  final String name;
  final String icon;
  final Color color;
  final double amount;

  const _CatData(
      {required this.name,
      required this.icon,
      required this.color,
      required this.amount});

  _CatData copyWith({double? amount}) => _CatData(
      name: name, icon: icon, color: color, amount: amount ?? this.amount);
}

class _OverviewToggle extends StatelessWidget {
  final bool isExpense;
  final ValueChanged<bool> onToggle;

  const _OverviewToggle({required this.isExpense, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!isExpense),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gold.withAlpha(128)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isExpense ? Icons.arrow_upward : Icons.arrow_downward,
              color: AppColors.gold,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              isExpense ? 'EXPENSE OVERVIEW' : 'INCOME OVERVIEW',
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final _CatData cat;
  final double pct;
  final double total;

  const _CategoryRow(
      {required this.cat, required this.pct, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cat.color.withAlpha(51),
            child:
                Icon(CategoryIcons.get(cat.icon), color: cat.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(cat.name,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500)),
                    Text(
                      '-₹${cat.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppColors.expense,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: pct / 100,
                  backgroundColor: AppColors.bgElevated,
                  color: cat.color,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 48,
            child: Text(
              '${pct.toStringAsFixed(2)}%',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
