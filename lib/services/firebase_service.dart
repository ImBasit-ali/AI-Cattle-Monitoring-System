import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/constants/app_constants.dart';

/// Firebase Service - Handles authentication and database operations
class FirebaseService {
  static FirebaseService? _instance;
  late final FirebaseAuth _auth;
  late final FirebaseDatabase _database;
  late final FirebaseStorage _storage;

  FirebaseService._internal();

  static FirebaseService get instance {
    _instance ??= FirebaseService._internal();
    return _instance!;
  }

  /// Initialize Firebase
  Future<void> initialize() async {
    _auth = FirebaseAuth.instance;
    _database = FirebaseDatabase.instance;
    _storage = FirebaseStorage.instance;
    
    // Enable offline persistence for Realtime Database
    _database.setPersistenceEnabled(true);
  }

  /// Get Firebase Auth instance
  FirebaseAuth get auth => _auth;

  /// Get Firebase Database instance
  FirebaseDatabase get database => _database;

  /// Get Firebase Storage instance
  FirebaseStorage get storage => _storage;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get current user ID
  String? get currentUserId => currentUser?.uid;

  // ==================== AUTHENTICATION ====================

  /// Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    try {
      print('🔄 FirebaseService: Attempting signup for $email');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user profile in Realtime Database
      if (userCredential.user != null && userData != null) {
        await _createUserProfile(userCredential.user!.uid, email, userData);
      }
      
      print('✅ FirebaseService: Signup successful - User ID: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      print('❌ FirebaseService: Signup error: $e');
      rethrow;
    }
  }

  /// Create user profile in database
  Future<void> _createUserProfile(
    String userId,
    String email,
    Map<String, dynamic> userData,
  ) async {
    final profileData = {
      'id': userId,
      'email': email,
      'name': userData['name'],
      'phone_number': userData['phone_number'],
      'farm_name': userData['farm_name'],
      'farm_location': userData['farm_location'],
      'created_at': ServerValue.timestamp,
      'last_login_at': ServerValue.timestamp,
    };
    
    await _database.ref('user_profiles/$userId').set(profileData);
  }

  /// Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔄 FirebaseService: Attempting signin for $email');
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update last login
      if (userCredential.user != null) {
        await updateLastLogin(userCredential.user!.uid);
      }
      
      print('✅ FirebaseService: Signin successful - User ID: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      print('❌ FirebaseService: Signin error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      // Update display name if provided
      if (data.containsKey('name')) {
        await user.updateDisplayName(data['name']);
      }
      
      // Update profile data in database
      await updateUserProfileData(user.uid, data);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== USER PROFILES ====================

  /// Check if email already exists
  Future<bool> emailExists(String email) async {
    try {
      final snapshot = await _database
          .ref('user_profiles')
          .orderByChild('email')
          .equalTo(email.toLowerCase())
          .limitToFirst(1)
          .get();
      return snapshot.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final snapshot = await _database.ref('user_profiles/$userId').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile in database
  Future<Map<String, dynamic>> updateUserProfileData(
    String userId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      await _database.ref('user_profiles/$userId').update(profileData);
      
      // Fetch and return updated profile
      final profile = await getUserProfile(userId);
      return profile ?? {};
    } catch (e) {
      rethrow;
    }
  }

  /// Update last login timestamp
  Future<void> updateLastLogin(String userId) async {
    try {
      await _database.ref('user_profiles/$userId').update({
        'last_login_at': ServerValue.timestamp,
      });
    } catch (e) {
      // Don't throw - last login update is not critical
    }
  }

  // ==================== ANIMALS ====================

  /// Create a new animal
  Future<Map<String, dynamic>> createAnimal(Map<String, dynamic> animalData) async {
    try {
      final animalRef = _database.ref(AppConstants.animalsTable).push();
      final animalId = animalRef.key!;
      
      final dataWithId = {
        ...animalData,
        'id': animalId,
        'created_at': ServerValue.timestamp,
      };
      
      await animalRef.set(dataWithId);
      
      // Return the created animal data
      final snapshot = await animalRef.get();
      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all animals for current user
  Future<List<Map<String, dynamic>>> getAnimals() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _database
          .ref(AppConstants.animalsTable)
          .orderByChild('user_id')
          .equalTo(currentUserId!)
          .get();

      if (!snapshot.exists) return [];

      final animalsMap = Map<String, dynamic>.from(snapshot.value as Map);
      final animalsList = animalsMap.entries.map((entry) {
        final data = Map<String, dynamic>.from(entry.value as Map);
        data['id'] = entry.key;
        return data;
      }).toList();

      // Sort by created_at descending
      animalsList.sort((a, b) {
        final aTime = a['created_at'] ?? 0;
        final bTime = b['created_at'] ?? 0;
        return bTime.compareTo(aTime);
      });

      return animalsList;
    } catch (e) {
      rethrow;
    }
  }

  /// Get animal by ID
  Future<Map<String, dynamic>> getAnimalById(String animalId) async {
    try {
      final snapshot = await _database
          .ref('${AppConstants.animalsTable}/$animalId')
          .get();
      
      if (!snapshot.exists) {
        throw Exception('Animal not found');
      }
      
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data['id'] = animalId;
      return data;
    } catch (e) {
      rethrow;
    }
  }

  /// Update animal
  Future<Map<String, dynamic>> updateAnimal(
    String animalId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _database
          .ref('${AppConstants.animalsTable}/$animalId')
          .update(updates);
      
      return await getAnimalById(animalId);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete animal
  Future<void> deleteAnimal(String animalId) async {
    try {
      await _database
          .ref('${AppConstants.animalsTable}/$animalId')
          .remove();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== MOVEMENT DATA ====================

  /// Create movement data record
  Future<Map<String, dynamic>> createMovementData(
    Map<String, dynamic> movementData,
  ) async {
    try {
      final movementRef = _database.ref(AppConstants.movementDataTable).push();
      final movementId = movementRef.key!;
      
      final dataWithId = {
        ...movementData,
        'id': movementId,
        'created_at': ServerValue.timestamp,
      };
      
      await movementRef.set(dataWithId);
      
      final snapshot = await movementRef.get();
      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (e) {
      rethrow;
    }
  }

  /// Get movement data for an animal
  Future<List<Map<String, dynamic>>> getMovementData({
    required String animalId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      var query = _database
          .ref(AppConstants.movementDataTable)
          .orderByChild('animal_id')
          .equalTo(animalId);

      final snapshot = await query.get();
      if (!snapshot.exists) return [];

      final dataMap = Map<String, dynamic>.from(snapshot.value as Map);
      var dataList = dataMap.entries.map((entry) {
        final data = Map<String, dynamic>.from(entry.value as Map);
        data['id'] = entry.key;
        return data;
      }).toList();

      // Filter by date if provided
      if (startDate != null) {
        dataList = dataList.where((item) {
          final itemDate = DateTime.parse(item['date']);
          return itemDate.isAfter(startDate) || itemDate.isAtSameMomentAs(startDate);
        }).toList();
      }

      if (endDate != null) {
        dataList = dataList.where((item) {
          final itemDate = DateTime.parse(item['date']);
          return itemDate.isBefore(endDate) || itemDate.isAtSameMomentAs(endDate);
        }).toList();
      }

      // Sort by date descending
      dataList.sort((a, b) {
        final aDate = DateTime.parse(a['date']);
        final bDate = DateTime.parse(b['date']);
        return bDate.compareTo(aDate);
      });

      if (limit != null && dataList.length > limit) {
        dataList = dataList.sublist(0, limit);
      }

      return dataList;
    } catch (e) {
      rethrow;
    }
  }

  /// Get latest movement data for an animal
  Future<Map<String, dynamic>?> getLatestMovementData(String animalId) async {
    try {
      final dataList = await getMovementData(animalId: animalId, limit: 1);
      return dataList.isNotEmpty ? dataList.first : null;
    } catch (e) {
      rethrow;
    }
  }

  // ==================== LAMENESS RECORDS ====================

  /// Create lameness record
  Future<Map<String, dynamic>> createLamenessRecord(
    Map<String, dynamic> lamenessData,
  ) async {
    try {
      final recordRef = _database.ref(AppConstants.lamenessRecordsTable).push();
      final recordId = recordRef.key!;
      
      final dataWithId = {
        ...lamenessData,
        'id': recordId,
        'created_at': ServerValue.timestamp,
      };
      
      await recordRef.set(dataWithId);
      
      final snapshot = await recordRef.get();
      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (e) {
      rethrow;
    }
  }

  /// Get lameness records for an animal
  Future<List<Map<String, dynamic>>> getLamenessRecords({
    required String animalId,
    int? limit,
  }) async {
    try {
      final snapshot = await _database
          .ref(AppConstants.lamenessRecordsTable)
          .orderByChild('animal_id')
          .equalTo(animalId)
          .get();

      if (!snapshot.exists) return [];

      final dataMap = Map<String, dynamic>.from(snapshot.value as Map);
      var dataList = dataMap.entries.map((entry) {
        final data = Map<String, dynamic>.from(entry.value as Map);
        data['id'] = entry.key;
        return data;
      }).toList();

      // Sort by detection_date descending
      dataList.sort((a, b) {
        final aDate = DateTime.parse(a['detection_date']);
        final bDate = DateTime.parse(b['detection_date']);
        return bDate.compareTo(aDate);
      });

      if (limit != null && dataList.length > limit) {
        dataList = dataList.sublist(0, limit);
      }

      return dataList;
    } catch (e) {
      rethrow;
    }
  }

  /// Get latest lameness record for an animal
  Future<Map<String, dynamic>?> getLatestLamenessRecord(String animalId) async {
    try {
      final records = await getLamenessRecords(animalId: animalId, limit: 1);
      return records.isNotEmpty ? records.first : null;
    } catch (e) {
      rethrow;
    }
  }

  // ==================== VIDEO RECORDS ====================

  /// Create video record
  Future<Map<String, dynamic>> createVideoRecord(
    Map<String, dynamic> videoData,
  ) async {
    try {
      final videoRef = _database.ref(AppConstants.videoRecordsTable).push();
      final videoId = videoRef.key!;
      
      final dataWithId = {
        ...videoData,
        'id': videoId,
        'created_at': ServerValue.timestamp,
      };
      
      await videoRef.set(dataWithId);
      
      final snapshot = await videoRef.get();
      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (e) {
      rethrow;
    }
  }

  /// Get video records for an animal
  Future<List<Map<String, dynamic>>> getVideoRecords({
    required String animalId,
    int? limit,
  }) async {
    try {
      final snapshot = await _database
          .ref(AppConstants.videoRecordsTable)
          .orderByChild('animal_id')
          .equalTo(animalId)
          .get();

      if (!snapshot.exists) return [];

      final dataMap = Map<String, dynamic>.from(snapshot.value as Map);
      var dataList = dataMap.entries.map((entry) {
        final data = Map<String, dynamic>.from(entry.value as Map);
        data['id'] = entry.key;
        return data;
      }).toList();

      // Sort by upload_date descending
      dataList.sort((a, b) {
        final aDate = DateTime.parse(a['upload_date']);
        final bDate = DateTime.parse(b['upload_date']);
        return bDate.compareTo(aDate);
      });

      if (limit != null && dataList.length > limit) {
        dataList = dataList.sublist(0, limit);
      }

      return dataList;
    } catch (e) {
      rethrow;
    }
  }

  /// Update video processing status
  Future<Map<String, dynamic>> updateVideoProcessingStatus({
    required String videoId,
    required String status,
    Map<String, dynamic>? results,
    String? errorMessage,
  }) async {
    try {
      final updates = <String, dynamic>{
        'processing_status': status,
      };

      if (results != null) {
        updates['analysis_results'] = results;
      }

      if (errorMessage != null) {
        updates['error_message'] = errorMessage;
      }

      await _database
          .ref('${AppConstants.videoRecordsTable}/$videoId')
          .update(updates);

      final snapshot = await _database
          .ref('${AppConstants.videoRecordsTable}/$videoId')
          .get();
      
      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== STORAGE ====================

  /// Upload file to storage
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required List<int> fileBytes,
    String? contentType,
  }) async {
    try {
      final ref = _storage.ref().child('$bucket/$path');
      
      SettableMetadata? metadata;
      if (contentType != null) {
        metadata = SettableMetadata(contentType: contentType);
      }
      
      await ref.putData(Uint8List.fromList(fileBytes), metadata);
      
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete file from storage
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      final ref = _storage.ref().child('$bucket/$path');
      await ref.delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Get download URL for file
  Future<String> getDownloadUrl({
    required String bucket,
    required String path,
  }) async {
    try {
      final ref = _storage.ref().child('$bucket/$path');
      return await ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== REAL-TIME SUBSCRIPTIONS ====================

  /// Subscribe to animal updates
  Stream<DatabaseEvent> subscribeToAnimals(String userId) {
    return _database
        .ref(AppConstants.animalsTable)
        .orderByChild('user_id')
        .equalTo(userId)
        .onValue;
  }

  /// Subscribe to movement data updates
  Stream<DatabaseEvent> subscribeToMovementData(String animalId) {
    return _database
        .ref(AppConstants.movementDataTable)
        .orderByChild('animal_id')
        .equalTo(animalId)
        .onValue;
  }

  /// Subscribe to specific animal updates
  Stream<DatabaseEvent> subscribeToAnimal(String animalId) {
    return _database
        .ref('${AppConstants.animalsTable}/$animalId')
        .onValue;
  }
}
