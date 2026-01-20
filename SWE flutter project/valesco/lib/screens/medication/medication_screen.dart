import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/medication_provider.dart';
import '../../models/medication_model.dart';
import '../../widgets/common_widgets.dart';
import 'add_medication_screen.dart';
import 'medication_detail_screen.dart';
import 'medication_calendar_screen.dart';

class MedicationScreen extends StatelessWidget {
  const MedicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.medications),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MedicationCalendarScreen(),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddMedicationScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primaryOrange,
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addMedication),
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          if (provider.medications.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.medication_outlined,
              title: 'No Medications',
              subtitle: 'Add your medications to get reminders and track adherence',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Adherence Card
                _buildAdherenceCard(context, provider),
                const SizedBox(height: 24),

                // Today's Schedule
                const SectionHeader(title: "Today's Schedule"),
                _buildTodaySchedule(context, provider),
                const SizedBox(height: 24),

                // Medications needing refill
                if (provider.getMedicationsNeedingRefill().isNotEmpty) ...[
                  const SectionHeader(title: 'Refill Needed'),
                  _buildRefillAlerts(context, provider),
                  const SizedBox(height: 24),
                ],

                // All Medications
                const SectionHeader(title: 'All Medications'),
                _buildMedicationsList(context, provider),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdherenceCard(BuildContext context, MedicationProvider provider) {
    final adherence = provider.getAdherenceRate();
    final color = adherence >= 80
        ? AppColors.success
        : adherence >= 60
            ? AppColors.warning
            : AppColors.error;

    return CustomCard(
      gradient: AppColors.primaryGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Adherence',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Last 7 days',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${adherence.toInt()}%',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Icon(
                  adherence >= 80
                      ? Icons.trending_up
                      : adherence >= 60
                          ? Icons.trending_flat
                          : Icons.trending_down,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: adherence / 100,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withOpacity(0.9),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            adherence >= 80
                ? 'Great job! Keep it up! 🎉'
                : adherence >= 60
                    ? 'You\'re doing okay. Try to be more consistent.'
                    : 'Your adherence is low. Set reminders!',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule(BuildContext context, MedicationProvider provider) {
    final todaySchedule = provider.getTodaySchedule();

    if (todaySchedule.isEmpty) {
      return CustomCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 48),
                const SizedBox(height: 8),
                const Text(
                  'No medications scheduled for today!',
                  style: TextStyle(color: AppColors.grey600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: todaySchedule.map((intake) {
        final medication = provider.getMedicationById(intake.medicationId);
        if (medication == null) return const SizedBox.shrink();

        return _buildScheduleItem(context, provider, medication, intake);
      }).toList(),
    );
  }

  Widget _buildScheduleItem(
    BuildContext context,
    MedicationProvider provider,
    MedicationModel medication,
    MedicationIntakeModel intake,
  ) {
    final isPast = intake.scheduledTime.isBefore(DateTime.now());
    final statusColor = intake.status == IntakeStatus.taken
        ? AppColors.success
        : intake.status == IntakeStatus.skipped
            ? AppColors.error
            : isPast
                ? AppColors.warning
                : AppColors.grey400;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.medication,
              color: AppColors.primaryOrange,
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
          if (intake.status == IntakeStatus.pending) ...[
            IconButton(
              onPressed: () {
                provider.recordIntake(medication.id, IntakeStatus.taken);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${medication.name} marked as taken'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              color: AppColors.success,
            ),
            IconButton(
              onPressed: () {
                provider.recordIntake(medication.id, IntakeStatus.skipped);
              },
              icon: const Icon(Icons.cancel_outlined),
              color: AppColors.error,
            ),
          ] else ...[
            StatusBadge(
              text: intake.status.name.toUpperCase(),
              color: statusColor,
              icon: intake.status == IntakeStatus.taken
                  ? Icons.check
                  : Icons.close,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRefillAlerts(BuildContext context, MedicationProvider provider) {
    final refillNeeded = provider.getMedicationsNeedingRefill();

    return Column(
      children: refillNeeded.map((medication) {
        return CustomCard(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
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
                      'Only ${medication.pillsRemaining} pills remaining',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refill reminder set!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                child: const Text('Refill'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMedicationsList(BuildContext context, MedicationProvider provider) {
    return Column(
      children: provider.activeMedications.map((medication) {
        return CustomCard(
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MedicationDetailScreen(medication: medication),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryViolet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medication_liquid,
                  color: AppColors.primaryViolet,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 4),
                    Text(
                      '${medication.dosage} • ${medication.frequency.displayName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.grey400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          medication.reminderTimes
                              .map((t) => DateFormat('hh:mm a').format(
                                    DateTime(2024, 1, 1, t.hour, t.minute),
                                  ))
                              .join(', '),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.grey400,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
