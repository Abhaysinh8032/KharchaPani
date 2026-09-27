// lib/features/export/import_service.dart
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../records/data/record_model.dart';
import '../records/data/record_repository.dart';
import '../categories/data/category_repository.dart';
import '../accounts/data/account_repository.dart';

class ImportResult {
  final int imported, skipped;
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

/// Imports from either CSV or XLSX produced by KharchaPani export.
///
/// Excel format (exact columns from uploaded file):
///   TIME                    | TYPE           | AMOUNT | CATEGORY | ACCOUNT   | NOTES
///   2026-09-01 23:41:00     | (-) Expense    | 30     | Food     | SBI       | Biscuit...
///   2026-09-05 23:45:00     | (*) Transfer   | 5000   | -        | hdfc->SBI | ...
///
/// CSV format:
///   "TIME","TYPE","AMOUNT","CATEGORY","ACCOUNT","NOTES"
class ImportService {
  final _recordRepo = RecordRepository();
  final _catRepo = CategoryRepository();
  final _accRepo = AccountRepository();

  Future<ImportResult> importFile() async {
    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
        allowMultiple: false,
      );
    } catch (e) {
      return ImportResult(
          imported: 0, skipped: 0, error: 'File picker error: $e');
    }

    if (picked == null || picked.files.isEmpty) {
      return const ImportResult(
          imported: 0, skipped: 0, error: 'No file selected');
    }

    final file = picked.files.single;
    final path = file.path;
    if (path == null) {
      return const ImportResult(
          imported: 0, skipped: 0, error: 'Cannot access file path');
    }

    final ext = (file.extension ?? '').toLowerCase();
    if (ext == 'xlsx') return _importExcel(path);
    if (ext == 'csv') return _importCsv(path);
    return const ImportResult(
        imported: 0, skipped: 0, error: 'Unsupported file type');
  }

  // ─── Excel ────────────────────────────────────────────────────────────────

  Future<ImportResult> _importExcel(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.sheets.values.first;
      final rows = sheet.rows;
      if (rows.length < 2) {
        return const ImportResult(
            imported: 0, skipped: 0, error: 'No data rows found');
      }

      // Build header index map from row 0
      final header = <String, int>{};
      for (var i = 0; i < rows[0].length; i++) {
        final h = rows[0][i]?.value?.toString().trim().toUpperCase() ?? '';
        if (h.isNotEmpty) header[h] = i;
      }

      return _processRows(
        rowCount: rows.length - 1,
        getCell: (rowIdx, col) {
          final colIdx = header[col];
          if (colIdx == null) return null;
          final cell = rows[rowIdx + 1][colIdx];
          return _excelCellString(cell);
        },
      );
    } catch (e) {
      return ImportResult(
          imported: 0, skipped: 0, error: 'Excel parse error: $e');
    }
  }

  String? _excelCellString(Data? cell) {
    if (cell == null || cell.value == null) return null;
    final v = cell.value;
    if (v is TextCellValue) return v.value.toString().trim();
    if (v is DoubleCellValue) return v.value.toStringAsFixed(2);
    if (v is IntCellValue) return v.value.toString();
    if (v is DateCellValue)
      return DateTime(v.year, v.month, v.day).toIso8601String();
    return v.toString().trim();
  }

  // ─── CSV ─────────────────────────────────────────────────────────────────

  Future<ImportResult> _importCsv(String path) async {
    try {
      final content = await File(path).readAsString();
      if (content.trim().isEmpty) {
        return const ImportResult(
            imported: 0, skipped: 0, error: 'File is empty');
      }

      final rows =
          const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
              .convert(content);
      if (rows.length < 2) {
        return const ImportResult(
            imported: 0, skipped: 0, error: 'No data rows');
      }

      // Build header index from row 0
      final headerRow = rows[0]
          .map((h) => h.toString().replaceAll('"', '').trim().toUpperCase())
          .toList();
      final header = <String, int>{};
      for (var i = 0; i < headerRow.length; i++) {
        header[headerRow[i]] = i;
      }

      return _processRows(
        rowCount: rows.length - 1,
        getCell: (rowIdx, col) {
          final colIdx = header[col];
          if (colIdx == null) return null;
          final row = rows[rowIdx + 1];
          if (colIdx >= row.length) return null;
          return row[colIdx].toString().replaceAll('"', '').trim();
        },
      );
    } catch (e) {
      return ImportResult(
          imported: 0, skipped: 0, error: 'CSV parse error: $e');
    }
  }

  // ─── Shared row processor ────────────────────────────────────────────────

  Future<ImportResult> _processRows({
    required int rowCount,
    required String? Function(int rowIdx, String col) getCell,
  }) async {
    final allAccounts = await _accRepo.getAll();
    final allCats = await _catRepo.getAll();

    // Build lookup maps
    final accByName = <String, String>{}; // lower(name) → id
    for (final a in allAccounts) accByName[a.name.toLowerCase()] = a.id;

    final catByName = <String, String>{}; // lower(name) → id
    for (final c in allCats) catByName[c.name.toLowerCase()] = c.id;

    int imported = 0, skipped = 0;
    final warnings = <String>[];

    for (var i = 0; i < rowCount; i++) {
      final rowNum = i + 2;
      try {
        final timeStr = getCell(i, 'TIME')?.trim() ?? '';
        final typeStr = getCell(i, 'TYPE')?.trim() ?? '';
        final amtStr = (getCell(i, 'AMOUNT') ?? '')
            .replaceAll(',', '')
            .replaceAll('₹', '')
            .trim();
        final catStr = (getCell(i, 'CATEGORY') ?? '').trim();
        final accStr = (getCell(i, 'ACCOUNT') ?? '').trim();
        final notes = getCell(i, 'NOTES')?.trim();

        if (timeStr.isEmpty && amtStr.isEmpty) continue;

        // Parse date: accepts "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm", "dd-MM-yyyy HH:mm"
        final date = _parseDate(timeStr);
        if (date == null) {
          warnings.add('Row $rowNum: Cannot parse date "$timeStr"');
          skipped++;
          continue;
        }

        final amount = double.tryParse(amtStr);
        if (amount == null || amount <= 0) {
          warnings.add('Row $rowNum: Invalid amount "$amtStr"');
          skipped++;
          continue;
        }

        // Parse type from TYPE column labels
        final RecordType type;
        final tl = typeStr.toLowerCase();
        if (tl.contains('income') || tl.startsWith('(+)')) {
          type = RecordType.income;
        } else if (tl.contains('transfer') || tl.startsWith('(*)')) {
          type = RecordType.transfer;
        } else {
          type = RecordType.expense; // default / (-) Expense
        }

        // Resolve account
        // For transfers, ACCOUNT column is "from->to" e.g. "hdfc->SBI"
        String? fromAccId, toAccId;
        if (type == RecordType.transfer) {
          final parts = accStr.split('->');
          fromAccId = parts.isNotEmpty
              ? _resolveAccount(parts[0].trim(), accByName)
              : null;
          toAccId = parts.length > 1
              ? _resolveAccount(parts[1].trim(), accByName)
              : null;
          if (fromAccId == null) {
            warnings
                .add('Row $rowNum: Account "${parts.firstOrNull}" not found');
            skipped++;
            continue;
          }
        } else {
          fromAccId = _resolveAccount(accStr, accByName);
          if (fromAccId == null) {
            warnings.add('Row $rowNum: Account "$accStr" not found');
            skipped++;
            continue;
          }
        }

        // Resolve category (skip for transfers where CATEGORY is '-')
        String? categoryId;
        if (type != RecordType.transfer && catStr != '-' && catStr.isNotEmpty) {
          categoryId = catByName[catStr.toLowerCase()];
          if (categoryId == null) {
            warnings.add(
                'Row $rowNum: Category "$catStr" not found — imported without category');
          }
        }

        await _recordRepo.create(
          type: type,
          amount: amount,
          accountId: fromAccId!,
          categoryId: categoryId,
          toAccountId: toAccId,
          notes: (notes == null || notes.isEmpty) ? null : notes,
          date: date,
          skipBalanceUpdate: false,
        );
        imported++;
      } catch (e) {
        warnings.add('Row $rowNum: Error — $e');
        skipped++;
      }
    }

    return ImportResult(
        imported: imported, skipped: skipped, warnings: warnings);
  }

  String? _resolveAccount(String name, Map<String, String> map) =>
      map[name.toLowerCase()];

  /// Parses multiple date formats:
  ///   "2026-09-01 23:41:00"   (Excel ISO-ish)
  ///   "2026-09-01 23:41"
  ///   "01-09-2026 23:41"      (CSV dd-MM-yyyy)
  DateTime? _parseDate(String s) {
    if (s.isEmpty) return null;
    // ISO-first: yyyy-MM-dd
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})');
    var m = iso.firstMatch(s);
    if (m != null) {
      return DateTime(
          int.parse(m.group(1)!),
          int.parse(m.group(2)!),
          int.parse(m.group(3)!),
          int.parse(m.group(4)!),
          int.parse(m.group(5)!));
    }
    // dd-MM-yyyy HH:mm
    final dmy = RegExp(r'^(\d{2})-(\d{2})-(\d{4})[ T](\d{2}):(\d{2})');
    m = dmy.firstMatch(s);
    if (m != null) {
      return DateTime(
          int.parse(m.group(3)!),
          int.parse(m.group(2)!),
          int.parse(m.group(1)!),
          int.parse(m.group(4)!),
          int.parse(m.group(5)!));
    }
    // Fallback
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }
}
