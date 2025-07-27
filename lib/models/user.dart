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
  });

  @override
  String toString() {
    return 'User{name: $name, age: $age, occupation: $occupation, email: $email}';
  }
}
