import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../utils/validation.dart';
import 'edit_transaction_screen.dart';

class AssetsScreen extends StatelessWidget {
  final List<Transaction> assets;
  final void Function(Transaction) onAddAsset;

  const AssetsScreen({
    super.key,
    required this.assets,
    required this.onAddAsset,
  }) : super();

  void _showAddAssetForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddAssetForm(onAdd: onAddAsset),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F8FB),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Assets',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3A3D5C),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: assets.isEmpty
                  ? Center(
                      child: Text(
                        'No assets added yet!',
                        style: TextStyle(color: Color(0xFF8A8D9F)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: assets.length,
                      itemBuilder: (context, index) {
                        final asset = assets[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          color: Color(0xFFE3F2FD),
                          elevation: 3,
                          margin: EdgeInsets.symmetric(vertical: 8),
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
                              // No need to refresh as Hive will automatically update the UI
                            },
                            leading: CircleAvatar(
                              backgroundColor: Color(0xFF90CAF9),
                              child: Icon(
                                Icons.trending_up,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              asset.title,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${asset.date.toLocal().toString().split(' ')[0]} • ${asset.tag}',
                                ),
                                if (asset.dueDate != null)
                                  Text(
                                    asset.isOverdue
                                        ? 'Overdue'
                                        : 'Due in ${asset.daysUntilDue} days',
                                    style: TextStyle(
                                      color: asset.isOverdue
                                          ? Color(0xFFD32F2F)
                                          : Color(0xFF1976D2),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '+ ₹${asset.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Color(0xFF388E3C),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (asset.dueDate != null)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: asset.isCompleted
                                          ? Color(0xFF4CAF50)
                                          : asset.isOverdue
                                          ? Color(0xFFD32F2F)
                                          : Color(0xFF1976D2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      asset.isCompleted
                                          ? 'Received'
                                          : 'Pending',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF1976D2),
        onPressed: () => _showAddAssetForm(context),
        tooltip: 'Add Asset',
        child: Icon(Icons.add, color: Colors.white),
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedTag == 'Loan' ? 'Add Incoming Credit' : 'Add Asset',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter a title' : null,
              onSaved: (value) => _title = value!,
            ),
            SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter an amount';
                final n = double.tryParse(value);
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
              onSaved: (value) => _amount = double.parse(value!),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.category),
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
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Note: Loans will be treated as liabilities (money you owe)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Date: ${_selectedDate.toLocal().toString().split(' ')[0]}',
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: Text('Select Date'),
                ),
              ],
            ),
            SizedBox(height: 12),
            // Only show due date for Loan tag (incoming credit)
            if (_selectedTag == 'Loan') ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Repayment Due: ${_dueDate?.toLocal().toString().split(' ')[0] ?? 'Not set'}',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            _dueDate ?? DateTime.now().add(Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _dueDate = picked);
                      }
                    },
                    child: Text('Select Due Date'),
                  ),
                ],
              ),
              SizedBox(height: 12),
            ],
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1976D2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: _submit,
              child: Text('Add Asset', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
