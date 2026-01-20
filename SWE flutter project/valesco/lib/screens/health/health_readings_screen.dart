import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/health_reading_provider.dart';
import '../../models/health_reading_model.dart';
import '../../widgets/common_widgets.dart';
import 'add_reading_screen.dart';

class HealthReadingsScreen extends StatefulWidget {
  const HealthReadingsScreen({super.key});

  @override
  State<HealthReadingsScreen> createState() => _HealthReadingsScreenState();
}

class _HealthReadingsScreenState extends State<HealthReadingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  HealthReadingType _selectedType = HealthReadingType.bloodGlucose;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedType = HealthReadingType.values[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.healthReadings),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Blood Sugar'),
            Tab(text: 'Blood Pressure'),
            Tab(text: 'Heart Rate'),
            Tab(text: 'Weight'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddReadingScreen(initialType: _selectedType),
            ),
          );
        },
        backgroundColor: AppColors.primaryOrange,
        icon: const Icon(Icons.add),
        label: const Text('Add Reading'),
      ),
      body: Consumer<HealthReadingProvider>(
        builder: (context, provider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildReadingsList(provider, HealthReadingType.bloodGlucose),
              _buildReadingsList(provider, HealthReadingType.bloodPressure),
              _buildReadingsList(provider, HealthReadingType.heartRate),
              _buildReadingsList(provider, HealthReadingType.weight),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReadingsList(HealthReadingProvider provider, HealthReadingType type) {
    final readings = provider.getReadingsByType(type);
    final averages = provider.getAveragesForType(type);

    if (readings.isEmpty) {
      return EmptyStateWidget(
        icon: _getIconForType(type),
        title: 'No ${type.displayName} Readings',
        subtitle: 'Start tracking your ${type.displayName.toLowerCase()} to see trends',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          _buildSummaryCard(type, averages, readings.first),
          const SizedBox(height: 24),

          // Chart Placeholder
          _buildChartPlaceholder(readings),
          const SizedBox(height: 24),

          // Recent Readings
          const SectionHeader(title: 'Recent Readings'),
          const SizedBox(height: 12),
          ...readings.take(10).map((reading) => _buildReadingCard(reading, provider)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    HealthReadingType type,
    Map<String, double> averages,
    HealthReadingModel latest,
  ) {
    return CustomCard(
      gradient: AppColors.primaryGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getIconForType(type), color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                type.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                latest.displayValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  latest.unit,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(latest.status).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              latest.status.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAverageItem('7 Day Avg', averages['7_day']?.toStringAsFixed(1) ?? '-'),
              _buildAverageItem('30 Day Avg', averages['30_day']?.toStringAsFixed(1) ?? '-'),
              _buildAverageItem('Min', averages['min']?.toStringAsFixed(1) ?? '-'),
              _buildAverageItem('Max', averages['max']?.toStringAsFixed(1) ?? '-'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAverageItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildChartPlaceholder(List<HealthReadingModel> readings) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trend',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              DropdownButton<String>(
                value: '7 days',
                items: ['7 days', '30 days', '90 days']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: SimpleChartPainter(readings),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingCard(HealthReadingModel reading, HealthReadingProvider provider) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: _getStatusColor(reading.status),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIconForType(reading.type),
              color: AppColors.primaryOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reading.displayValue,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      reading.unit,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(reading.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(
            text: reading.status.displayName,
            color: _getStatusColor(reading.status),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                provider.deleteReading(reading.id);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(HealthReadingType type) {
    switch (type) {
      case HealthReadingType.bloodGlucose:
        return Icons.bloodtype;
      case HealthReadingType.bloodPressure:
        return Icons.favorite;
      case HealthReadingType.heartRate:
        return Icons.monitor_heart;
      case HealthReadingType.weight:
        return Icons.scale;
      default:
        return Icons.health_and_safety;
    }
  }

  Color _getStatusColor(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.normal:
        return AppColors.success;
      case ReadingStatus.elevated:
        return AppColors.warning;
      case ReadingStatus.high:
        return AppColors.error;
      case ReadingStatus.low:
        return AppColors.info;
      case ReadingStatus.critical:
        return AppColors.error;
    }
  }
}

// Simple chart painter for trend visualization
class SimpleChartPainter extends CustomPainter {
  final List<HealthReadingModel> readings;

  SimpleChartPainter(this.readings);

  @override
  void paint(Canvas canvas, Size size) {
    if (readings.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.primaryOrange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppColors.primaryOrange.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = AppColors.primaryOrange
      ..style = PaintingStyle.fill;

    final values = readings.map((r) => r.value).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < readings.length && i < 30; i++) {
      final x = size.width - (i / 30) * size.width;
      final normalizedValue = range == 0 ? 0.5 : (readings[i].value - minValue) / range;
      final y = size.height - (normalizedValue * size.height * 0.8) - (size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // Draw dots
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = AppColors.grey200
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
