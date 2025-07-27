import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';

class DataMigration {
  static Future<void> migrateData() async {
    try {
      // Migrate assets
      final assetsBox = Hive.box('assetsBox');
      final migratedAssets = <Transaction>[];

      for (var i = 0; i < assetsBox.length; i++) {
        final item = assetsBox.getAt(i);
        if (item is Transaction) {
          // Check if this is an old transaction without new fields
          if (item.tag.isEmpty) {
            // Create new transaction with default values
            final migratedTransaction = Transaction(
              title: item.title,
              amount: item.amount,
              date: item.date,
              type: item.type,
              tag: 'Other', // Default tag
              dueDate: null,
              isCompleted: false,
            );
            migratedAssets.add(migratedTransaction);
          } else {
            migratedAssets.add(item);
          }
        }
      }

      // Clear and repopulate assets box
      await assetsBox.clear();
      for (final asset in migratedAssets) {
        await assetsBox.add(asset);
      }

      // Migrate liabilities
      final liabilitiesBox = Hive.box('liabilitiesBox');
      final migratedLiabilities = <Transaction>[];

      for (var i = 0; i < liabilitiesBox.length; i++) {
        final item = liabilitiesBox.getAt(i);
        if (item is Transaction) {
          // Check if this is an old transaction without new fields
          if (item.tag.isEmpty) {
            // Create new transaction with default values
            final migratedTransaction = Transaction(
              title: item.title,
              amount: item.amount,
              date: item.date,
              type: item.type,
              tag: 'Misc', // Default tag
              dueDate: null,
              isCompleted: false,
            );
            migratedLiabilities.add(migratedTransaction);
          } else {
            migratedLiabilities.add(item);
          }
        }
      }

      // Clear and repopulate liabilities box
      await liabilitiesBox.clear();
      for (final liability in migratedLiabilities) {
        await liabilitiesBox.add(liability);
      }

      if (kDebugMode) {
        debugPrint('Data migration completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error during data migration: $e');
      }
    }
  }
}
