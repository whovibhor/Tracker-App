import 'package:flutter/foundation.dart';

class ValidationUtils {
  // Input sanitization for text fields
  static String sanitizeInput(String input) {
    if (input.isEmpty) return input;

    // Remove potentially dangerous characters
    final sanitized = input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(
          RegExp(r'[^\w\s\-\.,]'),
          '',
        ) // Keep only alphanumeric, spaces, hyphens, periods, commas
        .trim();

    // Limit length to prevent DoS
    const maxLength = 100;
    return sanitized.length > maxLength
        ? sanitized.substring(0, maxLength)
        : sanitized;
  }

  // Validate amount input for financial data
  static bool isValidAmount(String amount) {
    if (amount.isEmpty) return false;

    final parsed = double.tryParse(amount);
    if (parsed == null) return false;

    // Check for reasonable bounds
    const minAmount = 0.01;
    const maxAmount = 999999999.99; // 999 million max

    return parsed >= minAmount && parsed <= maxAmount;
  }

  // Validate date to prevent invalid dates
  static bool isValidDate(DateTime? date) {
    if (date == null) return false;

    final now = DateTime.now();
    final minDate = DateTime(1900);
    final maxDate = DateTime(now.year + 100);

    return date.isAfter(minDate) && date.isBefore(maxDate);
  }

  // Sanitize tag input
  static String sanitizeTag(String tag) {
    if (tag.isEmpty) return 'Other';

    final sanitized = tag
        .replaceAll(RegExp(r'[^\w\s]'), '') // Only alphanumeric and spaces
        .trim();

    return sanitized.isEmpty ? 'Other' : sanitized;
  }

  // Log security events in debug mode
  static void logSecurityEvent(String event, String details) {
    if (kDebugMode) {
      debugPrint('SECURITY: $event - $details');
    }
  }
}
