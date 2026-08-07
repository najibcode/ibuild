import 'package:intl/intl.dart';

/// Utility to filter lists of objects by a date field within a date range.
class DateRangeFilterHelper {
  /// Parses a date string that could be in various formats:
  /// - yyyy-MM-dd (ISO, most common from Supabase)
  /// - yyyy-MM-ddTHH:mm:ss... (ISO 8601 full)
  /// - dd-MM-yyyy
  /// - dd/MM/yyyy
  /// - MM/dd/yyyy
  /// Returns null if parsing fails.
  static DateTime? _parseFlexible(String dateStr) {
    // Try standard ISO parse first (handles yyyy-MM-dd and full ISO 8601)
    final iso = DateTime.tryParse(dateStr);
    if (iso != null) return iso;

    // Try common non-ISO formats
    final formats = [
      DateFormat('dd-MM-yyyy'),
      DateFormat('dd/MM/yyyy'),
      DateFormat('MM/dd/yyyy'),
      DateFormat('dd MMM yyyy'),
      DateFormat('MMM dd, yyyy'),
    ];

    for (final fmt in formats) {
      try {
        return fmt.parseStrict(dateStr.trim());
      } catch (_) {}
    }

    return null;
  }

  /// Filters a list of items where [getDate] returns a date **String**
  /// (any common format). Items whose date falls within [start..end] are kept.
  static List<T> filter<T>(
    List<T> items, {
    required DateTime start,
    required DateTime end,
    required String? Function(T item) getDate,
  }) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    return items.where((item) {
      final dateStr = getDate(item);
      if (dateStr == null || dateStr.isEmpty) return false;
      final parsed = _parseFlexible(dateStr);
      if (parsed == null) return false;
      return !parsed.isBefore(startDay) && !parsed.isAfter(endDay);
    }).toList();
  }

  /// Filters a list of items where [getDate] returns a **DateTime** object.
  static List<T> filterByDateTime<T>(
    List<T> items, {
    required DateTime start,
    required DateTime end,
    required DateTime? Function(T item) getDate,
  }) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    return items.where((item) {
      final dt = getDate(item);
      if (dt == null) return false;
      return !dt.isBefore(startDay) && !dt.isAfter(endDay);
    }).toList();
  }
}
