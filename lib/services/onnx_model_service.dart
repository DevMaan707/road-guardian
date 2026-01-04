import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/risk_provider.dart';

/// Mappings from android_mappings.json
class ModelMappings {
  final Map<String, int> accusedType;
  final Map<String, int> victimType;
  final Map<String, int> policeStation;

  ModelMappings({
    required this.accusedType,
    required this.victimType,
    required this.policeStation,
  });

  factory ModelMappings.fromJson(Map<String, dynamic> json) {
    return ModelMappings(
      accusedType: Map<String, int>.from(json['Accused_Type'] ?? {}),
      victimType: Map<String, int>.from(json['Victim_Type'] ?? {}),
      policeStation: Map<String, int>.from(json['Police_Station'] ?? {}),
    );
  }

  static ModelMappings get defaultMappings => ModelMappings(
        accusedType: {'Car': 0, 'Heavy': 1, 'Other': 2, 'Two Wheeler': 3},
        victimType: {'Car': 0, 'Heavy': 1, 'Other': 2, 'Two Wheeler': 3},
        policeStation: {
          'Ghatkesar PS': 0,
          'Medipally PS': 1,
          'Pocharam PS': 2,
          'Uppal PS': 3
        },
      );
}

/// ONNX Model Service for Road Guardian Risk Prediction
/// Uses onnxruntime to run the road_guardian_model.onnx
class OnnxModelService {
  bool _isInitialized = false;
  ModelMappings? _mappings;
  OrtSession? _session;

  bool get isInitialized => _isInitialized;
  ModelMappings? get mappings => _mappings;

  Future<void> initialize() async {
    try {
      // Initialize ONNX Runtime environment
      OrtEnv.instance.init();

      // Load mappings
      await _loadMappings();

      // Load ONNX model
      await _loadModel();

      _isInitialized = true;
      print('ONNX Model Service initialized successfully');
    } catch (e) {
      print('Failed to initialize ONNX Model Service: $e');
      _isInitialized = false;
      // Don't rethrow - fall back to simulation mode
    }
  }

  Future<void> _loadMappings() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/mappings/android_mappings.json');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _mappings = ModelMappings.fromJson(json);
    } catch (e) {
      print('Using default mappings: $e');
      _mappings = ModelMappings.defaultMappings;
    }
  }

  Future<void> _loadModel() async {
    try {
      // Load the ONNX model from assets
      final modelBytes =
          await rootBundle.load('assets/model/road_guardian_model.onnx');

      // Write to temporary file for ONNX Runtime
      final tempDir = await getTemporaryDirectory();
      final modelPath = '${tempDir.path}/road_guardian_model.onnx';
      final modelFile = File(modelPath);
      await modelFile.writeAsBytes(modelBytes.buffer.asUint8List());

      // Create session options
      final sessionOptions = OrtSessionOptions();

      // Create ONNX Runtime session
      _session = OrtSession.fromFile(modelFile, sessionOptions);

      print('Model loaded successfully: ${modelBytes.lengthInBytes} bytes');
    } catch (e) {
      print('Model loading error (will use simulation): $e');
      _session = null;
    }
  }

  /// Predict risk score using the ONNX model
  Future<double> predictRisk(TelemetryData telemetry) async {
    if (!_isInitialized || _session == null) {
      print('ONNX not initialized, using rule-based fallback');
      return _ruleBasedPrediction(telemetry);
    }

    try {
      // Prepare input tensor
      final inputVector = telemetry.toInputVector();
      print('Input vector: $inputVector');

      // Create input tensor with shape [1, features]
      final inputOrt = OrtValueTensor.createTensorWithDataList(
        Float32List.fromList(inputVector),
        [1, inputVector.length],
      );

      // Run inference
      final inputs = {'input': inputOrt};
      final runOptions = OrtRunOptions();
      final outputs = _session!.run(runOptions, inputs);

      // Get output
      inputOrt.release();
      runOptions.release();

      if (outputs.isNotEmpty) {
        final outputTensor = outputs.first?.value;
        print('ONNX output tensor: $outputTensor');
        
        if (outputTensor is List && outputTensor.isNotEmpty) {
          final result = (outputTensor.first as num).toDouble();
          // Release outputs
          for (final output in outputs) {
            output?.release();
          }
          
          // Model output is typically 0-1, scale to 0-100
          final riskScore = (result * 100).clamp(0, 100).toDouble();
          print('ONNX risk score: $riskScore');
          return riskScore;
        }
      }

      print('ONNX output invalid, using fallback');
      return _ruleBasedPrediction(telemetry);
    } catch (e) {
      print('ONNX inference error: $e');
      return _ruleBasedPrediction(telemetry);
    }
  }

  double _ruleBasedPrediction(TelemetryData telemetry) {
    // Rule-based prediction when ONNX model is unavailable
    double risk = 20;

    // Police station risk factor
    // Uppal (3) and Ghatkesar (0) have higher accident rates
    if (telemetry.policeStation == 3 || telemetry.policeStation == 0) {
      risk += 25;
    }

    // Weather factor
    if (telemetry.weatherCode > 50) risk += 30;
    if (telemetry.weatherCode > 79) risk += 15;

    // Time factor (peak hours and night)
    if (telemetry.hour >= 8 && telemetry.hour <= 10) risk += 10;
    if (telemetry.hour >= 17 && telemetry.hour <= 20) risk += 15;
    if (telemetry.hour >= 22 || telemetry.hour <= 5) risk += 20;

    // Speed factor
    if (telemetry.speed > 50) risk += (telemetry.speed - 50) * 0.5;

    // Vehicle type factor (two wheelers are more vulnerable)
    if (telemetry.victimType == 3) risk += 10;

    return risk.clamp(0, 100);
  }

  /// Get encoded value for accused type
  int encodeAccusedType(String type) {
    return _mappings?.accusedType[type] ?? 2;
  }

  /// Get encoded value for victim type
  int encodeVictimType(String type) {
    return _mappings?.victimType[type] ?? 2;
  }

  /// Get encoded value for police station
  int encodePoliceStation(String station) {
    return _mappings?.policeStation[station] ?? 0;
  }

  void dispose() {
    // Cleanup ONNX session
    // _session?.close();
    _session = null;
    _isInitialized = false;
  }
}

/// Provider for ONNX Model Service (if using Riverpod)
// final onnxModelServiceProvider = Provider<OnnxModelService>((ref) {
//   final service = OnnxModelService();
//   ref.onDispose(() => service.dispose());
//   return service;
// });
