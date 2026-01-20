import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/medication_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/medication_model.dart';
import '../../widgets/common_widgets.dart';
import '../../services/medication_reminder_service.dart'; // Add this import

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
  bool _isSaving = false; // Add loading state

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

  void _updateReminderTimesForFrequency() {
    switch (_selectedFrequency) {
      case MedicationFrequency.daily:
        if (_reminderTimes.length != 1) {
          _reminderTimes = [const TimeOfDay(hour: 8, minute: 0)];
        }
        break;
      case MedicationFrequency.twiceDaily:
        if (_reminderTimes.length != 2) {
          _reminderTimes = [
            const TimeOfDay(hour: 8, minute: 0),
            const TimeOfDay(hour: 20, minute: 0),
          ];
        }
        break;
      case MedicationFrequency.threeTimesDaily:
        if (_reminderTimes.length != 3) {
          _reminderTimes = [
            const TimeOfDay(hour: 8, minute: 0),
            const TimeOfDay(hour: 14, minute: 0),
            const TimeOfDay(hour: 20, minute: 0),
          ];
        }
        break;
      default:
        break;
    }
    setState(() {});
  }

  Future<void> _selectTime(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTimes[index],
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryOrange,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _reminderTimes[index] = picked;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryOrange,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryOrange,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
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

      // Save medication to database
      if (widget.medication == null) {
        await medicationProvider.addMedication(medication);
      } else {
        await medicationProvider.updateMedication(medication);
        
        // Cancel old reminders if updating
        if (medication.id != null) {
          await reminderService.cancelPlanReminders(medication.id!);
        }
      }

      // Schedule notifications for each reminder time
      final now = DateTime.now();
      for (int i = 0; i < _reminderTimes.length; i++) {
        final reminderTime = _reminderTimes[i];
        
        // Create DateTime for today at the reminder time
        var scheduledDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          reminderTime.hour,
          reminderTime.minute,
        );

        // If the time has passed today, schedule for tomorrow
        if (scheduledDateTime.isBefore(now)) {
          scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
        }

        // Schedule the reminder
        await reminderService.scheduleSingleReminder(
          userId: userId,
          medicationName: '$medicationName - $dosage',
          scheduledTime: scheduledDateTime,
          notes: notes,
        );

        debugPrint('✅ Scheduled reminder for $medicationName at ${DateFormat('hh:mm a').format(scheduledDateTime)}');
      }

      if (mounted) {
        // Show pending notifications for debugging
        final pendingNotifications = await reminderService.getPendingNotifications();
        debugPrint('📱 Total pending notifications: ${pendingNotifications.length}');
        for (var notification in pendingNotifications) {
          debugPrint('   - ${notification.title} at ${notification.body}');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.medication == null
                  ? 'Medication added with ${_reminderTimes.length} reminder(s)!'
                  : 'Medication updated successfully!',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Error saving medication: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medication == null ? AppStrings.addMedication : 'Edit Medication'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medication Name
              CustomTextField(
                controller: _nameController,
                label: AppStrings.medicationName,
                hint: 'e.g., Metformin',
                prefixIcon: Icons.medication,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter medication name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Dosage
              CustomTextField(
                controller: _dosageController,
                label: AppStrings.dosage,
                hint: 'e.g., 500mg',
                prefixIcon: Icons.science,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter dosage';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Frequency
              DropdownButtonFormField<MedicationFrequency>(
                initialValue: _selectedFrequency,
                decoration: const InputDecoration(
                  labelText: AppStrings.frequency,
                  prefixIcon: Icon(Icons.repeat, color: AppColors.primaryOrange),
                ),
                items: MedicationFrequency.values.map((freq) {
                  return DropdownMenuItem(
                    value: freq,
                    child: Text(freq.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  _selectedFrequency = value!;
                  _updateReminderTimesForFrequency();
                },
              ),
              const SizedBox(height: 24),

              // Reminder Times
              _buildSectionTitle('Reminder Times'),
              const SizedBox(height: 12),
              ...List.generate(_reminderTimes.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => _selectTime(index),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.grey300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.alarm, color: AppColors.primaryOrange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dose ${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.grey500,
                                  ),
                                ),
                                Text(
                                  DateFormat('hh:mm a').format(
                                    DateTime(2024, 1, 1, _reminderTimes[index].hour, _reminderTimes[index].minute),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.edit, color: AppColors.grey400),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Duration
              _buildSectionTitle('Duration'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectStartDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.grey300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.grey500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(_startDate),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _selectEndDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.grey300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End Date (Optional)',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.grey500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _endDate != null
                                  ? DateFormat('dd MMM yyyy').format(_endDate!)
                                  : 'Not set',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _endDate != null ? null : AppColors.grey400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Total Pills
              CustomTextField(
                controller: _totalPillsController,
                label: 'Total Pills',
                hint: 'Number of pills in this prescription',
                prefixIcon: Icons.inventory_2_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Notes
              CustomTextField(
                controller: _notesController,
                label: AppStrings.notes,
                hint: 'e.g., Take with food',
                prefixIcon: Icons.note_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Save Button
              GradientButton(
                text: _isSaving 
                    ? 'Saving...' 
                    : (widget.medication == null ? 'Add Medication' : 'Save Changes'),
                onPressed: _isSaving ? null : _saveMedication,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}