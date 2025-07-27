import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';
import '../utils/validation.dart';
import '../widgets/swipeable_transaction_card.dart';
import 'edit_transaction_screen.dart';

class AssetsScreen extends StatefulWidget {
  final List<Transaction> assets;
  final void Function(Transaction) onAddAsset;

  const AssetsScreen({
    super.key,
    required this.assets,
    required this.onAddAsset,
  }) : super();

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  Future<void> _toggleAssetCompletion(int index) async {
    try {
      final box = Hive.box('assetsBox');
      final asset = widget.assets[index];

      final updatedAsset = Transaction(
        title: asset.title,
        amount: asset.amount,
        date: asset.date,
        type: asset.type,
        tag: asset.tag,
        dueDate: asset.dueDate,
        isCompleted: !asset.isCompleted,
      );

      await box.putAt(index, updatedAsset);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedAsset.isCompleted
                  ? 'Asset marked as received!'
                  : 'Asset marked as pending!',
            ),
            backgroundColor: Color(0xFF00C853),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating asset: $e'),
            backgroundColor: Color(0xFFFF1744),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0B), // Dashboard black background
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF00C853).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.trending_up_outlined,
                    color: Color(0xFF00C853),
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Assets',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Expanded(
              child: widget.assets.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: widget.assets.length,
                      itemBuilder: (context, index) {
                        final asset = widget.assets[index];
                        return _buildAssetCard(context, asset, index);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAssetForm(context),
        backgroundColor: Color(0xFF00C853),
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
          border: Border.all(color: Color(0xFF00C853), width: 1),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF00C853).withValues(alpha: 0.1),
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
                color: Color(0xFF00C853).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: Color(0xFF00C853),
              ),
            ),
            SizedBox(height: 20),
            Text(
              '🌟 Start Building Your Wealth!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Add your first asset and watch your financial portfolio grow.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetCard(BuildContext context, Transaction asset, int index) {
    final cardChild = Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: asset.isOverdue ? Color(0xFFFF1744) : Color(0xFF00C853),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (asset.isOverdue ? Color(0xFFFF1744) : Color(0xFF00C853))
                .withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: () async {
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => EditTransactionScreen(
                transaction: asset,
                index: index,
                boxType: 'assets',
              ),
            ),
          );
        },
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (asset.isOverdue ? Color(0xFFFF1744) : Color(0xFF00C853))
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.trending_up_rounded,
            color: asset.isOverdue ? Color(0xFFFF1744) : Color(0xFF00C853),
            size: 20,
          ),
        ),
        title: Text(
          asset.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              '${asset.date.toLocal().toString().split(' ')[0]} • ${asset.tag}',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            if (asset.dueDate != null) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (asset.isOverdue ? Color(0xFFFF1744) : Color(0xFF00C853))
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: asset.isOverdue
                        ? Color(0xFFFF1744)
                        : Color(0xFF00C853),
                    width: 1,
                  ),
                ),
                child: Text(
                  asset.isOverdue
                      ? 'Overdue'
                      : 'Due in ${asset.daysUntilDue} days',
                  style: TextStyle(
                    color: asset.isOverdue
                        ? Color(0xFFFF1744)
                        : Color(0xFF00C853),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
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
              '+ ₹${asset.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: Color(0xFF00C853),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            if (asset.dueDate != null) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: asset.isCompleted
                      ? Color(0xFF00C853)
                      : asset.isOverdue
                      ? Color(0xFFFF1744)
                      : Color(0xFF00C853).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  asset.isCompleted ? 'Received' : 'Pending',
                  style: TextStyle(
                    color: asset.isCompleted || asset.isOverdue
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
      ),
    );

    return SwipeableTransactionCard(
      transaction: asset,
      index: index,
      boxType: 'assets',
      onToggleComplete: () => _toggleAssetCompletion(index),
      child: cardChild,
    );
  }

  void _showAddAssetForm(BuildContext context) {
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
        child: _AddAssetForm(onAdd: widget.onAddAsset),
      ),
    );
  }
}

class _AddAssetForm extends StatefulWidget {
  final void Function(Transaction) onAdd;
  const _AddAssetForm({required this.onAdd});

  @override
  State<_AddAssetForm> createState() => _AddAssetFormState();
}

class _AddAssetFormState extends State<_AddAssetForm> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  double _amount = 0.0;
  DateTime _selectedDate = DateTime.now();
  String _selectedTag = 'Pocket Money';
  DateTime? _dueDate;

  final List<String> _assetTags = [
    'Pocket Money',
    'Loan', // This will be treated as incoming credit (liability)
    'Profits',
    'Random Money I Get',
    'Salary',
    'Investment Return',
    'Gift',
    'Other',
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
          type: sanitizedTag == 'Loan'
              ? TransactionType.liability
              : TransactionType.asset,
          tag: sanitizedTag,
          dueDate: sanitizedTag == 'Loan' ? _dueDate : null,
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
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF00C853).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.trending_up_outlined,
                        color: Color(0xFF00C853),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      _selectedTag == 'Loan'
                          ? 'Add Incoming Credit'
                          : 'Add Asset',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                TextFormField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF333333)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF333333)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF00C853)),
                    ),
                    prefixIcon: Icon(Icons.title, color: Color(0xFF00C853)),
                    filled: true,
                    fillColor: Color(0xFF0A0A0B),
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
                    labelStyle: TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF333333)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF333333)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF00C853)),
                    ),
                    prefixIcon: Icon(
                      Icons.attach_money,
                      color: Color(0xFF00C853),
                    ),
                    filled: true,
                    fillColor: Color(0xFF0A0A0B),
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
                    labelStyle: TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF333333)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF333333)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF00C853)),
                    ),
                    prefixIcon: Icon(Icons.category, color: Color(0xFF00C853)),
                    filled: true,
                    fillColor: Color(0xFF0A0A0B),
                  ),
                  value: _selectedTag,
                  items: _assetTags.map((tag) {
                    return DropdownMenuItem(value: tag, child: Text(tag));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTag = value!;
                      // Reset due date when changing from/to loan
                      if (_selectedTag != 'Loan') {
                        _dueDate = null;
                      }
                    });
                  },
                ),
                if (_selectedTag == 'Loan')
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF6F00).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFFF6F00), width: 1),
                      ),
                      child: Text(
                        'Note: Loans will be treated as liabilities (money you owe)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFF6F00),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF0A0A0B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF333333)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Color(0xFF00C853),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Date: ${_selectedDate.toLocal().toString().split(' ')[0]}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary: Color(0xFF00C853),
                                    surface: Color(0xFF1A1A1C),
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
                        child: Text(
                          'Select Date',
                          style: TextStyle(color: Color(0xFF00C853)),
                        ),
                      ),
                    ],
                  ),
                ),
                // Only show due date for Loan tag (incoming credit)
                if (_selectedTag == 'Loan') ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF0A0A0B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFF333333)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: Color(0xFFFF6F00),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Repayment Due: ${_dueDate?.toLocal().toString().split(' ')[0] ?? 'Not set'}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  _dueDate ??
                                  DateTime.now().add(Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.dark(
                                      primary: Color(0xFFFF6F00),
                                      surface: Color(0xFF1A1A1C),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() => _dueDate = picked);
                            }
                          },
                          child: Text(
                            'Select Due Date',
                            style: TextStyle(color: Color(0xFFFF6F00)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00C853),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    onPressed: _submit,
                    child: Text(
                      'Add Asset',
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
