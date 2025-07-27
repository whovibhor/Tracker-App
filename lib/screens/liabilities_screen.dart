import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';
import '../utils/validation.dart';
import '../widgets/swipeable_transaction_card.dart';
import 'edit_transaction_screen.dart';

class LiabilitiesScreen extends StatefulWidget {
  final List<Transaction> liabilities;
  final void Function(Transaction) onAddLiability;

  const LiabilitiesScreen({
    super.key,
    required this.liabilities,
    required this.onAddLiability,
  });

  @override
  State<LiabilitiesScreen> createState() => _LiabilitiesScreenState();
}

class _LiabilitiesScreenState extends State<LiabilitiesScreen> {
  Future<void> _toggleLiabilityCompletion(int index) async {
    try {
      final box = Hive.box('liabilitiesBox');
      final liability = widget.liabilities[index];

      final updatedLiability = Transaction(
        title: liability.title,
        amount: liability.amount,
        date: liability.date,
        type: liability.type,
        tag: liability.tag,
        dueDate: liability.dueDate,
        isCompleted: !liability.isCompleted,
      );

      await box.putAt(index, updatedLiability);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedLiability.isCompleted
                  ? 'Liability marked as paid!'
                  : 'Liability marked as pending!',
            ),
            backgroundColor: Color(0xFF00C853),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating liability: $e'),
            backgroundColor: Color(0xFFFF1744),
          ),
        );
      }
    }
  }

  void _showAddLiabilityForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _AddLiabilityForm(onAdd: widget.onAddLiability),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0B),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header section
            Container(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF1744).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.trending_down_rounded,
                      color: Color(0xFFFF1744),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Liabilities',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: widget.liabilities.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: widget.liabilities.length,
                      itemBuilder: (context, index) {
                        return _buildLiabilityCard(
                          context,
                          widget.liabilities[index],
                          index,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLiabilityForm(context),
        backgroundColor: Color(0xFFFF1744),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFFFF1744), width: 1),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFF1744).withValues(alpha: 0.1),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFFF1744).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.trending_down_rounded,
                size: 48,
                color: Color(0xFFFF1744),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No Liabilities Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start tracking your debts and bills\nto manage your finances better',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiabilityCard(
    BuildContext context,
    Transaction liability,
    int index,
  ) {
    final cardChild = Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => EditTransactionScreen(
                  transaction: liability,
                  index: index,
                  boxType: 'liabilities',
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF1744).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.trending_down_rounded,
                    color: Color(0xFFFF1744),
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        liability.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${liability.date.toLocal().toString().split(' ')[0]}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            liability.tag,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFF1744),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (liability.dueDate != null) ...[
                        SizedBox(height: 4),
                        Text(
                          liability.isOverdue
                              ? 'Overdue'
                              : 'Due in ${liability.daysUntilDue} days',
                          style: TextStyle(
                            color: liability.isOverdue
                                ? Color(0xFFFF1744)
                                : Color(0xFF00C853),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '- ₹${liability.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Color(0xFFFF1744),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (liability.dueDate != null) ...[
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: liability.isCompleted
                              ? Color(0xFF00C853)
                              : liability.isOverdue
                              ? Color(0xFFFF1744)
                              : Color(0xFF00C853).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          liability.isCompleted ? 'Paid' : 'Pending',
                          style: TextStyle(
                            color: liability.isCompleted || liability.isOverdue
                                ? Colors.white
                                : Color(0xFF00C853),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return SwipeableTransactionCard(
      transaction: liability,
      index: index,
      boxType: 'liabilities',
      onToggleComplete: () => _toggleLiabilityCompletion(index),
      child: cardChild,
    );
  }
}

class _AddLiabilityForm extends StatefulWidget {
  final void Function(Transaction) onAdd;
  const _AddLiabilityForm({required this.onAdd});

  @override
  State<_AddLiabilityForm> createState() => _AddLiabilityFormState();
}

class _AddLiabilityFormState extends State<_AddLiabilityForm> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  double _amount = 0.0;
  DateTime _selectedDate = DateTime.now();
  String _selectedTag = 'Bills';

  final List<String> _liabilityTags = [
    'Bills',
    'House Rent',
    'Food',
    'To Return',
    'Shopping',
    'Medical',
    'Travel',
    'Education',
    'Entertainment',
    'Transportation',
    'Utilities',
    'Misc',
  ];

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Sanitize inputs for security
      final sanitizedTitle = ValidationUtils.sanitizeInput(_title);
      final sanitizedTag = ValidationUtils.sanitizeTag(_selectedTag);

      // Additional validation
      if (!ValidationUtils.isValidAmount(_amount.toString())) {
        ValidationUtils.logSecurityEvent('Invalid amount', _amount.toString());
        return;
      }

      if (!ValidationUtils.isValidDate(_selectedDate)) {
        ValidationUtils.logSecurityEvent(
          'Invalid date',
          _selectedDate.toString(),
        );
        return;
      }

      widget.onAdd(
        Transaction(
          title: sanitizedTitle,
          amount: _amount,
          date: _selectedDate,
          type: TransactionType.liability,
          tag: sanitizedTag,
          dueDate:
              _selectedDate, // Use the main date as the due date for payment
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24.0,
          right: 24.0,
          top: 24.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF1744).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.trending_down_rounded,
                        color: Color(0xFFFF1744),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Add Liability',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32),
                TextFormField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color(0xFFFF1744),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color(0xFFFF1744),
                        width: 1,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color(0xFFFF1744),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Color(0xFF1A1A1C),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(
                      Icons.title_rounded,
                      color: Color(0xFFFF1744),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter a title' : null,
                  onSaved: (value) => _title = value!,
                ),
                SizedBox(height: 16),
                TextFormField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    labelStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color(0xFFFF1744),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color(0xFFFF1744),
                        width: 1,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color(0xFFFF1744),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Color(0xFF1A1A1C),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(
                      Icons.currency_rupee_rounded,
                      color: Color(0xFFFF1744),
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Enter an amount';
                    final n = double.tryParse(value);
                    if (n == null || n <= 0) return 'Enter a valid amount';
                    return null;
                  },
                  onSaved: (value) => _amount = double.parse(value!),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  style: TextStyle(color: Colors.white),
                  dropdownColor: Color(0xFF1A1A1C),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Color(0xFFFF1744),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Color(0xFF1A1A1C),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(
                      Icons.category_rounded,
                      color: Color(0xFFFF1744),
                    ),
                  ),
                  value: _selectedTag,
                  items: _liabilityTags.map((tag) {
                    return DropdownMenuItem(
                      value: tag,
                      child: Text(tag, style: TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTag = value!;
                    });
                  },
                ),
                SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1A1C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFFFF1744),
                    ),
                    title: Text(
                      'Payment Due Date',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      _selectedDate.toLocal().toString().split(' ')[0],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 16,
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: Color(0xFFFF1744),
                                onPrimary: Colors.white,
                                surface: Color(0xFF1A1A1C),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                  ),
                ),
                SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF1744),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      elevation: 0,
                    ),
                    onPressed: _submit,
                    child: Text(
                      'Add Liability',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
