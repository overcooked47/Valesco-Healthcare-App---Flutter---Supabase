import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/health_reading_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/health_reading_model.dart';
import '../../widgets/common_widgets.dart';

class AddReadingScreen extends StatefulWidget {
  final HealthReadingType? initialType;

  const AddReadingScreen({super.key, this.initialType});

  @override
  State<AddReadingScreen> createState() => _AddReadingScreenState();
}

class _AddReadingScreenState extends State<AddReadingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _notesController = TextEditingController();

  late HealthReadingType _selectedType;
  DateTime _selectedDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? HealthReadingType.bloodGlucose;
  }

  @override
  void dispose() {
    _valueController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Reading'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reading Type Selection
              const Text(
                'Reading Type',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HealthReadingType.values.map((type) {
                  final isSelected = type == _selectedType;
                  return ChoiceChip(
                    label: Text(type.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedType = type;
                          _valueController.clear();
                          _systolicController.clear();
                          _diastolicController.clear();
                        });
                      }
                    },
                    selectedColor: AppColors.primaryOrange.withOpacity(0.2),
                    checkmarkColor: AppColors.primaryOrange,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Value Input
              _buildValueInput(),
              const SizedBox(height: 24),

              // Date & Time
              const Text(
                'Date & Time',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.grey300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: AppColors.primaryOrange),
                            const SizedBox(width: 12),
                            Text(
                              '${_selectedDateTime.day}/${_selectedDateTime.month}/${_selectedDateTime.year}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _selectTime,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.grey300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time,
                                color: AppColors.primaryOrange),
                            const SizedBox(width: 12),
                            Text(
                              '${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Notes
              CustomTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                hint: 'e.g., After meal, Before exercise',
                prefixIcon: Icons.note_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Reference Values
              _buildReferenceCard(),
              const SizedBox(height: 24),

              // Save Button
              GradientButton(
                text: 'Save Reading',
                onPressed: _saveReading,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueInput() {
    if (_selectedType == HealthReadingType.bloodPressure) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Blood Pressure',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _systolicController,
                  label: 'Systolic',
                  hint: '120',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.arrow_upward,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    final num = double.tryParse(value);
                    if (num == null || num < 50 || num > 250) {
                      return 'Invalid';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _diastolicController,
                  label: 'Diastolic',
                  hint: '80',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.arrow_downward,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    final num = double.tryParse(value);
                    if (num == null || num < 30 || num > 150) {
                      return 'Invalid';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Measured in mmHg',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey500,
            ),
          ),
        ],
      );
    }

    String hint;
    String unit;
    double min;
    double max;

    switch (_selectedType) {
      case HealthReadingType.bloodGlucose:
        hint = '100';
        unit = 'mg/dL';
        min = 20;
        max = 600;
        break;
      case HealthReadingType.heartRate:
        hint = '72';
        unit = 'BPM';
        min = 30;
        max = 220;
        break;
      case HealthReadingType.weight:
        hint = '70';
        unit = 'kg';
        min = 20;
        max = 300;
        break;
      default:
        hint = '0';
        unit = '';
        min = 0;
        max = 1000;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedType.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _valueController,
          label: 'Value',
          hint: hint,
          keyboardType: TextInputType.number,
          prefixIcon: _getIconForType(_selectedType),
          suffixText: unit,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a value';
            }
            final num = double.tryParse(value);
            if (num == null || num < min || num > max) {
              return 'Please enter a valid value ($min-$max)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildReferenceCard() {
    String title;
    List<Map<String, dynamic>> ranges;

    switch (_selectedType) {
      case HealthReadingType.bloodGlucose:
        title = 'Blood Sugar Reference (mg/dL)';
        ranges = [
          {'label': 'Normal (Fasting)', 'range': '70-100', 'color': AppColors.success},
          {'label': 'Pre-diabetic', 'range': '100-125', 'color': AppColors.warning},
          {'label': 'Diabetic', 'range': '126+', 'color': AppColors.error},
        ];
        break;
      case HealthReadingType.bloodPressure:
        title = 'Blood Pressure Reference (mmHg)';
        ranges = [
          {'label': 'Normal', 'range': '<120/80', 'color': AppColors.success},
          {'label': 'Elevated', 'range': '120-129/<80', 'color': AppColors.warning},
          {'label': 'High (Stage 1)', 'range': '130-139/80-89', 'color': AppColors.error},
        ];
        break;
      case HealthReadingType.heartRate:
        title = 'Heart Rate Reference (BPM)';
        ranges = [
          {'label': 'Low', 'range': '<60', 'color': AppColors.info},
          {'label': 'Normal', 'range': '60-100', 'color': AppColors.success},
          {'label': 'High', 'range': '>100', 'color': AppColors.error},
        ];
        break;
      case HealthReadingType.weight:
        title = 'BMI Reference';
        ranges = [
          {'label': 'Underweight', 'range': '<18.5', 'color': AppColors.info},
          {'label': 'Normal', 'range': '18.5-24.9', 'color': AppColors.success},
          {'label': 'Overweight', 'range': '25-29.9', 'color': AppColors.warning},
        ];
        break;
      case HealthReadingType.temperature:
        title = 'Temperature Reference (°C)';
        ranges = [
          {'label': 'Low', 'range': '<36.1', 'color': AppColors.info},
          {'label': 'Normal', 'range': '36.1-37.2', 'color': AppColors.success},
          {'label': 'Fever', 'range': '>37.8', 'color': AppColors.error},
        ];
        break;
      case HealthReadingType.oxygenLevel:
        title = 'Oxygen Level Reference (%)';
        ranges = [
          {'label': 'Low', 'range': '<94', 'color': AppColors.error},
          {'label': 'Normal', 'range': '95-100', 'color': AppColors.success},
        ];
        break;
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...ranges.map((range) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: range['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      range['label'] as String,
                      style: TextStyle(
                        color: AppColors.grey600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    range['range'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getIconForType(HealthReadingType type) {
    switch (type) {
      case HealthReadingType.bloodGlucose:
        return Icons.bloodtype;
      case HealthReadingType.bloodPressure:
        return Icons.favorite;
      case HealthReadingType.heartRate:
        return Icons.monitor_heart;
      case HealthReadingType.weight:
        return Icons.scale;
      default:
        return Icons.health_and_safety;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
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
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
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
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _saveReading() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final readingProvider = context.read<HealthReadingProvider>();

    double value;
    double? secondaryValue;

    if (_selectedType == HealthReadingType.bloodPressure) {
      value = double.parse(_systolicController.text);
      secondaryValue = double.parse(_diastolicController.text);
    } else {
      value = double.parse(_valueController.text);
    }

    final reading = HealthReadingModel(
      userId: authProvider.currentUser?.id ?? 'user_1',
      type: _selectedType,
      value: value,
      secondaryValue: secondaryValue,
      timestamp: _selectedDateTime,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    await readingProvider.addReading(reading);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reading saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }
}
