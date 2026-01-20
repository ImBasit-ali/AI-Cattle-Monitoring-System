import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import 'dart:async';

/// Authentication Provider
class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<firebase_auth.User?>? _authSubscription;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  /// Initialize authentication state
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get current user
      final user = _firebaseService.currentUser;
      if (user != null) {
        // Load user profile data
        try {
          final profileData = await _firebaseService.getUserProfile(user.uid);
          
          debugPrint('📊 Loading user profile - ID: ${user.uid}, Email: ${user.email}');
          debugPrint('📊 Profile data: $profileData');
          
          _currentUser = UserModel(
            id: user.uid,
            email: user.email ?? '',
            name: profileData?['name'] ?? user.displayName,
            phoneNumber: profileData?['phone_number'],
            farmName: profileData?['farm_name'],
            farmLocation: profileData?['farm_location'],
            preferences: profileData?['preferences'] != null 
                ? Map<String, dynamic>.from(profileData!['preferences'])
                : null,
            createdAt: profileData?['created_at'] != null
                ? DateTime.fromMillisecondsSinceEpoch(profileData!['created_at'])
                : DateTime.now(),
            lastLoginAt: profileData?['last_login_at'] != null
                ? DateTime.fromMillisecondsSinceEpoch(profileData!['last_login_at'])
                : null,
          );
          
          debugPrint('✅ User loaded: ${_currentUser?.email}, Name: ${_currentUser?.name}');
        } catch (e) {
          debugPrint('⚠️ Error loading profile: $e');
          _currentUser = UserModel(
            id: user.uid,
            email: user.email ?? '',
            name: user.displayName,
            createdAt: DateTime.now(),
          );
        }
      }
      
      // Listen to auth state changes
      _setupAuthListener();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Setup authentication state listener
  void _setupAuthListener() {
    _authSubscription = _firebaseService.auth.authStateChanges().listen((user) async {
      if (user != null) {
        // Load user profile data when signing in
        try {
          final profileData = await _firebaseService.getUserProfile(user.uid);
          
          _currentUser = UserModel(
            id: user.uid,
            email: user.email ?? '',
            name: profileData?['name'] ?? user.displayName,
            phoneNumber: profileData?['phone_number'],
            farmName: profileData?['farm_name'],
            farmLocation: profileData?['farm_location'],
            preferences: profileData?['preferences'] != null 
                ? Map<String, dynamic>.from(profileData!['preferences'])
                : null,
            createdAt: profileData?['created_at'] != null
                ? DateTime.fromMillisecondsSinceEpoch(profileData!['created_at'])
                : DateTime.now(),
            lastLoginAt: profileData?['last_login_at'] != null
                ? DateTime.fromMillisecondsSinceEpoch(profileData!['last_login_at'])
                : null,
          );
        } catch (e) {
          _currentUser = UserModel(
            id: user.uid,
            email: user.email ?? '',
            name: user.displayName,
            createdAt: DateTime.now(),
          );
        }
        notifyListeners();
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  /// Check if email already exists
  Future<bool> emailExists(String email) async {
    try {
      return await _firebaseService.emailExists(email);
    } catch (e) {
      return false;
    }
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔄 Checking if email exists: $email');
      
      // Check if email already exists
      final exists = await _firebaseService.emailExists(email);
      if (exists) {
        _errorMessage = 'An account with this email already exists. Please sign in instead.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      debugPrint('🔄 Attempting signup for: $email');
      final userCredential = await _firebaseService.signUp(
        email: email,
        password: password,
        userData: {'name': name ?? ''},
      );

      debugPrint('📊 Signup response - User: ${userCredential.user?.uid}');

      // Check if signup was successful
      if (userCredential.user == null) {
        _errorMessage = 'Failed to create account. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // User account created successfully
      debugPrint('✅ User created, loading profile...');
      
      // Load profile data
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        
        final profileData = await _firebaseService.getUserProfile(userCredential.user!.uid);
        debugPrint('📊 Profile loaded: ${profileData?['name']}');
        
        _currentUser = UserModel(
          id: userCredential.user!.uid,
          email: email,
          name: profileData?['name'] ?? name ?? '',
          phoneNumber: profileData?['phone_number'],
          farmName: profileData?['farm_name'],
          farmLocation: profileData?['farm_location'],
          preferences: profileData?['preferences'] != null 
              ? Map<String, dynamic>.from(profileData!['preferences'])
              : null,
          createdAt: profileData?['created_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(profileData!['created_at'])
              : DateTime.now(),
          lastLoginAt: profileData?['last_login_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(profileData!['last_login_at'])
              : null,
        );
      } catch (e) {
        debugPrint('⚠️ Error loading profile: $e');
        _currentUser = UserModel(
          id: userCredential.user!.uid,
          email: email,
          name: name ?? '',
          createdAt: DateTime.now(),
        );
      }
        
      _isLoading = false;
      debugPrint('✅ Signup successful! User: ${_currentUser?.email}, Name: ${_currentUser?.name}');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔄 Attempting login for: $email');
      
      final userCredential = await _firebaseService.signIn(
        email: email,
        password: password,
      );

      debugPrint('📊 Login response - User: ${userCredential.user?.uid}');

      if (userCredential.user == null) {
        _errorMessage = 'Login failed. Please check your credentials.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Load user profile data
      try {
        debugPrint('🔄 Loading user profile for: ${userCredential.user!.uid}');
        
        final profileData = await _firebaseService.getUserProfile(userCredential.user!.uid);
        debugPrint('📊 Profile data: ${profileData?['name']}');
        
        _currentUser = UserModel(
          id: userCredential.user!.uid,
          email: email,
          name: profileData?['name'] ?? userCredential.user!.displayName ?? '',
          phoneNumber: profileData?['phone_number'],
          farmName: profileData?['farm_name'],
          farmLocation: profileData?['farm_location'],
          preferences: profileData?['preferences'] != null 
              ? Map<String, dynamic>.from(profileData!['preferences'])
              : null,
          createdAt: profileData?['created_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(profileData!['created_at'])
              : DateTime.now(),
          lastLoginAt: profileData?['last_login_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(profileData!['last_login_at'])
              : null,
        );
      } catch (e) {
        debugPrint('⚠️ Error loading profile, using basic user data: $e');
        _currentUser = UserModel(
          id: userCredential.user!.uid,
          email: email,
          name: userCredential.user!.displayName ?? '',
          createdAt: DateTime.now(),
        );
      }

      _isLoading = false;
      debugPrint('✅ Login successful! User: ${_currentUser?.email}, Name: ${_currentUser?.name}');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Login error: $e');
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseService.signOut();
      _currentUser = null;
      debugPrint('✅ User signed out successfully');
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ Sign out error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error is firebase_auth.FirebaseAuthException) {
      // Map common Firebase errors to user-friendly messages
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email. Please sign up.';
        case 'wrong-password':
          return 'Invalid password. Please try again.';
        case 'email-already-in-use':
          return 'This email is already registered. Please sign in instead.';
        case 'invalid-email':
          return 'Invalid email format. Please check and try again.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is disabled. Please contact support.';
        case 'invalid-credential':
          return 'Invalid email or password. Please try again.';
        default:
          return error.message ?? 'An error occurred. Please try again.';
      }
    }
    return error.toString().replaceAll('Exception: ', '');
  }
  
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
