import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/formatters.dart';
import '../records/data/record_model.dart';

class ExcelExportService {
  Future<void> exportRecords(List<FinancialRecord> records) async {
    final excel = Excel.createExcel();
    final sheet = excel['Records'];

    // Remove default sheet
    excel.delete('Sheet1');

    // Header style
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#D4A843'),
      fontColorHex: ExcelColor.fromHexString('#000000'),
      horizontalAlign: HorizontalAlign.Center,
    );

    // Headers
    final headers = [
      'Date',
      'Type',
      'Category',
      'Account',
      'To Account',
      'Amount (₹)',
      'Notes'
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Set column widths
    sheet.setColumnWidth(0, 18);
    sheet.setColumnWidth(1, 12);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 15);
    sheet.setColumnWidth(4, 15);
    sheet.setColumnWidth(5, 15);
    sheet.setColumnWidth(6, 30);

    // Data rows
    for (var i = 0; i < records.length; i++) {
      final r = records[i];
      final rowIdx = i + 1;

      // Row color alternating
      final rowStyle = CellStyle(
        backgroundColorHex: rowIdx % 2 == 0
            ? ExcelColor.fromHexString('#2A2A2A')
            : ExcelColor.fromHexString('#1E1E1E'),
        fontColorHex: ExcelColor.fromHexString('#EEEEEE'),
      );

      // Amount color based on type
      final amountStyle = CellStyle(
        fontColorHex: r.type == RecordType.expense
            ? ExcelColor.fromHexString('#E57373')
            : r.type == RecordType.income
                ? ExcelColor.fromHexString('#81C784')
                : ExcelColor.fromHexString('#64B5F6'),
        bold: true,
        backgroundColorHex: rowIdx % 2 == 0
            ? ExcelColor.fromHexString('#2A2A2A')
            : ExcelColor.fromHexString('#1E1E1E'),
      );

      void setCell(int col, CellValue value, [CellStyle? style]) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx));
        cell.value = value;
        cell.cellStyle = style ?? rowStyle;
      }

      setCell(0, TextCellValue(Formatters.excelDate(r.date)));
      setCell(1, TextCellValue(r.type.name.toUpperCase()));
      setCell(2, TextCellValue(r.categoryName ?? '-'));
      setCell(3, TextCellValue(r.accountName ?? '-'));
      setCell(4, TextCellValue(r.toAccountName ?? '-'));
      setCell(
        5,
        DoubleCellValue(r.type == RecordType.expense ? -r.amount : r.amount),
        amountStyle,
      );
      setCell(6, TextCellValue(r.notes ?? ''));
    }

    // Summary sheet
    final summarySheet = excel['Summary'];

    // Summary headers
    final sumHeaders = ['Category', 'Type', 'Total (₹)', 'Count'];
    for (var i = 0; i < sumHeaders.length; i++) {
      final cell = summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(sumHeaders[i]);
      cell.cellStyle = headerStyle;
    }

    // Group by category
    final catMap = <String, ({double total, int count, String type})>{};
    for (final r in records) {
      if (r.type == RecordType.transfer) continue;
      final key = r.categoryName ?? 'Uncategorized';
      final prev = catMap[key];
      catMap[key] = (
        total: (prev?.total ?? 0) + r.amount,
        count: (prev?.count ?? 0) + 1,
        type: r.type.name,
      );
    }

    int sRow = 1;
    for (final entry in catMap.entries) {
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sRow))
          .value = TextCellValue(entry.key);
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: sRow))
          .value = TextCellValue(entry.value.type.toUpperCase());
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: sRow))
          .value = DoubleCellValue(entry.value.total);
      summarySheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: sRow))
          .value = IntCellValue(entry.value.count);
      sRow++;
    }

    // Save and share
    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to encode Excel file');
    }

    final dir = await getTemporaryDirectory();
    final fileName =
        'MyMoney_Export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Exported ${records.length} financial records',
      subject: 'KharchaPani Records Export',
    );
  }

  /// Export records as CSV matching the import format:
  /// "TIME","TYPE","AMOUNT","CATEGORY","ACCOUNT","NOTES"
  Future<void> exportAsCsv(List<FinancialRecord> records) async {
    final buffer = StringBuffer();

    // Header — matches import format exactly
    buffer.writeln('"TIME","TYPE","AMOUNT","CATEGORY","ACCOUNT","NOTES"');

    for (final r in records) {
      final timeStr = _csvDate(r.date);
      final typeStr = r.type.name.toUpperCase();
      final amount = r.amount.toStringAsFixed(2);
      final category = _csvEscape(r.categoryName ?? '');
      final account = _csvEscape(r.accountName ?? '');
      final notes = _csvEscape(r.notes ?? '');

      buffer
          .writeln('"$timeStr","$typeStr","$amount",$category,$account,$notes');
    }

    final dir = await getTemporaryDirectory();
    final ts = DateTime.now();
    final fileName =
        'export_${_twoDigit(ts.day)}_${_twoDigit(ts.month)}_${ts.year % 100}_'
        '${_twoDigit(ts.hour)}${_twoDigit(ts.minute)}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Exported ${records.length} financial records',
      subject: 'KharchaPani CSV Export',
    );
  }

  /// Format: dd-MM-yyyy HH:mm (matches import parser)
  String _csvDate(DateTime d) {
    return '${_twoDigit(d.day)}-${_twoDigit(d.month)}-${d.year} '
        '${_twoDigit(d.hour)}:${_twoDigit(d.minute)}';
  }

  String _twoDigit(int n) => n.toString().padLeft(2, '0');

  /// Wrap in quotes and escape inner quotes
  String _csvEscape(String s) {
    if (s.isEmpty) return '""';
    final escaped = s.replaceAll('"', '""');
    return '"$escaped"';
  }
}
