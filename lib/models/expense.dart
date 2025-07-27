import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 2)
enum TransactionType {
  @HiveField(0)
  asset,
  @HiveField(1)
  liability,
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

  Transaction({
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.tag,
    this.dueDate,
    this.isCompleted = false,
  });

  bool get isOverdue =>
      dueDate != null && !isCompleted && DateTime.now().isAfter(dueDate!);
  int get daysUntilDue =>
      dueDate != null ? dueDate!.difference(DateTime.now()).inDays : 0;
}
