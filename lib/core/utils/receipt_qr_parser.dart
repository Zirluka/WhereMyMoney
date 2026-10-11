class ReceiptData {
  final double amount;
  final DateTime date;
  final String? fn;
  final String? fd;
  final String? fp;
  final String rawData;
  final bool isFiscal;

  const ReceiptData({
    required this.amount,
    required this.date,
    this.fn,
    this.fd,
    this.fp,
    required this.rawData,
    this.isFiscal = false,
  });
}

class ReceiptQrParser {
  /// Парсит QR-код кассового чека (ФНС РФ или произвольный)
  /// Пример ФНС: "t=20261012T143000&s=1240.50&fn=9960440300123456&i=15243&fp=3857291023&n=1"
  static ReceiptData? parse(String rawQr) {
    if (rawQr.trim().isEmpty) return null;

    final trimmed = rawQr.trim();
    final queryStr = trimmed.contains('?') ? trimmed.split('?').last : trimmed;

    final params = <String, String>{};
    for (final pair in queryStr.split('&')) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        params[parts[0].trim()] = parts[1].trim();
      }
    }

    // Проверяем наличие фискальных параметров (s = сумма, t = дата/время)
    if (params.containsKey('s')) {
      final amountStr = params['s']?.replaceAll(',', '.');
      final amount = double.tryParse(amountStr ?? '');

      if (amount != null && amount > 0) {
        DateTime date = DateTime.now();
        if (params.containsKey('t')) {
          final parsedDate = _parseFnsDate(params['t']!);
          if (parsedDate != null) {
            date = parsedDate;
          }
        }

        return ReceiptData(
          amount: amount,
          date: date,
          fn: params['fn'],
          fd: params['i'] ?? params['fd'],
          fp: params['fp'],
          rawData: trimmed,
          isFiscal: true,
        );
      }
    }

    // Fallback: Попытка найти сумму в тексте (например "1250.00" или "1250")
    final match = RegExp(r'(\d+[.,]\d{2})').firstMatch(trimmed);
    if (match != null) {
      final numStr = match.group(1)?.replaceAll(',', '.');
      final amount = double.tryParse(numStr ?? '');
      if (amount != null && amount > 0) {
        return ReceiptData(
          amount: amount,
          date: DateTime.now(),
          rawData: trimmed,
          isFiscal: false,
        );
      }
    }

    return null;
  }

  /// Парсинг даты ФНС формата: 20261012T143000 или 20261012T1430
  static DateTime? _parseFnsDate(String str) {
    try {
      final clean = str.replaceAll(RegExp(r'[^0-9T]'), '');
      if (clean.length >= 13 && clean.contains('T')) {
        final parts = clean.split('T');
        final datePart = parts[0];
        final timePart = parts[1];

        if (datePart.length >= 8 && timePart.length >= 4) {
          final year = int.parse(datePart.substring(0, 4));
          final month = int.parse(datePart.substring(4, 6));
          final day = int.parse(datePart.substring(6, 8));
          final hour = int.parse(timePart.substring(0, 2));
          final minute = int.parse(timePart.substring(2, 4));
          final second = timePart.length >= 6 ? int.parse(timePart.substring(4, 6)) : 0;

          return DateTime(year, month, day, hour, minute, second);
        }
      }
    } catch (_) {
      // Игнорируем ошибку парсинга даты, используем DateTime.now()
    }
    return null;
  }
}
