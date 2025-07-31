import 'package:flutter/material.dart';
import '../models/expense.dart';

class QuickAddExpenseWidget extends StatelessWidget {
  final Function(Transaction) onAddExpense;

  const QuickAddExpenseWidget({super.key, required this.onAddExpense});

  // Common expense templates for quick add
  static const List<Map<String, dynamic>> _quickExpenses = [
    {
      'title': '☕ Coffee',
      'amount': 50.0,
      'category': 'Coffee & Tea',
      'icon': Icons.local_cafe,
      'color': Color(0xFFD4A574),
    },
    {
      'title': '🍽️ Lunch',
      'amount': 150.0,
      'category': 'Restaurants',
      'icon': Icons.restaurant,
      'color': Color(0xFFE91E63),
    },
    {
      'title': '🚗 Auto/Taxi',
      'amount': 80.0,
      'category': 'Taxi/Uber',
      'icon': Icons.local_taxi,
      'color': Color(0xFF3F51B5),
    },
    {
      'title': '🛒 Groceries',
      'amount': 500.0,
      'category': 'Groceries',
      'icon': Icons.shopping_cart,
      'color': Color(0xFF4CAF50),
    },
    {
      'title': '⛽ Fuel',
      'amount': 1000.0,
      'category': 'Fuel',
      'icon': Icons.local_gas_station,
      'color': Color(0xFFFF5722),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.flash_on, color: Color(0xFF00C853), size: 24),
              const SizedBox(width: 12),
              const Text(
                'Quick Add Expense',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap any item to add it instantly:',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 20),

          // Quick expense buttons
          ...List.generate(_quickExpenses.length, (index) {
            final expense = _quickExpenses[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _addQuickExpense(context, expense),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF333333)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (expense['color'] as Color).withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            expense['icon'] as IconData,
                            color: expense['color'] as Color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense['title'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                expense['category'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFF1744,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(
                                0xFFFF1744,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '₹${(expense['amount'] as double).toInt()}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF1744),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Add custom expense button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // This will navigate to the full add expense form
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00C853),
                side: const BorderSide(color: Color(0xFF00C853)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text(
                'Add Custom Expense',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _addQuickExpense(BuildContext context, Map<String, dynamic> expense) {
    // Create transaction
    final transaction = Transaction(
      title: expense['title'] as String,
      amount: expense['amount'] as double,
      date: DateTime.now(),
      type: TransactionType.liability,
      tag: expense['category'] as String,
      isCompleted: true, // Quick expenses are usually immediate
      paymentMethod: PaymentMethod.upi, // Default to UPI for quick expenses
    );

    // Add the expense
    onAddExpense(transaction);

    // Show confirmation and close
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${expense['title']} - ₹${(expense['amount'] as double).toInt()}',
        ),
        backgroundColor: const Color(0xFF00C853),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
