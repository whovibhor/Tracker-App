import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user.dart';
import '../utils/validation.dart';

class AuthScreen extends StatefulWidget {
  final Function(User) onUserCreated;

  const AuthScreen({super.key, required this.onUserCreated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = true;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _occupationController = TextEditingController();
  File? _profileImage;
  bool _isLoading = false;

  // Rate limiting for security
  DateTime? _lastSubmissionTime;
  int _submissionAttempts = 0;
  static const int _maxAttempts = 5;
  static const Duration _cooldownDuration = Duration(minutes: 1);

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        // Validate file size (max 5MB)
        final file = File(image.path);
        final fileSize = await file.length();
        const maxFileSize = 5 * 1024 * 1024; // 5MB

        if (fileSize > maxFileSize) {
          throw Exception(
            'Image size too large. Please select an image smaller than 5MB.',
          );
        }

        // Validate file extension
        final allowedExtensions = ['.jpg', '.jpeg', '.png'];
        final extension = image.path.toLowerCase().split('.').last;
        if (!allowedExtensions.contains('.$extension')) {
          throw Exception(
            'Invalid file type. Please select a JPG or PNG image.',
          );
        }

        setState(() {
          _profileImage = file;
        });
      }
    } catch (e) {
      ValidationUtils.logSecurityEvent('Image picker error', e.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Rate limiting check
    if (_checkRateLimit()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Too many attempts. Please wait before trying again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _submissionAttempts++;
      _lastSubmissionTime = DateTime.now();

      if (_isSignUp) {
        // Validate email format before creating user
        final emailToValidate = _emailController.text.trim();
        if (!_isValidEmail(emailToValidate)) {
          throw Exception('Invalid email format');
        }

        // Create new user with sanitized inputs
        final user = User.createSanitized(
          name: _nameController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          occupation: _occupationController.text.trim(),
          email: emailToValidate,
          profilePicturePath: _profileImage?.path,
          createdAt: DateTime.now(),
          isLoggedIn: true,
        );

        // Save user data (you can implement actual storage logic here)
        await Future.delayed(Duration(milliseconds: 500)); // Simulate API call

        widget.onUserCreated(user);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account created successfully!')),
        );
      } else {
        // Login logic (for now just simulate)
        final emailToValidate = _emailController.text.trim();

        if (!_isValidEmail(emailToValidate)) {
          throw Exception('Invalid email format');
        }

        await Future.delayed(Duration(milliseconds: 500));

        // For demo purposes, create a dummy user for login
        final user = User.createSanitized(
          name: "Demo User",
          age: 25,
          occupation: "Professional",
          email: emailToValidate,
          createdAt: DateTime.now(),
          isLoggedIn: true,
        );

        widget.onUserCreated(user);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logged in successfully!')));
      }

      // Reset attempts on success
      _submissionAttempts = 0;
      Navigator.of(context).pop();
    } catch (e) {
      ValidationUtils.logSecurityEvent(
        'Auth form submission error',
        e.toString(),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _checkRateLimit() {
    if (_submissionAttempts >= _maxAttempts) {
      if (_lastSubmissionTime != null) {
        final timeSinceLastAttempt = DateTime.now().difference(
          _lastSubmissionTime!,
        );
        if (timeSinceLastAttempt < _cooldownDuration) {
          return true; // Rate limited
        } else {
          // Reset after cooldown
          _submissionAttempts = 0;
        }
      }
    }
    return false;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _signInWithGoogle() {
    // Placeholder for Google Sign-In
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Google Sign-In will be implemented later')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0B),
      appBar: AppBar(
        title: Text(
          _isSignUp ? 'Sign Up' : 'Sign In',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFF0A0A0B),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),

              // Welcome Section with Icon
              Container(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF00C853).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        _isSignUp
                            ? Icons.person_add_rounded
                            : Icons.login_rounded,
                        size: 48,
                        color: Color(0xFF00C853),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      _isSignUp ? 'Create Your Account' : 'Welcome Back',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      _isSignUp
                          ? 'Sign up to save your financial progress'
                          : 'Sign in to access your account',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Profile Picture (only for sign up)
              if (_isSignUp) ...[
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1A1A1C),
                        border: Border.all(color: Color(0xFF00C853), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF00C853).withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: _profileImage != null
                          ? ClipOval(
                              child: Image.file(
                                _profileImage!,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                              ),
                            )
                          : Icon(
                              Icons.add_a_photo_rounded,
                              size: 40,
                              color: Color(0xFF00C853),
                            ),
                    ),
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'Tap to add profile picture',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 32),
              ],

              // Name Field (only for sign up)
              if (_isSignUp)
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

              // Email Field
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              // Age Field (only for sign up)
              if (_isSignUp)
                _buildTextField(
                  controller: _ageController,
                  label: 'Age',
                  icon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your age';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age < 13 || age > 120) {
                      return 'Please enter a valid age (13-120)';
                    }
                    return null;
                  },
                ),

              // Occupation Field (only for sign up)
              if (_isSignUp)
                _buildTextField(
                  controller: _occupationController,
                  label: 'Occupation',
                  icon: Icons.work,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your occupation';
                    }
                    return null;
                  },
                ),

              SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isSignUp ? 'Create Account' : 'Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 16),

              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: Icon(Icons.g_translate, color: Color(0xFF00C853)),
                  label: Text(
                    'Sign in with Google',
                    style: TextStyle(color: Color(0xFF00C853)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Color(0xFF00C853)),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Toggle Sign In/Sign Up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUp
                        ? 'Already have an account? '
                        : "Don't have an account? ",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                      });
                    },
                    child: Text(
                      _isSignUp ? 'Sign In' : 'Sign Up',
                      style: TextStyle(
                        color: Color(0xFF00C853),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          prefixIcon: Icon(icon, color: Color(0xFF00C853)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF00C853), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFFF1744), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFFF1744), width: 2),
          ),
          filled: true,
          fillColor: Color(0xFF1A1A1C),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _occupationController.dispose();
    super.dispose();
  }
}
