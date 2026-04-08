import 'package:intl/intl.dart';
import '../constants/api_constants.dart';

class PriceFormatter {
  PriceFormatter._();

  static final _fmt = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
  );

  static String format(double price) => _fmt.format(price);
}
