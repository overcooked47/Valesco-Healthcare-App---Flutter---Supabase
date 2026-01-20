import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/medication_provider.dart';
import '../../models/medication_model.dart';
import '../../widgets/common_widgets.dart';
import 'add_medication_screen.dart';

class MedicationDetailScreen extends StatelessWidget {
  final MedicationModel medication;

  const MedicationDetailScreen({super.key, required this.medication});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddMedicationScreen(medication: medication),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          // Get latest medication data
          final currentMedication = provider.getMedicationById(medication.id) ?? medication;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                _buildHeaderCard(currentMedication),
                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActions(context, provider, currentMedication),
                const SizedBox(height: 24),

                // Schedule Info
                _buildInfoSection(
                  'Schedule',
                  Icons.schedule,
                  AppColors.primaryOrange,
                  [
                    _buildInfoRow('Frequency', currentMedication.frequency.displayName),
                    _buildInfoRow(
                      'Reminder Times',
                      currentMedication.reminderTimes
                          .map((t) => DateFormat('hh:mm a').format(
                                DateTime(2024, 1, 1, t.hour, t.minute),
                              ))
                          .join(', '),
                    ),
                    _buildInfoRow(
                      'Start Date',
                      DateFormat('dd MMM yyyy').format(currentMedication.startDate),
                    ),
                    if (currentMedication.endDate != null)
                      _buildInfoRow(
                        'End Date',
                        DateFormat('dd MMM yyyy').format(currentMedication.endDate!),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Inventory Info
                _buildInfoSection(
                  'Inventory',
                  Icons.inventory,
                  AppColors.primaryViolet,
                  [
                    _buildInfoRow('Total Pills', currentMedication.totalPills.toString()),
                    _buildInfoRow('Pills Remaining', currentMedication.pillsRemaining.toString()),
                    _buildInfoRow(
                      'Refill Alert',
                      currentMedication.needsRefill ? 'Refill needed!' : 'OK',
                      valueColor: currentMedication.needsRefill ? AppColors.warning : AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notes
                if (currentMedication.notes != null && currentMedication.notes!.isNotEmpty)
                  _buildInfoSection(
                    'Notes',
                    Icons.note,
                    AppColors.info,
                    [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          currentMedication.notes!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),

                // Recent History
                _buildRecentHistory(context, provider, currentMedication),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(MedicationModel medication) {
    return CustomCard(
      gradient: AppColors.primaryGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.medication,
                  color: Colors.white,
                  size: 40,
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      medication.dosage,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: medication.status == MedicationStatus.active
                  ? Colors.white.withOpacity(0.2)
                  : AppColors.grey500.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              medication.status.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    MedicationProvider provider,
    MedicationModel medication,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Mark as Taken',
            Icons.check_circle,
            AppColors.success,
            () {
              provider.recordIntake(medication.id, IntakeStatus.taken);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${medication.name} marked as taken'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            'Skip Dose',
            Icons.cancel,
            AppColors.warning,
            () {
              provider.recordIntake(medication.id, IntakeStatus.skipped);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${medication.name} dose skipped'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.grey600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentHistory(
    BuildContext context,
    MedicationProvider provider,
    MedicationModel medication,
  ) {
    final history = provider.intakeHistory
        .where((i) => i.medicationId == medication.id)
        .take(10)
        .toList();

    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history, color: AppColors.info, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Recent History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No history yet',
                style: TextStyle(color: AppColors.grey500),
              ),
            )
          else
            ...history.map((intake) {
              return ListTile(
                leading: Icon(
                  intake.status == IntakeStatus.taken
                      ? Icons.check_circle
                      : intake.status == IntakeStatus.skipped
                          ? Icons.cancel
                          : Icons.access_time,
                  color: intake.status == IntakeStatus.taken
                      ? AppColors.success
                      : intake.status == IntakeStatus.skipped
                          ? AppColors.error
                          : AppColors.grey400,
                ),
                title: Text(
                  DateFormat('EEE, dd MMM').format(intake.scheduledTime),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  DateFormat('hh:mm a').format(intake.scheduledTime),
                ),
                trailing: Text(
                  intake.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: intake.status == IntakeStatus.taken
                        ? AppColors.success
                        : intake.status == IntakeStatus.skipped
                            ? AppColors.error
                            : AppColors.grey500,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Medication'),
          content: Text('Are you sure you want to delete ${medication.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await context.read<MedicationProvider>().deleteMedication(medication.id);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
