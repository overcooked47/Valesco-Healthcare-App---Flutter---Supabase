import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/document_provider.dart';
import '../../widgets/common_widgets.dart';

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedFile;
  String? _selectedDocumentType;
  final TextEditingController _notesController = TextEditingController();

  final List<String> documentTypes = [
    'Prescription',
    'Test Report',
    'Medical Scan',
    'Lab Result',
    'Diagnosis Report',
    'Surgery Report',
    'Vaccination Record',
    'Other',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickMedia(
        requestFullMetadata: true,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e')),
      );
    }
  }

  Future<void> _uploadDocument() async {
    if (_selectedFile == null || _selectedDocumentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file and document type')),
      );
      return;
    }

    final provider = context.read<DocumentProvider>();
    final fileName = _selectedFile!.path.split('/').last;

    final success = await provider.uploadDocument(
      file: _selectedFile!,
      fileName: fileName,
      documentType: _selectedDocumentType!,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document uploaded successfully')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(provider.uploadState.errorMessage ?? 'Upload failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Document'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
    
            const Text(
              'Select Document',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _selectedFile != null
                ? _buildSelectedFileCard()
                : _buildFilePickerButtons(),
            const SizedBox(height: 24),

      
            const Text(
              'Document Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.grey300),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedDocumentType,
                hint: const Text('Select document type'),
                underline: const SizedBox.shrink(),
                items: documentTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedDocumentType = value),
              ),
            ),
            const SizedBox(height: 24),

            // Notes
            const Text(
              'Notes (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Add notes about this document...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 24),

            // Upload Progress (if uploading)
            Consumer<DocumentProvider>(
              builder: (context, provider, _) {
                if (provider.uploadState.status == 'uploading') {
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: provider.uploadState.uploadProgress,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(provider.uploadState.uploadProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.grey600),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Upload Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _uploadDocument,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryViolet,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Consumer<DocumentProvider>(
                  builder: (context, provider, _) {
                    return Text(
                      provider.uploadState.status == 'uploading'
                          ? 'Uploading...'
                          : 'Upload Document',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePickerButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _pickFile(ImageSource.gallery),
            icon: const Icon(Icons.image),
            label: const Text('Gallery'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _pickFile(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedFileCard() {
    final fileName = _selectedFile!.path.split('/').last;
    final fileSize = _selectedFile!.lengthSync() / 1024 / 1024;

    return CustomCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                color: AppColors.primaryViolet,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${fileSize.toStringAsFixed(2)} MB',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.grey600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedFile = null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
