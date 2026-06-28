import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/health_profile_model.dart';
import '../../providers/document_provider.dart';

class DocumentViewerScreen extends StatefulWidget {
  final MedicalDocument document;

  const DocumentViewerScreen({
    super.key,
    required this.document,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  Future<void> _downloadDocument(BuildContext context) async {
    final provider = context.read<DocumentProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading document...')),
    );

    final savedPath =
        await provider.downloadDocumentToDevice(widget.document.id);
    if (!context.mounted) return;

    if (savedPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Download failed')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Document saved to: $savedPath')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uploadDate =
        '${widget.document.uploadedAt.day}/${widget.document.uploadedAt.month}/${widget.document.uploadedAt.year}';
    final fileSizeMB = (widget.document.fileSize / 1024 / 1024).toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppColors.primaryViolet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.description,
                  size: 80,
                  color: AppColors.primaryViolet,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Document Info
            _buildInfoSection(
              title: 'Document Name',
              value: widget.document.name,
            ),
            const SizedBox(height: 16),
            _buildInfoSection(
              title: 'Document Type',
              value: widget.document.type,
            ),
            const SizedBox(height: 16),
            _buildInfoSection(
              title: 'File Format',
              value: widget.document.fileFormat.toUpperCase(),
            ),
            const SizedBox(height: 16),
            _buildInfoSection(
              title: 'File Size',
              value: '$fileSizeMB MB',
            ),
            const SizedBox(height: 16),
            _buildInfoSection(
              title: 'Upload Date',
              value: uploadDate,
            ),

            if (widget.document.notes != null && widget.document.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Notes',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryViolet.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryViolet.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  widget.document.notes!,
                  style: const TextStyle(fontSize: 12, height: 1.5),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Shareable Link Info (if exists)
            if (widget.document.shareableLink != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Shareable Link Available',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (widget.document.linkExpiry != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Expires: ${widget.document.linkExpiry!.day}/${widget.document.linkExpiry!.month}/${widget.document.linkExpiry!.year}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryViolet,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _downloadDocument(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
