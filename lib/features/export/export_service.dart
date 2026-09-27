// lib/features/export/export_service.dart
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/formatters.dart';
import '../records/data/record_model.dart';

/// Export format TYPE strings — matches what the Excel importer reads
class _TypeLabel {
  static const expense  = '(-) Expense';
  static const income   = '(+) Income';
  static const transfer = '(*) Transfer';

  static String from(RecordType t) => switch (t) {
    RecordType.expense  => expense,
    RecordType.income   => income,
    RecordType.transfer => transfer,
  };
}

class ExportService {
  // ─── Excel Export ───────────────────────────────────────────────────────────

  Future<void> exportExcel(List<FinancialRecord> records) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    final sheet = excel['Sheet1'];

    final hStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#D4A843'),
      fontColorHex: ExcelColor.fromHexString('#000000'),
      horizontalAlign: HorizontalAlign.Center,
    );

    // Header row — exact columns matching the uploaded Excel
    final headers = ['TIME', 'TYPE', 'AMOUNT', 'CATEGORY', 'ACCOUNT', 'NOTES'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = hStyle;
    }
    sheet.setColumnWidth(0, 22);
    sheet.setColumnWidth(1, 16);
    sheet.setColumnWidth(2, 12);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 35);

    for (var i = 0; i < records.length; i++) {
      final r      = records[i];
      final rowIdx = i + 1;
      final isEven = rowIdx % 2 == 0;

      final rowStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString(isEven ? '#2A2A2A' : '#1E1E1E'),
        fontColorHex: ExcelColor.fromHexString('#EEEEEE'),
      );
      final amtStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString(isEven ? '#2A2A2A' : '#1E1E1E'),
        fontColorHex: ExcelColor.fromHexString(
          r.type == RecordType.expense ? '#E57373'
          : r.type == RecordType.income ? '#81C784' : '#64B5F6'),
      );

      void setCell(int col, CellValue val, [CellStyle? style]) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx));
        cell.value = val;
        cell.cellStyle = style ?? rowStyle;
      }

      // TIME: yyyy-MM-dd HH:mm:ss (matches the uploaded Excel format exactly)
      setCell(0, TextCellValue(Formatters.excelDateTime(r.date)));
      setCell(1, TextCellValue(_TypeLabel.from(r.type)));
      setCell(2, DoubleCellValue(r.amount), amtStyle);

      // CATEGORY: '-' for transfers (matches uploaded Excel)
      final catDisplay = r.type == RecordType.transfer
          ? '-'
          : (r.categoryName ?? '-');
      setCell(3, TextCellValue(catDisplay));

      // ACCOUNT: 'from->to' for transfers
      final accDisplay = r.type == RecordType.transfer
          ? '${r.accountName ?? "?"}->${r.toAccountName ?? "?"}'
          : (r.accountName ?? '-');
      setCell(4, TextCellValue(accDisplay));
      setCell(5, TextCellValue(r.notes ?? ''));
    }

    final bytes = excel.encode();
    if (bytes == null) return;

    final dir  = await getTemporaryDirectory();
    final ts   = DateTime.now();
    final name = 'KharchaPani_${ts.year}${_pad(ts.month)}${_pad(ts.day)}'
        '_${_pad(ts.hour)}${_pad(ts.minute)}.xlsx';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)],
      subject: 'KharchaPani Export',
      text: 'Exported ${records.length} records');
  }

  // ─── CSV Export ─────────────────────────────────────────────────────────────

  Future<void> exportCsv(List<FinancialRecord> records) async {
    final buf = StringBuffer();
    buf.writeln('"TIME","TYPE","AMOUNT","CATEGORY","ACCOUNT","NOTES"');

    for (final r in records) {
      final time = Formatters.excelDateTime(r.date);
      final type = _TypeLabel.from(r.type);
      final cat  = r.type == RecordType.transfer ? '-' : (r.categoryName ?? '-');
      final acc  = r.type == RecordType.transfer
          ? '${r.accountName ?? "?"}->${r.toAccountName ?? "?"}'
          : (r.accountName ?? '-');

      buf.writeln('${_q(time)},${_q(type)},${r.amount.toStringAsFixed(2)},'
          '${_q(cat)},${_q(acc)},${_q(r.notes ?? '')}');
    }

    final dir  = await getTemporaryDirectory();
    final ts   = DateTime.now();
    final name = 'KharchaPani_${ts.year}${_pad(ts.month)}${_pad(ts.day)}'
        '_${_pad(ts.hour)}${_pad(ts.minute)}.csv';
    final file = File('${dir.path}/$name');
    await file.writeAsString(buf.toString());

    await Share.shareXFiles([XFile(file.path)],
      subject: 'KharchaPani CSV Export',
      text: 'Exported ${records.length} records');
  }

  String _q(String s) => '"${s.replaceAll('"', '""')}"';
  String _pad(int n)  => n.toString().padLeft(2, '0');
}
