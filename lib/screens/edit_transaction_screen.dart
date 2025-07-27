import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';
import '../utils/validation.dart';

class EditTransactionScreen extends StatefulWidget {
  final Transaction transaction;
  final int index;
  final String boxType; // 'assets' or 'liabilities'

  const EditTransactionScreen({
    super.key,
    required this.transaction,
    required this.index,
    required this.boxType,
  });

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  DateTime? _selectedDueDate;
  late String _selectedTag;
  late bool _isCompleted;

  final List<String> _assetTags = [
    'Salary',
    'Investment',
    'Business',
    'Freelance',
    'Gift',
    'Loan',
    'Rental Income',
    'Bonus',
    'Other',
  ];

  final List<String> _liabilityTags = [
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Health',
    'Education',
    'Bills',
    'Loan',
    'Rent',
    'Insurance',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.transaction.title);
    _amountController = TextEditingController(
      text: widget.transaction.amount.toString(),
    );
    _selectedDate = widget.transaction.date;
    _selectedDueDate = widget.transaction.dueDate;

    // Ensure the selected tag is valid for the current box type
    final availableTags = widget.boxType == 'assets'
        ? _assetTags
        : _liabilityTags;
    _selectedTag = availableTags.contains(widget.transaction.tag)
        ? widget.transaction.tag
        : availableTags.first;

    _isCompleted = widget.transaction.isCompleted;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  List<String> get _availableTags {
    return widget.boxType == 'assets' ? _assetTags : _liabilityTags;
  }

  Future<void> _updateTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final amount = double.parse(_amountController.text);

      if (!ValidationUtils.isValidAmount(_amountController.text)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid amount')),
          );
        }
        return;
      }

      final sanitizedTitle = ValidationUtils.sanitizeInput(
        _titleController.text,
      );
      if (sanitizedTitle != _titleController.text) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Title contains invalid characters')),
          );
        }
        return;
      }

      final updatedTransaction = Transaction(
        title: sanitizedTitle,
        amount: amount,
        date: _selectedDate,
        type: widget.transaction.type,
        tag: _selectedTag,
        dueDate: _selectedDueDate,
        isCompleted: _isCompleted,
      );

      final box = widget.boxType == 'assets'
          ? Hive.box('assetsBox')
          : Hive.box('liabilitiesBox');

      await box.putAt(widget.index, updatedTransaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction updated successfully!')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating transaction: $e')),
        );
      }
    }
  }

  Future<void> _deleteTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Transaction',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
          style: TextStyle(color: Color(0xFF999999)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: Color(0xFF999999)),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Color(0xFFFF1744)),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final box = widget.boxType == 'assets'
            ? Hive.box('assetsBox')
            : Hive.box('liabilitiesBox');

        await box.deleteAt(widget.index);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted successfully!')),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting transaction: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0B), // Black background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF1A1A1C),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Transaction',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: Color(0xFFFF1744)),
            onPressed: _deleteTransaction,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              // Transaction Details Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFF333333), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF00C853),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Transaction Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Title Field
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(color: Color(0xFF999999)),
                        filled: true,
                        fillColor: Color(0xFF0A0A0B),
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
                        prefixIcon: Icon(Icons.title, color: Color(0xFF999999)),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        if (value.trim().length < 3) {
                          return 'Title must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        labelStyle: TextStyle(color: Color(0xFF999999)),
                        filled: true,
                        fillColor: Color(0xFF0A0A0B),
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
                          Icons.currency_rupee,
                          color: Color(0xFF999999),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (!ValidationUtils.isValidAmount(value)) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedTag,
                      style: TextStyle(color: Colors.white),
                      dropdownColor: Color(0xFF1A1A1C),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: Color(0xFF999999)),
                        filled: true,
                        fillColor: Color(0xFF0A0A0B),
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
                          Icons.category,
                          color: Color(0xFF999999),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      items: _availableTags.map((tag) {
                        return DropdownMenuItem(
                          value: tag,
                          child: Text(
                            tag,
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTag = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Dates Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFF333333), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.date_range_outlined,
                          color: Color(0xFF00C853),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Dates',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Transaction Date
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(Duration(days: 365)),
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
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF0A0A0B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFF333333)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.date_range, color: Color(0xFF999999)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Transaction Date',
                                    style: TextStyle(
                                      color: Color(0xFF999999),
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.edit,
                              color: Color(0xFF00C853),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Due Date (if applicable)
                    if (widget.boxType == 'liabilities' ||
                        _selectedTag == 'Loan') ...[
                      SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDueDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 3650)),
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
                          if (date != null) {
                            setState(() {
                              _selectedDueDate = date;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFF0A0A0B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Color(0xFF333333)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.event, color: Color(0xFF999999)),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Due Date',
                                      style: TextStyle(
                                        color: Color(0xFF999999),
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _selectedDueDate != null
                                          ? '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}'
                                          : 'Not set',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_selectedDueDate != null)
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedDueDate = null;
                                    });
                                  },
                                  child: Icon(
                                    Icons.clear,
                                    color: Color(0xFFFF1744),
                                    size: 18,
                                  ),
                                )
                              else
                                Icon(
                                  Icons.edit,
                                  color: Color(0xFF00C853),
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Status Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFF333333), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.task_alt_outlined,
                          color: Color(0xFF00C853),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Status',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
                            _isCompleted ? Icons.check_circle : Icons.schedule,
                            color: _isCompleted
                                ? Color(0xFF00C853)
                                : Color(0xFF999999),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Completed',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _isCompleted
                                      ? 'This transaction has been settled'
                                      : 'This transaction is pending',
                                  style: TextStyle(
                                    color: Color(0xFF999999),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isCompleted,
                            onChanged: (value) {
                              setState(() {
                                _isCompleted = value;
                              });
                            },
                            activeColor: Color(0xFF00C853),
                            activeTrackColor: Color(
                              0xFF00C853,
                            ).withValues(alpha: 0.3),
                            inactiveThumbColor: Color(0xFF666666),
                            inactiveTrackColor: Color(0xFF333333),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Update Button
              Container(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _updateTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00C853),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Update Transaction',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
