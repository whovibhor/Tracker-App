import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ErrorHandler {
  // Global error handler for the app
  static void handleError(
    Object error,
    StackTrace stackTrace, {
    String? context,
  }) {
    if (kDebugMode) {
      debugPrint('ERROR${context != null ? ' in $context' : ''}: $error');
      debugPrint('Stack trace: $stackTrace');
    }

    // In production, you might want to send errors to a crash reporting service
    // like Firebase Crashlytics, Sentry, etc.
  }

  // Safe widget builder that handles errors gracefully
  static Widget safeBuilder({
    required Widget Function() builder,
    Widget? fallback,
    String? context,
  }) {
    try {
      return builder();
    } catch (error, stackTrace) {
      handleError(error, stackTrace, context: context);
      return fallback ??
          AppErrorWidget(
            message: 'Something went wrong. Please try again later.',
          );
    }
  }

  // Safe async operation wrapper
  static Future<T?> safeAsync<T>({
    required Future<T> Function() operation,
    String? context,
    T? fallback,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      handleError(error, stackTrace, context: context);
      return fallback;
    }
  }

  // Error dialog for user-facing errors
  static void showErrorDialog(BuildContext context, String message) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Custom error widget for better UX
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
