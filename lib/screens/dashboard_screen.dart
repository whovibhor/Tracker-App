import 'package:flutter/material.dart';
import '../models/expense.dart';

class DashboardScreen extends StatelessWidget {
  final List<Transaction> assets;
  final List<Transaction> liabilities;
  final void Function(Transaction) onToggleCompleted;
  final VoidCallback? onNavigateToAssets;
  final VoidCallback? onNavigateToLiabilities;

  const DashboardScreen({
    super.key,
    required this.assets,
    required this.liabilities,
    required this.onToggleCompleted,
    this.onNavigateToAssets,
    this.onNavigateToLiabilities,
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
      backgroundColor: Color(0xFF0A0A0B), // Deep black background
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Net Worth Card
            _buildNetWorthCard(),
            SizedBox(height: 24),

            // Incoming Bills Section
            _buildIncomingBillsSection(),
            SizedBox(height: 24),

            // Incoming Credits Section
            _buildIncomingCreditsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildNetWorthCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _netWorth >= 0 ? Color(0xFF00C853) : Color(0xFFFF1744),
          width: 1,
          style: BorderStyle.solid,
        ),
        boxShadow: [
          BoxShadow(
            color: (_netWorth >= 0 ? Color(0xFF00C853) : Color(0xFFFF1744))
                .withValues(alpha: 0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (_netWorth >= 0 ? Color(0xFF00C853) : Color(0xFFFF1744))
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _netWorth >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: _netWorth >= 0 ? Color(0xFF00C853) : Color(0xFFFF1744),
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Net Worth',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            (_netWorth >= 0 ? '+ ₹' : '- ₹') +
                _netWorth.abs().toStringAsFixed(2),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w300,
              color: _netWorth >= 0 ? Color(0xFF00C853) : Color(0xFFFF1744),
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: 20),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Assets',
                assets.length,
                Color(0xFF00C853),
                Icons.account_balance_wallet_outlined,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              _buildSummaryItem(
                'Liabilities',
                liabilities.length,
                Color(0xFFFF1744),
                Icons.credit_card_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white54,
            fontWeight: FontWeight.w400,
          ),
        ),
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
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF1744).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFFFF1744),
                    size: 18,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Incoming Bills',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFFF1744), width: 1),
              ),
              child: Text(
                '₹${_totalIncomingBills.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Color(0xFFFF1744),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          height: 130,
          child: _incomingBills.isEmpty
              ? Center(child: _buildBillsEmptyState())
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Color(0xFF00C853).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xFF00C853),
                    size: 18,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Incoming Credits',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFF00C853), width: 1),
              ),
              child: Text(
                '₹${_totalIncomingCredits.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Color(0xFF00C853),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          height: 130,
          child: _incomingCredits.isEmpty
              ? Center(child: _buildCreditsEmptyState())
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _incomingCredits.length,
                  itemBuilder: (context, index) {
                    final credit = _incomingCredits[index];
                    return _buildCreditCard(credit);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBillCard(Transaction bill) {
    final dueDate = bill.dueDate ?? bill.date;
    final isOverdue = dueDate.isBefore(DateTime.now());
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;

    return Container(
      width: 200,
      height: 125, // Match the container height
      margin: EdgeInsets.only(right: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOverdue ? Color(0xFFFF1744) : Color(0xFFFF6F00),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isOverdue ? Color(0xFFFF1744) : Color(0xFFFF6F00))
                  .withValues(alpha: 0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: (isOverdue ? Color(0xFFFF1744) : Color(0xFFFF6F00))
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      isOverdue
                          ? Icons.warning_rounded
                          : Icons.schedule_rounded,
                      color: isOverdue ? Color(0xFFFF1744) : Color(0xFFFF6F00),
                      size: 14,
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      bill.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                bill.tag,
                style: TextStyle(fontSize: 10, color: Colors.white54),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 6),
              Text(
                '₹${bill.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF1744),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                isOverdue
                    ? 'Overdue'
                    : daysUntilDue <= 0
                    ? 'Due today'
                    : 'Due in $daysUntilDue days',
                style: TextStyle(
                  fontSize: 9,
                  color: isOverdue ? Color(0xFFFF1744) : Color(0xFFFF6F00),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: () => onToggleCompleted(bill),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF00C853),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Mark Paid',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
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

    return Container(
      width: 200,
      height: 125,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue
              ? Color(0xFFFF1744)
              : (isLoan ? Color(0xFFFF6F00) : Color(0xFF00C853)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (isOverdue
                        ? Color(0xFFFF1744)
                        : (isLoan ? Color(0xFFFF6F00) : Color(0xFF00C853)))
                    .withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                        (isOverdue
                                ? Color(0xFFFF1744)
                                : (isLoan
                                      ? Color(0xFFFF6F00)
                                      : Color(0xFF00C853)))
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isLoan
                        ? Icons.account_balance_rounded
                        : (isOverdue
                              ? Icons.warning_rounded
                              : Icons.schedule_rounded),
                    color: isOverdue
                        ? Color(0xFFFF1744)
                        : (isLoan ? Color(0xFFFF6F00) : Color(0xFF00C853)),
                    size: 16,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    credit.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '₹${credit.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: isOverdue
                    ? Color(0xFFFF1744)
                    : (isLoan ? Color(0xFFFF6F00) : Color(0xFF00C853)),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              isOverdue
                  ? 'Overdue'
                  : (daysUntilDue == 0
                        ? 'Due today'
                        : daysUntilDue == 1
                        ? 'Due tomorrow'
                        : 'Due in $daysUntilDue days'),
              style: TextStyle(
                color: isOverdue ? Color(0xFFFF1744) : Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillsEmptyState() {
    return Container(
      width: 280,
      height: 150,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFFFF1744),
          width: 1,
          style: BorderStyle.solid,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF1744).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFFF1744).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 24,
              color: Color(0xFFFF1744),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '💸 Forgot to add your bills?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          GestureDetector(
            onTap: onNavigateToLiabilities,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFFFF1744),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF1744).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Add Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsEmptyState() {
    return Container(
      width: 280,
      height: 150,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF00C853),
          width: 1,
          style: BorderStyle.solid,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF00C853).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF00C853).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 24,
              color: Color(0xFF00C853),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '🌟 Ready to grow your wealth?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          GestureDetector(
            onTap: onNavigateToAssets,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF00C853),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF00C853).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Add Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
