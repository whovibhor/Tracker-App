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
    List<Transaction> incomingCredits = [];

    // Add future-dated assets (money coming in)
    incomingCredits.addAll(
      assets
          .where(
            (asset) =>
                asset.date.isAfter(DateTime.now()) ||
                (asset.dueDate != null &&
                    asset.dueDate!.isAfter(DateTime.now())),
          )
          .where((asset) => !asset.isCompleted),
    );

    // Add loans with due dates from liabilities (these are incoming credits to be repaid)
    incomingCredits.addAll(
      liabilities.where(
        (liability) =>
            liability.tag == 'Loan' &&
            liability.dueDate != null &&
            liability.dueDate!.isAfter(DateTime.now()) &&
            !liability.isCompleted,
      ),
    );

    // Sort by due date
    incomingCredits.sort((a, b) {
      final aDate = a.dueDate ?? a.date;
      final bDate = b.dueDate ?? b.date;
      return aDate.compareTo(bDate);
    });

    return incomingCredits;
  }

  List<Transaction> get _incomingBills {
    return liabilities
        .where(
          (liability) =>
              liability.tag !=
                  'Loan' && // Exclude loans as they're handled in credits
              liability.dueDate != null &&
              !liability.isCompleted &&
              liability.dueDate!.isAfter(
                DateTime.now().subtract(Duration(days: 30)),
              ), // Include overdue bills up to 30 days
        )
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  double get _totalIncomingCredits {
    return _incomingCredits.fold(0, (sum, credit) {
      // For loans, we're expecting to receive back, so it's positive
      // For regular assets, it's also positive income
      return sum + credit.amount;
    });
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
    final dueDate = bill.dueDate ?? bill.date;
    final isOverdue = dueDate.isBefore(DateTime.now());
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;

    return Container(
      width: 200,
      height: 145, // Increased height to prevent overflow
      margin: EdgeInsets.only(right: 12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isOverdue ? Color(0xFFFFEBEE) : Color(0xFFFFF3E0),
        child: Padding(
          padding: EdgeInsets.all(6), // Further reduced padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Important for overflow prevention
            children: [
              Row(
                children: [
                  Icon(
                    isOverdue ? Icons.warning : Icons.schedule,
                    color: isOverdue ? Color(0xFFD32F2F) : Color(0xFFFF9800),
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
              SizedBox(height: 2), // Reduced spacing
              Text(
                'Category: ${bill.tag}',
                style: TextStyle(fontSize: 10, color: Color(0xFF8A8D9F)),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2), // Reduced spacing
              Text(
                '₹${bill.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD32F2F),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 2), // Reduced spacing
              Text(
                isOverdue
                    ? 'Overdue'
                    : daysUntilDue <= 0
                    ? 'Due today'
                    : 'Due in $daysUntilDue days',
                style: TextStyle(
                  fontSize: 10,
                  color: isOverdue ? Color(0xFFD32F2F) : Color(0xFFFF9800),
                ),
              ),
              Spacer(), // Push button to bottom
              GestureDetector(
                onTap: () => onToggleCompleted(bill),
                child: Container(
                  width: double.infinity, // Full width
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Mark Paid',
                    textAlign: TextAlign.center, // Center the text
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
    final isLoan = credit.tag == 'Loan';
    final dueDate = credit.dueDate ?? credit.date;
    final isOverdue = dueDate.isBefore(DateTime.now());
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isOverdue
          ? Color(0xFFFFEBEE)
          : (isLoan ? Color(0xFFFFF3E0) : Color(0xFFE3F2FD)),
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOverdue
              ? Color(0xFFD32F2F)
              : (isLoan ? Color(0xFFFF9800) : Color(0xFF1976D2)),
          child: Icon(
            isLoan
                ? Icons.account_balance
                : (isOverdue ? Icons.warning : Icons.schedule),
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
            Text('Type: ${isLoan ? "Loan Repayment" : credit.tag}'),
            Text(
              isOverdue
                  ? 'Overdue'
                  : daysUntilDue <= 0
                  ? 'Due today'
                  : 'Due in $daysUntilDue days',
              style: TextStyle(
                color: isOverdue ? Color(0xFFD32F2F) : Color(0xFF1976D2),
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
              '+ ₹${credit.amount.toStringAsFixed(2)}',
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
                  isLoan ? 'Mark Repaid' : 'Mark Received',
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
