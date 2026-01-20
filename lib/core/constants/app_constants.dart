/// App-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Cattle AI Monitor';
  static const String appVersion = '1.0.0';
  
  // Storage Buckets/Folders (Firebase Storage)
  static const String animalImagesBucket = 'animal-images';
  static const String videosBucket = 'videos';
  static const String mlModelsBucket = 'ml-models';
  
  // Database Tables/Collections (Firebase Realtime Database)
  static const String animalsTable = 'animals';
  static const String movementDataTable = 'movement_data';
  static const String lamenessRecordsTable = 'lameness_records';
  static const String videoRecordsTable = 'video_records';
  
  // Animal Species
  static const List<String> animalSpecies = ['Cow', 'Buffalo'];
  
  // Health Status
  static const List<String> healthStatuses = [
    'Healthy',
    'Under Observation',
    'Sick',
    'Critical'
  ];
  
  // Lameness Severity Levels
  static const String lamenessNormal = 'Normal';
  static const String lamenessMild = 'Mild Lameness';
  static const String lamenessSevere = 'Severe Lameness';
  
  // Movement Thresholds
  static const int normalStepsPerDay = 3000;
  static const int lowActivityThreshold = 1500;
  static const double normalActivityDurationHours = 8.0;
  static const double lowActivityDurationHours = 4.0;
  
  // ML Model Constants
  static const String lamenessModelPath = 'assets/ml/lameness_model.tflite';
  static const int mlInputSize = 10;
  static const double mlConfidenceThreshold = 0.7;
  
  // Camera Settings
  static const int videoMaxDurationSeconds = 60;
  static const double videoQuality = 0.8;
  
  // Chart Settings
  static const int chartDaysToShow = 7;
  static const int chartDataPointsPerDay = 24;
  
  // Animation Durations
  static const int shortAnimationMs = 200;
  static const int mediumAnimationMs = 400;
  static const int longAnimationMs = 600;
  
  // Pagination
  static const int itemsPerPage = 20;
  
  // IoT Simulation Settings
  static const int simulationIntervalSeconds = 5;
  static const int simulationDataRetentionDays = 30;
}
