// lib/core/utils/formatters.dart
import 'package:intl/intl.dart';

class Formatters {
  static String currency(double amount) =>
      '₹${NumberFormat('#,##,##0.00', 'en_IN').format(amount)}';

  static String monthYear(DateTime d) => DateFormat('MMMM, yyyy').format(d);
  static String dayWeekday(DateTime d) => DateFormat('MMM d, EEEE').format(d);

  /// dd-MM-yyyy HH:mm  — matches export/import format
  static String csvDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}-'
      '${d.month.toString().padLeft(2,'0')}-'
      '${d.year} '
      '${d.hour.toString().padLeft(2,'0')}:'
      '${d.minute.toString().padLeft(2,'0')}';

  /// yyyy-MM-dd HH:mm:ss — matches Excel export TIME column
  static String excelDateTime(DateTime d) =>
      DateFormat('yyyy-MM-dd HH:mm:ss').format(d);

  static String excelDate(DateTime d) => DateFormat('dd-MM-yyyy').format(d);

  static String monthName(int m) {
    const n = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return n[m - 1];
  }
}
