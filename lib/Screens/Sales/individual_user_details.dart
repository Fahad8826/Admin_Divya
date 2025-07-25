import 'package:admin/Controller/usercontroller.dart';
import 'package:admin/Voice/admin_audio_listener.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class IndividualUserDetails extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const IndividualUserDetails({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<IndividualUserDetails> createState() => _IndividualUserDetailsState();
}

class _IndividualUserDetailsState extends State<IndividualUserDetails>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final AddUserController _addUserController = Get.put(AddUserController());

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _passwordController;
  late TextEditingController _placeController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isActive = true;
  String? _imageUrl;
  File? _selectedImage;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _passwordVisible = false;
  String? _selectedGender;
  String? _selectedRole;
  Map<String, dynamic>? _locationData;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimation();
    _fetchLocationData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.userData['name']);
    _emailController = TextEditingController(text: widget.userData['email']);
    _ageController = TextEditingController(
      text: widget.userData['age']?.toString() ?? '',
    );
    _phoneController = TextEditingController(text: widget.userData['phone']);
    _addressController = TextEditingController(
      text: widget.userData['address'],
    );
    _passwordController = TextEditingController();
    _placeController = TextEditingController(
      text: widget.userData['place'] ?? '',
    );
    _selectedGender = widget.userData['gender'];
    _isActive = widget.userData['isActive'] ?? true;
    _imageUrl = widget.userData['imageUrl'];
    _selectedRole = widget.userData['role'] ?? 'salesmen';
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<void> _fetchLocationData() async {
    setState(() => _isLoading = true);
    try {
      final locationData = await _addUserController.getUserLocationData(
        widget.userId,
      );
      if (mounted) {
        setState(() {
          _locationData = locationData;
        });
      }
    } catch (e) {
      _showErrorDialog('Error fetching location: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _placeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorDialog('Error picking image: $e');
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_selectedImage == null) return _imageUrl;

    try {
      final ref = _storage.ref().child('salesperson_images/$userId.jpg');
      final uploadTask = ref.putFile(_selectedImage!);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      _showErrorDialog('Error uploading image: $e');
      return _imageUrl;
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value))
      return 'Enter valid email';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'Phone number is required';
    if (value.length < 10) return 'Enter valid phone number';
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) return 'Age is required';
    final age = int.tryParse(value);
    if (age == null || age < 18 || age > 65) return 'Age must be 18-65';
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validatePlace(String? value) {
    if (value == null || value.trim().isEmpty) return 'Place is required';
    if (value.trim().length < 2) return 'Place must be at least 2 characters';
    return null;
  }

  String? _validateRole(String? value) {
    if (value == null) return 'Role is required';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value != null && value.isNotEmpty && value.length < 6)
      return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final phoneQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: _phoneController.text.trim())
          .get();

      if (phoneQuery.docs.isNotEmpty &&
          phoneQuery.docs.first.id != widget.userId) {
        _showErrorDialog('Phone number is already in use');
        setState(() => _isLoading = false);
        return;
      }

      final newImageUrl = await _uploadImage(widget.userId);

      final updatedData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'place': _placeController.text.trim(),
        'gender': _selectedGender,
        'role': _selectedRole,
        'isActive': _isActive,
        'imageUrl': newImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(widget.userId)
          .update(updatedData);

      if (_passwordController.text.trim().isNotEmpty) {
        await _auth.currentUser?.updatePassword(
          _passwordController.text.trim(),
        );
      }

      await _fetchLocationData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('User updated successfully'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() {
          _isEditing = false;
          _imageUrl = newImageUrl;
          _selectedImage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error updating user: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[600],
              size: isTablet ? 32 : 28,
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Text(
              'Error',
              style: TextStyle(color: Colors.red, fontSize: isTablet ? 20 : 18),
            ),
          ],
        ),
        content: Text(message, style: TextStyle(fontSize: isTablet ? 16 : 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red[700],
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 24,
                vertical: isTablet ? 16 : 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('OK', style: TextStyle(fontSize: isTablet ? 16 : 14)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final horizontalPadding = isTablet ? 32.0 : 20.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(isTablet),
      body: _isLoading
          ? _buildLoadingIndicator(isTablet)
          : _buildBody(isTablet, horizontalPadding),
      floatingActionButton: _isEditing
          ? _buildFloatingActionButton(isTablet)
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(bool isTablet) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey[800],
      title: Text(
        _isEditing ? 'Edit User' : 'User Details',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: isTablet ? 24 : 20,
        ),
      ),
      elevation: 0,
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey[200]),
      ),
      actions: [
        if (!_isEditing)
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Colors.blue[600],
              size: isTablet ? 28 : 24,
            ),
            onPressed: () => setState(() => _isEditing = true),
            tooltip: 'Edit User',
          ),

        SizedBox(width: isTablet ? 16 : 8),
      ],
    );
  }

  Widget _buildLoadingIndicator(bool isTablet) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: isTablet ? 60 : 40,
            height: isTablet ? 60 : 40,
            child: const CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(height: isTablet ? 24 : 16),
          Text(
            'Processing...',
            style: TextStyle(fontSize: isTablet ? 18 : 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isTablet, double horizontalPadding) {
    final userRole = widget.userData['role'];
    final maxWidth = isTablet ? 800.0 : double.infinity;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileSection(isTablet),
                  SizedBox(height: isTablet ? 40 : 32),
                  _buildPersonalInfoSection(isTablet),
                  SizedBox(height: isTablet ? 32 : 24),
                  _buildContactInfoSection(isTablet),
                  SizedBox(height: isTablet ? 32 : 24),
                  if (userRole != 'maker') _buildLocationSection(isTablet),
                  if (userRole != 'maker') SizedBox(height: isTablet ? 32 : 24),
                  _buildSecuritySection(isTablet),
                  SizedBox(height: isTablet ? 32 : 24),
                  _buildStatusSection(isTablet),
                  SizedBox(height: isTablet ? 32 : 20),
                  if (userRole != 'maker')
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isTablet ? 60 : 50),
                        child: SizedBox(
                          width: isTablet ? 200 : 150,
                          height: isTablet ? 50 : 40,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminAudioListenPage(
                                    userId: widget.userId,
                                  ),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.mic_none_outlined,
                              size: isTablet ? 28 : 24,
                            ),
                            label: Text(
                              "Monitor",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isTablet ? 20 : 18,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(bool isTablet) {
    final profileImageSize = isTablet ? 140.0 : 100.0;
    final cameraIconSize = isTablet ? 44.0 : 32.0;
    final nameTextSize = isTablet ? 28.0 : 22.0;
    final statusTextSize = isTablet ? 14.0 : 12.0;

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _isEditing ? _pickImage : null,
                child: Container(
                  width: profileImageSize,
                  height: profileImageSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _selectedImage != null
                      ? ClipOval(
                          child: Image.file(
                            _selectedImage!,
                            width: profileImageSize,
                            height: profileImageSize,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _imageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            _imageUrl!,
                            width: profileImageSize,
                            height: profileImageSize,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: profileImageSize * 0.5,
                                color: Colors.grey[500],
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: profileImageSize * 0.5,
                          color: Colors.grey[500],
                        ),
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: cameraIconSize,
                      height: cameraIconSize,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 209, 52, 67),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromARGB(
                              255,
                              209,
                              52,
                              67,
                            ).withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: cameraIconSize * 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isTablet ? 24 : 16),
          Text(
            _nameController.text.isNotEmpty ? _nameController.text : 'No Name',
            style: TextStyle(
              fontSize: nameTextSize,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 10,
              vertical: isTablet ? 8 : 4,
            ),
            decoration: BoxDecoration(
              color: _isActive ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isActive ? Colors.green[200]! : Colors.red[200]!,
                width: 1,
              ),
            ),
            child: Text(
              _isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: _isActive ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.w500,
                fontSize: statusTextSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(bool isTablet) {
    return _buildSection(
      title: 'Personal Information',
      icon: Icons.person_outline,
      isTablet: isTablet,
      children: [
        if (isTablet)
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildEnhancedTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person,
                  validator: _validateName,
                  isTablet: isTablet,
                ),
              ),
              SizedBox(width: isTablet ? 24 : 16),
              Expanded(
                child: _buildEnhancedTextField(
                  controller: _ageController,
                  label: 'Age',
                  icon: Icons.cake,
                  keyboardType: TextInputType.number,
                  validator: _validateAge,
                  isTablet: isTablet,
                ),
              ),
            ],
          )
        else ...[
          _buildEnhancedTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person,
            validator: _validateName,
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 24 : 16),
          _buildEnhancedTextField(
            controller: _ageController,
            label: 'Age',
            icon: Icons.cake,
            keyboardType: TextInputType.number,
            validator: _validateAge,
            isTablet: isTablet,
          ),
        ],
        SizedBox(height: isTablet ? 24 : 16),
        if (isTablet)
          Row(
            children: [
              Expanded(child: _buildEnhancedGenderField(isTablet)),
              SizedBox(width: isTablet ? 24 : 16),
              Expanded(child: _buildEnhancedRoleField(isTablet)),
            ],
          )
        else ...[
          _buildEnhancedGenderField(isTablet),
          SizedBox(height: isTablet ? 24 : 16),
          _buildEnhancedRoleField(isTablet),
        ],
        SizedBox(height: isTablet ? 24 : 16),
        _buildEnhancedTextField(
          controller: _placeController,
          label: 'Place',
          icon: Icons.place_outlined,
          validator: _validatePlace,
          isTablet: isTablet,
        ),
        SizedBox(height: isTablet ? 24 : 16),
        _buildEnhancedTextField(
          controller: _addressController,
          label: 'Address',
          icon: Icons.location_on,
          maxLines: 3,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Address is required'
              : null,
          isTablet: isTablet,
        ),
      ],
    );
  }

  Widget _buildContactInfoSection(bool isTablet) {
    return _buildSection(
      title: 'Contact Information',
      icon: Icons.contact_phone,
      isTablet: isTablet,
      children: [
        if (isTablet)
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildEnhancedTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  isTablet: isTablet,
                ),
              ),
              SizedBox(width: isTablet ? 24 : 16),
              Expanded(
                child: _buildEnhancedTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                  isTablet: isTablet,
                ),
              ),
            ],
          )
        else ...[
          _buildEnhancedTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            isTablet: isTablet,
          ),
          SizedBox(height: isTablet ? 24 : 16),
          _buildEnhancedTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: _validatePhone,
            isTablet: isTablet,
          ),
        ],
      ],
    );
  }

  Widget _buildLocationSection(bool isTablet) {
    final timestamp = _locationData?['lastLocationUpdate'];
    String formattedDate = 'Not available';

    if (timestamp != null && timestamp is Timestamp) {
      final dateTime = timestamp.toDate(); // Convert to DateTime
      formattedDate = DateFormat(
        "MMMM d, y 'at' h:mm:ss a 'UTC+5:30'",
      ).format(dateTime.toUtc().add(const Duration(hours: 5, minutes: 30)));
    }

    return _buildSection(
      title: 'Location Information',
      icon: Icons.map,
      isTablet: isTablet,
      children: [
        _buildInfoRow(
          label: 'Reverse Geocoded Address',
          value: _locationData?['reverseGeocodedAddress'] ?? 'Not available',
          isTablet: isTablet,
        ),
        SizedBox(height: isTablet ? 24 : 16),
        _buildInfoRow(
          label: 'Coordinates',
          value:
              _locationData != null &&
                  _locationData!['latitude'] != null &&
                  _locationData!['longitude'] != null
              ? 'Lat: ${_locationData!['latitude']}, Lng: ${_locationData!['longitude']}'
              : 'Not available',
          isTablet: isTablet,
        ),
        SizedBox(height: isTablet ? 24 : 16),
        _buildInfoRow(
          label: 'Last Location Update',
          value: formattedDate,
          isTablet: isTablet,
        ),
      ],
    );
  }

  Widget _buildSecuritySection(bool isTablet) {
    if (!_isEditing) return const SizedBox.shrink();

    return _buildSection(
      title: 'Security',
      icon: Icons.security,
      isTablet: isTablet,
      children: [
        _buildEnhancedTextField(
          controller: _passwordController,
          label: 'New Password (optional)',
          icon: Icons.lock,
          obscureText: !_passwordVisible,
          suffixIcon: IconButton(
            icon: Icon(
              _passwordVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
              size: isTablet ? 28 : 24,
            ),
            onPressed: () {
              setState(() {
                _passwordVisible = !_passwordVisible;
              });
            },
          ),
          validator: _validatePassword,
          isTablet: isTablet,
        ),
      ],
    );
  }

  Widget _buildStatusSection(bool isTablet) {
    return _buildSection(
      title: 'Account Status',
      icon: Icons.settings,
      isTablet: isTablet,
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(
                _isActive ? Icons.check_circle : Icons.cancel,
                color: _isActive ? Colors.green[600] : Colors.red[600],
                size: isTablet ? 28 : 24,
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Text(
                  'Account Status',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_isEditing)
                Switch(
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  activeColor: Colors.green[600],
                )
              else
                Text(
                  _isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: _isActive ? Colors.green[600] : Colors.red[600],
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isTablet,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 12 : 8),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 209, 52, 67),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: isTablet ? 28 : 24,
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 22 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 24 : 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
    required bool isTablet,
  }) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        fontSize: isTablet ? 16 : 14,
        color: _isEditing ? Colors.black87 : Colors.grey[600],
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: _isEditing
              ? Color.fromARGB(255, 209, 52, 67)
              : Colors.grey[400],
          size: isTablet ? 24 : 20,
        ),
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(
          color: _isEditing
              ? Color.fromARGB(255, 209, 52, 67)
              : Colors.grey[500],
          fontSize: isTablet ? 16 : 14,
        ),
        filled: true,
        fillColor: _isEditing ? Colors.white : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Color.fromARGB(255, 209, 52, 67),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[600]!, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 16 : 12,
        ),
      ),
    );
  }

  Widget _buildEnhancedGenderField(bool isTablet) {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      items: ['Male', 'Female', 'Other'].map((gender) {
        return DropdownMenuItem(
          value: gender,
          child: Text(gender, style: TextStyle(fontSize: isTablet ? 16 : 14)),
        );
      }).toList(),
      onChanged: _isEditing
          ? (value) {
              setState(() {
                _selectedGender = value;
              });
            }
          : null,
      validator: (value) => value == null ? 'Please select gender' : null,
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: Icon(
          Icons.person_outline,
          color: _isEditing
              ? Color.fromARGB(255, 209, 52, 67)
              : Colors.grey[400],
          size: isTablet ? 24 : 20,
        ),
        labelStyle: TextStyle(
          color: _isEditing
              ? Color.fromARGB(255, 209, 52, 67)
              : Colors.grey[500],
          fontSize: isTablet ? 16 : 14,
        ),
        filled: true,
        fillColor: _isEditing ? Colors.white : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Color.fromARGB(255, 209, 52, 67),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[600]!, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 16 : 12,
        ),
      ),
    );
  }

  Widget _buildEnhancedRoleField(bool isTablet) {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      items: ['salesmen', 'maker'].map((role) {
        return DropdownMenuItem(
          value: role,
          child: Text(
            role.toUpperCase(),
            style: TextStyle(fontSize: isTablet ? 16 : 14),
          ),
        );
      }).toList(),
      onChanged: _isEditing
          ? (value) {
              setState(() {
                _selectedRole = value;
              });
            }
          : null,
      validator: _validateRole,
      decoration: InputDecoration(
        labelText: 'Role',
        prefixIcon: Icon(
          Icons.work_outline,
          color: _isEditing
              ? Color.fromARGB(255, 209, 52, 67)
              : Colors.grey[400],
          size: isTablet ? 24 : 20,
        ),
        labelStyle: TextStyle(
          color: _isEditing
              ? Color.fromARGB(255, 209, 52, 67)
              : Colors.grey[500],
          fontSize: isTablet ? 16 : 14,
        ),
        filled: true,
        fillColor: _isEditing ? Colors.white : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Color.fromARGB(255, 209, 52, 67),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[600]!, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 16 : 12,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isTablet ? 180 : 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(bool isTablet) {
    return FloatingActionButton.extended(
      onPressed: _isLoading ? null : _updateUser,
      backgroundColor: Color.fromARGB(255, 209, 52, 67),
      foregroundColor: Colors.white,
      icon: _isLoading
          ? SizedBox(
              width: isTablet ? 20 : 16,
              height: isTablet ? 20 : 16,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(Icons.save, size: isTablet ? 24 : 20),
      label: Text(
        _isLoading ? 'Saving...' : 'Save Changes',
        style: TextStyle(
          fontSize: isTablet ? 16 : 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
