import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class DateFormatter {
  static final _wib = tz.getLocation('Asia/Jakarta');

  /// Mengonversi DateTime (diasumsikan UTC) ke string format WIB.
  ///
  /// Contoh format: 'dd MMM yyyy, HH:mm' -> '18 Jun 2025, 07:00'
  static String toWibString(DateTime? utcDate, {String format = 'dd MMM yyyy, HH:mm'}) {
    if (utcDate == null) {
      return 'N/A';
    }
    
    // Ubah DateTime UTC menjadi TZDateTime dalam zona waktu WIB
    final wibDate = tz.TZDateTime.from(utcDate, _wib);
    
    // Format menggunakan intl dengan lokal Indonesia
    return DateFormat(format, 'id_ID').format(wibDate);
  }
}