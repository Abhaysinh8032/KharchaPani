// lib/features/shell/main_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../accounts/presentation/providers/account_providers.dart';
import '../export/export_service.dart';
import '../export/import_service.dart';
import '../records/data/record_repository.dart';
import '../records/presentation/providers/record_providers.dart';
import '../records/presentation/screens/records_screen.dart';
import '../analysis/presentation/screens/analysis_screen.dart';
import '../budgets/presentation/screens/budgets_screen.dart';
import '../accounts/presentation/screens/accounts_screen.dart';
import '../categories/presentation/screens/categories_screen.dart';

final _tabProvider = StateProvider<int>((_) => 0);

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _screens = [
    RecordsScreen(),
    AnalysisScreen(),
    BudgetsScreen(),
    AccountsScreen(),
    CategoriesScreen(),
  ];

  static const _labels = [
    'Records', 'Analysis', 'Budgets', 'Accounts', 'Categories'
  ];
  static const _icons = [
    Icons.receipt_long_outlined, Icons.pie_chart_outline,
    Icons.calculate_outlined, Icons.account_balance_wallet_outlined,
    Icons.local_offer_outlined,
  ];
  static const _activeIcons = [
    Icons.receipt_long, Icons.pie_chart,
    Icons.calculate, Icons.account_balance_wallet,
    Icons.local_offer,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_tabProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.gold),
          onPressed: () {},
        ),
        title: RichText(
          text: const TextSpan(children: [
            TextSpan(
              text: 'KharchaPani ',
              style: TextStyle(
                  color: AppColors.gold, fontSize: 20,
                  fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            ),
          ]),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.search, color: AppColors.gold),
              onPressed: () {}),
          PopupMenuButton<String>(
            color: AppColors.bgCard,
            icon: const Icon(Icons.more_vert, color: AppColors.gold),
            onSelected: (v) => _onMenu(v, context, ref),
            itemBuilder: (_) => [
              // ── Export ──────────────────────────────────────────────────
              const PopupMenuItem(
                value: 'export_excel',
                child: _MenuRow(Icons.table_chart,
                    'Export to Excel (.xlsx)', AppColors.income),
              ),
              const PopupMenuItem(
                value: 'export_csv',
                child: _MenuRow(Icons.description_outlined,
                    'Export to CSV (.csv)', AppColors.transfer),
              ),
              const PopupMenuDivider(),
              // ── Import ──────────────────────────────────────────────────
              const PopupMenuItem(
                value: 'import',
                child: _MenuRow(Icons.upload_file,
                    'Import CSV / Excel', AppColors.gold),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: tab, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tab,
        onTap: (i) => ref.read(_tabProvider.notifier).state = i,
        items: List.generate(
          _labels.length,
          (i) => BottomNavigationBarItem(
            icon: Icon(_icons[i]),
            activeIcon: Icon(_activeIcons[i]),
            label: _labels[i],
          ),
        ),
      ),
    );
  }

  // ─── Menu actions ──────────────────────────────────────────────────────────

  Future<void> _onMenu(String val, BuildContext ctx, WidgetRef ref) async {
    switch (val) {
      case 'export_excel': await _exportExcel(ctx);
      case 'export_csv':   await _exportCsv(ctx);
      case 'import':       await _import(ctx, ref);
    }
  }

  Future<void> _exportExcel(BuildContext ctx) async {
    final records = await RecordRepository().getAll();
    if (records.isEmpty) {
      _snack(ctx, 'No records to export', error: true); return;
    }
    try {
      await ExportService().exportExcel(records);
    } catch (e) {
      if (ctx.mounted) _snack(ctx, 'Export failed: $e', error: true);
    }
  }

  Future<void> _exportCsv(BuildContext ctx) async {
    final records = await RecordRepository().getAll();
    if (records.isEmpty) {
      _snack(ctx, 'No records to export', error: true); return;
    }
    try {
      await ExportService().exportCsv(records);
    } catch (e) {
      if (ctx.mounted) _snack(ctx, 'CSV export failed: $e', error: true);
    }
  }

  Future<void> _import(BuildContext ctx, WidgetRef ref) async {
    // Show loading dialog
    if (ctx.mounted) {
      showDialog(
        context: ctx,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          backgroundColor: AppColors.bgCard,
          content: Row(children: [
            CircularProgressIndicator(color: AppColors.gold),
            SizedBox(width: 16),
            Text('Importing…',
                style: TextStyle(color: AppColors.textPrimary)),
          ]),
        ),
      );
    }

    ImportResult result;
    try {
      result = await ImportService().importFile();
    } catch (e) {
      result = ImportResult(
          imported: 0, skipped: 0, error: 'Import failed: $e');
    }

    // Dismiss loader
    if (ctx.mounted) Navigator.of(ctx, rootNavigator: true).pop();
    if (!ctx.mounted) return;

    // Refresh state if anything was imported
    if (result.imported > 0) {
      ref.invalidate(monthRecordsProvider);
      ref.invalidate(allRecordsProvider);
      ref.invalidate(accountsProvider);
    }

    // Show result
    if (result.error != null) {
      _snack(ctx, result.error!, error: true);
    } else if (result.hasWarnings || result.skipped > 0) {
      _showResultDialog(ctx, result);
    } else {
      _snack(ctx,
          'Imported ${result.imported} records successfully ✓');
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _snack(BuildContext ctx, String msg, {bool error = false}) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.expense : AppColors.bgElevated,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ));
  }

  void _showResultDialog(BuildContext ctx, ImportResult result) {
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(
          result.imported > 0 ? 'Import Complete' : 'Import Issues',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats row
              Row(children: [
                _StatChip('Imported', '${result.imported}', AppColors.income),
                const SizedBox(width: 10),
                _StatChip('Skipped', '${result.skipped}', AppColors.expense),
              ]),
              if (result.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Warnings:',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView(
                    shrinkWrap: true,
                    children: result.warnings.take(15).map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $w',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    )).toList(),
                  ),
                ),
                if (result.warnings.length > 15)
                  Text('…and ${result.warnings.length - 15} more',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('OK',
                  style: TextStyle(color: AppColors.gold))),
        ],
      ),
    );
  }
}

// ─── Small helpers ─────────────────────────────────────────────────────────────

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MenuRow(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: color, size: 20),
    const SizedBox(width: 10),
    Text(label, style: const TextStyle(color: AppColors.textPrimary)),
  ]);
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: color.withAlpha(30),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withAlpha(80)),
    ),
    child: Column(children: [
      Text(value,
          style: TextStyle(
              color: color, fontSize: 22, fontWeight: FontWeight.bold)),
      Text(label,
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 11)),
    ]),
  );
}
