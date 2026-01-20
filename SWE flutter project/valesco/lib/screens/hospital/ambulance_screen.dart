import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/hospital_provider.dart';
import '../../models/hospital_model.dart';
import '../../widgets/common_widgets.dart';

class AmbulanceScreen extends StatefulWidget {
  const AmbulanceScreen({super.key});

  @override
  State<AmbulanceScreen> createState() => _AmbulanceScreenState();
}

class _AmbulanceScreenState extends State<AmbulanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HospitalProvider>().fetchNearbyAmbulances();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.ambulanceService),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<HospitalProvider>().fetchNearbyAmbulances();
            },
          ),
        ],
      ),
      body: Consumer<HospitalProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emergency Call Card
                _buildEmergencyCard(),
                const SizedBox(height: 24),

                // Available Ambulances Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SectionHeader(title: 'Available Ambulances'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${provider.availableAmbulances.length} Available',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Ambulance List
                if (provider.ambulances.isEmpty)
                  const EmptyStateWidget(
                    icon: Icons.local_hospital_outlined,
                    title: 'No Ambulances Found',
                    subtitle: 'No ambulances are available in your area',
                  )
                else
                  ...provider.ambulances.map((ambulance) {
                    return _buildAmbulanceCard(ambulance);
                  }),

                const SizedBox(height: 24),

                // Emergency Numbers Section
                const SectionHeader(title: 'Emergency Numbers'),
                const SizedBox(height: 12),
                _buildEmergencyNumbers(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmergencyCard() {
    return CustomCard(
      gradient: LinearGradient(
        colors: [AppColors.error, AppColors.error.withOpacity(0.8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emergency,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Call an ambulance immediately',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _callEmergency('999'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.phone),
                  label: const Text(
                    'Call 999',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _callEmergency('01713-222222'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.local_hospital),
                  label: const Text('Hospital Line'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmbulanceCard(AmbulanceModel ambulance) {
    final isAvailable = ambulance.status == AmbulanceStatus.available;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.grey200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_hospital,
                  color: isAvailable ? AppColors.success : AppColors.grey500,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ambulance.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ambulance.hospitalName,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(
                    text: ambulance.status.name.toUpperCase(),
                    color: isAvailable ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ambulance.distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryViolet,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildAmbulanceInfo(Icons.directions_car, ambulance.vehicleNumber),
              const SizedBox(width: 16),
              _buildAmbulanceInfo(Icons.person, ambulance.driverName),
              const SizedBox(width: 16),
              _buildAmbulanceInfo(Icons.timer, '~${ambulance.estimatedArrivalMinutes} min'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (ambulance.hasACAndOxygen) ...[
                _buildFeatureChip('AC', Icons.ac_unit),
                const SizedBox(width: 8),
                _buildFeatureChip('Oxygen', Icons.air),
                const SizedBox(width: 8),
              ],
              if (ambulance.isAdvancedLifeSupport)
                _buildFeatureChip('ALS', Icons.favorite),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _callNumber(ambulance.phone),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: isAvailable
                      ? () => _bookAmbulance(context, ambulance)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                  ),
                  icon: const Icon(Icons.local_hospital),
                  label: Text(isAvailable ? 'Book Now' : 'Not Available'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmbulanceInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.grey500),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryViolet.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryViolet),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryViolet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyNumbers() {
    final emergencyNumbers = [
      {'name': 'National Emergency', 'number': '999', 'icon': Icons.emergency},
      {'name': 'Fire Service', 'number': '199', 'icon': Icons.local_fire_department},
      {'name': 'Police', 'number': '100', 'icon': Icons.local_police},
      {'name': 'Women Helpline', 'number': '10921', 'icon': Icons.woman},
    ];

    return CustomCard(
      child: Column(
        children: emergencyNumbers.map((item) {
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item['icon'] as IconData,
                color: AppColors.error,
                size: 20,
              ),
            ),
            title: Text(item['name'] as String),
            subtitle: Text(
              item['number'] as String,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryOrange,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.phone, color: AppColors.success),
              onPressed: () => _callNumber(item['number'] as String),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _callEmergency(String number) async {
    final url = Uri.parse('tel:$number');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _callNumber(String number) async {
    final url = Uri.parse('tel:$number');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _bookAmbulance(BuildContext context, AmbulanceModel ambulance) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Book Ambulance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ambulance: ${ambulance.name}'),
              Text('Hospital: ${ambulance.hospitalName}'),
              Text('Est. Arrival: ~${ambulance.estimatedArrivalMinutes} minutes'),
              const SizedBox(height: 16),
              const Text(
                'Your current location will be shared with the ambulance driver.',
                style: TextStyle(color: AppColors.grey500, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Ambulance booked! ${ambulance.driverName} will arrive in ~${ambulance.estimatedArrivalMinutes} minutes.',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
              ),
              child: const Text('Confirm Booking'),
            ),
          ],
        );
      },
    );
  }
}
