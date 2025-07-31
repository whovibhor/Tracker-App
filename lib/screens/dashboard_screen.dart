import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';
import '../utils/dashboard_themes.dart';

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

  // New financial health calculations
  double get _monthlyIncome {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return assets
        .where(
          (asset) =>
              asset.date.isAfter(startOfMonth.subtract(Duration(days: 1))) &&
              asset.date.isBefore(endOfMonth.add(Duration(days: 1))) &&
              asset.isCompleted,
        )
        .fold(0.0, (sum, asset) => sum + asset.amount);
  }

  double get _monthlyExpenses {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return liabilities
        .where(
          (liability) =>
              liability.date.isAfter(
                startOfMonth.subtract(Duration(days: 1)),
              ) &&
              liability.date.isBefore(endOfMonth.add(Duration(days: 1))) &&
              liability.isCompleted,
        )
        .fold(0.0, (sum, liability) => sum + liability.amount);
  }

  double get _monthlyNetFlow {
    return _monthlyIncome - _monthlyExpenses;
  }

  double get _dailyAverageSpending {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(Duration(days: 7));

    final recentExpenses = liabilities
        .where(
          (liability) =>
              liability.date.isAfter(sevenDaysAgo) &&
              liability.date.isBefore(now.add(Duration(days: 1))) &&
              liability.isCompleted,
        )
        .fold(0.0, (sum, liability) => sum + liability.amount);

    return recentExpenses / 7;
  }

  double get _weeklyBudgetRemaining {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));

    final weeklyExpenses = liabilities
        .where(
          (liability) =>
              liability.date.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
              liability.date.isBefore(endOfWeek.add(Duration(days: 1))) &&
              liability.isCompleted,
        )
        .fold(0.0, (sum, liability) => sum + liability.amount);

    // Assuming a weekly budget of 20% of monthly income
    final estimatedWeeklyBudget = (_monthlyIncome * 0.2) / 4;
    return estimatedWeeklyBudget - weeklyExpenses;
  }

  int get _daysUntilNextPaycheck {
    // For demo purposes, assuming paycheck every 30 days
    // In real app, this would be configurable in user settings
    final now = DateTime.now();
    final nextPaycheck = DateTime(now.year, now.month + 1, 1);
    return nextPaycheck.difference(now).inDays;
  }

  DashboardLayoutTheme get _currentTheme {
    // Get theme from Hive storage or default to multiCard
    try {
      final box = Hive.box('userBox');
      final themeIndex = box.get(
        DashboardThemeHelper.dashboardThemeKey,
        defaultValue: 0,
      );
      return DashboardLayoutTheme.values[themeIndex];
    } catch (e) {
      return DashboardLayoutTheme.multiCard;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0B), // Deep black background
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16.0,
            16.0,
            16.0,
            100.0,
          ), // Added bottom padding for floating nav
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dashboard Layout based on selected theme
              _buildFinancialOverview(),
              SizedBox(height: 20),

              // Incoming Bills Section
              _buildIncomingBillsSection(),
              SizedBox(height: 20),

              // Incoming Credits Section
              _buildIncomingCreditsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialOverview() {
    switch (_currentTheme) {
      case DashboardLayoutTheme.multiCard:
        return _buildMultiCardLayout();
      case DashboardLayoutTheme.comprehensive:
        return _buildComprehensiveLayout();
      case DashboardLayoutTheme.grid:
        return _buildGridLayout();
    }
  }

  // Theme 1: Multi-Card Layout
  Widget _buildMultiCardLayout() {
    return Column(
      children: [
        // Monthly Cash Flow Card
        _buildMonthlyCashFlowCard(),
        SizedBox(height: 16),

        // Two smaller cards in a row
        Row(
          children: [
            Expanded(child: _buildWeeklyBudgetCard()),
            SizedBox(width: 12),
            Expanded(child: _buildDailyAverageCard()),
          ],
        ),
        SizedBox(height: 16),

        // Paycheck countdown banner
        _buildPaycheckCountdownBanner(),
      ],
    );
  }

  // Theme 2: Comprehensive Layout
  Widget _buildComprehensiveLayout() {
    return _buildComprehensiveCard();
  }

  // Theme 3: Grid Layout
  Widget _buildGridLayout() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMonthlyCashFlowGridCard()),
            SizedBox(width: 12),
            Expanded(child: _buildWeeklyBudgetGridCard()),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDailyAverageGridCard()),
            SizedBox(width: 12),
            Expanded(child: _buildPaycheckGridCard()),
          ],
        ),
      ],
    );
  }

  // Multi-Card Layout Components
  Widget _buildMonthlyCashFlowCard() {
    final netFlow = _monthlyNetFlow;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: netFlow >= 0 ? Color(0xFF00C853) : Color(0xFFFF1744),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (netFlow >= 0 ? Color(0xFF00C853) : Color(0xFFFF1744))
                .withValues(alpha: 0.1),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (netFlow >= 0 ? Color(0xFF00C853) : Color(0xFFFF1744))
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: netFlow >= 0 ? Color(0xFF00C853) : Color(0xFFFF1744),
                  size: 20,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Monthly Cash Flow',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Income',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  Text(
                    '₹${_monthlyIncome.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00C853),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expenses',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  Text(
                    '₹${_monthlyExpenses.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF1744),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Net Flow: ',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              Text(
                (netFlow >= 0 ? '+ ' : '- ') +
                    '₹${netFlow.abs().toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: netFlow >= 0 ? Color(0xFF00C853) : Color(0xFFFF1744),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBudgetCard() {
    final remaining = _weeklyBudgetRemaining;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: remaining >= 0 ? Color(0xFF00C853) : Color(0xFFFF6F00),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_view_week_outlined,
                color: remaining >= 0 ? Color(0xFF00C853) : Color(0xFFFF6F00),
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'Weekly Budget',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '₹${remaining.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: remaining >= 0 ? Color(0xFF00C853) : Color(0xFFFF6F00),
            ),
          ),
          Text(
            remaining >= 0 ? 'remaining' : 'over budget',
            style: TextStyle(fontSize: 10, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyAverageCard() {
    final average = _dailyAverageSpending;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF6C63FF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: Color(0xFF6C63FF),
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'Daily Average',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '₹${average.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6C63FF),
            ),
          ),
          Text(
            '(last 7 days)',
            style: TextStyle(fontSize: 10, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildPaycheckCountdownBanner() {
    final days = _daysUntilNextPaycheck;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFFF6F00), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFFF6F00).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.payments_outlined,
              color: Color(0xFFFF6F00),
              size: 18,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Paycheck',
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
                Text(
                  '$days days remaining',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF6F00),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Comprehensive Layout
  Widget _buildComprehensiveCard() {
    final netFlow = _monthlyNetFlow;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: netFlow >= 0 ? Color(0xFF00C853) : Color(0xFFFF1744),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (netFlow >= 0 ? Color(0xFF00C853) : Color(0xFFFF1744))
                .withValues(alpha: 0.1),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Health',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Flow:',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              Text(
                (netFlow >= 0 ? '+₹' : '-₹') +
                    '${netFlow.abs().toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: netFlow >= 0 ? Color(0xFF00C853) : Color(0xFFFF1744),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Income ₹${_monthlyIncome.toStringAsFixed(0)} | Expenses ₹${_monthlyExpenses.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
          SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Week Budget: ₹${_weeklyBudgetRemaining.abs().toStringAsFixed(0)} ${_weeklyBudgetRemaining >= 0 ? 'left' : 'over'}',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Daily Avg: ₹${_dailyAverageSpending.toStringAsFixed(0)} | Next Pay: ${_daysUntilNextPaycheck}d',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Grid Layout Components
  Widget _buildMonthlyCashFlowGridCard() {
    final netFlow = _monthlyNetFlow;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: netFlow >= 0 ? Color(0xFF00C853) : Color(0xFFFF1744),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                netFlow >= 0 ? Icons.trending_up : Icons.trending_down,
                color: netFlow >= 0 ? Color(0xFF00C853) : Color(0xFFFF1744),
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'Monthly',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            (netFlow >= 0 ? '+₹' : '-₹') +
                '${netFlow.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: netFlow >= 0 ? Color(0xFF00C853) : Color(0xFFFF1744),
            ),
          ),
          Text(
            'Net Flow',
            style: TextStyle(fontSize: 10, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBudgetGridCard() {
    final remaining = _weeklyBudgetRemaining;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: remaining >= 0 ? Color(0xFF00C853) : Color(0xFFFF6F00),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_view_week_outlined,
                color: remaining >= 0 ? Color(0xFF00C853) : Color(0xFFFF6F00),
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'Weekly Budget',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '₹${remaining.abs().toStringAsFixed(0)} ${remaining >= 0 ? 'left' : 'over'}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: remaining >= 0 ? Color(0xFF00C853) : Color(0xFFFF6F00),
            ),
          ),
          Text(
            '5 days left',
            style: TextStyle(fontSize: 10, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyAverageGridCard() {
    final average = _dailyAverageSpending;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF6C63FF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: Color(0xFF6C63FF),
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'Daily Avg',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '₹${average.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6C63FF),
            ),
          ),
          Text(
            '(7d trend)',
            style: TextStyle(fontSize: 10, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildPaycheckGridCard() {
    final days = _daysUntilNextPaycheck;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFFF6F00), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, color: Color(0xFFFF6F00), size: 16),
              SizedBox(width: 6),
              Text(
                'Next Paycheck',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '$days days',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF6F00),
            ),
          ),
          Text(
            '(₹45,000)',
            style: TextStyle(fontSize: 10, color: Colors.white54),
          ),
        ],
      ),
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
