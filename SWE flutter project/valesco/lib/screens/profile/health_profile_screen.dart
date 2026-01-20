import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/health_profile_provider.dart';
import '../../models/health_profile_model.dart';
import '../../widgets/common_widgets.dart';
import 'edit_profile_screen.dart';
import 'emergency_contacts_screen.dart';
import 'medical_documents_screen.dart';

class HealthProfileScreen extends StatelessWidget {
  const HealthProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.healthProfile),
        actions: [
          Consumer<HealthProfileProvider>(
            builder: (context, provider, _) {
              if (provider.healthProfile != null) {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(
                          profile: provider.healthProfile!,
                        ),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<HealthProfileProvider>(
        builder: (context, provider, child) {
          final profile = provider.healthProfile;

          if (profile == null) {
            return EmptyStateWidget(
              icon: Icons.person_add_outlined,
              title: 'No Health Profile',
              subtitle: 'Create your health profile to get started',
              actionText: 'Create Profile',
              onAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditProfileScreen(),
                  ),
                );
              },
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                _buildProfileHeader(profile),
                const SizedBox(height: 24),

                // Quick Stats
                _buildQuickStats(profile),
                const SizedBox(height: 24),

                // Medical History Section
                _buildSection(
                  context,
                  title: 'Medical History',
                  icon: Icons.history,
                  children: [
                    if (profile.chronicConditions.isNotEmpty)
                      _buildInfoTile(
                        'Chronic Conditions',
                        profile.chronicConditions.join(', '),
                        Icons.health_and_safety,
                      ),
                    if (profile.pastSurgeries.isNotEmpty)
                      _buildInfoTile(
                        'Past Surgeries',
                        profile.pastSurgeries.join(', '),
                        Icons.local_hospital,
                      ),
                    if (profile.currentMedications.isNotEmpty)
                      _buildInfoTile(
                        'Current Medications',
                        profile.currentMedications.join(', '),
                        Icons.medication,
                      ),
                    if (profile.chronicConditions.isEmpty &&
                        profile.pastSurgeries.isEmpty &&
                        profile.currentMedications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No medical history recorded',
                          style: TextStyle(color: AppColors.grey500),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Allergies Section
                _buildSection(
                  context,
                  title: 'Allergies',
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppColors.warning,
                  children: [
                    if (profile.drugAllergies.isNotEmpty)
                      _buildAllergyChips('Drug Allergies', profile.drugAllergies),
                    if (profile.foodAllergies.isNotEmpty)
                      _buildAllergyChips('Food Allergies', profile.foodAllergies),
                    if (profile.drugAllergies.isEmpty && profile.foodAllergies.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No allergies recorded',
                          style: TextStyle(color: AppColors.grey500),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Emergency Contacts
                _buildActionCard(
                  context,
                  title: 'Emergency Contacts',
                  subtitle: '${profile.emergencyContacts.length} contacts saved',
                  icon: Icons.emergency,
                  color: AppColors.error,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EmergencyContactsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Medical Documents
                _buildActionCard(
                  context,
                  title: 'Medical Documents',
                  subtitle: '${profile.medicalDocuments.length} documents uploaded',
                  icon: Icons.folder_open,
                  color: AppColors.primaryViolet,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MedicalDocumentsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(HealthProfileModel profile) {
    return CustomCard(
      gradient: AppColors.primaryGradient,
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${profile.age} years • ${profile.gender.name.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Blood: ${profile.bloodGroup.displayName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(HealthProfileModel profile) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Height',
            '${profile.height.toInt()}',
            'cm',
            Icons.height,
            AppColors.primaryOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            'Weight',
            profile.weight.toStringAsFixed(1),
            'kg',
            Icons.monitor_weight,
            AppColors.primaryViolet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            'BMI',
            profile.bmi.toStringAsFixed(1),
            profile.bmiCategory,
            Icons.speed,
            _getBmiColor(profile.bmi),
          ),
        ),
      ],
    );
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return AppColors.warning;
    if (bmi < 25) return AppColors.success;
    if (bmi < 30) return AppColors.warning;
    return AppColors.error;
  }

  Widget _buildStatItem(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return CustomCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.grey500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    Color? iconColor,
    required List<Widget> children,
  }) {
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
                    color: (iconColor ?? AppColors.primaryOrange).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AppColors.primaryOrange,
                    size: 20,
                  ),
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
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.grey400, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergyChips(String title, List<String> allergies) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allergies.map((allergy) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      size: 14,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      allergy,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
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
  }
}
