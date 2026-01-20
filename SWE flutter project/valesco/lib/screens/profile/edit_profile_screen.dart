import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/health_profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/health_profile_model.dart';
import '../../widgets/common_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  final HealthProfileModel? profile;

  const EditProfileScreen({super.key, this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _chronicConditionsController;
  late TextEditingController _pastSurgeriesController;
  late TextEditingController _currentMedicationsController;
  late TextEditingController _drugAllergiesController;
  late TextEditingController _foodAllergiesController;

  Gender _selectedGender = Gender.male;
  BloodGroup _selectedBloodGroup = BloodGroup.oPositive;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;

    _nameController = TextEditingController(text: profile?.name ?? '');
    _ageController = TextEditingController(
      text: profile?.age.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: profile?.height.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: profile?.weight.toString() ?? '',
    );
    _chronicConditionsController = TextEditingController(
      text: profile?.chronicConditions.join(', ') ?? '',
    );
    _pastSurgeriesController = TextEditingController(
      text: profile?.pastSurgeries.join(', ') ?? '',
    );
    _currentMedicationsController = TextEditingController(
      text: profile?.currentMedications.join(', ') ?? '',
    );
    _drugAllergiesController = TextEditingController(
      text: profile?.drugAllergies.join(', ') ?? '',
    );
    _foodAllergiesController = TextEditingController(
      text: profile?.foodAllergies.join(', ') ?? '',
    );

    if (profile != null) {
      _selectedGender = profile.gender;
      _selectedBloodGroup = profile.bloodGroup;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _chronicConditionsController.dispose();
    _pastSurgeriesController.dispose();
    _currentMedicationsController.dispose();
    _drugAllergiesController.dispose();
    _foodAllergiesController.dispose();
    super.dispose();
  }

  List<String> _parseList(String text) {
    return text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<HealthProfileProvider>();

    final newProfile = HealthProfileModel(
      id: widget.profile?.id,
      userId: authProvider.currentUser?.id ?? 'user_1',
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text),
      gender: _selectedGender,
      bloodGroup: _selectedBloodGroup,
      height: double.parse(_heightController.text),
      weight: double.parse(_weightController.text),
      chronicConditions: _parseList(_chronicConditionsController.text),
      pastSurgeries: _parseList(_pastSurgeriesController.text),
      currentMedications: _parseList(_currentMedicationsController.text),
      drugAllergies: _parseList(_drugAllergiesController.text),
      foodAllergies: _parseList(_foodAllergiesController.text),
      emergencyContacts: widget.profile?.emergencyContacts ?? [],
      medicalDocuments: widget.profile?.medicalDocuments ?? [],
    );

    if (widget.profile == null) {
      await profileProvider.createProfile(newProfile);
    } else {
      await profileProvider.updateProfile(newProfile);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.profile == null
                ? 'Profile created successfully!'
                : 'Profile updated successfully!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile == null ? 'Create Profile' : 'Edit Profile'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information Section
              _buildSectionTitle('Personal Information'),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _nameController,
                label: 'Full Name',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _ageController,
                      label: AppStrings.age,
                      prefixIcon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final age = int.tryParse(value);
                        if (age == null || age < 1 || age > 150) {
                          return 'Invalid age';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown<Gender>(
                      label: AppStrings.gender,
                      value: _selectedGender,
                      items: Gender.values,
                      getLabel: (g) => g.name[0].toUpperCase() + g.name.substring(1),
                      onChanged: (value) {
                        setState(() => _selectedGender = value!);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildDropdown<BloodGroup>(
                label: AppStrings.bloodGroup,
                value: _selectedBloodGroup,
                items: BloodGroup.values,
                getLabel: (bg) => bg.displayName,
                onChanged: (value) {
                  setState(() => _selectedBloodGroup = value!);
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _heightController,
                      label: AppStrings.height,
                      prefixIcon: Icons.height,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final height = double.tryParse(value);
                        if (height == null || height < 50 || height > 250) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _weightController,
                      label: AppStrings.weight,
                      prefixIcon: Icons.monitor_weight_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final weight = double.tryParse(value);
                        if (weight == null || weight < 20 || weight > 300) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Medical History Section
              _buildSectionTitle('Medical History'),
              const SizedBox(height: 8),
              Text(
                'Separate multiple entries with commas',
                style: TextStyle(fontSize: 12, color: AppColors.grey500),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _chronicConditionsController,
                label: AppStrings.chronicConditions,
                hint: 'e.g., Diabetes, Hypertension',
                prefixIcon: Icons.health_and_safety_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _pastSurgeriesController,
                label: AppStrings.pastSurgeries,
                hint: 'e.g., Appendectomy (2020)',
                prefixIcon: Icons.local_hospital_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _currentMedicationsController,
                label: AppStrings.currentMedications,
                hint: 'e.g., Metformin 500mg',
                prefixIcon: Icons.medication_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Allergies Section
              _buildSectionTitle('Allergies'),
              const SizedBox(height: 8),
              Text(
                'Separate multiple entries with commas',
                style: TextStyle(fontSize: 12, color: AppColors.grey500),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _drugAllergiesController,
                label: AppStrings.drugAllergies,
                hint: 'e.g., Penicillin, Sulfa',
                prefixIcon: Icons.warning_amber_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _foodAllergiesController,
                label: AppStrings.foodAllergies,
                hint: 'e.g., Peanuts, Shellfish',
                prefixIcon: Icons.no_food_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Save Button
              GradientButton(
                text: widget.profile == null ? 'Create Profile' : 'Save Changes',
                onPressed: _saveProfile,
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) getLabel,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.arrow_drop_down_circle_outlined, color: AppColors.primaryOrange),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(getLabel(item)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
