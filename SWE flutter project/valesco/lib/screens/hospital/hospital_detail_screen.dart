import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/hospital_model.dart';
import '../../widgets/common_widgets.dart';

class HospitalDetailScreen extends StatelessWidget {
  final HospitalModel hospital;

  const HospitalDetailScreen({super.key, required this.hospital});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Hospital Image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.local_hospital,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              title: Text(
                hospital.name,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Info Card
                  _buildQuickInfoCard(),
                  const SizedBox(height: 16),

                  // Action Buttons
                  _buildActionButtons(context),
                  const SizedBox(height: 24),

                  // About Section
                  _buildSection(
                    'About',
                    Icons.info_outline,
                    AppColors.info,
                    [
                      Text(
                        hospital.description ?? 
                            'A leading healthcare facility providing comprehensive medical services.',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Specialties
                  _buildSection(
                    'Specialties',
                    Icons.medical_services,
                    AppColors.primaryOrange,
                    [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: hospital.specialties.map((specialty) {
                          return Chip(
                            label: Text(
                              specialty,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: AppColors.primaryOrange.withOpacity(0.1),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Facilities
                  _buildSection(
                    'Facilities',
                    Icons.apartment,
                    AppColors.primaryViolet,
                    [
                      _buildFacilityItem('Emergency Department', hospital.hasEmergency),
                      _buildFacilityItem('24/7 Service', hospital.isOpen24Hours),
                      _buildFacilityItem('Ambulance Service', hospital.hasAmbulance),
                      _buildFacilityItem('ICU', true),
                      _buildFacilityItem('Laboratory', true),
                      _buildFacilityItem('Pharmacy', true),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Contact Information
                  _buildSection(
                    'Contact Information',
                    Icons.contact_phone,
                    AppColors.success,
                    [
                      _buildContactItem(
                        Icons.location_on,
                        'Address',
                        hospital.address,
                        onTap: () => _openMaps(context),
                      ),
                      _buildContactItem(
                        Icons.phone,
                        'Phone',
                        hospital.phone,
                        onTap: () => _callHospital(),
                      ),
                      if (hospital.email != null)
                        _buildContactItem(
                          Icons.email,
                          'Email',
                          hospital.email!,
                          onTap: () => _sendEmail(),
                        ),
                      if (hospital.website != null)
                        _buildContactItem(
                          Icons.language,
                          'Website',
                          hospital.website!,
                          onTap: () => _openWebsite(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Operating Hours
                  _buildSection(
                    'Operating Hours',
                    Icons.access_time,
                    AppColors.warning,
                    [
                      _buildHoursRow('Monday - Friday', '8:00 AM - 10:00 PM'),
                      _buildHoursRow('Saturday', '9:00 AM - 8:00 PM'),
                      _buildHoursRow('Sunday', '9:00 AM - 6:00 PM'),
                      if (hospital.isOpen24Hours)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Emergency services available 24/7',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _callHospital,
                icon: const Icon(Icons.phone),
                label: const Text('Call'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GradientButton(
                text: 'Get Directions',
                icon: Icons.directions,
                onPressed: () => _openMaps(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfoCard() {
    return CustomCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            Icons.star,
            Colors.amber,
            hospital.rating.toString(),
            'Rating',
          ),
          _buildDivider(),
          _buildInfoItem(
            Icons.location_on,
            AppColors.primaryViolet,
            '${hospital.distanceKm.toStringAsFixed(1)} km',
            'Distance',
          ),
          _buildDivider(),
          _buildInfoItem(
            hospital.isOpen24Hours ? Icons.check_circle : Icons.access_time,
            hospital.isOpen24Hours ? AppColors.success : AppColors.warning,
            hospital.isOpen24Hours ? 'Open' : 'Hours',
            hospital.isOpen24Hours ? '24/7' : 'Limited',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.grey500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 50,
      width: 1,
      color: AppColors.grey200,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            Icons.bookmark_outline,
            'Save',
            AppColors.primaryOrange,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hospital saved!')),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            Icons.share,
            'Share',
            AppColors.primaryViolet,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality')),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            Icons.report_outlined,
            'Report',
            AppColors.grey500,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
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

  Widget _buildFacilityItem(String name, bool available) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            color: available ? AppColors.success : AppColors.grey400,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: TextStyle(
              color: available ? null : AppColors.grey400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryOrange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey500,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: AppColors.grey400,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursRow(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: TextStyle(color: AppColors.grey600),
          ),
          Text(
            hours,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _callHospital() async {
    final url = Uri.parse('tel:${hospital.phone}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openMaps(BuildContext context) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${hospital.latitude},${hospital.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendEmail() async {
    if (hospital.email == null) return;
    final url = Uri.parse('mailto:${hospital.email}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openWebsite() async {
    if (hospital.website == null) return;
    final url = Uri.parse(hospital.website!);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
