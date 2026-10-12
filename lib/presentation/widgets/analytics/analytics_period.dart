enum AnalyticsPeriodType {
  week,
  month,
  year,
  custom,
}

class AnalyticsDateRange {
  final AnalyticsPeriodType type;
  final DateTime startDate;
  final DateTime endDate;
  final String label;

  const AnalyticsDateRange({
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.label,
  });

  /// Вычисляет диапазон дат по типу и относительному смещению (offset: 0 - текущий, -1 - прошлый)
  factory AnalyticsDateRange.fromType({
    required AnalyticsPeriodType type,
    int offset = 0,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final now = DateTime.now();

    switch (type) {
      case AnalyticsPeriodType.week:
        // Определяем понедельник текущей недели со смещением
        final currentWeekday = now.weekday; // 1 = Пн, 7 = Вс
        final baseMonday = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: currentWeekday - 1));
        final start = baseMonday.add(Duration(days: offset * 7));
        final end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        return AnalyticsDateRange(
          type: type,
          startDate: start,
          endDate: end,
          label: offset == 0
              ? 'Текущая неделя'
              : offset == -1
                  ? 'Прошлая неделя'
                  : '${start.day}.${start.month} — ${end.day}.${end.month}',
        );

      case AnalyticsPeriodType.month:
        final targetMonthDate = DateTime(now.year, now.month + offset, 1);
        final start = DateTime(targetMonthDate.year, targetMonthDate.month, 1);
        final end = DateTime(
          targetMonthDate.year,
          targetMonthDate.month + 1,
          0,
          23,
          59,
          59,
        );
        const months = [
          'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
          'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
        ];
        return AnalyticsDateRange(
          type: type,
          startDate: start,
          endDate: end,
          label: offset == 0
              ? 'Текущий месяц (${months[start.month - 1]})'
              : '${months[start.month - 1]} ${start.year}',
        );

      case AnalyticsPeriodType.year:
        final targetYear = now.year + offset;
        final start = DateTime(targetYear, 1, 1);
        final end = DateTime(targetYear, 12, 31, 23, 59, 59);
        return AnalyticsDateRange(
          type: type,
          startDate: start,
          endDate: end,
          label: '$targetYear год',
        );

      case AnalyticsPeriodType.custom:
        final start = customStart ?? DateTime(now.year, now.month, 1);
        final end = customEnd ??
            DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return AnalyticsDateRange(
          type: type,
          startDate: start,
          endDate: end,
          label: 'Свой период',
        );
    }
  }

  int get daysCount {
    return endDate.difference(startDate).inDays + 1;
  }
}
