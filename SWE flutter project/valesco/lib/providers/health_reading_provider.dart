import 'package:flutter/material.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/health_reading_model.dart';

class HealthReadingProvider extends ChangeNotifier {
  List<HealthReadingModel> _readings = [];
  bool _isLoading = false;
  String? _error;

  final SupabaseClient _supabase = Supabase.instance.client;

  List<HealthReadingModel> get readings => _readings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load readings from Supabase
  Future<void> loadReadings() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final data = await _supabase
          .from('health_readings')
          .select()
          .eq('user_id', user.id)
          .order('timestamp', ascending: false);

      _readings = (data as List).map((r) => _readingFromSupabase(r)).toList();
    } catch (e) {
      debugPrint('Failed to load health readings: $e');
      _error = e.toString();
      // If no data exists, keep empty list
      _readings = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  HealthReadingModel _readingFromSupabase(Map<String, dynamic> data) {
    return HealthReadingModel(
      id: data['id'],
      userId: data['user_id'],
      type: HealthReadingType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => HealthReadingType.bloodGlucose,
      ),
      value: (data['value'] ?? 0).toDouble(),
      secondaryValue: data['secondary_value']?.toDouble(),
      timestamp: DateTime.parse(data['timestamp']),
      context: data['context'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> _readingToSupabase(HealthReadingModel reading) {
    return {
      'user_id': reading.userId,
      'type': reading.type.name,
      'value': reading.value,
      'secondary_value': reading.secondaryValue,
      'timestamp': reading.timestamp.toIso8601String(),
      'context': reading.context,
      'notes': reading.notes,
    };
  }

  // Initialize with mock data (for new users or development)
  Future<void> initMockReadings(String userId) async {
    final random = Random();
    _readings = [];

    // Generate readings for the past 30 days
    for (int i = 0; i < 30; i++) {
      final date = DateTime.now().subtract(Duration(days: i));

      // Blood Glucose (1-3 readings per day)
      final glucoseReadingsCount = random.nextInt(3) + 1;
      for (int j = 0; j < glucoseReadingsCount; j++) {
        final hour = j == 0 ? 7 : (j == 1 ? 13 : 19);
        final context = j == 0
            ? 'Before breakfast'
            : (j == 1 ? 'After lunch' : 'Before dinner');
        _readings.add(
          HealthReadingModel(
            userId: userId,
            type: HealthReadingType.bloodGlucose,
            value: 80 + random.nextDouble() * 100, // 80-180 range
            timestamp: DateTime(
              date.year,
              date.month,
              date.day,
              hour,
              random.nextInt(30),
            ),
            context: context,
          ),
        );
      }

      // Blood Pressure (1-2 readings per day)
      if (i % 2 == 0 || i < 7) {
        _readings.add(
          HealthReadingModel(
            userId: userId,
            type: HealthReadingType.bloodPressure,
            value: 110 + random.nextDouble() * 30, // Systolic: 110-140
            secondaryValue: 70 + random.nextDouble() * 20, // Diastolic: 70-90
            timestamp: DateTime(
              date.year,
              date.month,
              date.day,
              8,
              random.nextInt(30),
            ),
            context: 'Morning reading',
          ),
        );
      }

      // Heart Rate (daily)
      _readings.add(
        HealthReadingModel(
          userId: userId,
          type: HealthReadingType.heartRate,
          value: 60 + random.nextDouble() * 30, // 60-90 BPM
          timestamp: DateTime(
            date.year,
            date.month,
            date.day,
            9,
            random.nextInt(30),
          ),
        ),
      );

      // Temperature (occasional)
      if (i % 3 == 0) {
        _readings.add(
          HealthReadingModel(
            userId: userId,
            type: HealthReadingType.temperature,
            value: 36.1 + random.nextDouble() * 1.0, // 36.1-37.1
            timestamp: DateTime(
              date.year,
              date.month,
              date.day,
              10,
              random.nextInt(30),
            ),
          ),
        );
      }

      // Oxygen Level (occasional)
      if (i % 2 == 0) {
        _readings.add(
          HealthReadingModel(
            userId: userId,
            type: HealthReadingType.oxygenLevel,
            value: 95 + random.nextDouble() * 4, // 95-99
            timestamp: DateTime(
              date.year,
              date.month,
              date.day,
              11,
              random.nextInt(30),
            ),
          ),
        );
      }

      // Weight (weekly)
      if (i % 7 == 0) {
        _readings.add(
          HealthReadingModel(
            userId: userId,
            type: HealthReadingType.weight,
            value: 71 + random.nextDouble() * 2, // 71-73 kg
            timestamp: DateTime(date.year, date.month, date.day, 7, 0),
          ),
        );
      }
    }

    _readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  List<HealthReadingModel> getReadingsByType(HealthReadingType type) {
    return _readings.where((r) => r.type == type).toList();
  }

  List<HealthReadingModel> getRecentReadings({int limit = 10}) {
    return _readings.take(limit).toList();
  }

  HealthReadingModel? getLatestReading(HealthReadingType type) {
    try {
      return _readings.firstWhere((r) => r.type == type);
    } catch (_) {
      return null;
    }
  }

  List<HealthReadingModel> getReadingsForDateRange(
    HealthReadingType type,
    DateTime start,
    DateTime end,
  ) {
    return _readings.where((r) {
      return r.type == type &&
          r.timestamp.isAfter(start) &&
          r.timestamp.isBefore(end);
    }).toList();
  }

  Map<String, double> getAverages(HealthReadingType type, {int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final relevantReadings = _readings.where(
      (r) => r.type == type && r.timestamp.isAfter(cutoff),
    );

    if (relevantReadings.isEmpty) {
      return {'average': 0, 'min': 0, 'max': 0};
    }

    final values = relevantReadings.map((r) => r.value).toList();
    final average = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    return {'average': average, 'min': min, 'max': max};
  }

  Future<void> addReading(HealthReadingModel reading) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _supabase
          .from('health_readings')
          .insert(_readingToSupabase(reading))
          .select()
          .single();

      final savedReading = _readingFromSupabase(data);
      _readings.insert(0, savedReading);
      _readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint('Failed to add reading: $e');
      _error = e.toString();
      // Still add locally for offline support
      _readings.insert(0, reading);
      _readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteReading(String id) async {
    try {
      await _supabase.from('health_readings').delete().eq('id', id);
    } catch (e) {
      debugPrint('Failed to delete reading: $e');
    }

    _readings.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  // Check for critical values and return alerts
  List<String> checkForAlerts() {
    final alerts = <String>[];

    for (final type in HealthReadingType.values) {
      final latest = getLatestReading(type);
      if (latest != null && latest.status == ReadingStatus.critical) {
        alerts.add(
          'Critical ${type.displayName}: ${latest.displayValue} ${type.unit}',
        );
      }
    }

    return alerts;
  }

  void clearReadings() {
    _readings = [];
    notifyListeners();
  }

  Map<String, double> getAveragesForType(HealthReadingType type) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final allReadings = getReadingsByType(type);
    final sevenDayReadings = allReadings
        .where((r) => r.timestamp.isAfter(sevenDaysAgo))
        .toList();
    final thirtyDayReadings = allReadings
        .where((r) => r.timestamp.isAfter(thirtyDaysAgo))
        .toList();

    double calculateAverage(List<HealthReadingModel> readings) {
      if (readings.isEmpty) return 0;
      return readings.map((r) => r.value).reduce((a, b) => a + b) /
          readings.length;
    }

    double calculateMin(List<HealthReadingModel> readings) {
      if (readings.isEmpty) return 0;
      return readings.map((r) => r.value).reduce((a, b) => a < b ? a : b);
    }

    double calculateMax(List<HealthReadingModel> readings) {
      if (readings.isEmpty) return 0;
      return readings.map((r) => r.value).reduce((a, b) => a > b ? a : b);
    }

    return {
      '7_day': calculateAverage(sevenDayReadings),
      '30_day': calculateAverage(thirtyDayReadings),
      'min': calculateMin(allReadings),
      'max': calculateMax(allReadings),
    };
  }
}
