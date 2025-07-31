import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 2)
enum TransactionType {
  @HiveField(0)
  asset,
  @HiveField(1)
  liability,
}

@HiveType(typeId: 4)
enum PaymentMethod {
  @HiveField(0)
  cash,
  @HiveField(1)
  creditCard,
  @HiveField(2)
  debitCard,
  @HiveField(3)
  upi,
  @HiveField(4)
  bankTransfer,
}

@HiveType(typeId: 1)
class Transaction extends HiveObject {
  @HiveField(0)
  final String title;
  @HiveField(1)
  final double amount;
  @HiveField(2)
  final DateTime date;
  @HiveField(3)
  final TransactionType type;
  @HiveField(4)
  final String tag;
  @HiveField(5)
  final DateTime? dueDate;
  @HiveField(6)
  final bool isCompleted;
  @HiveField(7)
  final PaymentMethod? paymentMethod;

  Transaction({
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.tag,
    this.dueDate,
    this.isCompleted = false,
    this.paymentMethod,
  });

  bool get isOverdue =>
      dueDate != null && !isCompleted && DateTime.now().isAfter(dueDate!);
  int get daysUntilDue =>
      dueDate != null ? dueDate!.difference(DateTime.now()).inDays : 0;

  String get paymentMethodDisplay {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return '💵 Cash';
      case PaymentMethod.creditCard:
        return '💳 Credit Card';
      case PaymentMethod.debitCard:
        return '💳 Debit Card';
      case PaymentMethod.upi:
        return '📱 UPI';
      case PaymentMethod.bankTransfer:
        return '🏦 Bank Transfer';
      case null:
        return '💰 Not Specified';
    }
  }
}
