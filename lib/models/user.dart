import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 3)
class User extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int age;

  @HiveField(2)
  String occupation;

  @HiveField(3)
  String email;

  @HiveField(4)
  String? profilePicturePath;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  bool isLoggedIn;

  User({
    required this.name,
    required this.age,
    required this.occupation,
    required this.email,
    this.profilePicturePath,
    required this.createdAt,
    this.isLoggedIn = true,
  }) {
    // Validate inputs on creation
    _validateInputs();
  }

  // Validate user inputs for security
  void _validateInputs() {
    if (name.trim().isEmpty || name.length > 100) {
      throw ArgumentError('Invalid name: must be 1-100 characters');
    }

    if (age < 13 || age > 120) {
      throw ArgumentError('Invalid age: must be between 13-120');
    }

    if (occupation.trim().isEmpty || occupation.length > 100) {
      throw ArgumentError('Invalid occupation: must be 1-100 characters');
    }

    if (!_isValidEmail(email)) {
      throw ArgumentError('Invalid email format');
    }

    if (profilePicturePath != null && profilePicturePath!.length > 500) {
      throw ArgumentError('Profile picture path too long');
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Sanitize user inputs
  static User createSanitized({
    required String name,
    required int age,
    required String occupation,
    required String email,
    String? profilePicturePath,
    required DateTime createdAt,
    bool isLoggedIn = true,
  }) {
    return User(
      name: _sanitizeString(name),
      age: age,
      occupation: _sanitizeString(occupation),
      email: _sanitizeString(email.toLowerCase()),
      profilePicturePath: profilePicturePath,
      createdAt: createdAt,
      isLoggedIn: isLoggedIn,
    );
  }

  static String _sanitizeString(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[^\w\s\-\.,@]'), '') // Keep safe characters
        .trim();
  }

  @override
  String toString() {
    return 'User{name: $name, age: $age, occupation: $occupation, email: $email}';
  }
}
