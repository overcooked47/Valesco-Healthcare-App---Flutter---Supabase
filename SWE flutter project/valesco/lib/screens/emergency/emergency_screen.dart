import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/emergency_provider.dart';
import '../../providers/health_profile_provider.dart';
import '../../models/emergency_alert_model.dart';
import '../../widgets/common_widgets.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.emergencyAlert),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showAlertHistory(context),
          ),
        ],
      ),
      body: Consumer2<EmergencyProvider, HealthProfileProvider>(
        builder: (context, emergencyProvider, profileProvider, child) {
          if (emergencyProvider.isAlertActive) {
            return _buildActiveAlertView(emergencyProvider);
          }

          return _buildSOSView(context, emergencyProvider, profileProvider);
        },
      ),
    );
  }

  Widget _buildSOSView(
    BuildContext context,
    EmergencyProvider emergencyProvider,
    HealthProfileProvider profileProvider,
  ) {
    final hasEmergencyContacts =
        profileProvider.profile?.emergencyContacts.isNotEmpty ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // SOS Button
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: GestureDetector(
                    onLongPress: () => _initiateEmergency(context),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.error,
                            AppColors.error.withOpacity(0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emergency,
                            color: Colors.white,
                            size: 60,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Long press SOS button to send emergency alert',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.grey600,
            ),
          ),

          const SizedBox(height: 40),

          // Emergency Contacts Status
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasEmergencyContacts
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        hasEmergencyContacts
                            ? Icons.check_circle
                            : Icons.warning,
                        color: hasEmergencyContacts
                            ? AppColors.success
                            : AppColors.warning,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Emergency Contacts',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            hasEmergencyContacts
                                ? '${profileProvider.profile!.emergencyContacts.length} contacts configured'
                                : 'No contacts configured',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!hasEmergencyContacts)
                      TextButton(
                        onPressed: () {
                          // Navigate to emergency contacts
                        },
                        child: const Text('Add'),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // What happens section
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'What happens when you trigger SOS?',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSOSStep('1', 'Countdown starts (5 seconds)'),
                _buildSOSStep('2', 'SMS sent to emergency contacts'),
                _buildSOSStep('3', 'Your location is shared'),
                _buildSOSStep('4', 'Nearby hospitals are notified'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions
          const SectionHeader(title: 'Quick Actions'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  'Call 999',
                  Icons.phone,
                  AppColors.error,
                  () => emergencyProvider.callEmergencyNumber('999'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAction(
                  'Book Ambulance',
                  Icons.local_hospital,
                  AppColors.primaryOrange,
                  () {
                    // Navigate to ambulance screen
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSOSStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
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

  Widget _buildActiveAlertView(EmergencyProvider provider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.error, Color(0xFFB71C1C)],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (provider.countdownSeconds > 0) ...[
              // Countdown View
              const Text(
                'EMERGENCY ALERT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Center(
                  child: Text(
                    '${provider.countdownSeconds}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Alert will be sent in...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => provider.cancelAlert(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                ),
                icon: const Icon(Icons.cancel),
                label: const Text(
                  'Cancel Alert',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else ...[
              // Alert Active View
              const Icon(
                Icons.warning,
                color: Colors.white,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'ALERT SENT!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Emergency contacts have been notified with your location',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Status Updates
              CustomCard(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildStatusRow(
                      'SMS to contacts',
                      true,
                      Icons.message,
                    ),
                    _buildStatusRow(
                      'Location shared',
                      true,
                      Icons.location_on,
                    ),
                    _buildStatusRow(
                      'Ambulance notified',
                      provider.activeAlert?.isAmbulanceBooked ?? false,
                      Icons.local_hospital,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => provider.resolveAlert(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text("I'm Safe"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => provider.callEmergencyNumber('999'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.phone),
                    label: const Text('Call 999'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String text, bool completed, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.grey500, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
          Icon(
            completed ? Icons.check_circle : Icons.circle_outlined,
            color: completed ? AppColors.success : AppColors.grey400,
            size: 20,
          ),
        ],
      ),
    );
  }

  void _initiateEmergency(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: AppColors.error),
              SizedBox(width: 8),
              Text('Confirm Emergency'),
            ],
          ),
          content: const Text(
            'This will send an emergency alert to your contacts and share your location. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<EmergencyProvider>().initiateAlert(
                  userId: 'current_user',
                  latitude: 23.8103,
                  longitude: 90.4125,
                  address: 'Current Location',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Send Alert'),
            ),
          ],
        );
      },
    );
  }

  void _showAlertHistory(BuildContext context) {
    final provider = context.read<EmergencyProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.grey300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Alert History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: provider.alertHistory.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.history,
                          title: 'No Alerts',
                          subtitle: 'Your emergency alert history will appear here',
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.alertHistory.length,
                          itemBuilder: (context, index) {
                            final alert = provider.alertHistory[index];
                            return _buildAlertHistoryItem(alert);
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAlertHistoryItem(EmergencyAlertModel alert) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: alert.status == AlertStatus.resolved
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              alert.status == AlertStatus.resolved
                  ? Icons.check_circle
                  : Icons.warning,
              color: alert.status == AlertStatus.resolved
                  ? AppColors.success
                  : AppColors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Alert',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${alert.createdAt.day}/${alert.createdAt.month}/${alert.createdAt.year} at ${alert.createdAt.hour}:${alert.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(
            text: alert.status.name.toUpperCase(),
            color: alert.status == AlertStatus.resolved
                ? AppColors.success
                : AppColors.error,
          ),
        ],
      ),
    );
  }
}
