// lib/core/utils/formatters.dart
import 'package:intl/intl.dart';

class Formatters {
  static final _currency = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
    locale: 'en_IN',
  );

  static final _currencyCompact = NumberFormat.compactCurrency(
    symbol: '₹',
    locale: 'en_IN',
  );

  static String currency(double amount) => _currency.format(amount);
  static String currencyCompact(double amount) => _currencyCompact.format(amount);

  static String date(DateTime d) => DateFormat('MMM dd, yyyy').format(d);
  static String dateShort(DateTime d) => DateFormat('dd MMM').format(d);
  static String monthYear(DateTime d) => DateFormat('MMMM, yyyy').format(d);
  static String dayWeekday(DateTime d) => DateFormat('MMM d, EEEE').format(d);
  static String time(DateTime d) => DateFormat('hh:mm a').format(d);
  static String excelDate(DateTime d) => DateFormat('dd-MM-yyyy').format(d);
}
