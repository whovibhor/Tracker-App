import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Box assetsBox;
  late Box liabilitiesBox;
  String _selectedFilter = 'All';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initHive();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initHive() async {
    assetsBox = Hive.box('assetsBox');
    liabilitiesBox = Hive.box('liabilitiesBox');
    setState(() {});
  }

  List<Transaction> get _allTransactions {
    List<Transaction> transactions = [];

    // Add all assets
    for (var i = 0; i < assetsBox.length; i++) {
      final data = assetsBox.getAt(i);
      if (data != null && data is Transaction) {
        transactions.add(data);
      }
    }

    // Add all liabilities
    for (var i = 0; i < liabilitiesBox.length; i++) {
      final data = liabilitiesBox.getAt(i);
      if (data != null && data is Transaction) {
        transactions.add(data);
      }
    }

    // Sort by date (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  List<Transaction> get _incomingTransactions {
    return _allTransactions
        .where((t) => t.type == TransactionType.asset && !t.isCompleted)
        .toList();
  }

  List<Transaction> get _outgoingTransactions {
    return _allTransactions
        .where((t) => t.type == TransactionType.liability && !t.isCompleted)
        .toList();
  }

  List<Transaction> get _settledTransactions {
    return _allTransactions.where((t) => t.isCompleted).toList();
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    var filtered = transactions;

    if (_selectedFilter != 'All') {
      filtered = filtered.where((t) => t.tag == _selectedFilter).toList();
    }

    if (_selectedDate != null) {
      filtered = filtered
          .where(
            (t) =>
                t.date.year == _selectedDate!.year &&
                t.date.month == _selectedDate!.month &&
                t.date.day == _selectedDate!.day,
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list, size: 20)),
            Tab(text: 'Incoming', icon: Icon(Icons.arrow_downward, size: 20)),
            Tab(text: 'Outgoing', icon: Icon(Icons.arrow_upward, size: 20)),
            Tab(text: 'Settled', icon: Icon(Icons.check_circle, size: 20)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Categories')),
              const PopupMenuItem(value: 'Food', child: Text('Food')),
              const PopupMenuItem(value: 'Transport', child: Text('Transport')),
              const PopupMenuItem(
                value: 'Entertainment',
                child: Text('Entertainment'),
              ),
              const PopupMenuItem(value: 'Shopping', child: Text('Shopping')),
              const PopupMenuItem(value: 'Health', child: Text('Health')),
              const PopupMenuItem(value: 'Education', child: Text('Education')),
              const PopupMenuItem(value: 'Bills', child: Text('Bills')),
              const PopupMenuItem(value: 'Loan', child: Text('Loan')),
              const PopupMenuItem(value: 'Salary', child: Text('Salary')),
              const PopupMenuItem(
                value: 'Investment',
                child: Text('Investment'),
              ),
              const PopupMenuItem(value: 'Other', child: Text('Other')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _selectedDate = null;
                });
              },
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionList(_getFilteredTransactions(_allTransactions)),
          _buildTransactionList(
            _getFilteredTransactions(_incomingTransactions),
          ),
          _buildTransactionList(
            _getFilteredTransactions(_outgoingTransactions),
          ),
          _buildTransactionList(_getFilteredTransactions(_settledTransactions)),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isIncome = transaction.type == TransactionType.asset;
    final isCompleted = transaction.isCompleted;
    final isOverdue =
        transaction.dueDate != null &&
        transaction.dueDate!.isBefore(DateTime.now()) &&
        !isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: isCompleted
              ? Colors.green[100]
              : isOverdue
              ? Colors.red[100]
              : isIncome
              ? Colors.blue[100]
              : Colors.orange[100],
          child: Icon(
            isCompleted
                ? Icons.check_circle
                : isOverdue
                ? Icons.warning
                : isIncome
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            color: isCompleted
                ? Colors.green[600]
                : isOverdue
                ? Colors.red[600]
                : isIncome
                ? Colors.blue[600]
                : Colors.orange[600],
          ),
        ),
        title: Text(
          transaction.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Category: ${transaction.tag}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            Text(
              'Date: ${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (transaction.dueDate != null) ...[
              const SizedBox(height: 2),
              Text(
                'Due: ${transaction.dueDate!.day}/${transaction.dueDate!.month}/${transaction.dueDate!.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: isOverdue ? Colors.red[600] : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isCompleted
                    ? Colors.grey[600]
                    : isIncome
                    ? Colors.green[600]
                    : Colors.red[600],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green[100]
                    : isOverdue
                    ? Colors.red[100]
                    : Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isCompleted
                    ? 'Settled'
                    : isOverdue
                    ? 'Overdue'
                    : 'Pending',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isCompleted
                      ? Colors.green[700]
                      : isOverdue
                      ? Colors.red[700]
                      : Colors.blue[700],
                ),
              ),
            ),
          ],
        ),
        onTap: () => _showTransactionDetails(transaction),
      ),
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(transaction.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              'Amount',
              '₹${transaction.amount.toStringAsFixed(2)}',
            ),
            _buildDetailRow('Category', transaction.tag),
            _buildDetailRow(
              'Type',
              transaction.type == TransactionType.asset ? 'Asset' : 'Liability',
            ),
            _buildDetailRow(
              'Date',
              '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
            ),
            if (transaction.dueDate != null)
              _buildDetailRow(
                'Due Date',
                '${transaction.dueDate!.day}/${transaction.dueDate!.month}/${transaction.dueDate!.year}',
              ),
            _buildDetailRow(
              'Status',
              transaction.isCompleted ? 'Completed' : 'Pending',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
