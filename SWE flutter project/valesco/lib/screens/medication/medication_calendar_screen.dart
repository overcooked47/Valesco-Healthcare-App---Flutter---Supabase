import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/medication_provider.dart';
import '../../models/medication_model.dart';
import '../../widgets/common_widgets.dart';

class MedicationCalendarScreen extends StatefulWidget {
  const MedicationCalendarScreen({super.key});

  @override
  State<MedicationCalendarScreen> createState() => _MedicationCalendarScreenState();
}

class _MedicationCalendarScreenState extends State<MedicationCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Calendar'),
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Month Header
              _buildMonthHeader(),
              // Calendar Grid
              _buildCalendar(provider),
              const Divider(),
              // Selected Day Schedule
              Expanded(
                child: _buildDaySchedule(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
              });
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(_focusedMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(MedicationProvider provider) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Weekday Headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((day) => SizedBox(
                      width: 40,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey500,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar Days
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayOffset = index - (firstWeekday % 7);
              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                return const SizedBox();
              }

              final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayOffset + 1);
              final isToday = _isSameDay(date, DateTime.now());
              final isSelected = _isSameDay(date, _selectedDate);
              final adherence = _getDayAdherence(provider, date);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryOrange
                        : isToday
                            ? AppColors.primaryOrange.withOpacity(0.1)
                            : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.primaryOrange, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${dayOffset + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isToday || isSelected ? FontWeight.bold : null,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppColors.primaryOrange
                                  : null,
                        ),
                      ),
                      if (adherence != null)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.white
                                : adherence >= 80
                                    ? AppColors.success
                                    : adherence >= 50
                                        ? AppColors.warning
                                        : AppColors.error,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDaySchedule(MedicationProvider provider) {
    final dayIntakes = _getDayIntakes(provider, _selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryViolet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: AppColors.primaryViolet,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                DateFormat('EEEE, dd MMMM').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: dayIntakes.isEmpty
              ? const Center(
                  child: Text(
                    'No medications scheduled for this day',
                    style: TextStyle(color: AppColors.grey500),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: dayIntakes.length,
                  itemBuilder: (context, index) {
                    final intake = dayIntakes[index];
                    final medication = provider.getMedicationById(intake.medicationId);
                    if (medication == null) return const SizedBox.shrink();

                    return _buildIntakeItem(medication, intake);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildIntakeItem(MedicationModel medication, MedicationIntakeModel intake) {
    final statusColor = intake.status == IntakeStatus.taken
        ? AppColors.success
        : intake.status == IntakeStatus.skipped
            ? AppColors.error
            : AppColors.grey400;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              intake.status == IntakeStatus.taken
                  ? Icons.check_circle
                  : intake.status == IntakeStatus.skipped
                      ? Icons.cancel
                      : Icons.medication,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${medication.dosage} • ${DateFormat('hh:mm a').format(intake.scheduledTime)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(
            text: intake.status.name.toUpperCase(),
            color: statusColor,
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  double? _getDayAdherence(MedicationProvider provider, DateTime date) {
    final dayIntakes = _getDayIntakes(provider, date);
    if (dayIntakes.isEmpty) return null;

    final taken = dayIntakes.where((i) => i.status == IntakeStatus.taken).length;
    return (taken / dayIntakes.length) * 100;
  }

  List<MedicationIntakeModel> _getDayIntakes(MedicationProvider provider, DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return provider.intakeHistory.where((intake) {
      return intake.scheduledTime.isAfter(dayStart) &&
          intake.scheduledTime.isBefore(dayEnd);
    }).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }
}
