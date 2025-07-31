import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import '../models/expense.dart';
import '../models/user.dart';
import '../utils/dashboard_themes.dart';
import '../widgets/quick_add_expense_widget.dart';
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
  int _selectedIndex = 2; // 0: Expenses, 1: Income, 2: Dashboard, 3: Account
  late Box assetsBox;
  late Box liabilitiesBox;
  late Box userBox;
  bool _hiveInitialized = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    try {
      assetsBox = Hive.box('assetsBox');
      liabilitiesBox = Hive.box('liabilitiesBox');
      userBox = Hive.box('userBox');

      // Load current user safely
      if (userBox.isNotEmpty) {
        try {
          final userData = userBox.getAt(0);
          if (userData is User) {
            _currentUser = userData;
          } else {
            // Clear invalid data and set to null
            userBox.clear();
            _currentUser = null;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error loading user data: $e');
          }
          userBox.clear();
          _currentUser = null;
        }
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

        // Load current user safely
        if (userBox.isNotEmpty) {
          try {
            final userData = userBox.getAt(0);
            if (userData is User) {
              _currentUser = userData;
            } else {
              // Clear invalid data and set to null
              userBox.clear();
              _currentUser = null;
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error loading user data: $e');
            }
            userBox.clear();
            _currentUser = null;
          }
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
    _refreshAppState();
  }

  void _addLiability(Transaction liability) {
    liabilitiesBox.add(liability);
    _refreshAppState();
  }

  // Force refresh the entire app state to ensure data synchronization
  void _refreshAppState() {
    if (mounted) {
      setState(() {
        // This will trigger a rebuild of all widgets that depend on the data
      });
    }
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
      _refreshAppState();
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

  void _showDashboardSettings(BuildContext context) {
    // Get current theme
    final currentThemeIndex = userBox.get(
      DashboardThemeHelper.dashboardThemeKey,
      defaultValue: 0,
    );
    DashboardLayoutTheme selectedTheme =
        DashboardLayoutTheme.values[currentThemeIndex];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Color(0xFF1A1A1C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Dashboard Layout',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Theme selection
                  ...DashboardLayoutTheme.values.map((theme) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: selectedTheme == theme
                            ? Color(0xFF00C853).withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: selectedTheme == theme
                            ? Border.all(color: Color(0xFF00C853), width: 1)
                            : Border.all(color: Color(0xFF333333), width: 1),
                      ),
                      child: RadioListTile<DashboardLayoutTheme>(
                        title: Text(
                          DashboardThemeHelper.getThemeName(theme),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: selectedTheme == theme
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          DashboardThemeHelper.getThemeDescription(theme),
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        value: theme,
                        groupValue: selectedTheme,
                        onChanged: (DashboardLayoutTheme? value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedTheme = value;
                            });
                          }
                        },
                        activeColor: Color(0xFF00C853),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                    );
                  }).toList(),

                  // Divider
                  SizedBox(height: 16),
                  Divider(color: Color(0xFF333333)),
                  SizedBox(height: 16),

                  // Reset Data Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF1744).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFFF1744), width: 1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFFF1744),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Reset All Data',
                              style: TextStyle(
                                color: Color(0xFFFF1744),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'This will permanently delete all your income, expenses, and user data. This action cannot be undone.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showResetConfirmation(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Color(0xFFFF1744),
                              side: BorderSide(color: Color(0xFFFF1744)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: Icon(Icons.delete_forever, size: 18),
                            label: Text('Reset App Data'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Save the selected theme
                    userBox.put(
                      DashboardThemeHelper.dashboardThemeKey,
                      selectedTheme.index,
                    );
                    Navigator.of(context).pop();
                    // Refresh the dashboard
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showResetConfirmation(BuildContext context) {
    Navigator.of(context).pop(); // Close the settings dialog first

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A1C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFFF1744),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Reset All Data?',
                style: TextStyle(color: Color(0xFFFF1744), fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action will permanently delete:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              _buildResetItem('All income records'),
              _buildResetItem('All expense records'),
              _buildResetItem('User profile data'),
              _buildResetItem('Dashboard preferences'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFFF1744).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFFF1744), width: 1),
                ),
                child: Text(
                  '⚠️ This action cannot be undone!\nThe app will restart with a fresh state.',
                  style: TextStyle(
                    color: Color(0xFFFF1744),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => _performReset(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF1744),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Reset Everything'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResetItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.circle, color: Color(0xFFFF1744), size: 6),
          SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _performReset(BuildContext context) async {
    try {
      // Show loading
      Navigator.of(context).pop(); // Close confirmation dialog

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xFF1A1A1C),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFFF1744)),
              SizedBox(height: 16),
              Text(
                'Resetting app data...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // Clear all Hive boxes
      await assetsBox.clear();
      await liabilitiesBox.clear();
      await userBox.clear();

      // Reset current user
      _currentUser = null;

      // Wait a moment for visual feedback
      await Future.delayed(Duration(seconds: 1));

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 App reset successfully! Fresh start unlocked.'),
          backgroundColor: Color(0xFF00C853),
          duration: Duration(seconds: 3),
        ),
      );

      // Refresh the entire app state
      setState(() {
        _selectedIndex = 2; // Reset to dashboard
      });
    } catch (e) {
      // Close any open dialogs
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting app data: $e'),
          backgroundColor: Color(0xFFFF1744),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
                    label: 'Expenses',
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
                    label: 'Income',
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
          height: 60, // Increased height to prevent overflow
          width: 120,
          padding: EdgeInsets.symmetric(
            vertical: 6,
            horizontal: 6,
          ), // Adjusted padding
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : Color(0xFF1A1A1C),
            borderRadius: BorderRadius.circular(24),
            border: selected
                ? Border.all(color: color.withValues(alpha: 0.3), width: 1)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize:
                MainAxisSize.min, // Changed to min to prevent overflow
            children: [
              Icon(
                selected ? _getFilledIcon(icon) : icon,
                color: selected ? color : Color(0xFF999999),
                size: 20, // Slightly reduced icon size
              ),
              SizedBox(height: 3), // Reduced spacing
              Flexible(
                // Added Flexible to prevent text overflow
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? color : Color(0xFF999999),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 11, // Slightly reduced font size
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
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

    Widget _getCurrentScreen() {
      switch (_selectedIndex) {
        case 0:
          return LiabilitiesScreen(
            liabilities: liabilitiesBox.values.cast<Transaction>().toList(),
            onAddLiability: _addLiability,
          );
        case 1:
          return AssetsScreen(
            assets: assetsBox.values.cast<Transaction>().toList(),
            onAddAsset: _addAsset,
          );
        case 2:
          return DashboardScreen(
            assets: assetsBox.values.cast<Transaction>().toList(),
            liabilities: liabilitiesBox.values.cast<Transaction>().toList(),
            onToggleCompleted: _toggleCompleted,
            onNavigateToAssets: () => _onNavTap(1),
            onNavigateToLiabilities: () => _onNavTap(0),
          );
        case 3:
          return ProfileScreen(
            user: _currentUser!,
            onUserUpdated: _updateUser,
            onLogout: _logout,
          );
        default:
          return DashboardScreen(
            assets: assetsBox.values.cast<Transaction>().toList(),
            liabilities: liabilitiesBox.values.cast<Transaction>().toList(),
            onToggleCompleted: _toggleCompleted,
            onNavigateToAssets: () => _onNavTap(1),
            onNavigateToLiabilities: () => _onNavTap(0),
          );
      }
    }

    return _getCurrentScreen();
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
                    _buildDrawerItem(
                      icon: Icons.settings_outlined,
                      title: 'Dashboard Settings',
                      onTap: () {
                        Navigator.pop(context);
                        _showDashboardSettings(context);
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
        height: 120, // Increased height to accommodate navigation
        child: SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: true,
          child: Stack(children: [_buildBottomNav()]),
        ),
      ),
      floatingActionButton:
          _selectedIndex ==
              2 // Only show on Dashboard
          ? FloatingActionButton(
              onPressed: _showQuickAddExpense,
              backgroundColor: const Color(0xFFFF1744),
              foregroundColor: Colors.white,
              elevation: 8,
              child: const Icon(Icons.flash_on, size: 28),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showQuickAddExpense() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickAddExpenseWidget(onAddExpense: _addLiability),
    );
  }
}
