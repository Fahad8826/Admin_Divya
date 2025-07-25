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

class _IndividualUserDetailsState extends State<IndividualUserDetails> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _controller = Get.put(AddUserController());

  // Define the custom icon color
  static const Color _iconColor = Color.fromARGB(255, 209, 52, 67);
  static const Color _textColor = Color(0xFF1A1A1A);

  // Controllers
  late final _nameController = TextEditingController(
    text: widget.userData['name'],
  );
  late final _emailController = TextEditingController(
    text: widget.userData['email'],
  );
  late final _ageController = TextEditingController(
    text: widget.userData['age']?.toString() ?? '',
  );
  late final _phoneController = TextEditingController(
    text: widget.userData['phone'],
  );
  late final _addressController = TextEditingController(
    text: widget.userData['address'],
  );
  late final _passwordController = TextEditingController();
  late final _placeController = TextEditingController(
    text: widget.userData['place'] ?? '',
  );

  // State variables
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
    _initializeData();
    _fetchLocationData();
  }

  void _initializeData() {
    _selectedGender = widget.userData['gender'];
    _isActive = widget.userData['isActive'] ?? true;
    _imageUrl = widget.userData['imageUrl'];
    _selectedRole = widget.userData['role'] ?? 'salesmen';
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
    super.dispose();
  }

  Future<void> _fetchLocationData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final locationData = await _controller.getUserLocationData(widget.userId);
      if (mounted) setState(() => _locationData = locationData);
    } catch (e) {
      _showError('Error fetching location: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600, // Smaller max width
        maxHeight: 600, // Smaller max height
        imageQuality: 70, // Slightly reduced quality for smaller size
      );
      if (image != null) setState(() => _selectedImage = File(image.path));
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _imageUrl;
    try {
      final ref = _storage.ref().child(
        'salesperson_images/${widget.userId}.jpg',
      );
      final snapshot = await ref.putFile(_selectedImage!);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      _showError('Error uploading image: $e');
      return _imageUrl;
    }
  }

  // Validation methods
  String? _validate(String? value, String field, {int? minLength}) {
    if (field == 'Password') {
      if (value?.isEmpty ?? true) return null; // Password is optional
      if (value!.trim().length < 6) {
        return 'Password must be at least 6 characters';
      }
    } else {
      if (value?.trim().isEmpty ?? true) return '$field is required';
      if (minLength != null && value!.trim().length < minLength) {
        return '$field must be at least $minLength characters';
      }
      if (field == 'Email' &&
          !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
        return 'Enter valid email';
      }
      if (field == 'Age') {
        final age = int.tryParse(value!);
        if (age == null || age < 18 || age > 65) return 'Age must be 18-65';
      }
      if (field == 'Phone' && value!.length < 10) {
        return 'Enter valid phone number';
      }
    }
    return null;
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Check phone uniqueness
      final phoneQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: _phoneController.text.trim())
          .get();

      if (phoneQuery.docs.isNotEmpty &&
          phoneQuery.docs.first.id != widget.userId) {
        _showError('Phone number is already in use');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final newImageUrl = await _uploadImage();

      await _firestore.collection('users').doc(widget.userId).update({
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
      });

      if (_passwordController.text.trim().isNotEmpty) {
        await _auth.currentUser?.updatePassword(
          _passwordController.text.trim(),
        );
      }

      await _fetchLocationData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('User updated successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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
      _showError('Error updating user: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: _iconColor), // Use custom color
            SizedBox(width: 12),
            Text(
              'Error',
              style: TextStyle(color: _iconColor),
            ), // Use custom color
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: _iconColor),
            ), // Use custom color
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit User' : 'User Details',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: _textColor,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor:
            _textColor, // Use custom text color for general foreground
        elevation: 1,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: _iconColor,
              ), // Use custom color
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: _isEditing ? _buildSaveButton() : null,
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileSection(),
            const SizedBox(height: 24),
            _buildInfoCard('Personal Information', Icons.person, [
              _buildTextField(
                _nameController,
                'Name',
                Icons.person_outline,
                validator: (v) => _validate(v, 'Name', minLength: 2),
              ),
              _buildTextField(
                _ageController,
                'Age',
                Icons.cake_outlined,
                keyboardType: TextInputType.number,
                validator: (v) => _validate(v, 'Age'),
              ),
              _buildDropdown('Gender', _selectedGender, [
                'Male',
                'Female',
                'Other',
              ], (v) => setState(() => _selectedGender = v)),
              _buildDropdown('Role', _selectedRole, [
                'salesmen',
                'maker',
              ], (v) => setState(() => _selectedRole = v)),
              _buildTextField(
                _placeController,
                'Place',
                Icons.place_outlined,
                validator: (v) => _validate(v, 'Place', minLength: 2),
              ),
              _buildTextField(
                _addressController,
                'Address',
                Icons.location_on_outlined,
                maxLines: 2,
                validator: (v) => _validate(v, 'Address'),
              ),
            ]),
            const SizedBox(height: 24),
            _buildInfoCard('Contact Information', Icons.contact_mail, [
              _buildTextField(
                _emailController,
                'Email',
                Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => _validate(v, 'Email'),
              ),
              _buildTextField(
                _phoneController,
                'Phone',
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => _validate(v, 'Phone'),
              ),
            ]),
            if (widget.userData['role'] != 'maker') ...[
              const SizedBox(height: 24),
              _buildLocationCard(),
            ],
            if (_isEditing) ...[
              const SizedBox(height: 24),
              _buildSecurityCard(),
            ],
            const SizedBox(height: 24),
            _buildStatusCard(),
            if (widget.userData['role'] != 'maker') ...[
              const SizedBox(height: 32),
              _buildMonitorButton(),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    const double avatarRadius = 50.0;

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Colors.grey[200],
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!) as ImageProvider
                    : _imageUrl != null
                    ? NetworkImage(_imageUrl!)
                    : null,
                child: _selectedImage == null && _imageUrl == null
                    ? Icon(
                        Icons.person,
                        size: avatarRadius * 0.8,
                        color: Colors.grey,
                      )
                    : null,
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: _iconColor, // Use custom color
                      child: Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _nameController.text.isNotEmpty ? _nameController.text : 'No Name',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _isActive ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: _isActive ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white, // Explicitly set card color to white
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _iconColor), // Use custom color
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            ...children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: child,
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _iconColor), // Use custom color
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _isEditing ? Colors.grey[50] : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _iconColor,
            width: 2,
          ), // Use custom color for focused border
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 10,
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: _isEditing ? onChanged : null,
      validator: (v) => v == null ? 'Please select $label' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          label == 'Gender' ? Icons.person_outline : Icons.work_outline,
          color: _iconColor, // Use custom color
        ),
        filled: true,
        fillColor: _isEditing ? Colors.grey[50] : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _iconColor,
            width: 2,
          ), // Use custom color for focused border
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 10,
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    final timestamp = _locationData?['lastLocationUpdate'];
    String formattedDate = 'Not available';

    if (timestamp is Timestamp) {
      formattedDate = DateFormat(
        "MMM d, y 'at' h:mm a",
      ).format(timestamp.toDate());
    }

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white, // Explicitly set card color to white
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.map_outlined, color: _iconColor), // Use custom color
                SizedBox(width: 10),
                Text(
                  'Location Information',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            _buildInfoRow(
              'Address',
              _locationData?['reverseGeocodedAddress'] ?? 'Not available',
            ),
            _buildInfoRow(
              'Coordinates',
              _locationData != null &&
                      _locationData!['latitude'] != null &&
                      _locationData!['longitude'] != null
                  ? 'Lat: ${_locationData!['latitude'].toStringAsFixed(4)}, Lng: ${_locationData!['longitude'].toStringAsFixed(4)}'
                  : 'Not available',
            ),
            _buildInfoRow('Last Update', formattedDate),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white, // Explicitly set card color to white
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.security_outlined,
                  color: _iconColor,
                ), // Use custom color
                SizedBox(width: 10),
                Text(
                  'Security',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            _buildTextField(
              _passwordController,
              'New Password (optional)',
              Icons.lock_outline,
              obscureText: !_passwordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[600],
                ),
                onPressed: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
              ),
              validator: (v) => _validate(v, 'Password'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white, // Explicitly set card color to white
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  color: _iconColor,
                ), // Use custom color
                SizedBox(width: 10),
                Text(
                  'Account Status',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            Row(
              children: [
                Icon(
                  _isActive
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: _isActive ? Colors.green[600] : Colors.red[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Account Status')),
                if (_isEditing)
                  Switch(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    activeColor: Colors.green,
                  )
                else
                  Text(
                    _isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: _isActive ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildMonitorButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminAudioListenPage(userId: widget.userId),
          ),
        ),
        icon: const Icon(Icons.mic_none_outlined),
        label: const Text(
          'Monitor User Activity',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _iconColor, // Use custom color
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return FloatingActionButton.extended(
      onPressed: _isLoading ? null : _updateUser,
      backgroundColor: _iconColor, // Use custom color
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : const Icon(Icons.save_outlined),
      label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
    );
  }
}
