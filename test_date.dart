import 'package:intl/intl.dart';

void main() {
  final df = DateFormat('dd MMM yyyy');
  final now = DateTime.now();
  final d = df.format(now);
  print('Formatted date: $d');
  
  final parsed = df.parse(d);
  print('Parsed date: $parsed');
}
