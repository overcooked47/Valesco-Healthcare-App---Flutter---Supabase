import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/hospital_provider.dart';
import '../../models/hospital_model.dart';
import '../../widgets/common_widgets.dart';
import 'hospital_detail_screen.dart';
import 'ambulance_screen.dart';

class HospitalScreen extends StatefulWidget {
  const HospitalScreen({super.key});

  @override
  State<HospitalScreen> createState() => _HospitalScreenState();
}

class _HospitalScreenState extends State<HospitalScreen> {
  final _searchController = TextEditingController();
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HospitalProvider>().fetchNearbyHospitals();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.hospitalLocator),
        actions: [
          // Refresh location button
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Refresh location',
            onPressed: () {
              context.read<HospitalProvider>().fetchNearbyHospitals(refreshLocation: true);
            },
          ),
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
          ),
        ],
      ),
      body: Consumer<HospitalProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search hospitals...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    provider.searchHospitals('');
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          provider.searchHospitals(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: AppColors.primaryViolet,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AmbulanceScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.local_hospital,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              SizedBox(
                height: 45,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip(
                      'All',
                      provider.selectedSpecialty == null,
                      () => provider.filterBySpecialty(null),
                    ),
                    _buildFilterChip(
                      'Emergency',
                      provider.selectedSpecialty == 'Emergency',
                      () => provider.filterBySpecialty('Emergency'),
                    ),
                    _buildFilterChip(
                      'Cardiology',
                      provider.selectedSpecialty == 'Cardiology',
                      () => provider.filterBySpecialty('Cardiology'),
                    ),
                    _buildFilterChip(
                      'Diabetes',
                      provider.selectedSpecialty == 'Diabetes',
                      () => provider.filterBySpecialty('Diabetes'),
                    ),
                    _buildFilterChip(
                      'Open Now',
                      provider.selectedSpecialty == 'Open Now',
                      () => provider.filterBySpecialty('Open Now'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Location Permission Banner (if needed)
              if (provider.locationPermissionDenied || provider.locationServiceDisabled)
                _buildLocationBanner(provider),

              // Content
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _showMap
                        ? _buildMapView(provider)
                        : _buildListView(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLocationBanner(HospitalProvider provider) {
    final isServiceDisabled = provider.locationServiceDisabled;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isServiceDisabled ? Icons.location_off : Icons.location_disabled,
            color: AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isServiceDisabled ? 'Location Services Disabled' : 'Location Permission Required',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isServiceDisabled 
                      ? 'Enable location to find hospitals near you'
                      : 'Allow location access to see nearby hospitals',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              if (isServiceDisabled) {
                await provider.openLocationSettings();
              } else {
                await provider.openAppSettings();
              }
              // Refresh after returning from settings
              if (mounted) {
                provider.fetchNearbyHospitals(refreshLocation: true);
              }
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryOrange.withOpacity(0.2),
        checkmarkColor: AppColors.primaryOrange,
        labelStyle: TextStyle(
          color: selected ? AppColors.primaryOrange : AppColors.grey600,
          fontWeight: selected ? FontWeight.w600 : null,
        ),
      ),
    );
  }

  Widget _buildMapView(HospitalProvider provider) {
    // Placeholder for Google Maps integration
    return Stack(
      children: [
        Container(
          color: AppColors.grey100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 80,
                  color: AppColors.grey400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Map View',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.grey500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Google Maps integration will be displayed here\nwith ${provider.hospitals.length} hospitals marked',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.grey400,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final url = Uri.parse(
                      'https://www.google.com/maps/search/hospitals+near+me',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open in Google Maps'),
                ),
              ],
            ),
          ),
        ),
        // Bottom sheet preview
        DraggableScrollableSheet(
          initialChildSize: 0.3,
          minChildSize: 0.1,
          maxChildSize: 0.7,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: provider.hospitals.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
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
                        Row(
                          children: [
                            Text(
                              '${provider.hospitals.length} hospitals found',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  }
                  return _buildHospitalCard(provider.hospitals[index - 1]);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildListView(HospitalProvider provider) {
    if (provider.hospitals.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.local_hospital_outlined,
        title: 'No Hospitals Found',
        subtitle: 'Try adjusting your search or filters',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.hospitals.length,
      itemBuilder: (context, index) {
        return _buildHospitalCard(provider.hospitals[index]);
      },
    );
  }

  Widget _buildHospitalCard(HospitalModel hospital) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HospitalDetailScreen(hospital: hospital),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: AppColors.primaryOrange,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.grey500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hospital.address,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.grey500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hospital.isOpen24Hours
                                ? AppColors.success
                                : AppColors.grey400,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hospital.isOpen24Hours ? 'Open 24/7' : 'Check hours',
                          style: TextStyle(
                            fontSize: 12,
                            color: hospital.isOpen24Hours
                                ? AppColors.success
                                : AppColors.grey500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${hospital.distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryViolet,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Rating and Actions
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                hospital.rating.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              if (hospital.hasEmergency)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'EMERGENCY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.phone, color: AppColors.primaryOrange),
                onPressed: () async {
                  final url = Uri.parse('tel:${hospital.phone}');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.directions, color: AppColors.primaryViolet),
                onPressed: () async {
                  final url = Uri.parse(
                    'https://www.google.com/maps/dir/?api=1&destination=${hospital.latitude},${hospital.longitude}',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
