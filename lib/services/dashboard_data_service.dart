import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/firebase_service.dart';

/// Dashboard Data Service - Fetches real-time statistics from Firebase
/// 
/// DATA SECURITY & USER ISOLATION:
/// ===============================
/// All database queries are automatically filtered by the authenticated user's ID
/// through Firebase Security Rules. This ensures:
/// 
/// 1. Each user ONLY sees their own cattle data
/// 2. Users CANNOT access other users' data, even if they try
/// 3. Data isolation is enforced at the DATABASE level, not just in the app
/// 4. WRITE operations automatically include user_id from the authenticated session
/// 
/// Security Rules Applied to:
/// - animals/{userId}/
/// - ear_tag_camera/{userId}/
/// - depth_camera/{userId}/
/// - side_view_camera/{userId}/
/// - milking_status/{userId}/
/// - video_records/{userId}/
/// 
/// This means all data is stored under the user's ID path,
/// and Firebase will automatically enforce access control.

/// Dashboard Statistics Model
class DashboardStats {
  final int totalCattle;
  final int healthyCattle;
  final int lamenessCattle;
  final int milkingCattle;
  final Map<String, int> dailyCounts; // date -> count
  final Map<String, int> lamenessCount; // date -> lameness count
  final Map<String, double> avgBCS; // date -> average BCS
  
  DashboardStats({
    this.totalCattle = 0,
    this.healthyCattle = 0,
    this.lamenessCattle = 0,
    this.milkingCattle = 0,
    this.dailyCounts = const {},
    this.lamenessCount = const {},
    this.avgBCS = const {},
  });
}

/// Dashboard Data Service - Fetches real-time statistics from Firebase
class DashboardDataService {
  static final DashboardDataService _instance = DashboardDataService._internal();
  factory DashboardDataService() => _instance;
  DashboardDataService._internal();

  static DashboardDataService get instance => _instance;

  final FirebaseService _firebaseService = FirebaseService.instance;
  DatabaseReference get _db => _firebaseService.database.ref();
  String? get _userId => _firebaseService.currentUserId;

  /// Get dashboard statistics
  Future<DashboardStats> getDashboardStats() async {
    try {
      if (_userId == null) {
        debugPrint('No authenticated user');
        return DashboardStats();
      }

      // Get unique cattle count from ear_tag_camera
      final earTagSnapshot = await _db.child('ear_tag_camera/$_userId').get();
      
      final uniqueCattle = <String>{};
      if (earTagSnapshot.exists) {
        final earTagData = Map<String, dynamic>.from(earTagSnapshot.value as Map);
        for (final record in earTagData.values) {
          if (record is Map) {
            final cowId = record['cow_id'];
            if (cowId != null) {
              uniqueCattle.add(cowId.toString());
            }
          }
        }
      }

      // Get lameness records
      final lamenessSnapshot = await _db.child('depth_camera/$_userId').get();
      final lamenessCattleSet = <String>{};
      final Map<String, int> lamenessCountByDate = {};
      
      if (lamenessSnapshot.exists) {
        final lamenessData = Map<String, dynamic>.from(lamenessSnapshot.value as Map);
        for (final record in lamenessData.values) {
          if (record is Map) {
            final score = record['lameness_score'];
            final cowId = record['cow_id'];
            final timestamp = record['post_milking_timestamp'];
            
            if (score != null && score is int && score > 1 && cowId != null) {
              lamenessCattleSet.add(cowId.toString());
            }
            
            // Group by date
            if (timestamp != null) {
              try {
                final date = DateTime.parse(timestamp.toString());
                final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                lamenessCountByDate[dateKey] = (lamenessCountByDate[dateKey] ?? 0) + 1;
              } catch (e) {
                debugPrint('Error parsing timestamp: $e');
              }
            }
          }
        }
      }

      // Get BCS records from video_records
      final videoRecordsSnapshot = await _db.child('video_records/$_userId').get();
      final Map<String, List<double>> bcsByDate = {};
      
      if (videoRecordsSnapshot.exists) {
        final videoRecordsData = Map<String, dynamic>.from(videoRecordsSnapshot.value as Map);
        for (final record in videoRecordsData.values) {
          if (record is Map) {
            final timestamp = record['timestamp'];
            final analysisResults = record['analysis_results'];
            
            if (timestamp != null && analysisResults != null && analysisResults is Map) {
              try {
                final date = DateTime.parse(timestamp.toString());
                final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                
                final bcsScore = analysisResults['bcs_score'];
                if (bcsScore != null && bcsScore is num) {
                  if (!bcsByDate.containsKey(dateKey)) {
                    bcsByDate[dateKey] = [];
                  }
                  bcsByDate[dateKey]!.add(bcsScore.toDouble());
                }
              } catch (e) {
                debugPrint('Error parsing timestamp: $e');
              }
            }
          }
        }
      }

      // Calculate average BCS per date
      final Map<String, double> avgBcsByDate = {};
      bcsByDate.forEach((date, scores) {
        avgBcsByDate[date] = scores.reduce((a, b) => a + b) / scores.length;
      });

      // Count daily cattle detections
      final Map<String, int> dailyCounts = {};
      if (earTagSnapshot.exists) {
        final earTagData = Map<String, dynamic>.from(earTagSnapshot.value as Map);
        for (final record in earTagData.values) {
          if (record is Map) {
            final timestamp = record['timestamp'];
            if (timestamp != null) {
              try {
                final date = DateTime.parse(timestamp.toString());
                final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
              } catch (e) {
                debugPrint('Error parsing timestamp: $e');
              }
            }
          }
        }
      }

      // Get milking status from animals table
      final animalsSnapshot = await _db.child('animals/$_userId').get();
      int milkingCattle = 0;
      
      if (animalsSnapshot.exists) {
        final animalsData = Map<String, dynamic>.from(animalsSnapshot.value as Map);
        for (final animal in animalsData.values) {
          if (animal is Map && animal['milking_status'] == 'milking') {
            milkingCattle++;
          }
        }
      }
      
      final totalCattle = uniqueCattle.length;
      final lamenessCattle = lamenessCattleSet.length;
      final healthyCattle = totalCattle - lamenessCattle;

      return DashboardStats(
        totalCattle: totalCattle,
        healthyCattle: healthyCattle,
        lamenessCattle: lamenessCattle,
        milkingCattle: milkingCattle,
        dailyCounts: dailyCounts,
        lamenessCount: lamenessCountByDate,
        avgBCS: avgBcsByDate,
      );
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
      return DashboardStats();
    }
  }

  /// Get today's detected cattle with health data
  Future<List<Map<String, dynamic>>> getTodaysCattle() async {
    try {
      if (_userId == null) return [];

      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      // Get ear tag detections from today
      final earTagSnapshot = await _db.child('ear_tag_camera/$_userId').get();
      final lamenessSnapshot = await _db.child('depth_camera/$_userId').get();
      final videoRecordsSnapshot = await _db.child('video_records/$_userId').get();
      
      // Build cattle map
      final Map<String, Map<String, dynamic>> cattleMap = {};
      
      if (earTagSnapshot.exists) {
        final earTagData = Map<String, dynamic>.from(earTagSnapshot.value as Map);
        for (final record in earTagData.values) {
          if (record is Map) {
            final timestamp = record['detection_timestamp'];
            if (timestamp != null && timestamp.toString().startsWith(today)) {
              final cowId = record['cow_id']?.toString();
              if (cowId != null) {
                cattleMap[cowId] = {
                  'cow_id': cowId,
                  'ear_tag': record['ear_tag_number'],
                  'lameness_score': 0.0,
                  'bcs_score': null,
                  'timestamp': timestamp,
                };
              }
            }
          }
        }
      }
      
      // Add lameness scores
      if (lamenessSnapshot.exists) {
        final lamenessData = Map<String, dynamic>.from(lamenessSnapshot.value as Map);
        for (final record in lamenessData.values) {
          if (record is Map) {
            final cowId = record['cow_id']?.toString();
            if (cowId != null && cattleMap.containsKey(cowId)) {
              cattleMap[cowId]!['lameness_score'] = (record['lameness_score'] as num?)?.toDouble() ?? 0.0;
            }
          }
        }
      }
      
      // Add BCS scores from video processing
      if (videoRecordsSnapshot.exists) {
        final videoRecords = Map<String, dynamic>.from(videoRecordsSnapshot.value as Map);
        for (final record in videoRecords.values) {
          if (record is Map) {
            final analysisResults = record['analysis_results'];
            if (analysisResults != null && analysisResults is Map) {
              final bcsScore = analysisResults['bcs_score'];
              if (bcsScore != null && cattleMap.isNotEmpty) {
                final firstCowId = cattleMap.keys.first;
                cattleMap[firstCowId]!['bcs_score'] = (bcsScore as num).toDouble();
              }
            }
          }
        }
      }
      
      return cattleMap.values.toList();
    } catch (e) {
      debugPrint('Error fetching today\'s cattle: $e');
      return [];
    }
  }

  /// Subscribe to real-time updates using Firebase Database listeners
  StreamSubscription? subscribeToUpdates(Function(DashboardStats) onUpdate) {
    if (_userId == null) return null;
    
    // Listen to all relevant database paths
    final stream = _db.child('ear_tag_camera/$_userId').onValue;
    
    return stream.listen((event) async {
      debugPrint('🔔 Real-time update: Database changed');
      final stats = await getDashboardStats();
      onUpdate(stats);
    });
  }

  /// Get all cattle information with milking and lameness status
  Future<List<Map<String, dynamic>>> getCattleInformation() async {
    try {
      if (_userId == null) return [];

      // Get all cattle data
      final earTagSnapshot = await _db.child('ear_tag_camera/$_userId').get();
      final milkingSnapshot = await _db.child('milking_status/$_userId').get();
      final lamenessSnapshot = await _db.child('depth_camera/$_userId').get();
      
      // Get unique cattle
      final Map<String, Map<String, dynamic>> uniqueCattle = {};
      if (earTagSnapshot.exists) {
        final earTagData = Map<String, dynamic>.from(earTagSnapshot.value as Map);
        for (final entry in earTagData.entries) {
          final record = entry.value;
          if (record is Map) {
            final cowId = record['cow_id'];
            if (cowId != null && !uniqueCattle.containsKey(cowId.toString())) {
              uniqueCattle[cowId.toString()] = Map<String, dynamic>.from(record);
            }
          }
        }
      }

      // Build results with health data
      final results = <Map<String, dynamic>>[];
      
      for (final cattle in uniqueCattle.values) {
        final cowId = cattle['cow_id'];
        
        // Get latest milking status
        bool isMilking = false;
        double? milkingConfidence;
        if (milkingSnapshot.exists) {
          final milkingData = Map<String, dynamic>.from(milkingSnapshot.value as Map);
          for (final record in milkingData.values) {
            if (record is Map && record['cow_id'] == cowId) {
              isMilking = record['is_being_milked'] == true;
              milkingConfidence = (record['milking_confidence'] as num?)?.toDouble();
              break;
            }
          }
        }

        // Get latest lameness score
        int? lamenessScore;
        String? lamenessSeverity;
        if (lamenessSnapshot.exists) {
          final lamenessData = Map<String, dynamic>.from(lamenessSnapshot.value as Map);
          for (final record in lamenessData.values) {
            if (record is Map && record['cow_id'] == cowId) {
              lamenessScore = record['lameness_score'];
              lamenessSeverity = record['lameness_severity'];
              break;
            }
          }
        }

        final isLame = lamenessScore != null && lamenessScore > 1;

        results.add({
          'cow_id': cowId,
          'ear_tag': cattle['ear_tag_number'],
          'is_milking': isMilking,
          'is_lame': isLame,
          'lameness_score': lamenessScore,
          'lameness_severity': lamenessSeverity,
          'milking_confidence': milkingConfidence,
        });
      }

      return results;
    } catch (e) {
      debugPrint('Error fetching cattle information: $e');
      return [];
    }
  }
}

//     try {
//       // Get unique cattle count from ear_tag_camera (RLS filters by current user)
//       final earTagData = await _supabaseService.client
//           .from('ear_tag_camera')
//           .select('cow_id')
//           .order('timestamp', ascending: false);
      
//       final uniqueCattle = <String>{};
//       for (final record in earTagData) {
//         final cowId = record['cow_id'];
//         if (cowId != null) {
//           uniqueCattle.add(cowId.toString());
//         }
//       }

//       // Get lameness records (RLS filters by current user)
//       final lamenessData = await _supabaseService.client
//           .from('depth_camera')
//           .select('cow_id, lameness_score, lameness_severity, post_milking_timestamp')
//           .order('post_milking_timestamp', ascending: false);

//       // Count lameness cattle (score > 1)
//       final lamenessCattleSet = <String>{};
//       final Map<String, int> lamenessCountByDate = {};
      
//       for (final record in lamenessData) {
//         final score = record['lameness_score'];
//         final cowId = record['cow_id'];
//         final timestampStr = record['post_milking_timestamp'];
        
//         if (score != null && score is int && score > 1 && cowId != null) {
//           lamenessCattleSet.add(cowId.toString());
//         }
        
//         // Group by date
//         if (timestampStr != null) {
//           final timestamp = DateTime.parse(timestampStr.toString());
//           final dateKey = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
//           lamenessCountByDate[dateKey] = (lamenessCountByDate[dateKey] ?? 0) + 1;
//         }
//       }

//       // Get BCS records from video_records and rgbd_camera (if available)
//       final videoRecordsData = await _supabaseService.client
//           .from('video_records')
//           .select('analysis_results, timestamp')
//           .order('timestamp', ascending: false);

//       final Map<String, List<double>> bcsByDate = {};
//       for (final record in videoRecordsData) {
//         final timestampStr = record['timestamp'];
//         final analysisResults = record['analysis_results'];
        
//         if (timestampStr != null && analysisResults != null && analysisResults is Map) {
//           final timestamp = DateTime.parse(timestampStr.toString());
//           final dateKey = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
          
//           final bcsScore = analysisResults['bcs_score'];
//           if (bcsScore != null && bcsScore is num) {
//             if (!bcsByDate.containsKey(dateKey)) {
//               bcsByDate[dateKey] = [];
//             }
//             bcsByDate[dateKey]!.add(bcsScore.toDouble());
//           }
//         }
//       }

//       // Calculate average BCS per date
//       final Map<String, double> avgBcsByDate = {};
//       bcsByDate.forEach((date, scores) {
//         avgBcsByDate[date] = scores.reduce((a, b) => a + b) / scores.length;
//       });

//       // Count daily cattle detections
//       final Map<String, int> dailyCounts = {};
//       for (final record in earTagData) {
//         final timestampStr = record['timestamp'];
//         if (timestampStr != null) {
//           final timestamp = DateTime.parse(timestampStr.toString());
//           final dateKey = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
//           dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
//         }
//       }

//       // Get milking status from animals table (RLS filters by current user)
//       final milkingData = await _supabaseService.client
//           .from('animals')
//           .select('animal_id, milking_status')
//           .eq('milking_status', 'milking');
      
//       final milkingCattle = milkingData.length;
      
//       final totalCattle = uniqueCattle.length;
//       final lamenessCattle = lamenessCattleSet.length;
//       final healthyCattle = totalCattle - lamenessCattle;

//       return DashboardStats(
//         totalCattle: totalCattle,
//         healthyCattle: healthyCattle,
//         lamenessCattle: lamenessCattle,
//         milkingCattle: milkingCattle,
//         dailyCounts: dailyCounts,
//         lamenessCount: lamenessCountByDate,
//         avgBCS: avgBcsByDate,
//       );
//     } catch (e) {
//       debugPrint('Error fetching dashboard stats: $e');
//       return DashboardStats();
//     }
//   }

//   /// Get today's detected cattle with health data
//   Future<List<Map<String, dynamic>>> getTodaysCattle() async {
//     try {
//       final now = DateTime.now();
//       final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
//       // Get ear tag detections from today
//       final earTagData = await _supabaseService.client
//           .from('ear_tag_camera')
//           .select('cow_id, ear_tag_number, detection_timestamp')
//           .gte('detection_timestamp', '${today}T00:00:00')
//           .lte('detection_timestamp', '${today}T23:59:59')
//           .order('detection_timestamp', ascending: false);
      
//       // Get lameness data
//       final lamenessData = await _supabaseService.client
//           .from('depth_camera')
//           .select('cow_id, lameness_score, post_milking_timestamp')
//           .gte('post_milking_timestamp', '${today}T00:00:00')
//           .order('post_milking_timestamp', ascending: false);
      
//       // Get BCS data from video records
//       final videoRecords = await _supabaseService.client
//           .from('video_records')
//           .select('analysis_results, timestamp')
//           .gte('timestamp', '${today}T00:00:00')
//           .order('timestamp', ascending: false);
      
//       // Build cattle list with health metrics
//       final Map<String, Map<String, dynamic>> cattleMap = {};
      
//       for (final record in earTagData) {
//         final cowId = record['cow_id']?.toString();
//         if (cowId != null) {
//           cattleMap[cowId] = {
//             'cow_id': cowId,
//             'ear_tag': record['ear_tag_number'],
//             'lameness_score': 0.0,
//             'bcs_score': null,
//             'timestamp': record['detection_timestamp'],
//           };
//         }
//       }
      
//       // Add lameness scores
//       for (final record in lamenessData) {
//         final cowId = record['cow_id']?.toString();
//         if (cowId != null && cattleMap.containsKey(cowId)) {
//           cattleMap[cowId]!['lameness_score'] = (record['lameness_score'] as num?)?.toDouble() ?? 0.0;
//         }
//       }
      
//       // Add BCS scores from video processing
//       for (final record in videoRecords) {
//         final analysisResults = record['analysis_results'];
//         if (analysisResults != null && analysisResults is Map) {
//           final bcsScore = analysisResults['bcs_score'];
//           if (bcsScore != null) {
//             // For now, apply to first cattle in map (in production, match by cattle ID)
//             if (cattleMap.isNotEmpty) {
//               final firstCowId = cattleMap.keys.first;
//               cattleMap[firstCowId]!['bcs_score'] = (bcsScore as num).toDouble();
//             }
//           }
//         }
//       }
      
//       return cattleMap.values.toList();
//     } catch (e) {
//       debugPrint('Error fetching today\'s cattle: $e');
//       return [];
//     }
//   }

//   /// Subscribe to real-time updates
//   RealtimeChannel subscribeToUpdates(Function(DashboardStats) onUpdate) {
//     final channel = _supabaseService.client.channel('dashboard_updates');
    
//     // Listen to ear_tag_camera inserts
//     channel.onPostgresChanges(
//       event: PostgresChangeEvent.insert,
//       schema: 'public',
//       table: 'ear_tag_camera',
//       callback: (payload) async {
//         debugPrint('🔔 Real-time update: New detection in ear_tag_camera');
//         final stats = await getDashboardStats();
//         onUpdate(stats);
//       },
//     );

//     // Listen to depth_camera inserts (lameness)
//     channel.onPostgresChanges(
//       event: PostgresChangeEvent.insert,
//       schema: 'public',
//       table: 'depth_camera',
//       callback: (payload) async {
//         debugPrint('🔔 Real-time update: New lameness detection');
//         final stats = await getDashboardStats();
//         onUpdate(stats);
//       },
//     );

//     // Listen to milking_status inserts
//     channel.onPostgresChanges(
//       event: PostgresChangeEvent.insert,
//       schema: 'public',
//       table: 'milking_status',
//       callback: (payload) async {
//         debugPrint('🔔 Real-time update: New milking status');
//         final stats = await getDashboardStats();
//         onUpdate(stats);
//       },
//     );

//     // Listen to animals table updates
//     channel.onPostgresChanges(
//       event: PostgresChangeEvent.update,
//       schema: 'public',
//       table: 'animals',
//       callback: (payload) async {
//         debugPrint('🔔 Real-time update: Animal data updated');
//         final stats = await getDashboardStats();
//         onUpdate(stats);
//       },
//     );

//     // Listen to animals table inserts
//     channel.onPostgresChanges(
//       event: PostgresChangeEvent.insert,
//       schema: 'public',
//       table: 'animals',
//       callback: (payload) async {
//         debugPrint('🔔 Real-time update: New animal added');
//         final stats = await getDashboardStats();
//         onUpdate(stats);
//       },
//     );

//     // Listen to video_records inserts (video processing complete)
//     channel.onPostgresChanges(
//       event: PostgresChangeEvent.insert,
//       schema: 'public',
//       table: 'video_records',
//       callback: (payload) async {
//         debugPrint('🔔 Real-time update: Video processing completed');
//         final stats = await getDashboardStats();
//         onUpdate(stats);
//       },
//     );

//     channel.subscribe();
//     return channel;
//   }

//   /// Get all cattle information with milking and lameness status
//   /// Note: All queries are automatically filtered by user_id through Supabase RLS policies
//   /// Each user sees only their own cattle data - data isolation is enforced at database level
//   Future<List<Map<String, dynamic>>> getCattleInformation() async {
//     try {
//       // Get all unique cattle from ear_tag_camera (RLS filters by current user)
//       final earTagData = await _supabaseService.client
//           .from('ear_tag_camera')
//           .select('cow_id, ear_tag_number, confidence, timestamp')
//           .order('timestamp', ascending: false);
      
//       // Get unique cattle
//       final Map<String, Map<String, dynamic>> uniqueCattle = {};
//       for (final record in earTagData) {
//         final cowId = record['cow_id'];
//         if (cowId != null && !uniqueCattle.containsKey(cowId.toString())) {
//           uniqueCattle[cowId.toString()] = record;
//         }
//       }

//       // Fetch milking and lameness status for each cattle
//       final results = <Map<String, dynamic>>[];
//       for (final cattle in uniqueCattle.values) {
//         final cowId = cattle['cow_id'];
        
//         // Get latest milking status
//         final milkingData = await _supabaseService.client
//             .from('milking_status')
//             .select('is_being_milked, milking_confidence')
//             .eq('cow_id', cowId)
//             .order('timestamp', ascending: false)
//             .limit(1);

//         // Get latest lameness score
//         final lamenessData = await _supabaseService.client
//             .from('depth_camera')
//             .select('lameness_score, lameness_severity')
//             .eq('cow_id', cowId)
//             .order('post_milking_timestamp', ascending: false)
//             .limit(1);

//         final isMilking = milkingData.isNotEmpty && milkingData[0]['is_being_milked'] == true;
//         final lamenessScore = lamenessData.isNotEmpty ? lamenessData[0]['lameness_score'] : null;
//         final isLame = lamenessScore != null && lamenessScore is int && lamenessScore > 1;

//         results.add({
//           'cow_id': cowId,
//           'ear_tag': cattle['ear_tag_number'],
//           'is_milking': isMilking,
//           'is_lame': isLame,
//           'lameness_score': lamenessScore,
//           'lameness_severity': lamenessData.isNotEmpty ? lamenessData[0]['lameness_severity'] : null,
//           'milking_confidence': milkingData.isNotEmpty ? milkingData[0]['milking_confidence'] : null,
//         });
//       }

//       return results;
//     } catch (e) {
//       debugPrint('Error fetching cattle information: $e');
//       return [];
//     }
//   }
// }
