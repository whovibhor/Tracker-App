import 'package:flutter/material.dart';
import '../models/expense.dart';

class LiabilitiesScreen extends StatelessWidget {
  final List<Transaction> liabilities;
  final void Function(Transaction) onAddLiability;

  const LiabilitiesScreen({
    Key? key,
    required this.liabilities,
    required this.onAddLiability,
  }) : super(key: key);

  void _showAddLiabilityForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddLiabilityForm(onAdd: onAddLiability),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDF6F6),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Liabilities',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5C3A3A),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: liabilities.isEmpty
                  ? Center(
                      child: Text(
                        'No liabilities added yet!',
                        style: TextStyle(color: Color(0xFF9F8A8A)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: liabilities.length,
                      itemBuilder: (context, index) {
                        final liability = liabilities[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          color: Color(0xFFFFEBEE),
                          elevation: 3,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color(0xFFEF9A9A),
                              child: Icon(
                                Icons.trending_down,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              liability.title,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${liability.date.toLocal().toString().split(' ')[0]}',
                            ),
                            trailing: Text(
                              '- ₹${liability.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Color(0xFFD32F2F),
                                fontWeight: FontWeight.bold,
                              ),
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
        backgroundColor: Color(0xFFD32F2F),
        onPressed: () => _showAddLiabilityForm(context),
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Liability',
      ),
    );
  }
}

class _AddLiabilityForm extends StatefulWidget {
  final void Function(Transaction) onAdd;
  const _AddLiabilityForm({Key? key, required this.onAdd}) : super(key: key);

  @override
  State<_AddLiabilityForm> createState() => _AddLiabilityFormState();
}

class _AddLiabilityFormState extends State<_AddLiabilityForm> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  double _amount = 0.0;
  DateTime _selectedDate = DateTime.now();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onAdd(
        Transaction(
          title: _title,
          amount: _amount,
          date: _selectedDate,
          type: TransactionType.liability,
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
              'Add Liability',
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
                prefixIcon: Icon(Icons.money_off),
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
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD32F2F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: _submit,
              child: Text('Add Liability', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
