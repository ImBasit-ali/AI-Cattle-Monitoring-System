import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/movement_data.dart';
import '../core/constants/app_constants.dart';

/// Machine Learning Service for Lameness Detection
/// Implements both Rule-Based and ML-Based detection
class MLService {
  static final MLService _instance = MLService._internal();
  factory MLService() => _instance;
  MLService._internal();

  // TFLite Interpreter (placeholder for actual implementation)
  // Interpreter? _interpreter;
  bool _modelLoaded = false;

  /// Initialize ML Model
  Future<void> initializeModel() async {
    try {
      // NOTE: Load TFLite model when actual model file is available
      // _interpreter = await Interpreter.fromAsset(AppConstants.lamenessModelPath);
      
      // Simulate model loading
      await Future.delayed(const Duration(seconds: 1));
      _modelLoaded = true;
      if (kDebugMode) {
        debugPrint('ML Model initialized (simulated)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing ML model: $e');
      }
      _modelLoaded = false;
    }
  }

  /// Check if model is loaded
  bool get isModelLoaded => _modelLoaded;

  // ==================== RULE-BASED DETECTION ====================

  /// Rule-Based Lameness Detection
  /// Phase 1: Simple threshold-based detection
  LamenessDetectionResult detectLamenessRuleBased({
    required int stepCount,
    required double activityHours,
    required double restHours,
  }) {
    String severity;
    double confidence;
    String explanation;

    // Rule 1: Severe Lameness - Very low movement + excessive rest
    if (stepCount < 1000 && restHours > 18) {
      severity = AppConstants.lamenessSevere;
      confidence = 0.85;
      explanation = 'Critical: Very low step count (<1000) and excessive rest (>18h)';
    }
    // Rule 2: Severe Lameness - Extremely low activity
    else if (stepCount < 800 && activityHours < 3) {
      severity = AppConstants.lamenessSevere;
      confidence = 0.80;
      explanation = 'Critical: Extremely low activity pattern detected';
    }
    // Rule 3: Mild Lameness - Reduced movement
    else if (stepCount < AppConstants.lowActivityThreshold && 
             activityHours < AppConstants.lowActivityDurationHours) {
      severity = AppConstants.lamenessMild;
      confidence = 0.70;
      explanation = 'Warning: Below normal activity thresholds';
    }
    // Rule 4: Mild Lameness - Low steps but reasonable activity
    else if (stepCount < 2000) {
      severity = AppConstants.lamenessMild;
      confidence = 0.60;
      explanation = 'Caution: Step count below recommended levels';
    }
    // Rule 5: Normal
    else {
      severity = AppConstants.lamenessNormal;
      confidence = 0.90;
      explanation = 'Healthy: Movement patterns within normal range';
    }

    return LamenessDetectionResult(
      severity: severity,
      confidence: confidence,
      detectionMethod: 'Rule-Based',
      explanation: explanation,
      inputFeatures: {
        'step_count': stepCount,
        'activity_hours': activityHours,
        'rest_hours': restHours,
      },
    );
  }

  // ==================== ML-BASED DETECTION ====================

  /// ML-Based Lameness Detection
  /// Phase 2: Neural network-based detection
  Future<LamenessDetectionResult> detectLamenessMLBased({
    required int stepCount,
    required double activityHours,
    required double restHours,
    double? averageSpeed,
    double? symmetryScore,
  }) async {
    if (!_modelLoaded) {
      // Fallback to rule-based if model not loaded
      return detectLamenessRuleBased(
        stepCount: stepCount,
        activityHours: activityHours,
        restHours: restHours,
      );
    }

    try {
      // Prepare input features
      final inputFeatures = _prepareMLInput(
        stepCount: stepCount,
        activityHours: activityHours,
        restHours: restHours,
        averageSpeed: averageSpeed ?? 0.0,
        symmetryScore: symmetryScore ?? 0.5,
      );

      // Run ML inference
      final predictions = await _runInference(inputFeatures);

      // Process output probabilities
      final severity = _getSeverityFromProbabilities(predictions);
      final confidence = predictions.reduce(math.max);

      return LamenessDetectionResult(
        severity: severity,
        confidence: confidence,
        detectionMethod: 'ML-Based',
        explanation: _generateMLExplanation(severity, predictions),
        inputFeatures: {
          'step_count': stepCount,
          'activity_hours': activityHours,
          'rest_hours': restHours,
          'average_speed': averageSpeed,
          'symmetry_score': symmetryScore,
        },
        outputProbabilities: predictions,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in ML detection: $e');
      }
      // Fallback to rule-based
      return detectLamenessRuleBased(
        stepCount: stepCount,
        activityHours: activityHours,
        restHours: restHours,
      );
    }
  }

  /// Prepare ML input features
  /// Features: [step_count, activity_hours, rest_hours, average_speed, 
  ///            symmetry_score, movement_score, activity_ratio, ...]
  List<double> _prepareMLInput({
    required int stepCount,
    required double activityHours,
    required double restHours,
    required double averageSpeed,
    required double symmetryScore,
  }) {
    // Normalize features to 0-1 range
    final normalizedSteps = (stepCount / 5000.0).clamp(0.0, 1.0);
    final normalizedActivity = (activityHours / 12.0).clamp(0.0, 1.0);
    final normalizedRest = (restHours / 24.0).clamp(0.0, 1.0);
    final normalizedSpeed = (averageSpeed / 100.0).clamp(0.0, 1.0);
    
    // Derived features
    final activityRatio = activityHours / (activityHours + restHours);
    final movementScore = (stepCount / 50.0).clamp(0.0, 100.0);
    
    return [
      normalizedSteps,
      normalizedActivity,
      normalizedRest,
      normalizedSpeed,
      symmetryScore,
      movementScore / 100.0,
      activityRatio,
      1.0 - symmetryScore, // Asymmetry score
      normalizedSteps * normalizedActivity, // Interaction feature
      normalizedRest / normalizedActivity, // Rest-activity ratio
    ];
  }

  /// Run ML inference (simulated)
  /// In production, this would use TFLite interpreter
  Future<List<double>> _runInference(List<double> input) async {
    // NOTE: Replace with actual TFLite inference
    // var output = List.filled(3, 0.0);
    // _interpreter!.run(input, output);
    // return output;

    // SIMULATED ML MODEL INFERENCE
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Simulate neural network output based on input features
    final stepNormalized = input[0];
    final activityNormalized = input[1];
    final restNormalized = input[2];
    final symmetryScore = input[4];
    
    // Simple heuristic simulation of ML model
    double normalProb, mildProb, severeProb;
    
    if (stepNormalized > 0.6 && activityNormalized > 0.5 && symmetryScore > 0.7) {
      // Healthy animal
      normalProb = 0.85 + math.Random().nextDouble() * 0.10;
      mildProb = 0.10 + math.Random().nextDouble() * 0.05;
      severeProb = 0.05;
    } else if (stepNormalized < 0.2 && restNormalized > 0.75) {
      // Severely lame
      normalProb = 0.05;
      mildProb = 0.15 + math.Random().nextDouble() * 0.10;
      severeProb = 0.75 + math.Random().nextDouble() * 0.15;
    } else {
      // Mildly lame
      normalProb = 0.20 + math.Random().nextDouble() * 0.15;
      mildProb = 0.55 + math.Random().nextDouble() * 0.20;
      severeProb = 0.15 + math.Random().nextDouble() * 0.10;
    }
    
    // Normalize probabilities to sum to 1.0
    final total = normalProb + mildProb + severeProb;
    return [
      normalProb / total,
      mildProb / total,
      severeProb / total,
    ];
  }

  /// Get severity from probability distribution
  String _getSeverityFromProbabilities(List<double> probabilities) {
    final maxIndex = probabilities.indexOf(probabilities.reduce(math.max));
    
    switch (maxIndex) {
      case 0:
        return AppConstants.lamenessNormal;
      case 1:
        return AppConstants.lamenessMild;
      case 2:
        return AppConstants.lamenessSevere;
      default:
        return AppConstants.lamenessNormal;
    }
  }

  /// Generate ML explanation
  String _generateMLExplanation(String severity, List<double> probabilities) {
    final normalProb = (probabilities[0] * 100).toStringAsFixed(1);
    final mildProb = (probabilities[1] * 100).toStringAsFixed(1);
    final severeProb = (probabilities[2] * 100).toStringAsFixed(1);
    
    switch (severity) {
      case 'Normal':
        return 'ML Analysis: Normal ($normalProb%), Mild ($mildProb%), Severe ($severeProb%)';
      case 'Mild Lameness':
        return 'ML Analysis: Mild lameness detected with $mildProb% confidence';
      case 'Severe Lameness':
        return 'ML Analysis: Severe lameness detected with $severeProb% confidence - immediate attention required';
      default:
        return 'ML Analysis: Unable to determine severity';
    }
  }

  /// Detect lameness from movement data
  Future<LamenessDetectionResult> detectFromMovementData({
    required MovementData movementData,
    bool useMLBased = true,
  }) async {
    if (useMLBased) {
      return await detectLamenessMLBased(
        stepCount: movementData.stepCount,
        activityHours: movementData.activityDurationHours,
        restHours: movementData.restDurationHours,
        averageSpeed: movementData.averageSpeed,
      );
    } else {
      return detectLamenessRuleBased(
        stepCount: movementData.stepCount,
        activityHours: movementData.activityDurationHours,
        restHours: movementData.restDurationHours,
      );
    }
  }

  /// Dispose resources
  void dispose() {
    // NOTE: Close TFLite interpreter when implemented
    // _interpreter?.close();
    _modelLoaded = false;
  }
}

/// Lameness Detection Result
class LamenessDetectionResult {
  final String severity;
  final double confidence;
  final String detectionMethod;
  final String explanation;
  final Map<String, dynamic> inputFeatures;
  final List<double>? outputProbabilities;

  LamenessDetectionResult({
    required this.severity,
    required this.confidence,
    required this.detectionMethod,
    required this.explanation,
    required this.inputFeatures,
    this.outputProbabilities,
  });

  bool get isLame => severity != AppConstants.lamenessNormal;
  
  int get severityLevel {
    switch (severity) {
      case 'Normal':
        return 0;
      case 'Mild Lameness':
        return 1;
      case 'Severe Lameness':
        return 2;
      default:
        return 0;
    }
  }
}
