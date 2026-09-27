// lib/features/analysis/presentation/screens/analysis_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../records/presentation/providers/record_providers.dart';
import '../../../records/presentation/widgets/month_navigator.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});
  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  bool _showExpense = true;
  int? _touchedIdx;

  @override
  Widget build(BuildContext context) {
    final breakdown = _showExpense
        ? ref.watch(expenseBreakdownProvider)
        : ref.watch(incomeBreakdownProvider);

    final catList = breakdown.values.toList();
    final total   = catList.fold(0.0, (s, c) => s + c.amount);

    return Scaffold(
      body: Column(
        children: [
          const MonthNavigator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  // Toggle button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _OverviewToggle(
                      isExpense: _showExpense,
                      onToggle: (v) => setState(() {
                        _showExpense = v;
                        _touchedIdx  = null;
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (catList.isEmpty)
                    _EmptyChart(label: _showExpense ? 'expense' : 'income')
                  else ...[
                    // ✅ FIX: Donut chart takes full width, centered
                    //    Legend moves BELOW the chart — no more tiny squished layout
                    _DonutChart(
                      catList: catList,
                      total: total,
                      touchedIdx: _touchedIdx,
                      onTouch: (idx) => setState(() => _touchedIdx = idx),
                    ),
                    const SizedBox(height: 12),

                    // ✅ Legend below chart in a wrap
                    _ChartLegend(catList: catList),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF3A3A3A), height: 1),
                    const SizedBox(height: 8),

                    // Category rows
                    ...catList.asMap().entries.map((e) => _CategoryRow(
                      cat: e.value,
                      pct: total > 0 ? e.value.amount / total * 100 : 0,
                      isHighlighted: _touchedIdx == e.key,
                      onTap: () => setState(() =>
                          _touchedIdx = _touchedIdx == e.key ? null : e.key),
                    )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Donut Chart ───────────────────────────────────────────────────────────────

class _DonutChart extends StatelessWidget {
  final List<CatBreakdown> catList;
  final double total;
  final int? touchedIdx;
  final ValueChanged<int?> onTouch;

  const _DonutChart({
    required this.catList, required this.total,
    required this.touchedIdx, required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 70,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (event is FlTapUpEvent) {
                    final idx = response?.touchedSection?.touchedSectionIndex;
                    onTouch(idx);
                  }
                },
              ),
              sections: catList.asMap().entries.map((e) {
                final isTouched = touchedIdx == e.key;
                return PieChartSectionData(
                  color: Color(e.value.color),
                  value: e.value.amount,
                  radius: isTouched ? 60 : 48,
                  showTitle: false,
                );
              }).toList(),
            ),
          ),
          // Center label: show tapped category or total
          if (touchedIdx != null && touchedIdx! < catList.length)
            _CenterLabel(
              label: catList[touchedIdx!].name,
              amount: catList[touchedIdx!].amount,
              total: total,
              color: Color(catList[touchedIdx!].color),
            )
          else
            _CenterLabel(label: 'Total', amount: total, total: total,
                color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _CenterLabel extends StatelessWidget {
  final String label;
  final double amount, total;
  final Color color;

  const _CenterLabel({
    required this.label, required this.amount,
    required this.total, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? amount / total * 100 : 0.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text('₹${amount.toStringAsFixed(0)}',
            style: const TextStyle(color: AppColors.textPrimary,
                fontSize: 15, fontWeight: FontWeight.bold)),
        if (total != amount)
          Text('${pct.toStringAsFixed(1)}%',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}

// ─── Legend ────────────────────────────────────────────────────────────────────

class _ChartLegend extends StatelessWidget {
  final List<CatBreakdown> catList;
  const _ChartLegend({required this.catList});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: catList.map((c) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: Color(c.color),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(c.name,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        )).toList(),
      ),
    );
  }
}

// ─── Category Row ──────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final CatBreakdown cat;
  final double pct;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.cat, required this.pct,
    required this.isHighlighted, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: isHighlighted ? Color(cat.color).withAlpha(20) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Color(cat.color).withAlpha(40),
              child: Icon(CategoryIcons.get(cat.icon),
                  color: Color(cat.color), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(cat.name,
                            style: TextStyle(
                              color: isHighlighted
                                  ? Color(cat.color) : AppColors.textPrimary,
                              fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text('-₹${cat.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: AppColors.expense, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: AppColors.bgElevated,
                      color: Color(cat.color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 52,
              child: Text('${pct.toStringAsFixed(2)}%',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                  textAlign: TextAlign.right),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Misc ──────────────────────────────────────────────────────────────────────

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
          border: Border.all(color: AppColors.gold.withAlpha(120)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                color: AppColors.gold, size: 16),
            const SizedBox(width: 8),
            Text(isExpense ? 'EXPENSE OVERVIEW' : 'INCOME OVERVIEW',
                style: const TextStyle(
                    color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String label;
  const _EmptyChart({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.pie_chart_outline, size: 56,
              color: AppColors.textMuted.withAlpha(80)),
          const SizedBox(height: 12),
          Text('No $label data this month',
              style: const TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
