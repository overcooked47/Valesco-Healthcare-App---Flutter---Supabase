import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/health_profile_provider.dart';
import '../../models/health_profile_model.dart';
import '../../widgets/common_widgets.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContactDialog(context),
        backgroundColor: AppColors.primaryOrange,
        icon: const Icon(Icons.add),
        label: const Text('Add Contact'),
      ),
      body: Consumer<HealthProfileProvider>(
        builder: (context, provider, child) {
          // Use the emergencyContacts getter which works with or without a profile
          final contacts = provider.emergencyContacts;

          if (contacts.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.contact_emergency_outlined,
              title: 'No Emergency Contacts',
              subtitle:
                  'Add emergency contacts who can be notified in case of emergency',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return _buildContactCard(context, contact);
            },
          );
        },
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, EmergencyContact contact) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: contact.isPrimary
                    ? AppColors.primaryOrange.withOpacity(0.1)
                    : AppColors.primaryViolet.withOpacity(0.1),
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: contact.isPrimary
                        ? AppColors.primaryOrange
                        : AppColors.primaryViolet,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          contact.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (contact.isPrimary) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'PRIMARY',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.relationship,
                      style: TextStyle(fontSize: 13, color: AppColors.grey500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contact.phoneNumber,
                      style: TextStyle(fontSize: 14, color: AppColors.grey700),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    _showEditContactDialog(context, contact);
                  } else if (value == 'delete') {
                    _confirmDeleteContact(context, contact);
                  } else if (value == 'primary') {
                    await _setPrimaryContact(context, contact);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  if (!contact.isPrimary)
                    const PopupMenuItem(
                      value: 'primary',
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 20),
                          SizedBox(width: 8),
                          Text('Set as Primary'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: AppColors.error),
                        SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAddContactDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final relationshipController = TextEditingController();
    final phoneController = TextEditingController();
    bool isPrimary = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Emergency Contact'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      controller: nameController,
                      label: 'Name',
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: relationshipController,
                      label: 'Relationship',
                      hint: 'e.g., Spouse, Parent, Sibling',
                      prefixIcon: Icons.people_outline,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: phoneController,
                      label: 'Phone Number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: isPrimary,
                      onChanged: (value) {
                        setState(() => isPrimary = value ?? false);
                      },
                      title: const Text('Set as primary contact'),
                      subtitle: const Text(
                        'First to be contacted in emergency',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        relationshipController.text.isEmpty ||
                        phoneController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all fields'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    final contact = EmergencyContact(
                      name: nameController.text.trim(),
                      relationship: relationshipController.text.trim(),
                      phoneNumber: phoneController.text.trim(),
                      isPrimary: isPrimary,
                    );

                    await context
                        .read<HealthProfileProvider>()
                        .addEmergencyContact(contact);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditContactDialog(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    final nameController = TextEditingController(text: contact.name);
    final relationshipController = TextEditingController(
      text: contact.relationship,
    );
    final phoneController = TextEditingController(text: contact.phoneNumber);
    bool isPrimary = contact.isPrimary;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Emergency Contact'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      controller: nameController,
                      label: 'Name',
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: relationshipController,
                      label: 'Relationship',
                      prefixIcon: Icons.people_outline,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: phoneController,
                      label: 'Phone Number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: isPrimary,
                      onChanged: (value) {
                        setState(() => isPrimary = value ?? false);
                      },
                      title: const Text('Set as primary contact'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final updatedContact = contact.copyWith(
                      name: nameController.text.trim(),
                      relationship: relationshipController.text.trim(),
                      phoneNumber: phoneController.text.trim(),
                      isPrimary: isPrimary,
                    );

                    await context
                        .read<HealthProfileProvider>()
                        .updateEmergencyContact(updatedContact);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteContact(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Contact'),
          content: Text('Are you sure you want to delete ${contact.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await context.read<HealthProfileProvider>().removeEmergencyContact(
        contact.id,
      );
    }
  }

  Future<void> _setPrimaryContact(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    final provider = context.read<HealthProfileProvider>();
    final contacts = provider.healthProfile?.emergencyContacts ?? [];

    // Remove primary from all contacts
    for (final c in contacts) {
      if (c.isPrimary && c.id != contact.id) {
        await provider.updateEmergencyContact(c.copyWith(isPrimary: false));
      }
    }

    // Set this contact as primary
    await provider.updateEmergencyContact(contact.copyWith(isPrimary: true));
  }
}
