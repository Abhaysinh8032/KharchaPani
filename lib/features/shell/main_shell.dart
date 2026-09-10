// lib/features/shell/main_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../export/excel_export_service.dart';
import '../export/csv_import_service.dart';
import '../records/data/record_repository.dart';
import '../records/presentation/providers/record_providers.dart';
import '../records/presentation/screens/records_screen.dart';
import '../accounts/presentation/providers/account_providers.dart';
import '../analysis/presentation/screens/analysis_screen.dart';
import '../budgets/presentation/screens/budgets_screen.dart';
import '../accounts/presentation/screens/accounts_screen.dart';
import '../categories/presentation/screens/categories_screen.dart';

final _shellIndexProvider = StateProvider<int>((ref) => 0);

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
    'Records',
    'Analysis',
    'Budgets',
    'Accounts',
    'Categories'
  ];

  static const _icons = [
    Icons.receipt_long,
    Icons.pie_chart_outline,
    Icons.calculate_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.local_offer_outlined,
  ];

  static const _activeIcons = [
    Icons.receipt_long,
    Icons.pie_chart,
    Icons.calculate,
    Icons.account_balance_wallet,
    Icons.local_offer,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = ref.watch(_shellIndexProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.gold),
          onPressed: () {},
        ),
        title: const Text(
          'KharchaPani',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.gold),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            color: AppColors.bgCard,
            icon: const Icon(Icons.more_vert, color: AppColors.gold),
            onSelected: (val) => _handleMenuAction(val, context, ref),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'export_excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: AppColors.income, size: 20),
                    SizedBox(width: 10),
                    Text('Export to Excel',
                        style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export_csv',
                child: Row(
                  children: [
                    Icon(Icons.download, color: AppColors.transfer, size: 20),
                    SizedBox(width: 10),
                    Text('Export to CSV',
                        style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'import_csv',
                child: Row(
                  children: [
                    Icon(Icons.upload_file, color: AppColors.gold, size: 20),
                    SizedBox(width: 10),
                    Text('Import from CSV/Excel',
                        style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: idx,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) => ref.read(_shellIndexProvider.notifier).state = i,
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

  Future<void> _handleMenuAction(
      String val, BuildContext context, WidgetRef ref) async {
    switch (val) {
      case 'export_excel':
        await _exportExcel(context, ref);
      case 'export_csv':
        await _exportCsv(context, ref);
      case 'import_csv':
        await _importFile(context, ref);
    }
  }

  Future<void> _exportExcel(BuildContext context, WidgetRef ref) async {
    final records = await RecordRepository().getAll();
    if (records.isEmpty) {
      if (context.mounted) {
        _showSnack(context, 'No records to export', isError: true);
      }
      return;
    }
    try {
      await ExcelExportService().exportRecords(records);
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, 'Export failed: $e', isError: true);
      }
    }
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final records = await RecordRepository().getAll();
    if (records.isEmpty) {
      if (context.mounted) {
        _showSnack(context, 'No records to export', isError: true);
      }
      return;
    }
    try {
      await ExcelExportService().exportAsCsv(records);
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, 'CSV export failed: $e', isError: true);
      }
    }
  }

  Future<void> _importFile(BuildContext context, WidgetRef ref) async {
    // Show loading indicator
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          backgroundColor: AppColors.bgCard,
          content: Row(
            children: [
              CircularProgressIndicator(color: AppColors.gold),
              SizedBox(width: 16),
              Text('Importing...',
                  style: TextStyle(color: AppColors.textPrimary)),
            ],
          ),
        ),
      );
    }

    ImportResult result;
    try {
      result = await CsvImportService().importFromFile();
    } catch (e) {
      result =
          ImportResult(imported: 0, skipped: 0, error: 'Import failed: $e');
    }

    // Dismiss loading dialog
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

    if (!context.mounted) return;

    // Refresh data
    if (result.imported > 0) {
      ref.invalidate(monthRecordsProvider);
      ref.invalidate(accountsProvider);
      ref.invalidate(allRecordsProvider);
    }

    // Show result
    if (result.error != null) {
      _showSnack(context, result.error!, isError: true);
    } else if (result.hasWarnings) {
      _showImportResultDialog(context, result);
    } else {
      _showSnack(
        context,
        'Imported ${result.imported} records successfully'
        '${result.skipped > 0 ? ", skipped ${result.skipped}" : ""}',
      );
    }
  }

  void _showImportResultDialog(BuildContext context, ImportResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(
          result.imported > 0 ? 'Import Complete' : 'Import Issues',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Summary row
              Row(
                children: [
                  _StatChip(
                    label: 'Imported',
                    value: '${result.imported}',
                    color: AppColors.income,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Skipped',
                    value: '${result.skipped}',
                    color: AppColors.expense,
                  ),
                ],
              ),
              if (result.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Warnings:',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 4),
                ...result.warnings.take(10).map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $w',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    )),
                if (result.warnings.length > 10)
                  Text('... and ${result.warnings.length - 10} more',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.expense : AppColors.bgElevated,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
