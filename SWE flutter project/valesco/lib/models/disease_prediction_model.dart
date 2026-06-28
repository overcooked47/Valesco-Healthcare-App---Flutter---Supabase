import 'package:flutter/material.dart';

/// Risk level categorization for disease predictions
enum RiskLevel {
  low,
  moderate,
  high;

  String get displayName {
    switch (this) {
      case RiskLevel.low:
        return 'Low';
      case RiskLevel.moderate:
        return 'Moderate';
      case RiskLevel.high:
        return 'High';
    }
  }

  Color get color {
    switch (this) {
      case RiskLevel.low:
        return const Color(0xFF4CAF50); // Green
      case RiskLevel.moderate:
        return const Color(0xFFFFC107); // Amber
      case RiskLevel.high:
        return const Color(0xFFF44336); // Red
    }
  }

  Color get lightColor {
    switch (this) {
      case RiskLevel.low:
        return const Color(0xFFE8F5E9);
      case RiskLevel.moderate:
        return const Color(0xFFFFF8E1);
      case RiskLevel.high:
        return const Color(0xFFFFEBEE);
    }
  }

  IconData get icon {
    switch (this) {
      case RiskLevel.low:
        return Icons.check_circle;
      case RiskLevel.moderate:
        return Icons.warning_amber;
      case RiskLevel.high:
        return Icons.error;
    }
  }

  static RiskLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return RiskLevel.low;
      case 'moderate':
        return RiskLevel.moderate;
      case 'high':
        return RiskLevel.high;
      default:
        return RiskLevel.low;
    }
  }
}

/// A contributing factor that drives a prediction
class ContributingFactor {
  final String factorName;
  final double impactPercentage;
  final double currentValue;
  final String targetRange;

  const ContributingFactor({
    required this.factorName,
    required this.impactPercentage,
    required this.currentValue,
    required this.targetRange,
  });

  String get displayName {
    switch (factorName) {
      case 'blood_glucose':
        return 'Blood Glucose';
      case 'bp_systolic':
        return 'Systolic BP';
      case 'bp_diastolic':
        return 'Diastolic BP';
      case 'heart_rate':
        return 'Heart Rate';
      case 'weight':
        return 'Weight';
      case 'bmi':
        return 'BMI';
      case 'age':
        return 'Age';
      default:
        return factorName;
    }
  }

  factory ContributingFactor.fromJson(Map<String, dynamic> json) {
    return ContributingFactor(
      factorName: json['factor'] ?? '',
      impactPercentage: (json['impact_percentage'] ?? 0).toDouble(),
      currentValue: (json['current_value'] ?? 0).toDouble(),
      targetRange: json['target_range'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'factor': factorName,
      'impact_percentage': impactPercentage,
      'current_value': currentValue,
      'target_range': targetRange,
    };
  }
}

/// A preventive recommendation with completion tracking
class PreventiveRecommendation {
  final String text;
  final String category;
  bool isCompleted;

  PreventiveRecommendation({
    required this.text,
    required this.category,
    this.isCompleted = false,
  });

  factory PreventiveRecommendation.fromJson(Map<String, dynamic> json) {
    return PreventiveRecommendation(
      text: json['text'] ?? '',
      category: json['category'] ?? '',
      isCompleted: json['is_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'category': category,
      'is_completed': isCompleted,
    };
  }
}

/// Per-condition prediction result
class DiseasePredictionResult {
  final String conditionName;
  final String conditionKey;
  final int riskScore; // 0-100
  final RiskLevel riskLevel;
  final List<ContributingFactor> contributingFactors;
  final List<PreventiveRecommendation> recommendations;

  const DiseasePredictionResult({
    required this.conditionName,
    required this.conditionKey,
    required this.riskScore,
    required this.riskLevel,
    required this.contributingFactors,
    required this.recommendations,
  });

  factory DiseasePredictionResult.fromJson(
      String key, Map<String, dynamic> json) {
    final recommendationTexts =
        List<String>.from(json['preventive_recommendations'] ?? []);

    return DiseasePredictionResult(
      conditionName: json['condition_name'] ?? key,
      conditionKey: key,
      riskScore: (json['risk_score'] ?? 0).toInt(),
      riskLevel: RiskLevel.fromString(json['risk_level'] ?? 'Low'),
      contributingFactors: (json['contributing_factors'] as List?)
              ?.map((f) => ContributingFactor.fromJson(f))
              .toList() ??
          [],
      recommendations: recommendationTexts
          .map((text) => PreventiveRecommendation(text: text, category: key))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'condition_name': conditionName,
      'condition_key': conditionKey,
      'risk_score': riskScore,
      'risk_level': riskLevel.displayName,
      'contributing_factors':
          contributingFactors.map((f) => f.toJson()).toList(),
      'preventive_recommendations':
          recommendations.map((r) => r.toJson()).toList(),
    };
  }
}

/// Aggregated health insights summary for all conditions
class HealthInsightsSummary {
  final Map<String, DiseasePredictionResult> predictions;
  final DateTime timestamp;
  final bool isCached;

  const HealthInsightsSummary({
    required this.predictions,
    required this.timestamp,
    this.isCached = false,
  });

  DiseasePredictionResult? get diabetes => predictions['diabetes'];
  DiseasePredictionResult? get hypertension => predictions['hypertension'];
  DiseasePredictionResult? get cardiovascular => predictions['cardiovascular'];

  /// Get the highest risk level across all conditions
  RiskLevel get overallRiskLevel {
    RiskLevel highest = RiskLevel.low;
    for (final result in predictions.values) {
      if (result.riskLevel == RiskLevel.high) return RiskLevel.high;
      if (result.riskLevel == RiskLevel.moderate) highest = RiskLevel.moderate;
    }
    return highest;
  }

  factory HealthInsightsSummary.fromApiResponse(Map<String, dynamic> json) {
    final predictionsMap = <String, DiseasePredictionResult>{};
    final predictionsJson = json['predictions'] as Map<String, dynamic>? ?? {};

    for (final entry in predictionsJson.entries) {
      predictionsMap[entry.key] = DiseasePredictionResult.fromJson(
        entry.key,
        entry.value as Map<String, dynamic>,
      );
    }

    return HealthInsightsSummary(
      predictions: predictionsMap,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'predictions':
          predictions.map((key, value) => MapEntry(key, value.toJson())),
      'timestamp': timestamp.toIso8601String(),
      'is_cached': isCached,
    };
  }

  HealthInsightsSummary copyWithCached() {
    return HealthInsightsSummary(
      predictions: predictions,
      timestamp: timestamp,
      isCached: true,
    );
  }
}

/// Historical risk score entry for trend tracking
class RiskScoreEntry {
  final String condition;
  final int riskScore;
  final RiskLevel riskLevel;
  final DateTime date;

  const RiskScoreEntry({
    required this.condition,
    required this.riskScore,
    required this.riskLevel,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'condition': condition,
      'risk_score': riskScore,
      'risk_level': riskLevel.displayName,
      'date': date.toIso8601String(),
    };
  }

  factory RiskScoreEntry.fromJson(Map<String, dynamic> json) {
    return RiskScoreEntry(
      condition: json['condition'] ?? '',
      riskScore: (json['risk_score'] ?? 0).toInt(),
      riskLevel: RiskLevel.fromString(json['risk_level'] ?? 'Low'),
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    );
  }
}
