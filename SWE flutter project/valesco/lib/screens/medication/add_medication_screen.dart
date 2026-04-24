import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/medication_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/medication_model.dart';
import '../../widgets/common_widgets.dart';
import '../../services/medication_reminder_service.dart';
import '../../services/ocr_service.dart';

class AddMedicationScreen extends StatefulWidget {
  final MedicationModel? medication;

  const AddMedicationScreen({super.key, this.medication});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  final _totalPillsController = TextEditingController();

  MedicationFrequency _selectedFrequency = MedicationFrequency.daily;
  List<TimeOfDay> _reminderTimes = [const TimeOfDay(hour: 8, minute: 0)];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isSaving = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _nameController.text = widget.medication!.name;
      _dosageController.text = widget.medication!.dosage;
      _notesController.text = widget.medication!.notes ?? '';
      _totalPillsController.text = widget.medication!.totalPills.toString();
      _selectedFrequency = widget.medication!.frequency;
      _reminderTimes = List.from(widget.medication!.reminderTimes);
      _startDate = widget.medication!.startDate;
      _endDate = widget.medication!.endDate;
    } else {
      _totalPillsController.text = '30';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    _totalPillsController.dispose();
    super.dispose();
  }

  final dosagePattern = RegExp(
    r'(\d+(?:\.\d+)?)\s*(?:x\s*)?(\d+(?:\.\d+)?)?'
    r'\s*(?:mg|mcg|μg|g|ml|cc|iu|IU|tabs?|tablet|capsule|caps?|drop|drops|dose|%)?'
    r'(?:\s*(?:x|times|daily|per\s*day))?',
    caseSensitive: false,
  );

  void _autoFillMedicationFields(String ocrText) {
    final extracted = _extractMedicationInfo(ocrText);

    setState(() {
      _nameController.text = extracted['name']!;
      _dosageController.text = extracted['dosage']!;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fields autofilled! Please review and adjust if needed.'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _scanMedicineLabel() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
    });

    try {
      final result = await OcrService.instance.scanText(source: ImageSource.camera);

      if (!mounted || result == null) {
        return;
      }

      if (!result.hasText) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No readable text was found in the image.'),
          ),
        );
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OCR Result',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Review the extracted text and choose an option below.',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      result.rawText,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _autoFillMedicationFields(result.rawText);
                        },
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Autofill Fields'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: AppColors.primaryOrange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final navigator = Navigator.of(sheetContext);
                                await Clipboard.setData(
                                  ClipboardData(text: result.rawText),
                                );
                                if (!mounted) return;
                                navigator.pop();
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('OCR text copied to clipboard.'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy Text'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              child: const Text('Close'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR scan failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final medicationProvider = context.read<MedicationProvider>();
      final reminderService = MedicationReminderService.instance;

      final userId = authProvider.currentUser?.id ?? 'user_1';
      final medicationName = _nameController.text.trim();
      final dosage = _dosageController.text.trim();
      final notes = _notesController.text.trim().isEmpty 
          ? null 
          : _notesController.text.trim();

      final medication = MedicationModel(
        id: widget.medication?.id,
        userId: userId,
        name: medicationName,
        dosage: dosage,
        frequency: _selectedFrequency,
        reminderTimes: _reminderTimes,
        startDate: _startDate,
        endDate: _endDate,
        notes: notes,
        totalPills: int.tryParse(_totalPillsController.text) ?? 30,
        pillsRemaining: widget.medication?.pillsRemaining ?? 
            (int.tryParse(_totalPillsController.text) ?? 30),
      );

      if (widget.medication == null) {
        await medicationProvider.addMedication(medication);
      } else {
        await medicationProvider.updateMedication(medication);
        if (!kIsWeb) {
          await reminderService.cancelPlanReminders(medication.id);
        }
      }

      if (!kIsWeb) {
        final canSchedule = await reminderService.canScheduleExactNotifications();
        if (!canSchedule) {
          if (mounted) {
            _showExactAlarmPermissionDialog();
          }
          setState(() => _isSaving = false);
          return;
        }

        final now = DateTime.now();

        for (int i = 0; i < _reminderTimes.length; i++) {
          final reminderTime = _reminderTimes[i];

          var scheduledDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            reminderTime.hour,
            reminderTime.minute,
          );

          if (scheduledDateTime.isBefore(now)) {
            scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
          }

          await reminderService.scheduleSingleReminder(
            userId: userId,
            medicationName: '$medicationName - $dosage',
            scheduledTime: scheduledDateTime,
            notes: notes,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.medication == null
                    ? 'Medication added!'
                    : 'Medication updated successfully!',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}