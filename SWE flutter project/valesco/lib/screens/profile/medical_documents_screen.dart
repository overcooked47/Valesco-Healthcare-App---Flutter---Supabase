import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/health_profile_provider.dart';
import '../../models/health_profile_model.dart';
import '../../widgets/common_widgets.dart';

class MedicalDocumentsScreen extends StatelessWidget {
  const MedicalDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Documents'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDocumentDialog(context),
        backgroundColor: AppColors.primaryViolet,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
      body: Consumer<HealthProfileProvider>(
        builder: (context, provider, child) {
          final documents = provider.healthProfile?.medicalDocuments ?? [];

          if (documents.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.folder_off_outlined,
              title: 'No Documents',
              subtitle: 'Upload medical documents like prescriptions, test reports, and scans',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              return _buildDocumentCard(context, document);
            },
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, MedicalDocument document) {
    IconData iconData;
    Color iconColor;

    switch (document.type.toLowerCase()) {
      case 'prescription':
        iconData = Icons.receipt_long;
        iconColor = AppColors.primaryOrange;
        break;
      case 'test_report':
        iconData = Icons.science;
        iconColor = AppColors.primaryViolet;
        break;
      case 'scan':
        iconData = Icons.image;
        iconColor = AppColors.info;
        break;
      default:
        iconData = Icons.description;
        iconColor = AppColors.grey600;
    }

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  document.type.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Uploaded on ${_formatDate(document.uploadedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
                if (document.notes != null && document.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    document.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'view') {
                _viewDocument(context, document);
              } else if (value == 'delete') {
                _confirmDeleteDocument(context, document);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 20),
                    SizedBox(width: 8),
                    Text('View'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _viewDocument(BuildContext context, MedicalDocument document) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(document.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: AppColors.grey400,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Document Preview',
                        style: TextStyle(color: AppColors.grey500),
                      ),
                      Text(
                        '(Mock - No actual file)',
                        style: TextStyle(
                          color: AppColors.grey400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Type: ${document.type.replaceAll('_', ' ')}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Uploaded: ${_formatDate(document.uploadedAt)}',
                style: const TextStyle(fontSize: 14),
              ),
              if (document.notes != null && document.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Notes: ${document.notes}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAddDocumentDialog(BuildContext context) {
    final nameController = TextEditingController();
    final notesController = TextEditingController();
    String selectedType = 'prescription';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Upload Document'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mock file picker area
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('File picker would open here'),
                            backgroundColor: AppColors.info,
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.grey300,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 40,
                              color: AppColors.primaryViolet,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to select file',
                              style: TextStyle(
                                color: AppColors.primaryViolet,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'PDF, Image, or Document',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.grey500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: nameController,
                      label: 'Document Name',
                      hint: 'e.g., Blood Test Report',
                      prefixIcon: Icons.description_outlined,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Document Type',
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'prescription',
                          child: Text('Prescription'),
                        ),
                        DropdownMenuItem(
                          value: 'test_report',
                          child: Text('Test Report'),
                        ),
                        DropdownMenuItem(
                          value: 'scan',
                          child: Text('Scan/Image'),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => selectedType = value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: notesController,
                      label: 'Notes (Optional)',
                      hint: 'Add any notes about this document',
                      prefixIcon: Icons.note_outlined,
                      maxLines: 2,
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
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a document name'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    final document = MedicalDocument(
                      name: nameController.text.trim(),
                      type: selectedType,
                      filePath: 'mock_path/${DateTime.now().millisecondsSinceEpoch}',
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                    );

                    await context.read<HealthProfileProvider>().addMedicalDocument(document);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteDocument(BuildContext context, MedicalDocument document) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Document'),
          content: Text('Are you sure you want to delete "${document.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await context.read<HealthProfileProvider>().removeMedicalDocument(document.id);
                if (context.mounted) Navigator.pop(context);
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
