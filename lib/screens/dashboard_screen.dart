import 'package:flutter/material.dart';
import '../models/expense.dart';

class DashboardScreen extends StatelessWidget {
  final List<Transaction> assets;
  final List<Transaction> liabilities;
  final void Function(Transaction) onToggleCompleted;

  const DashboardScreen({
    super.key,
    required this.assets,
    required this.liabilities,
    required this.onToggleCompleted,
  });

  double get _netWorth {
    double totalAssets = assets.fold(0, (sum, asset) => sum + asset.amount);
    double totalLiabilities = liabilities.fold(
      0,
      (sum, liability) => sum + liability.amount,
    );
    return totalAssets - totalLiabilities;
  }

  List<Transaction> get _incomingCredits {
    return assets
        .where((asset) => asset.dueDate != null && !asset.isCompleted)
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  List<Transaction> get _incomingBills {
    return liabilities
        .where(
          (liability) => liability.dueDate != null && !liability.isCompleted,
        )
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  double get _totalIncomingCredits {
    return _incomingCredits.fold(0, (sum, credit) => sum + credit.amount);
  }

  double get _totalIncomingBills {
    return _incomingBills.fold(0, (sum, bill) => sum + bill.amount);
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
              'Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3A3D5C),
              ),
            ),
            SizedBox(height: 20),

            // Net Worth Card
            _buildNetWorthCard(),
            SizedBox(height: 20),

            // Incoming Bills Section
            _buildIncomingBillsSection(),
            SizedBox(height: 20),

            // Incoming Credits Section
            _buildIncomingCreditsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildNetWorthCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: _netWorth >= 0
                ? [Color(0xFFE8F5E8), Color(0xFFC8E6C9)]
                : [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              'Net Worth',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A3D5C),
              ),
            ),
            SizedBox(height: 8),
            Text(
              (_netWorth >= 0 ? '+ ₹' : '- ₹') +
                  _netWorth.abs().toStringAsFixed(2),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _netWorth >= 0 ? Color(0xFF388E3C) : Color(0xFFD32F2F),
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Assets', assets.length, Color(0xFF388E3C)),
                _buildSummaryItem(
                  'Liabilities',
                  liabilities.length,
                  Color(0xFFD32F2F),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Color(0xFF8A8D9F))),
      ],
    );
  }

  Widget _buildIncomingBillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Incoming Bills',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3A3D5C),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFFD32F2F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '₹${_totalIncomingBills.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: _incomingBills.isEmpty
              ? _buildEmptyState('No upcoming bills', Icons.receipt_long)
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _incomingBills.length,
                  itemBuilder: (context, index) {
                    final bill = _incomingBills[index];
                    return _buildBillCard(bill);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildIncomingCreditsSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Incoming Credits',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3A3D5C),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF388E3C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '₹${_totalIncomingCredits.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Expanded(
            child: _incomingCredits.isEmpty
                ? _buildEmptyState(
                    'No upcoming credits',
                    Icons.account_balance_wallet,
                  )
                : ListView.builder(
                    itemCount: _incomingCredits.length,
                    itemBuilder: (context, index) {
                      final credit = _incomingCredits[index];
                      return _buildCreditCard(credit);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard(Transaction bill) {
    return Container(
      width: 200,
      margin: EdgeInsets.only(right: 12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: bill.isOverdue ? Color(0xFFFFEBEE) : Color(0xFFFFF3E0),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    bill.isOverdue ? Icons.warning : Icons.schedule,
                    color: bill.isOverdue
                        ? Color(0xFFD32F2F)
                        : Color(0xFFFF9800),
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      bill.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Category: ${bill.tag}',
                style: TextStyle(fontSize: 10, color: Color(0xFF8A8D9F)),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                '₹${bill.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD32F2F),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                bill.isOverdue ? 'Overdue' : 'Due in ${bill.daysUntilDue} days',
                style: TextStyle(
                  fontSize: 10,
                  color: bill.isOverdue ? Color(0xFFD32F2F) : Color(0xFFFF9800),
                ),
              ),
              SizedBox(height: 4),
              GestureDetector(
                onTap: () => onToggleCompleted(bill),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Mark Paid',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditCard(Transaction credit) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: credit.isOverdue ? Color(0xFFE8F5E8) : Color(0xFFE3F2FD),
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: credit.isOverdue
              ? Color(0xFF4CAF50)
              : Color(0xFF1976D2),
          child: Icon(
            credit.isOverdue ? Icons.check_circle : Icons.schedule,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          credit.title,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${credit.tag}'),
            Text(
              credit.isOverdue
                  ? 'Overdue'
                  : 'Due in ${credit.daysUntilDue} days',
              style: TextStyle(
                color: credit.isOverdue ? Color(0xFFD32F2F) : Color(0xFF1976D2),
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
              '₹${credit.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF388E3C),
              ),
            ),
            SizedBox(height: 4),
            GestureDetector(
              onTap: () => onToggleCompleted(credit),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF388E3C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Mark Received',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Color(0xFF8A8D9F)),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Color(0xFF8A8D9F), fontSize: 16),
          ),
        ],
      ),
    );
  }
}
