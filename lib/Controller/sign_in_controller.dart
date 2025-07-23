// // import 'package:admin/Auth/forgot_password.dart';
// import 'package:admin/home.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class SigninController extends GetxController {
//   final emailOrPhoneController = TextEditingController();
//   final passwordController = TextEditingController();

//   var isPasswordVisible = false.obs;
//   var isInputEmpty = true.obs;
//   var isInputValid = false.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     emailOrPhoneController.addListener(() {
//       final input = emailOrPhoneController.text.trim();
//       isInputEmpty.value = input.isEmpty;
//       isInputValid.value = _isValidEmail(input) || _isValidPhone(input);
//     });
//   }

//   bool _isValidEmail(String email) {
//     final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
//     return emailRegex.hasMatch(email);
//   }

//   bool _isValidPhone(String phone) {
//     final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');
//     return phoneRegex.hasMatch(phone);
//   }

//   Future<String?> signIn(String input, String password) async {
//     try {
//       String? email;
//       String? uid;

//       if (_isValidEmail(input)) {
//         email = input;
//       } else if (_isValidPhone(input)) {
//         QuerySnapshot query = await FirebaseFirestore.instance
//             .collection('admins')
//             .where('phone', isEqualTo: input)
//             .limit(1)
//             .get();
//         if (query.docs.isNotEmpty) {
//           email = query.docs.first.get('email');
//           uid = query.docs.first.get('uid');
//         } else {
//           return 'No account found for this phone number.';
//         }
//       } else {
//         return 'Invalid email or phone number format.';
//       }

//       UserCredential userCredential = await FirebaseAuth.instance
//           .signInWithEmailAndPassword(email: email!, password: password);

//       uid ??= userCredential.user!.uid;

//       DocumentSnapshot adminDoc = await FirebaseFirestore.instance
//           .collection('admins')
//           .doc(uid)
//           .get();

//       if (adminDoc.exists && adminDoc.get('role') == 'admin') {
//         return null;
//       } else {
//         await FirebaseAuth.instance.signOut();
//         return 'Access denied. You are not an admin.';
//       }
//     } on FirebaseAuthException catch (e) {
//       return e.message;
//     } catch (e) {
//       return 'Unexpected error: $e';
//     }
//   }

//   Future<void> handleSignIn() async {
//     final input = emailOrPhoneController.text.trim();
//     final password = passwordController.text.trim();

//     if (input.isEmpty || password.isEmpty) {
//       Get.snackbar(
//         'Error',
//         'Please fill in both fields',
//         snackPosition: SnackPosition.BOTTOM,
//       );
//       return;
//     }

//     Get.dialog(
//       const Center(child: CircularProgressIndicator()),
//       barrierDismissible: false,
//     );

//     final result = await signIn(input, password);
//     Get.back(); // Remove loading

//     if (result == null) {
//       Get.offAll(() => Dashboard());
//       Get.snackbar(
//         "Success",
//         "Signed in successfully",
//         backgroundColor: const Color(0xFFFFCC3E),
//         colorText: const Color(0xFF030047),
//       );
//     } else {
//       Get.snackbar(
//         "Login Failed",
//         "Please Enter valid email, phone number, or password",
//       );
//     }
//   }

//   void togglePasswordVisibility() {
//     isPasswordVisible.value = !isPasswordVisible.value;
//   }
// }
// import 'package:admin/Auth/forgot_password.dart';
import 'package:admin/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SigninController extends GetxController {
  // Text Controllers
  final emailOrPhoneController = TextEditingController();
  final passwordController = TextEditingController();

  // Observable variables
  var isPasswordVisible = false.obs;
  var isInputEmpty = true.obs;
  var isInputValid = false.obs;
  var isLoading = false.obs; // Added loading state
  var hasError = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _setupValidationListeners();
  }

  @override
  void onClose() {
    // Dispose controllers to prevent memory leaks
    emailOrPhoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// Setup validation listeners for real-time feedback
  void _setupValidationListeners() {
    emailOrPhoneController.addListener(() {
      final input = emailOrPhoneController.text.trim();
      isInputEmpty.value = input.isEmpty;
      isInputValid.value = _isValidEmail(input) || _isValidPhone(input);

      // Clear error when user starts typing
      if (hasError.value) {
        _clearError();
      }
    });

    passwordController.addListener(() {
      // Clear error when user starts typing
      if (hasError.value) {
        _clearError();
      }
    });
  }

  /// Clear error state
  void _clearError() {
    hasError.value = false;
    errorMessage.value = '';
  }

  /// Set error state
  void _setError(String message) {
    hasError.value = true;
    errorMessage.value = message;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Validate phone format
  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');
    return phoneRegex.hasMatch(phone);
  }

  /// Firebase sign in method
  Future<String?> signIn(String input, String password) async {
    try {
      String? email;
      String? uid;

      if (_isValidEmail(input)) {
        email = input;
      } else if (_isValidPhone(input)) {
        // Query Firestore for phone number
        QuerySnapshot query = await FirebaseFirestore.instance
            .collection('admins')
            .where('phone', isEqualTo: input)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          email = query.docs.first.get('email');
          uid = query.docs.first.get('uid');
        } else {
          return 'No account found for this phone number.';
        }
      } else {
        return 'Invalid email or phone number format.';
      }

      // Sign in with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email!, password: password);

      uid ??= userCredential.user!.uid;

      // Verify admin role
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();

      if (adminDoc.exists && adminDoc.get('role') == 'admin') {
        return null; // Success
      } else {
        await FirebaseAuth.instance.signOut();
        return 'Access denied. You are not an admin.';
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many unsuccessful login attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return e.message ?? 'Authentication failed.';
      }
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  /// Handle sign in process with loading state
  Future<void> handleSignIn() async {
    try {
      // Start loading
      isLoading.value = true;
      _clearError();

      // Add haptic feedback
      HapticFeedback.lightImpact();

      final input = emailOrPhoneController.text.trim();
      final password = passwordController.text.trim();

      // Validate inputs
      if (input.isEmpty || password.isEmpty) {
        _setError('Please fill in both fields');
        _showErrorSnackbar('Error', 'Please fill in both fields');
        return;
      }

      if (!_isValidEmail(input) && !_isValidPhone(input)) {
        _setError('Please enter a valid email or phone number');
        _showErrorSnackbar(
          'Invalid Input',
          'Please enter a valid email or phone number',
        );
        return;
      }

      if (password.length < 6) {
        _setError('Password must be at least 6 characters');
        _showErrorSnackbar(
          'Invalid Password',
          'Password must be at least 6 characters',
        );
        return;
      }

      // Attempt sign in
      final result = await signIn(input, password);

      if (result == null) {
        // Success
        _handleSignInSuccess();
      } else {
        // Error
        _setError(result);
        _handleSignInError(result);
      }
    } catch (e) {
      _setError('An unexpected error occurred');
      _handleSignInError('An unexpected error occurred: $e');
    } finally {
      // Always stop loading
      isLoading.value = false;
    }
  }

  /// Handle successful sign in
  void _handleSignInSuccess() {
    // Navigate to dashboard
    Get.offAll(() => Dashboard());

    // Show success message
    Get.snackbar(
      "Welcome Back!",
      "Signed in successfully",
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade700,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
    );

    // Success haptic feedback
    HapticFeedback.lightImpact();
  }

  /// Handle sign in errors
  void _handleSignInError(String error) {
    _showErrorSnackbar("Login Failed", error);

    // Error haptic feedback
    HapticFeedback.heavyImpact();
  }

  /// Show error snackbar
  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade700,
      icon: const Icon(Icons.error, color: Colors.red),
      duration: const Duration(seconds: 4),
      snackPosition: SnackPosition.TOP,
    );
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// Handle forgot password
  void handleForgotPassword() async {
    final input = emailOrPhoneController.text.trim();

    if (input.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your email address',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade700,
      );
      return;
    }

    if (!_isValidEmail(input)) {
      Get.snackbar(
        'Error',
        'Please enter a valid email address',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade700,
      );
      return;
    }

    try {
      isLoading.value = true;

      await FirebaseAuth.instance.sendPasswordResetEmail(email: input);

      Get.snackbar(
        'Password Reset',
        'Password reset email has been sent to $input',
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade700,
        icon: const Icon(Icons.email, color: Colors.blue),
        duration: const Duration(seconds: 4),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to send password reset email';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email address';
      }

      Get.snackbar(
        'Error',
        message,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade700,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Handle social sign in (placeholder for future implementation)
  Future<void> handleSocialSignIn(String provider) async {
    Get.snackbar(
      '$provider Sign In',
      '$provider authentication will be implemented soon',
      backgroundColor: Colors.orange.shade100,
      colorText: Colors.orange.shade700,
      icon: const Icon(Icons.info, color: Colors.orange),
    );
  }

  /// Clear all form data
  void clearForm() {
    emailOrPhoneController.clear();
    passwordController.clear();
    _clearError();
    isPasswordVisible.value = false;
    isInputEmpty.value = true;
    isInputValid.value = false;
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      clearForm();
    } catch (e) {
      print('Sign out error: $e');
    }
  }
}
