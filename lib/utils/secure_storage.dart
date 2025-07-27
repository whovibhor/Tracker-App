import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';

class SecureStorageService {
  static const String _assetsBoxName = 'assetsBox';
  static const String _liabilitiesBoxName = 'liabilitiesBox';
  static const String _userBoxName = 'userBox';

  // Secure box opening with error handling
  static Future<Box?> openSecureBox(String boxName) async {
    try {
      // Ensure box name is safe
      if (!_isValidBoxName(boxName)) {
        if (kDebugMode) {
          debugPrint('SECURITY: Invalid box name attempted: $boxName');
        }
        return null;
      }

      return await Hive.openBox(boxName);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SECURITY: Failed to open box $boxName: $e');
      }
      return null;
    }
  }

  // Validate box names to prevent directory traversal
  static bool _isValidBoxName(String boxName) {
    final validNames = [_assetsBoxName, _liabilitiesBoxName, _userBoxName];
    return validNames.contains(boxName) &&
        !boxName.contains('../') &&
        !boxName.contains('..\\') &&
        !boxName.contains('/') &&
        !boxName.contains('\\') &&
        boxName.isNotEmpty;
  }

  // Secure transaction addition
  static Future<bool> addTransaction(Box box, Transaction transaction) async {
    try {
      // Validate transaction data
      if (!_isValidTransaction(transaction)) {
        if (kDebugMode) {
          debugPrint('SECURITY: Invalid transaction rejected');
        }
        return false;
      }

      await box.add(transaction);
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SECURITY: Failed to add transaction: $e');
      }
      return false;
    }
  }

  // Validate transaction data for security
  static bool _isValidTransaction(Transaction transaction) {
    // Check title length and content
    if (transaction.title.isEmpty || transaction.title.length > 100) {
      return false;
    }

    // Check amount bounds
    if (transaction.amount <= 0 || transaction.amount > 999999999.99) {
      return false;
    }

    // Check date validity
    final now = DateTime.now();
    final minDate = DateTime(1900);
    final maxDate = DateTime(now.year + 100);

    if (transaction.date.isBefore(minDate) ||
        transaction.date.isAfter(maxDate)) {
      return false;
    }

    // Check tag validity
    if (transaction.tag.isEmpty || transaction.tag.length > 50) {
      return false;
    }

    return true;
  }

  // Get box count with bounds checking
  static int getSecureBoxCount(Box box) {
    try {
      final count = box.length;
      // Prevent excessive memory usage
      if (count > 10000) {
        if (kDebugMode) {
          debugPrint('SECURITY: Excessive box size detected: $count');
        }
      }
      return count;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SECURITY: Failed to get box count: $e');
      }
      return 0;
    }
  }
}
