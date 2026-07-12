import 'package:intl/intl.dart';

class FormatHelper {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );

  static String currency(num? value) {
    return _currencyFormat.format(value ?? 0);
  }

  static String date(String? value) {
    if (value == null || value.isEmpty) return '';
    final dateTime = DateTime.tryParse(value);
    if (dateTime == null) return value;
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  static String dateTime(String? value) {
    if (value == null || value.isEmpty) return '';
    final dateTime = DateTime.tryParse(value);
    if (dateTime == null) return value;
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
}
