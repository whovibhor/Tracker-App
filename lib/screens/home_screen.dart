import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import '../models/expense.dart';
import '../models/user.dart';
import 'assets_screen.dart';
import 'liabilities_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'auth_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2; // 0: Liabilities, 1: Assets, 2: Dashboard, 3: Account
  late Box assetsBox;
  late Box liabilitiesBox;
  late Box userBox;
  bool _hiveInitialized = false;
  late PageController _pageController;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initHive();
    // Start with a high initial page to allow circular scrolling in both directions
    // Page 1000 corresponds to Dashboard (middle of 3 screens: 1000 % 3 = 1)
    _pageController = PageController(initialPage: 1000);
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
      userBox = Hive.box('userBox');

      // Load current user
      if (userBox.isNotEmpty) {
        _currentUser = userBox.getAt(0) as User?;
      }

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
        userBox = await Hive.openBox('userBox');

        // Load current user
        if (userBox.isNotEmpty) {
          _currentUser = userBox.getAt(0) as User?;
        }

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
    // If it's a loan from the assets screen, it should be added to liabilities
    if (asset.type == TransactionType.liability) {
      liabilitiesBox.add(asset);
    } else {
      assetsBox.add(asset);
    }
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

  void _saveUser(User user) {
    userBox.clear();
    userBox.add(user);
    setState(() {
      _currentUser = user;
    });
  }

  void _updateUser(User user) {
    userBox.putAt(0, user);
    setState(() {
      _currentUser = user;
    });
  }

  void _logout() {
    userBox.clear();
    setState(() {
      _currentUser = null;
    });
  }

  void _showAuthScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AuthScreen(onUserCreated: _saveUser),
      ),
    );
  }

  void _showProfileScreen() {
    if (_currentUser != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            user: _currentUser!,
            onUserUpdated: _updateUser,
            onLogout: _logout,
          ),
        ),
      );
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Handle Account screen separately (no PageView navigation)
    if (index == 3) {
      return; // Just update the state, Account screen is shown directly
    }

    // For circular navigation, calculate the target page based on current position
    final currentPage = _pageController.page?.round() ?? 1000;
    final currentScreenIndex = currentPage % 3;

    // Map logical indices to screen indices for circular navigation
    int targetScreenIndex;
    if (index == 0) {
      targetScreenIndex = 0; // Liabilities
    } else if (index == 2) {
      targetScreenIndex = 1; // Dashboard
    } else if (index == 1) {
      targetScreenIndex = 2; // Assets
    } else {
      return;
    }

    // Calculate the closest page to navigate to
    int targetPage = currentPage - currentScreenIndex + targetScreenIndex;

    _pageController.animateToPage(
      targetPage,
      duration: Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isSelected,
    bool isDestructive = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? Color(0xFF00C853).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                color: Color(0xFF00C853).withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive
              ? Color(0xFFFF1744)
              : isSelected
              ? Color(0xFF00C853)
              : Color(0xFF999999),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive
                ? Color(0xFFFF1744)
                : isSelected
                ? Color(0xFF00C853)
                : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return AppBar(
      backgroundColor: Color(0xFF1A1A1C), // Dark app bar
      elevation: 0,
      systemOverlayStyle:
          SystemUiOverlayStyle.light, // Light status bar content
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Color(0xFF0A0A0B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _netAmount >= 0 ? Color(0xFF00C853) : Color(0xFFFF1744),
            width: 1,
          ),
        ),
        child: Text(
          (_netAmount >= 0
              ? '+ ₹${_netAmount.toStringAsFixed(2)}'
              : '- ₹${_netAmount.abs().toStringAsFixed(2)}'),
          style: TextStyle(
            color: _netAmount >= 0 ? Color(0xFF00C853) : Color(0xFFFF1744),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        _currentUser != null
            ? Container(
                margin: EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color(0xFF00C853).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_circle_rounded,
                      color: Color(0xFF00C853),
                    ),
                  ),
                  onPressed: _showProfileScreen,
                ),
              )
            : Container(
                margin: EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: _showAuthScreen,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF00C853), width: 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: Color(0xFF00C853),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
      ],
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
              color: Color(0xFF1A1A1C),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Color(0xFF333333), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
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
                    icon: Icons.trending_down_outlined,
                    label: 'Liabilities',
                    selected: _selectedIndex == 0,
                    color: Color(0xFFFF1744),
                    onTap: () => _onNavTap(0),
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    selected: _selectedIndex == 2,
                    color: Color(0xFF00C853),
                    onTap: () => _onNavTap(2),
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.trending_up_outlined,
                    label: 'Assets',
                    selected: _selectedIndex == 1,
                    color: Color(0xFF00C853),
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
            color: selected ? color.withValues(alpha: 0.15) : Color(0xFF1A1A1C),
            borderRadius: BorderRadius.circular(24),
            border: selected
                ? Border.all(color: color.withValues(alpha: 0.3), width: 1)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(
                selected ? _getFilledIcon(icon) : icon,
                color: selected ? color : Color(0xFF999999),
                size: 22,
              ),
              SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : Color(0xFF999999),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
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

  IconData _getFilledIcon(IconData outlinedIcon) {
    switch (outlinedIcon) {
      case Icons.trending_down_outlined:
        return Icons.trending_down;
      case Icons.dashboard_outlined:
        return Icons.dashboard;
      case Icons.trending_up_outlined:
        return Icons.trending_up;
      default:
        return outlinedIcon;
    }
  }

  Widget _buildBody() {
    if (!_hiveInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    // If Account screen is selected, show appropriate content
    if (_selectedIndex == 3) {
      if (_currentUser != null) {
        return ProfileScreen(
          user: _currentUser!,
          onUserUpdated: _updateUser,
          onLogout: _logout,
        );
      } else {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_circle, size: 80, color: Color(0xFF8A8D9F)),
                SizedBox(height: 24),
                Text(
                  'Sign up to save your progress',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3A3D5C),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'Create an account to securely save your financial data and access it from anywhere.',
                  style: TextStyle(fontSize: 16, color: Color(0xFF8A8D9F)),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _showAuthScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Sign Up / Login',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          // Circular navigation with 3 screens (Liabilities, Dashboard, Assets)
          // Map any index to the corresponding screen using modulo
          final screenIndex = index % 3;
          if (screenIndex == 0) {
            _selectedIndex = 0; // Liabilities
          } else if (screenIndex == 1) {
            _selectedIndex = 2; // Dashboard
          } else if (screenIndex == 2) {
            _selectedIndex = 1; // Assets
          }
        });
      },
      itemBuilder: (context, index) {
        // Create infinite scrolling by repeating the 3 screens
        final screenIndex = index % 3;

        if (screenIndex == 0) {
          return LiabilitiesScreen(
            liabilities: liabilitiesBox.values.cast<Transaction>().toList(),
            onAddLiability: _addLiability,
          );
        } else if (screenIndex == 1) {
          return DashboardScreen(
            assets: assetsBox.values.cast<Transaction>().toList(),
            liabilities: liabilitiesBox.values.cast<Transaction>().toList(),
            onToggleCompleted: _toggleCompleted,
            onNavigateToAssets: () => _onNavTap(1), // Navigate to Assets
            onNavigateToLiabilities: () =>
                _onNavTap(0), // Navigate to Liabilities
          );
        } else {
          return AssetsScreen(
            assets: assetsBox.values.cast<Transaction>().toList(),
            onAddAsset: _addAsset,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Configure status bar to match app theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1A1A1C), // Dark status bar background
        statusBarIconBrightness: Brightness.light, // Light icons
        statusBarBrightness: Brightness.dark, // For iOS
      ),
    );

    return Scaffold(
      backgroundColor: Color(0xFF0A0A0B), // Black background
      drawer: Drawer(
        backgroundColor: Color(0xFF0A0A0B),
        child: Column(
          children: [
            _currentUser != null
                ? Container(
                    margin: EdgeInsets.only(
                      top: 40,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF00C853).withValues(alpha: 0.1),
                          Color(0xFF1A1A1C),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(0xFF00C853).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Color(0xFF1A1A1C),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: Color(0xFF00C853),
                              width: 2,
                            ),
                          ),
                          child:
                              _currentUser!.profilePicturePath != null &&
                                  _currentUser!.profilePicturePath!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(38),
                                  child: Image.file(
                                    File(_currentUser!.profilePicturePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Color(0xFF00C853),
                                        ),
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Color(0xFF00C853),
                                ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          _currentUser!.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _netAmount >= 0
                                ? Color(0xFF00C853).withValues(alpha: 0.1)
                                : Color(0xFFFF1744).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _netAmount >= 0
                                  ? Color(0xFF00C853)
                                  : Color(0xFFFF1744),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Net Worth: ${_netAmount >= 0 ? '+' : '-'}₹${_netAmount.abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              color: _netAmount >= 0
                                  ? Color(0xFF00C853)
                                  : Color(0xFFFF1744),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    margin: EdgeInsets.only(
                      top: 50,
                      left: 16,
                      right: 16,
                      bottom: 20,
                    ),
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A1A1C),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(0xFF00C853).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_circle_outlined,
                          size: 60,
                          color: Color(0xFF666666),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Welcome to FINLY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _showAuthScreen();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF00C853),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: ListView(
                  children: [
                    _buildDrawerItem(
                      icon: Icons.dashboard_outlined,
                      title: 'Dashboard',
                      onTap: () {
                        _onNavTap(2);
                        Navigator.pop(context);
                      },
                      isSelected: _selectedIndex == 2,
                    ),
                    _buildDrawerItem(
                      icon: Icons.trending_up_outlined,
                      title: 'Assets',
                      onTap: () {
                        _onNavTap(1);
                        Navigator.pop(context);
                      },
                      isSelected: _selectedIndex == 1,
                    ),
                    _buildDrawerItem(
                      icon: Icons.trending_down_outlined,
                      title: 'Liabilities',
                      onTap: () {
                        _onNavTap(0);
                        Navigator.pop(context);
                      },
                      isSelected: _selectedIndex == 0,
                    ),
                    _buildDrawerItem(
                      icon: Icons.history_outlined,
                      title: 'History',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HistoryScreen(),
                          ),
                        );
                      },
                      isSelected: false,
                    ),
                    Divider(color: Color(0xFF333333), thickness: 1, height: 32),
                    if (_currentUser != null)
                      _buildDrawerItem(
                        icon: Icons.person_outline,
                        title: 'Profile',
                        onTap: () {
                          Navigator.pop(context);
                          _onNavTap(3);
                        },
                        isSelected: _selectedIndex == 3,
                      ),
                    if (_currentUser != null)
                      _buildDrawerItem(
                        icon: Icons.logout_outlined,
                        title: 'Sign Out',
                        onTap: _logout,
                        isSelected: false,
                        isDestructive: true,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Builder(builder: (context) => _buildTopBar(context)),
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
