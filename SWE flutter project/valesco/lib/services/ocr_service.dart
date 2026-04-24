import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrScanResult {
  final String rawText;
  final List<String> lines;

  const OcrScanResult({
    required this.rawText,
    required this.lines,
  });

  bool get hasText => rawText.trim().isNotEmpty;
}

class OcrService {
  OcrService._();

  static final OcrService instance = OcrService._();

  final ImagePicker _picker = ImagePicker();

  Future<OcrScanResult?> scanText({required ImageSource source}) async {
    if (kIsWeb) {
      throw UnsupportedError('OCR scanning is currently supported on mobile only.');
    }

    final pickedImage = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (pickedImage == null) {
      return null;
    }

    final inputImage = InputImage.fromFilePath(pickedImage.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final lines = recognizedText.blocks
          .expand((block) => block.lines)
          .map((line) => line.text.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      return OcrScanResult(
        rawText: recognizedText.text.trim(),
        lines: lines,
      );
    } finally {
      await textRecognizer.close();
    }
  }
}