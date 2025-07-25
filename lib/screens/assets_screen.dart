import 'package:flutter/material.dart';
import '../models/expense.dart';

class AssetsScreen extends StatelessWidget {
  final List<Transaction> assets;
  final void Function(Transaction) onAddAsset;

  const AssetsScreen({Key? key, required this.assets, required this.onAddAsset})
    : super(key: key);

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
                            subtitle: Text(
                              '${asset.date.toLocal().toString().split(' ')[0]}',
                            ),
                            trailing: Text(
                              '+ ₹${asset.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Color(0xFF388E3C),
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
        backgroundColor: Color(0xFF1976D2),
        onPressed: () => _showAddAssetForm(context),
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Asset',
      ),
    );
  }
}

class _AddAssetForm extends StatefulWidget {
  final void Function(Transaction) onAdd;
  const _AddAssetForm({Key? key, required this.onAdd}) : super(key: key);

  @override
  State<_AddAssetForm> createState() => _AddAssetFormState();
}

class _AddAssetFormState extends State<_AddAssetForm> {
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
          type: TransactionType.asset,
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
              'Add Asset',
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
