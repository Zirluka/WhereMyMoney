import 'package:intl/intl.dart';

class DateFormatter {
  static const List<String> _monthsGenitive = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  static const List<String> _monthsNominative = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  static const List<String> _weekdays = [
    'понедельник',
    'вторник',
    'среда',
    'четверг',
    'пятница',
    'суббота',
    'воскресенье',
  ];

  /// Формат для таймстемпа транзакции:
  /// formatShort(DateTime.now()) -> "Сегодня, 14:30"
  /// formatShort(вчера) -> "Вчера, 18:15"
  /// formatShort(10 мая) -> "10 мая, 12:00"
  static String formatShort(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final check = DateTime(date.year, date.month, date.day);
    final timeStr = DateFormat('HH:mm').format(date);

    if (check == today) {
      return 'Сегодня, $timeStr';
    } else if (check == yesterday) {
      return 'Вчера, $timeStr';
    } else {
      final monthName = _monthsGenitive[date.month - 1];
      if (date.year == now.year) {
        return '${date.day} $monthName, $timeStr';
      } else {
        return '${date.day} $monthName ${date.year}, $timeStr';
      }
    }
  }

  /// Заголовок дня в списке транзакций:
  /// formatDayHeader(DateTime.now()) -> "Сегодня, 12 октября"
  /// formatDayHeader(вчера) -> "Вчера, 11 октября"
  /// formatDayHeader(другой день) -> "10 октября, суббота"
  static String formatDayHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final check = DateTime(date.year, date.month, date.day);
    final monthName = _monthsGenitive[date.month - 1];
    final weekdayName = _weekdays[date.weekday - 1];

    if (check == today) {
      return 'Сегодня, ${date.day} $monthName';
    } else if (check == yesterday) {
      return 'Вчера, ${date.day} $monthName';
    } else if (date.year == now.year) {
      return '${date.day} $monthName, $weekdayName';
    } else {
      return '${date.day} $monthName ${date.year}';
    }
  }

  /// Заголовок месяца для отчетов:
  /// formatMonthYear(DateTime.now()) -> "Октябрь 2026"
  static String formatMonthYear(DateTime date) {
    final monthName = _monthsNominative[date.month - 1];
    return '$monthName ${date.year}';
  }

  /// Короткий формат дня и месяца ("12 окт")
  static String formatShortDayMonth(DateTime date) {
    const shortMonths = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${date.day} ${shortMonths[date.month - 1]}';
  }

  /// Форматирование диапазона дат для периода
  static String formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return '${start.day} ${_monthsGenitive[start.month - 1]} ${start.year}';
    }
    if (start.year == end.year && start.month == end.month) {
      return '${start.day} — ${end.day} ${_monthsGenitive[start.month - 1]} ${start.year}';
    }
    if (start.year == end.year) {
      return '${start.day} ${_monthsGenitive[start.month - 1]} — ${end.day} ${_monthsGenitive[end.month - 1]} ${start.year}';
    }
    return '${start.day} ${_monthsGenitive[start.month - 1]} ${start.year} — ${end.day} ${_monthsGenitive[end.month - 1]} ${end.year}';
  }
}
