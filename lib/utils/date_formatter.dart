import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class DateFormatter {
  static final _wib = tz.getLocation('Asia/Jakarta');
  static String toWibString(DateTime? utcDate, {String format = 'dd MMM yyyy, HH:mm'}) {
    if (utcDate == null) {
      return 'N/A';
    }
    
    final wibDate = tz.TZDateTime.from(utcDate, _wib);
    
    return DateFormat(format, 'id_ID').format(wibDate);
  }
}