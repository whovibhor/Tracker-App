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

  Transaction({
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
  });
}
