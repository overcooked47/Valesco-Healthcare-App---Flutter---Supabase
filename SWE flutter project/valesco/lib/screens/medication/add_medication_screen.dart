import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/medication_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/medication_model.dart';
import '../../widgets/common_widgets.dart';
import '../../services/medication_reminder_service.dart';
import '../../services/ocr_service.dart';

class AddMedicationScreen extends StatefulWidget {
  final MedicationModel? medication;

  const AddMedicationScreen({super.key, this.medication});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  final _totalPillsController = TextEditingController();

  MedicationFrequency _selectedFrequency = MedicationFrequency.daily;
  List<TimeOfDay> _reminderTimes = [const TimeOfDay(hour: 8, minute: 0)];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isSaving = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _nameController.text = widget.medication!.name;
      _dosageController.text = widget.medication!.dosage;
      _notesController.text = widget.medication!.notes ?? '';
      _totalPillsController.text = widget.medication!.totalPills.toString();
      _selectedFrequency = widget.medication!.frequency;
      _reminderTimes = List.from(widget.medication!.reminderTimes);
      _startDate = widget.medication!.startDate;
      _endDate = widget.medication!.endDate;
    } else {
      _totalPillsController.text = '30';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    _totalPillsController.dispose();
    super.dispose();
  }

  String _correctOcrErrors(String text) {
    return text
        .replaceAll(RegExp(r'[|1l](?=[a-z])'), 'i')
        .replaceAll(RegExp(r'(?<=[a-z])[|1l]'), 'l')
        .replaceAll('O', '0')
        .replaceAll(RegExp(r'\bMg\b'), 'mg')
        .replaceAll(RegExp(r'\bMcg\b'), 'mcg')
        .replaceAll(RegExp(r'\bMl\b'), 'ml')
        .replaceAll(RegExp(r'\bG\b'), 'g')
        .replaceAll(RegExp(r'\bIu\b'), 'iu')
        .replaceAll(RegExp(r'\bTab(?:let)?s?\b', caseSensitive: false), 'tablet')
        .replaceAll(RegExp(r'\bCap(?:sule)?s?\b', caseSensitive: false), 'capsule');
  }

  List<Map<String, dynamic>> _findAllDosages(String text) {
    final List<Map<String, dynamic>> dosages = [];

    final betterPattern = RegExp(
      r'\b(\d+(?:\.?\d+)?)\s*(?:mg|mcg|μg|g|ml|cc|iu|IU|%|units?)\b',
      caseSensitive: false,
    );

    for (final match in betterPattern.allMatches(text)) {
      final dosageText = text.substring(match.start, match.end).trim();
      if (dosageText.isNotEmpty && !dosageText.contains(RegExp(r'^\d+$'))) {
        dosages.add({
          'text': dosageText,
          'position': match.start,
        });
      }
    }

    return dosages;
  }

  List<Map<String, dynamic>> _analyzeLines(List<String> lines) {
    final List<Map<String, dynamic>> analyzed = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final corrected = _correctOcrErrors(line);
      final hasDosage = _findAllDosages(corrected).isNotEmpty;
      final wordCount = line.split(RegExp(r'\s+\b')).length;

      int score = 0;
      if (hasDosage) score += 10;
      if (wordCount <= 3 && !hasDosage) score += 8;
      if (i <= 2) score += 5;
      if (wordCount > 8) score -= 5;
      if (RegExp(r'\b(indication|active|ingredient|use|direction|warning)\b', caseSensitive: false)
          .hasMatch(line)) {
        score -= 10;
      }

      analyzed.add({
        'text': corrected,
        'original': line,
        'hasDosage': hasDosage,
        'wordCount': wordCount,
        'score': score,
        'index': i,
      });
    }

    return analyzed;
  }

  String _extractNameFromLine(String line) {
    final nameOnlyPattern = RegExp(
      r'^([^0-9]*?)(?=\d+\s*(?:mg|mcg|μg|g|ml|cc|iu|IU|%|tablet|capsule|drop))',
      caseSensitive: false,
    );

    final match = nameOnlyPattern.firstMatch(line);
    if (match != null) {
      return match.group(1)!.trim();
    }

    return line
        .replaceAll(RegExp(r'\s*(?:tablet|capsule|drop|dose|branded|generic)\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'[\-–—].*$'), '')
        .trim();
  }

  Map<String, String> _extractMedicationInfo(String text) {
    if (text.trim().isEmpty) {
      return {
        'name': 'Unknown Medicine',
        'dosage': 'Not specified',
      };
    }

    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final analyzed = _analyzeLines(lines);

    String bestMedicineName = '';
    String bestDosage = '';

    final dosageLines = analyzed.where((a) => a['hasDosage'] as bool).toList();
    if (dosageLines.isNotEmpty) {
      final dosageLine = dosageLines.first;
      final lineText = dosageLine['text'] as String;
      final dosages = _findAllDosages(lineText);

      if (dosages.isNotEmpty) {
        bestDosage = dosages.first['text'] as String;
        bestMedicineName = _extractNameFromLine(lineText);
      }
    }

    if (bestMedicineName.isEmpty && analyzed.isNotEmpty) {
      final sortedByScore = analyzed..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      bestMedicineName = _extractNameFromLine(sortedByScore.first['text'] as String);
    }

    bestMedicineName = bestMedicineName
        .replaceAll(RegExp(r'^(brand\s*name|generic\s*name|medicine|drug)\s*:?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s\-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (bestMedicineName.length < 2) {
      bestMedicineName = analyzed.firstWhere(
        (a) => (a['wordCount'] as int) <= 3,
        orElse: () => analyzed.isNotEmpty ? analyzed.first : {'text': ''},
      )['text'] as String? ?? '';
    }

    if (bestMedicineName.length > 50) {
      bestMedicineName = bestMedicineName.split(' ').take(3).join(' ');
    }

    return {
      'name': bestMedicineName.isNotEmpty ? bestMedicineName : 'Unknown Medicine',
      'dosage': bestDosage.isNotEmpty ? bestDosage : 'Not specified',
    };
  }

  void _autoFillMedicationFields(String ocrText) {
    final extracted = _extractMedicationInfo(ocrText);

    setState(() {
      _nameController.text = extracted['name']!;
      _dosageController.text = extracted['dosage']!;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fields autofilled! Please review and adjust if needed.'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}