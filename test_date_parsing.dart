import 'package:intl/intl.dart';

void main() {
  final now = DateTime.now();
  final df = DateFormat('dd MMM yyyy');

  for (int i = 0; i < 5; i++) {
    final createdDate = now.subtract(Duration(days: i * 2));
    final str = df.format(createdDate);
    
    DateTime? parsed;
    try {
      parsed = DateFormat('dd MMM yyyy').parse(str);
    } catch (_) {
      try {
        parsed = DateTime.parse(str);
      } catch (_) {
        parsed = null;
      }
    }
    
    print('String: $str, Parsed: $parsed');
  }
}
