/// Utility to filter lists of objects by a date field within a date range.
class DateRangeFilterHelper {
  /// Filters a list of items where [getDate] returns a date string (yyyy-MM-dd or ISO).
  /// Items whose date falls within [start..end] are kept.
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
      final parsed = DateTime.tryParse(dateStr);
      if (parsed == null) return false;
      return !parsed.isBefore(startDay) && !parsed.isAfter(endDay);
    }).toList();
  }
}
