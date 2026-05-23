import 'package:cloud_firestore/cloud_firestore.dart';

class BillingAccount {
  final String? id;
  final String initials;
  final String name;
  final String meter;
  final String account;
  final String consumption;
  final String fraudStatus;
  final String totalAmount;
  final String amountPaid;
  final String fraudBillStatus;
  final String balance;
  final String tariff;
  final String status;
  final String scheduled;
  final String createdAt;
  final String address;
  final DateTime? importedAt;

  BillingAccount({
    this.id,
    required this.initials,
    required this.name,
    required this.meter,
    required this.account,
    required this.consumption,
    required this.fraudStatus,
    required this.totalAmount,
    required this.amountPaid,
    required this.fraudBillStatus,
    required this.balance,
    required this.tariff,
    required this.status,
    required this.scheduled,
    required this.createdAt,
    required this.address,
    this.importedAt,
  });

  factory BillingAccount.fromMap(Map<String, dynamic> map, {String? id}) {
    return BillingAccount(
      id: id,
      initials: map['initials'] ?? '',
      name: map['name'] ?? '',
      meter: map['meter'] ?? '',
      account: map['account'] ?? '',
      consumption: map['consumption'] ?? '',
      fraudStatus: map['fraud_status'] ?? '',
      totalAmount: map['total_amount'] ?? '',
      amountPaid: map['amount_paid'] ?? '',
      fraudBillStatus: map['fraud_bill_status'] ?? '',
      balance: map['balance'] ?? '',
      tariff: map['tariff'] ?? '',
      status: map['status'] ?? '',
      scheduled: map['scheduled'] ?? '',
      createdAt: map['created_at'] ?? '',
      address: map['address'] ?? '—',
      importedAt: map['imported_at'] != null 
          ? (map['imported_at'] is Timestamp 
              ? (map['imported_at'] as Timestamp).toDate() 
              : DateTime.parse(map['imported_at']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'initials': initials,
      'name': name,
      'meter': meter,
      'account': account,
      'consumption': consumption,
      'fraud_status': fraudStatus,
      'total_amount': totalAmount,
      'amount_paid': amountPaid,
      'fraud_bill_status': fraudBillStatus,
      'balance': balance,
      'tariff': tariff,
      'status': status,
      'scheduled': scheduled,
      'created_at': createdAt,
      'address': address,
      'imported_at': importedAt != null ? Timestamp.fromDate(importedAt!) : FieldValue.serverTimestamp(),
    };
  }

  BillingAccount copyWith({
    String? id,
    String? initials,
    String? name,
    String? meter,
    String? account,
    String? consumption,
    String? fraudStatus,
    String? totalAmount,
    String? amountPaid,
    String? fraudBillStatus,
    String? balance,
    String? tariff,
    String? status,
    String? scheduled,
    String? createdAt,
    String? address,
    DateTime? importedAt,
  }) {
    return BillingAccount(
      id: id ?? this.id,
      initials: initials ?? this.initials,
      name: name ?? this.name,
      meter: meter ?? this.meter,
      account: account ?? this.account,
      consumption: consumption ?? this.consumption,
      fraudStatus: fraudStatus ?? this.fraudStatus,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      fraudBillStatus: fraudBillStatus ?? this.fraudBillStatus,
      balance: balance ?? this.balance,
      tariff: tariff ?? this.tariff,
      status: status ?? this.status,
      scheduled: scheduled ?? this.scheduled,
      createdAt: createdAt ?? this.createdAt,
      address: address ?? this.address,
      importedAt: importedAt ?? this.importedAt,
    );
  }
}
