import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
);
final _date = DateFormat('dd/MM/yyyy');

String formatCurrency(num value) => _currency.format(value);
String formatDate(DateTime value) => _date.format(value);
