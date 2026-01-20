import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medication_model.dart';

class MedicationProvider extends ChangeNotifier {
  List<MedicationModel> _medications = [];
  List<MedicationIntakeModel> _intakeHistory = [];
  bool _isLoading = false;
  String? _error;

  final SupabaseClient _supabase = Supabase.instance.client;

  List<MedicationModel> get medications => _medications;
  List<MedicationModel> get activeMedications =>
      _medications.where((m) => m.status == MedicationStatus.active).toList();
  List<MedicationIntakeModel> get intakeHistory => _intakeHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load medications from Supabase
  Future<void> loadMedications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('loadMedications: No authenticated user');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('loadMedications: Loading medications for user ${user.id}');

      final data = await _supabase
          .from('medications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      _medications = (data as List)
          .map((m) => _medicationFromSupabase(m))
          .toList();
      debugPrint('loadMedications: Loaded ${_medications.length} medications');

      // Load intake history
      try {
        final intakeData = await _supabase
            .from('medication_intakes')
            .select()
            .eq('user_id', user.id)
            .gte(
              'scheduled_time',
              DateTime.now()
                  .subtract(const Duration(days: 7))
                  .toIso8601String(),
            )
            .order('scheduled_time', ascending: false);

        _intakeHistory = (intakeData as List)
            .map((i) => _intakeFromSupabase(i))
            .toList();
        debugPrint(
          'loadMedications: Loaded ${_intakeHistory.length} intake records',
        );
      } catch (intakeError) {
        debugPrint(
          'loadMedications: Failed to load intake history: $intakeError',
        );
        // Don't fail if intake history fails
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load medications: $e';
      debugPrint('loadMedications error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  MedicationModel _medicationFromSupabase(Map<String, dynamic> data) {
    // Parse reminder times from stored format
    List<TimeOfDay> reminderTimes = [];
    if (data['reminder_times'] != null) {
      reminderTimes = (data['reminder_times'] as List).map((t) {
        final parts = t.toString().split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }).toList();
    }

    return MedicationModel(
      id: data['id'],
      userId: data['user_id'],
      name: data['name'] ?? '',
      dosage: data['dosage'] ?? '',
      frequency: MedicationFrequency.values.firstWhere(
        (f) => f.name == data['frequency'],
        orElse: () => MedicationFrequency.daily,
      ),
      reminderTimes: reminderTimes,
      startDate: DateTime.parse(data['start_date']),
      endDate: data['end_date'] != null
          ? DateTime.parse(data['end_date'])
          : null,
      notes: data['notes'],
      totalPills: data['total_pills'] ?? 30,
      pillsRemaining: data['pills_remaining'] ?? 30,
      refillReminderThreshold: data['refill_reminder_threshold'] ?? 5,
      status: MedicationStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => MedicationStatus.active,
      ),
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  Map<String, dynamic> _medicationToSupabase(MedicationModel medication) {
    return {
      'user_id': medication.userId,
      'name': medication.name,
      'dosage': medication.dosage,
      'frequency': medication.frequency.name,
      'reminder_times': medication.reminderTimes
          .map(
            (t) =>
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
          )
          .toList(),
      'start_date': medication.startDate.toIso8601String(),
      'end_date': medication.endDate?.toIso8601String(),
      'notes': medication.notes,
      'total_pills': medication.totalPills,
      'pills_remaining': medication.pillsRemaining,
      'refill_reminder_threshold': medication.refillReminderThreshold,
      'status': medication.status.name,
    };
  }

  MedicationIntakeModel _intakeFromSupabase(Map<String, dynamic> data) {
    return MedicationIntakeModel(
      id: data['id'],
      medicationId: data['medication_id'],
      scheduledTime: DateTime.parse(data['scheduled_time']),
      actualTime: data['actual_time'] != null
          ? DateTime.parse(data['actual_time'])
          : null,
      status: IntakeStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => IntakeStatus.pending,
      ),
    );
  }

  List<MedicationIntakeModel> getTodaySchedule() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final todayIntakes = _intakeHistory.where((intake) {
      return intake.scheduledTime.isAfter(todayStart) &&
          intake.scheduledTime.isBefore(todayEnd);
    }).toList();

    // Add pending intakes for today from active medications
    for (final medication in activeMedications) {
      for (final time in medication.reminderTimes) {
        final scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        final exists = todayIntakes.any(
          (i) =>
              i.medicationId == medication.id &&
              i.scheduledTime.hour == time.hour &&
              i.scheduledTime.minute == time.minute,
        );

        if (!exists) {
          todayIntakes.add(
            MedicationIntakeModel(
              medicationId: medication.id,
              scheduledTime: scheduledTime,
              status: IntakeStatus.pending,
            ),
          );
        }
      }
    }

    todayIntakes.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return todayIntakes;
  }

  MedicationModel? getMedicationById(String id) {
    try {
      return _medications.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  double getAdherenceRate({int days = 7}) {
    if (_intakeHistory.isEmpty) return 0.0;

    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final relevantHistory = _intakeHistory.where(
      (i) => i.scheduledTime.isAfter(cutoffDate),
    );

    if (relevantHistory.isEmpty) return 0.0;

    final takenCount = relevantHistory
        .where((i) => i.status == IntakeStatus.taken)
        .length;

    return (takenCount / relevantHistory.length) * 100;
  }

  Future<void> addMedication(MedicationModel medication) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _error = 'You must be logged in to add medications';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Override userId with authenticated user
      final medicationWithUserId = medication.copyWith(userId: user.id);
      final data = _medicationToSupabase(medicationWithUserId);
      data['created_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('medications')
          .insert(data)
          .select()
          .single();

      _medications.insert(0, _medicationFromSupabase(response));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add medication: $e';
      debugPrint('Add medication error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateMedication(MedicationModel medication) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = _medicationToSupabase(medication);
      data['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('medications').update(data).eq('id', medication.id);

      final index = _medications.indexWhere((m) => m.id == medication.id);
      if (index != -1) {
        _medications[index] = medication;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update medication: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMedication(String id) async {
    try {
      await _supabase.from('medications').delete().eq('id', id);

      _medications.removeWhere((m) => m.id == id);
      _intakeHistory.removeWhere((i) => i.medicationId == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete medication: $e';
      notifyListeners();
    }
  }

  Future<void> recordIntake(String medicationId, IntakeStatus status) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final medication = getMedicationById(medicationId);
    if (medication == null) return;

    final now = DateTime.now();

    try {
      // Insert intake record
      final response = await _supabase
          .from('medication_intakes')
          .insert({
            'user_id': user.id,
            'medication_id': medicationId,
            'scheduled_time': now.toIso8601String(),
            'actual_time': status == IntakeStatus.taken
                ? now.toIso8601String()
                : null,
            'status': status.name,
          })
          .select()
          .single();

      _intakeHistory.insert(0, _intakeFromSupabase(response));

      // Update pills remaining if taken
      if (status == IntakeStatus.taken) {
        final newPillsRemaining = medication.pillsRemaining - 1;
        await _supabase
            .from('medications')
            .update({'pills_remaining': newPillsRemaining})
            .eq('id', medicationId);

        final medIndex = _medications.indexWhere((m) => m.id == medicationId);
        if (medIndex != -1) {
          _medications[medIndex] = medication.copyWith(
            pillsRemaining: newPillsRemaining,
          );
        }
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to record intake: $e';
      notifyListeners();
    }
  }

  List<MedicationModel> getMedicationsNeedingRefill() {
    return _medications
        .where((m) => m.needsRefill && m.status == MedicationStatus.active)
        .toList();
  }

  void clearMedications() {
    _medications = [];
    _intakeHistory = [];
    notifyListeners();
  }

  // Initialize with mock data (for offline/demo mode)
  void initMockMedications(String userId) {
    _medications = [
      MedicationModel(
        userId: userId,
        name: 'Metformin',
        dosage: '500mg',
        frequency: MedicationFrequency.twiceDaily,
        reminderTimes: [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ],
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        totalPills: 60,
        pillsRemaining: 42,
        notes: 'Take with food',
      ),
      MedicationModel(
        userId: userId,
        name: 'Lisinopril',
        dosage: '10mg',
        frequency: MedicationFrequency.daily,
        reminderTimes: [const TimeOfDay(hour: 9, minute: 0)],
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        totalPills: 30,
        pillsRemaining: 8,
        notes: 'For blood pressure',
      ),
      MedicationModel(
        userId: userId,
        name: 'Vitamin D3',
        dosage: '2000 IU',
        frequency: MedicationFrequency.daily,
        reminderTimes: [const TimeOfDay(hour: 12, minute: 0)],
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        totalPills: 30,
        pillsRemaining: 20,
      ),
    ];
    _generateMockIntakeHistory();
    notifyListeners();
  }

  void _generateMockIntakeHistory() {
    _intakeHistory = [];
    for (final medication in _medications) {
      for (int i = 0; i < 7; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        for (final time in medication.reminderTimes) {
          final scheduledTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );

          final isTaken = DateTime.now().millisecondsSinceEpoch % (i + 3) != 0;

          _intakeHistory.add(
            MedicationIntakeModel(
              medicationId: medication.id,
              scheduledTime: scheduledTime,
              actualTime: isTaken
                  ? scheduledTime.add(const Duration(minutes: 5))
                  : null,
              status: isTaken ? IntakeStatus.taken : IntakeStatus.skipped,
            ),
          );
        }
      }
    }
  }
}
