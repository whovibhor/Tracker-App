import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import 'assets_screen.dart';
import 'liabilities_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2; // 0: Liabilities, 1: Assets, 2: Dashboard, 3: Account
  late Box assetsBox;
  late Box liabilitiesBox;
  bool _hiveInitialized = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _initHive();
    _pageController = PageController(initialPage: 2);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initHive() async {
    try {
      assetsBox = Hive.box('assetsBox');
      liabilitiesBox = Hive.box('liabilitiesBox');
      setState(() {
        _hiveInitialized = true;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error accessing Hive boxes: $e');
      }
      // Fallback: try to open boxes if they don't exist
      try {
        assetsBox = await Hive.openBox('assetsBox');
        liabilitiesBox = await Hive.openBox('liabilitiesBox');
        setState(() {
          _hiveInitialized = true;
        });
      } catch (e2) {
        if (kDebugMode) {
          debugPrint('Error opening Hive boxes: $e2');
        }
      }
    }
  }

  void _addAsset(Transaction asset) {
    assetsBox.add(asset);
    setState(() {});
  }

  void _addLiability(Transaction liability) {
    liabilitiesBox.add(liability);
    setState(() {});
  }

  void _toggleCompleted(Transaction transaction) {
    final box = transaction.type == TransactionType.asset
        ? assetsBox
        : liabilitiesBox;
    final index = box.values.toList().indexOf(transaction);
    if (index != -1) {
      final updatedTransaction = Transaction(
        title: transaction.title,
        amount: transaction.amount,
        date: transaction.date,
        type: transaction.type,
        tag: transaction.tag,
        dueDate: transaction.dueDate,
        isCompleted: !transaction.isCompleted,
      );
      box.putAt(index, updatedTransaction);
      setState(() {});
    }
  }

  double get _netAmount {
    double assets = 0;
    double liabilities = 0;
    if (_hiveInitialized) {
      for (var t in assetsBox.values) {
        assets += (t as Transaction).amount;
      }
      for (var t in liabilitiesBox.values) {
        liabilities += (t as Transaction).amount;
      }
    }
    return assets - liabilities;
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildTopBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 2,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Hamburger menu
          IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          // App title and net amount
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Finly',
                  style: TextStyle(
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  (_netAmount >= 0
                      ? '+ ₹${_netAmount.toStringAsFixed(2)}'
                      : '- ₹${_netAmount.abs().toStringAsFixed(2)}'),
                  style: TextStyle(
                    color: _netAmount >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          // Account button
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.black),
            onPressed: () {
              setState(() {
                _selectedIndex = 3;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = MediaQuery.of(context).size.width * 0.9;
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: width,
            margin: const EdgeInsets.only(bottom: 28),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.money_off,
                    label: 'Liabilities',
                    selected: _selectedIndex == 0,
                    color: Colors.red,
                    onTap: () => _onNavTap(0),
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    selected: _selectedIndex == 2,
                    color: Colors.blue,
                    onTap: () => _onNavTap(2),
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.account_balance_wallet,
                    label: 'Assets',
                    selected: _selectedIndex == 1,
                    color: Colors.green,
                    onTap: () => _onNavTap(1),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          height: 50,
          width: 120,
          padding: EdgeInsets.symmetric(vertical: 3.5, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(icon, color: color, size: 22),
              SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_hiveInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      children: [
        LiabilitiesScreen(
          liabilities: liabilitiesBox.values.cast<Transaction>().toList(),
          onAddLiability: _addLiability,
        ),
        AssetsScreen(
          assets: assetsBox.values.cast<Transaction>().toList(),
          onAddAsset: _addAsset,
        ),
        DashboardScreen(
          assets: assetsBox.values.cast<Transaction>().toList(),
          liabilities: liabilitiesBox.values.cast<Transaction>().toList(),
          onToggleCompleted: _toggleCompleted,
        ),
        Center(child: Text('Account Screen')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),

              onTap: () {
                _onNavTap(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.account_balance_wallet),

              onTap: () {
                _onNavTap(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.money_off),

              onTap: () {
                _onNavTap(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Account'),
              onTap: () {
                _onNavTap(3);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Builder(builder: (context) => _buildTopBar()),
      ),
      body: _buildBody(),
      bottomNavigationBar: SizedBox(
        height: 100,
        child: SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: true,
          child: Stack(children: [_buildBottomNav()]),
        ),
      ),
    );
  }
}
