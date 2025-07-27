import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
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
              color: Colors.grey[200],
              border: Border.all(color: Color(0xFF1976D2), width: 3),
            ),
            child: imagePath != null
                ? ClipOval(
                    child: kIsWeb
                        ? Image.network(
                            imagePath,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.person, size: 60, color: Color(0xFF1976D2)),
                          )
                        : Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                          ),
                  )
                : Icon(Icons.person, size: 60, color: Color(0xFF1976D2)),
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
                    color: Color(0xFF1976D2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
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
      backgroundColor: Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing) ...[
            IconButton(icon: Icon(Icons.close), onPressed: _cancelEditing),
            IconButton(icon: Icon(Icons.check), onPressed: _saveChanges),
          ],
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 10),

                // Profile Picture
                _buildProfileImage(),

                SizedBox(height: 24),

                // User Info Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  shadowColor: Colors.black12,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_outline, color: Color(0xFF1976D2)),
                            SizedBox(width: 8),
                            Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3A3D5C),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

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
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                shadowColor: Colors.black12,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_circle_outlined, color: Color(0xFF1976D2)),
                          SizedBox(width: 8),
                          Text(
                            'Account Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3A3D5C),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      _buildInfoRow(
                        'Member Since',
                        '${widget.user.createdAt.day}/${widget.user.createdAt.month}/${widget.user.createdAt.year}',
                        Icons.date_range,
                      ),

                      SizedBox(height: 12),

                      _buildInfoRow(
                        'Account Status',
                        'Active',
                        Icons.verified_user,
                        valueColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Logout Button
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Logout'),
                      content: Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onLogout();
                            Navigator.pop(context);
                          },
                          child: Text('Logout'),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(Icons.logout, color: Colors.red),
                label: Text('Logout', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.red),
                ),
              ),

              SizedBox(height: 20),
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF1976D2)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _isEditing ? Colors.grey[300]! : Colors.grey[200]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF1976D2)),
        ),
        filled: true,
        fillColor: _isEditing ? Colors.white : Colors.grey[50],
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
        Icon(icon, color: Color(0xFF1976D2), size: 20),
        SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xFF8A8D9F),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor ?? Color(0xFF3A3D5C),
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
