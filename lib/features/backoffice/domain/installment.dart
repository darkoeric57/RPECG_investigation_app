import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'installment.g.dart';

@immutable
@HiveType(typeId: 7)
class Installment {
  @HiveField(0) final double amount;
  @HiveField(1) final DateTime dueDate;
  @HiveField(2) final bool isPaid;

  const Installment({
    this.amount = 0.0,
    required this.dueDate,
    this.isPaid = false,
  });

  Installment copyWith({
    double? amount,
    DateTime? dueDate,
    bool? isPaid,
  }) {
    return Installment(
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'isPaid': isPaid,
    };
  }

  factory Installment.fromMap(Map<String, dynamic> map) {
    return Installment(
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: map['dueDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int) 
          : DateTime.now(),
      isPaid: map['isPaid'] as bool? ?? false,
    );
  }

  @override
  String toString() => 'Installment(amount: $amount, dueDate: $dueDate, isPaid: $isPaid)';
}
