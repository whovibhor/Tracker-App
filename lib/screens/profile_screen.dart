import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  final User user;
  final Function(User) onUserUpdated;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.onUserUpdated,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late TextEditingController _occupationController;

  File? _newProfileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _ageController = TextEditingController(text: widget.user.age.toString());
    _occupationController = TextEditingController(text: widget.user.occupation);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _newProfileImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) return;

    final updatedUser = User(
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      occupation: _occupationController.text.trim(),
      email: _emailController.text.trim(),
      profilePicturePath:
          _newProfileImage?.path ?? widget.user.profilePicturePath,
      createdAt: widget.user.createdAt,
      isLoggedIn: true,
    );

    widget.onUserUpdated(updatedUser);

    setState(() {
      _isEditing = false;
      _newProfileImage = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Profile updated successfully!')));
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _newProfileImage = null;
      _nameController.text = widget.user.name;
      _emailController.text = widget.user.email;
      _ageController.text = widget.user.age.toString();
      _occupationController.text = widget.user.occupation;
    });
  }

  Widget _buildProfileImage() {
    String? imagePath =
        _newProfileImage?.path ?? widget.user.profilePicturePath;

    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1A1A1C),
              border: Border.all(color: Color(0xFF00C853), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF00C853).withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: imagePath != null
                ? ClipOval(
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                    ),
                  )
                : Icon(
                    Icons.person_rounded,
                    size: 60,
                    color: Color(0xFF00C853),
                  ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF00C853),
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFF0A0A0B), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0B),
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFF0A0A0B),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit_rounded, color: Color(0xFF00C853)),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing) ...[
            IconButton(
              icon: Icon(Icons.close_rounded, color: Color(0xFFFF1744)),
              onPressed: _cancelEditing,
            ),
            IconButton(
              icon: Icon(Icons.check_rounded, color: Color(0xFF00C853)),
              onPressed: _saveChanges,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),

              // Profile Picture
              _buildProfileImage(),

              SizedBox(height: 32),

              // User Info Card
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF00C853).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              color: Color(0xFF00C853),
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Name Field
                      _buildInfoField(
                        label: 'Name',
                        controller: _nameController,
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      // Email Field
                      _buildInfoField(
                        label: 'Email',
                        controller: _emailController,
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

                      SizedBox(height: 16),

                      // Age Field
                      _buildInfoField(
                        label: 'Age',
                        controller: _ageController,
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

                      SizedBox(height: 16),

                      // Occupation Field
                      _buildInfoField(
                        label: 'Occupation',
                        controller: _occupationController,
                        icon: Icons.work,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your occupation';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Account Info Card
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF00C853).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.verified_user_rounded,
                              color: Color(0xFF00C853),
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Account Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      _buildInfoRow(
                        'Member Since',
                        '${widget.user.createdAt.day}/${widget.user.createdAt.month}/${widget.user.createdAt.year}',
                        Icons.date_range_rounded,
                      ),

                      SizedBox(height: 16),

                      _buildInfoRow(
                        'Account Status',
                        'Active',
                        Icons.verified_user_rounded,
                        valueColor: Color(0xFF00C853),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 32),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Color(0xFF1A1A1C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(
                          'Logout',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          'Are you sure you want to logout?',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onLogout();
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Logout',
                              style: TextStyle(color: Color(0xFFFF1744)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.logout_rounded, color: Color(0xFFFF1744)),
                  label: Text(
                    'Logout',
                    style: TextStyle(color: Color(0xFFFF1744)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Color(0xFFFF1744)),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: _isEditing
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(
          icon,
          color: _isEditing
              ? Color(0xFF00C853)
              : Colors.white.withValues(alpha: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _isEditing
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF00C853), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
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
        fillColor: _isEditing
            ? Color(0xFF1A1A1C)
            : Color(0xFF1A1A1C).withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF00C853), size: 20),
        SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.white,
            ),
          ),
        ),
      ],
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
