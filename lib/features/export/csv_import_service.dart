// lib/features/export/csv_import_service.dart
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../records/data/record_model.dart';
import '../records/data/record_repository.dart';
import '../categories/data/category_repository.dart';
import '../accounts/data/account_repository.dart';

/// Result of a CSV import operation
class ImportResult {
  final int imported;
  final int skipped;
  final String? error;
  final List<String> warnings;

  const ImportResult({
    required this.imported,
    required this.skipped,
    this.error,
    this.warnings = const [],
  });

  bool get success => error == null;
  bool get hasWarnings => warnings.isNotEmpty;
}

/// Imports records from a CSV or Excel file.
/// CSV format: "TIME","TYPE","AMOUNT","CATEGORY","ACCOUNT","NOTES"
/// TIME format: dd-MM-yyyy HH:mm
/// Excel format: Same columns as CSV, first row is header.
class CsvImportService {
  final _recordRepo = RecordRepository();
  final _catRepo = CategoryRepository();
  final _accRepo = AccountRepository();

  Future<ImportResult> importFromFile() async {
    // --- Step 1: Pick file ---
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
        allowMultiple: false,
      );
    } catch (e) {
      return ImportResult(imported: 0, skipped: 0, error: 'File picker error: $e');
    }

    if (result == null || result.files.isEmpty) {
      return const ImportResult(imported: 0, skipped: 0, error: 'No file selected');
    }

    final path = result.files.single.path;
    if (path == null) {
      return const ImportResult(imported: 0, skipped: 0, error: 'Cannot read file path');
    }

    // --- Step 2: Detect file type and read ---
    final extension = path.split('.').last.toLowerCase();
    List<List<dynamic>> rows;

    if (extension == 'csv') {
      // Read as text and parse CSV
      String content;
      try {
        content = await File(path).readAsString();
      } catch (e) {
        return ImportResult(imported: 0, skipped: 0, error: 'Cannot read CSV file: $e');
      }

      if (content.trim().isEmpty) {
        return const ImportResult(imported: 0, skipped: 0, error: 'File is empty');
      }

      try {
        rows = const CsvToListConverter(
          eol: '\n',
          shouldParseNumbers: false,
        ).convert(content);
      } catch (e) {
        return ImportResult(imported: 0, skipped: 0, error: 'CSV parse error: $e');
      }
    } else if (extension == 'xlsx') {
      // Read as Excel
      try {
        final bytes = await File(path).readAsBytes();
        final excel = Excel.decodeBytes(bytes);
        final sheet = excel.tables[excel.tables.keys.first]; // Get first sheet
        if (sheet == null) {
          return const ImportResult(imported: 0, skipped: 0, error: 'Excel file has no sheets');
        }
        rows = sheet.rows.map((row) => row.map((cell) => cell?.value).toList()).toList();
      } catch (e) {
        return ImportResult(imported: 0, skipped: 0, error: 'Excel parse error: $e');
      }
    } else {
      return ImportResult(imported: 0, skipped: 0, error: 'Unsupported file type: $extension');
    }

    if (rows.length < 2) {
      return const ImportResult(imported: 0, skipped: 0, error: 'No data rows found (only header)');
    }

    // Limit to prevent memory issues
    const maxRows = 10000;
    if (rows.length > maxRows + 1) { // +1 for header
      return ImportResult(imported: 0, skipped: 0, error: 'Too many rows (max $maxRows allowed)');
    }

    // Validate header row
    final header = rows[0].map((h) => h.toString().replaceAll('"', '').trim().toUpperCase()).toList();
    final expectedHeaders = ['TIME', 'TYPE', 'AMOUNT', 'CATEGORY', 'ACCOUNT', 'NOTES'];
    final missingHeaders = expectedHeaders
        .where((h) => !header.contains(h))
        .where((h) => h != 'NOTES') // notes is optional
        .toList();

    if (missingHeaders.isNotEmpty) {
      return ImportResult(
        imported: 0,
        skipped: 0,
        error: 'Missing columns: ${missingHeaders.join(", ")}. '
            'Expected: TIME, TYPE, AMOUNT, CATEGORY, ACCOUNT, NOTES',
      );
    }

    // Build column index map from header
    final colTime     = header.indexOf('TIME');
    final colType     = header.indexOf('TYPE');
    final colAmount   = header.indexOf('AMOUNT');
    final colCategory = header.indexOf('CATEGORY');
    final colAccount  = header.indexOf('ACCOUNT');
    final colNotes    = header.indexOf('NOTES'); // may be -1

    // --- Step 4: Load reference data ---
    final allAccounts  = await _accRepo.getAll();
    final allCats      = await _catRepo.getAll();

    // Build lookup maps (lowercase name → id)
    final accountMap  = {for (final a in allAccounts) a.name.toLowerCase(): a};
    final categoryMap = {for (final c in allCats) c.name.toLowerCase(): c};

    // --- Step 5: Process rows ---
    int imported = 0;
    int skipped  = 0;
    final warnings = <String>[];

    final dataRows = rows.skip(1).toList();

    for (int i = 0; i < dataRows.length; i++) {
      final row     = dataRows[i];
      final rowNum  = i + 2; // 1-indexed, accounting for header

      try {
        // Safely get cell value
        String cell(int idx) {
          if (idx < 0 || idx >= row.length) return '';
          return row[idx].toString().replaceAll('"', '').trim();
        }

        final timeStr  = cell(colTime);
        final typeStr  = cell(colType).toLowerCase();
        final amtStr   = cell(colAmount).replaceAll(',', '').replaceAll('₹', '');
        final catName  = cell(colCategory);
        final accName  = cell(colAccount);
        final notes    = colNotes >= 0 ? cell(colNotes) : '';

        // Skip completely blank rows
        if (timeStr.isEmpty && amtStr.isEmpty && accName.isEmpty) continue;

        // --- Parse date: "dd-MM-yyyy HH:mm" ---
        final date = _parseDate(timeStr);
        if (date == null) {
          warnings.add('Row $rowNum: Cannot parse date "$timeStr" — skipped');
          skipped++;
          continue;
        }

        // --- Parse amount ---
        final amount = double.tryParse(amtStr);
        if (amount == null || amount <= 0) {
          warnings.add('Row $rowNum: Invalid amount "$amtStr" — skipped');
          skipped++;
          continue;
        }

        // --- Parse type ---
        RecordType type;
        switch (typeStr) {
          case 'income':
            type = RecordType.income;
          case 'transfer':
            type = RecordType.transfer;
          case 'expense':
          default:
            type = RecordType.expense;
        }

        // --- Resolve account ---
        final account = accountMap[accName.toLowerCase()];
        if (account == null) {
          warnings.add('Row $rowNum: Account "$accName" not found — skipped');
          skipped++;
          continue;
        }

        // --- Resolve category (nullable for transfers) ---
        final category = categoryMap[catName.toLowerCase()];
        if (category == null && type != RecordType.transfer && catName.isNotEmpty) {
          warnings.add('Row $rowNum: Category "$catName" not found — will import without category');
        }

        // --- Create record ---
        await _recordRepo.create(
          type: type,
          amount: amount,
          accountId: account.id,
          categoryId: category?.id,
          notes: notes.isEmpty ? null : notes,
          date: date,
        );
        imported++;
      } catch (e) {
        warnings.add('Row $rowNum: Unexpected error — $e');
        skipped++;
      }
    }

    return ImportResult(
      imported: imported,
      skipped: skipped,
      warnings: warnings,
    );
  }

  /// Parse date string in "dd-MM-yyyy HH:mm" format.
  /// Falls back to ISO 8601 if that fails.
  DateTime? _parseDate(String s) {
    if (s.isEmpty) return null;

    // Try "dd-MM-yyyy HH:mm"
    try {
      final spaceIdx = s.indexOf(' ');
      final datePart = spaceIdx > 0 ? s.substring(0, spaceIdx) : s;
      final timePart = spaceIdx > 0 ? s.substring(spaceIdx + 1) : '00:00';

      final d = datePart.split('-');
      final t = timePart.split(':');

      if (d.length == 3) {
        return DateTime(
          int.parse(d[2]), // year
          int.parse(d[1]), // month
          int.parse(d[0]), // day
          t.isNotEmpty ? int.tryParse(t[0]) ?? 0 : 0,
          t.length > 1 ? int.tryParse(t[1]) ?? 0 : 0,
        );
      }
    } catch (_) {}

    // Try "yyyy-MM-dd HH:mm:ss" (ISO-ish)
    try {
      return DateTime.parse(s);
    } catch (_) {}

    return null;
  }
}
