class CurrencyFormatter {
  /// Formats amount in Indian currency notation (e.g. ₹25,000, ₹2.50 L, ₹1.38 Cr).
  static String formatINR(double amount, {bool includeSymbol = true}) {
    final prefix = includeSymbol ? '₹' : '';
    final absAmt = amount.abs();

    if (absAmt >= 10000000) {
      final cr = amount / 10000000;
      return '$prefix${_formatDecimal(cr)} Cr';
    } else if (absAmt >= 100000) {
      final lakh = amount / 100000;
      return '$prefix${_formatDecimal(lakh)} L';
    } else {
      final formatted = _formatWithCommas(amount.round());
      return '$prefix$formatted';
    }
  }

  /// Formats full exact amount with Indian commas (e.g. ₹60,00,000, ₹59,98,100, ₹1,900).
  static String formatFullINR(double amount, {bool includeSymbol = true}) {
    final prefix = includeSymbol ? '₹' : '';
    final formatted = _formatWithCommas(amount.round());
    return '$prefix$formatted';
  }

  /// Compact smart formatter for dashboard KPIs (e.g. ₹60L, ₹59.98L, ₹1.9K, ₹850).
  static String formatCompact(double amount, {bool includeSymbol = true}) {
    if (amount.isNaN || amount.isInfinite) return includeSymbol ? '₹0' : '0';
    final prefix = includeSymbol ? '₹' : '';
    if (amount < 0) return '-$prefix${formatCompact(-amount, includeSymbol: false)}';

    final absAmt = amount.abs();
    if (absAmt >= 10000000) {
      final cr = amount / 10000000;
      return '$prefix${_formatDecimal(cr)}Cr';
    } else if (absAmt >= 100000) {
      final lakh = amount / 100000;
      return '$prefix${_formatDecimal(lakh)}L';
    } else if (absAmt >= 1000) {
      final k = amount / 1000;
      return '$prefix${_formatDecimal(k)}K';
    }
    return '$prefix${amount.toStringAsFixed(0)}';
  }

  static String _formatDecimal(double val) {
    final absVal = val.abs();
    if (absVal == absVal.roundToDouble()) {
      return val.toStringAsFixed(0);
    }
    final str = val.toStringAsFixed(2);
    if (str.endsWith('0')) {
      return val.toStringAsFixed(1);
    }
    return str;
  }

  static String _formatWithCommas(int n) {
    final String s = n.abs().toString();
    final int len = s.length;
    if (len <= 3) {
      return n < 0 ? '-$s' : s;
    }
    final String lastThree = s.substring(len - 3);
    final String firstPart = s.substring(0, len - 3);
    final StringBuffer indianPart = StringBuffer();

    for (int i = 0; i < firstPart.length; i++) {
      if (i > 0 && (firstPart.length - i) % 2 == 0) {
        indianPart.write(',');
      }
      indianPart.write(firstPart[i]);
    }
    final result = '${indianPart.toString()},$lastThree';
    return n < 0 ? '-$result' : result;
  }
}
