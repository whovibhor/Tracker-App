// Enhanced category system for better expense tracking
import 'package:flutter/material.dart';
import 'expense.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final List<String> subcategories;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.subcategories,
  });
}

class ExpenseCategories {
  // Income Categories
  static const List<ExpenseCategory> incomeCategories = [
    ExpenseCategory(
      id: 'salary',
      name: 'Salary',
      icon: '💼',
      color: Color(0xFF4CAF50),
      subcategories: ['Monthly Salary', 'Bonus', 'Overtime', 'Commission'],
    ),
    ExpenseCategory(
      id: 'business',
      name: 'Business',
      icon: '💰',
      color: Color(0xFF2196F3),
      subcategories: ['Sales', 'Services', 'Consulting', 'Products'],
    ),
    ExpenseCategory(
      id: 'investment',
      name: 'Investment',
      icon: '📈',
      color: Color(0xFF9C27B0),
      subcategories: ['Stocks', 'Mutual Funds', 'Real Estate', 'Crypto'],
    ),
    ExpenseCategory(
      id: 'freelance',
      name: 'Freelance',
      icon: '💻',
      color: Color(0xFFFF9800),
      subcategories: ['Projects', 'Consulting', 'Content Creation', 'Design'],
    ),
    ExpenseCategory(
      id: 'other_income',
      name: 'Other Income',
      icon: '🎁',
      color: Color(0xFF607D8B),
      subcategories: ['Gift', 'Refund', 'Cashback', 'Prize', 'Rental'],
    ),
  ];

  // Expense Categories
  static const List<ExpenseCategory> expenseCategories = [
    ExpenseCategory(
      id: 'food',
      name: 'Food & Dining',
      icon: '🍕',
      color: Color(0xFFE91E63),
      subcategories: [
        'Groceries',
        'Restaurants',
        'Fast Food',
        'Coffee & Tea',
        'Snacks',
        'Alcohol',
      ],
    ),
    ExpenseCategory(
      id: 'transport',
      name: 'Transportation',
      icon: '🚗',
      color: Color(0xFF3F51B5),
      subcategories: [
        'Fuel',
        'Public Transport',
        'Taxi/Uber',
        'Parking',
        'Vehicle Maintenance',
        'Tolls',
      ],
    ),
    ExpenseCategory(
      id: 'shopping',
      name: 'Shopping',
      icon: '🛍️',
      color: Color(0xFFFF5722),
      subcategories: [
        'Clothing',
        'Electronics',
        'Home Goods',
        'Personal Care',
        'Books',
        'Gifts',
      ],
    ),
    ExpenseCategory(
      id: 'entertainment',
      name: 'Entertainment',
      icon: '🎬',
      color: Color(0xFF9C27B0),
      subcategories: [
        'Movies',
        'Games',
        'Streaming Services',
        'Concerts',
        'Sports',
        'Hobbies',
      ],
    ),
    ExpenseCategory(
      id: 'bills',
      name: 'Bills & Utilities',
      icon: '📄',
      color: Color(0xFF795548),
      subcategories: [
        'Electricity',
        'Water',
        'Gas',
        'Internet',
        'Phone',
        'Insurance',
        'Rent',
      ],
    ),
    ExpenseCategory(
      id: 'health',
      name: 'Health & Fitness',
      icon: '🏥',
      color: Color(0xFF4CAF50),
      subcategories: [
        'Doctor Visits',
        'Medicines',
        'Gym',
        'Health Insurance',
        'Dental',
        'Wellness',
      ],
    ),
    ExpenseCategory(
      id: 'education',
      name: 'Education',
      icon: '📚',
      color: Color(0xFF2196F3),
      subcategories: [
        'Courses',
        'Books',
        'Online Learning',
        'Workshops',
        'Certifications',
        'School Fees',
      ],
    ),
    ExpenseCategory(
      id: 'travel',
      name: 'Travel',
      icon: '✈️',
      color: Color(0xFF00BCD4),
      subcategories: [
        'Flights',
        'Hotels',
        'Vacation',
        'Business Travel',
        'Local Travel',
        'Travel Insurance',
      ],
    ),
    ExpenseCategory(
      id: 'family',
      name: 'Family & Personal',
      icon: '👨‍👩‍👧‍👦',
      color: Color(0xFFE91E63),
      subcategories: [
        'Childcare',
        'Pet Care',
        'Personal Grooming',
        'Family Events',
        'Donations',
        'Subscriptions',
      ],
    ),
    ExpenseCategory(
      id: 'other_expense',
      name: 'Other Expenses',
      icon: '📦',
      color: Color(0xFF9E9E9E),
      subcategories: [
        'Miscellaneous',
        'Fees',
        'Fines',
        'Repairs',
        'Emergency',
        'Other',
      ],
    ),
  ];

  // Payment Methods
  static const List<PaymentMethod> paymentMethods = [
    PaymentMethod(
      id: 'cash',
      name: 'Cash',
      icon: '💵',
      color: Color(0xFF4CAF50),
    ),
    PaymentMethod(
      id: 'credit_card',
      name: 'Credit Card',
      icon: '💳',
      color: Color(0xFFFF9800),
    ),
    PaymentMethod(
      id: 'debit_card',
      name: 'Debit Card',
      icon: '💳',
      color: Color(0xFF2196F3),
    ),
    PaymentMethod(id: 'upi', name: 'UPI', icon: '📱', color: Color(0xFF9C27B0)),
    PaymentMethod(
      id: 'bank_transfer',
      name: 'Bank Transfer',
      icon: '🏦',
      color: Color(0xFF607D8B),
    ),
    PaymentMethod(
      id: 'digital_wallet',
      name: 'Digital Wallet',
      icon: '📲',
      color: Color(0xFFE91E63),
    ),
  ];

  // Helper methods
  static ExpenseCategory? getCategoryById(String id, TransactionType type) {
    final categories = type == TransactionType.asset
        ? incomeCategories
        : expenseCategories;
    return categories.where((cat) => cat.id == id).firstOrNull;
  }

  static List<String> getSubcategories(
    String categoryId,
    TransactionType type,
  ) {
    final category = getCategoryById(categoryId, type);
    return category?.subcategories ?? [];
  }

  static PaymentMethod? getPaymentMethodById(String id) {
    return paymentMethods.where((method) => method.id == id).firstOrNull;
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final String icon;
  final Color color;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

// Frequently used combinations for quick add
class FrequentExpenses {
  static const List<Map<String, dynamic>> common = [
    {
      'title': 'Coffee',
      'category': 'food',
      'subcategory': 'Coffee & Tea',
      'amount': 50.0,
      'paymentMethod': 'upi',
    },
    {
      'title': 'Lunch',
      'category': 'food',
      'subcategory': 'Restaurants',
      'amount': 150.0,
      'paymentMethod': 'upi',
    },
    {
      'title': 'Auto/Taxi',
      'category': 'transport',
      'subcategory': 'Taxi/Uber',
      'amount': 80.0,
      'paymentMethod': 'upi',
    },
    {
      'title': 'Groceries',
      'category': 'food',
      'subcategory': 'Groceries',
      'amount': 500.0,
      'paymentMethod': 'cash',
    },
    {
      'title': 'Fuel',
      'category': 'transport',
      'subcategory': 'Fuel',
      'amount': 1000.0,
      'paymentMethod': 'credit_card',
    },
  ];
}
