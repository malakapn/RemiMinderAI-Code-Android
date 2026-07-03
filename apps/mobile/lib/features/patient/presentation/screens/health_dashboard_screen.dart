import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/utils/locale_format.dart';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  String _selectedTimeRange = '7d'; // 7d, 30d, 90d

  // Mock health data
  final List<Map<String, dynamic>> _bloodPressureData = [
    {'date': '2024-12-10', 'systolic': 128, 'diastolic': 82},
    {'date': '2024-12-11', 'systolic': 125, 'diastolic': 80},
    {'date': '2024-12-12', 'systolic': 130, 'diastolic': 85},
    {'date': '2024-12-13', 'systolic': 127, 'diastolic': 81},
    {'date': '2024-12-14', 'systolic': 124, 'diastolic': 79},
    {'date': '2024-12-15', 'systolic': 126, 'diastolic': 82},
    {'date': '2024-12-16', 'systolic': 129, 'diastolic': 83},
  ];

  final List<Map<String, dynamic>> _weightData = [
    {'date': '2024-12-10', 'weight': 165.2},
    {'date': '2024-12-11', 'weight': 164.8},
    {'date': '2024-12-12', 'weight': 165.0},
    {'date': '2024-12-13', 'weight': 164.5},
    {'date': '2024-12-14', 'weight': 164.2},
    {'date': '2024-12-15', 'weight': 164.0},
    {'date': '2024-12-16', 'weight': 163.8},
  ];

  final List<Map<String, dynamic>> _medicationAdherenceData = [
    {'date': '2024-12-10', 'adherence': 1.0},
    {'date': '2024-12-11', 'adherence': 1.0},
    {'date': '2024-12-12', 'adherence': 0.67},
    {'date': '2024-12-13', 'adherence': 1.0},
    {'date': '2024-12-14', 'adherence': 1.0},
    {'date': '2024-12-15', 'adherence': 0.33},
    {'date': '2024-12-16', 'adherence': 1.0},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => context.go('/patient/home'),
        ),
        title: const Text(
          'Health Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedTimeRange = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: '7d', child: Text('Last 7 days')),
              PopupMenuItem(value: '30d', child: Text('Last 30 days')),
              PopupMenuItem(value: '90d', child: Text('Last 90 days')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _selectedTimeRange.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Key Metrics Overview
              _buildKeyMetrics(),

              const SizedBox(height: 32),

              // Blood Pressure Chart
              _buildMetricChart(
                'Blood Pressure',
                Icons.favorite,
                Colors.red,
                _buildBloodPressureChart(),
              ),

              const SizedBox(height: 32),

              // Weight Trend Chart
              _buildMetricChart(
                'Weight Trend',
                Icons.monitor_weight,
                Colors.blue,
                _buildWeightChart(),
              ),

              const SizedBox(height: 32),

              // Medication Adherence
              _buildMetricChart(
                'Medication Adherence',
                Icons.medication,
                Colors.green,
                _buildAdherenceChart(),
              ),

              const SizedBox(height: 32),

              // Health Insights
              _buildHealthInsights(),

              const SizedBox(height: 32),

              // Recent Measurements
              _buildRecentMeasurements(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyMetrics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildKeyMetricItem(
                  'Blood Pressure',
                  '126/81',
                  'mmHg',
                  Icons.favorite,
                  Colors.red,
                  '+2 pts this week',
                  true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKeyMetricItem(
                  'Weight',
                  '163.8',
                  'lbs',
                  Icons.monitor_weight,
                  Colors.blue,
                  '-1.4 lbs this week',
                  true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildKeyMetricItem(
                  'Med Adherence',
                  '86%',
                  'this week',
                  Icons.check_circle,
                  Colors.green,
                  'Good progress',
                  false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKeyMetricItem(
                  'Heart Rate',
                  '72',
                  'bpm',
                  Icons.monitor_heart,
                  Colors.purple,
                  'Resting average',
                  false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetricItem(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
    String trend,
    bool showTrend,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
            ),
          ),
          if (showTrend) ...[
            const SizedBox(height: 4),
            Text(
              trend,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricChart(String title, IconData icon, Color color, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: chart,
          ),
        ],
      ),
    );
  }

  Widget _buildBloodPressureChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  LocaleFormat.number(context, value.round()),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _bloodPressureData.length) {
                  final date = _bloodPressureData[index]['date'] as String;
                  final parsed = DateTime.tryParse(date);
                  return Text(
                    parsed != null
                        ? LocaleFormat.number(context, parsed.day)
                        : '',
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Systolic line
          LineChartBarData(
            spots: _bloodPressureData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value['systolic'].toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
          // Diastolic line
          LineChartBarData(
            spots: _bloodPressureData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value['diastolic'].toDouble());
            }).toList(),
            isCurved: true,
            color: Colors.red.withOpacity(0.6),
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  LocaleFormat.number(context, value.round()),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _weightData.length) {
                  final date = _weightData[index]['date'] as String;
                  final parsed = DateTime.tryParse(date);
                  return Text(
                    parsed != null
                        ? LocaleFormat.number(context, parsed.day)
                        : '',
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _weightData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value['weight']);
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildAdherenceChart() {
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  LocaleFormat.percent(context, value * 100),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _medicationAdherenceData.length) {
                  final date =
                      _medicationAdherenceData[index]['date'] as String;
                  final parsed = DateTime.tryParse(date);
                  return Text(
                    parsed != null
                        ? LocaleFormat.number(context, parsed.day)
                        : '',
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _medicationAdherenceData.asMap().entries.map((entry) {
          final adherence = entry.value['adherence'] as double;
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: adherence,
                color: adherence >= 0.8 ? Colors.green : Colors.orange,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHealthInsights() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Health Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            'Blood Pressure Trend',
            'Your systolic pressure has been stable with a slight downward trend. Keep up the good work!',
            Icons.trending_down,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            'Weight Management',
            'Consistent weight loss of 1.4 lbs this week. You\'re on track for your goal!',
            Icons.trending_down,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            'Medication Adherence',
            '86% adherence this week. Consider setting medication reminders to reach 100%.',
            Icons.warning,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            'Next Checkup',
            'Your next cardiology appointment is due in 3 months. Schedule it soon.',
            Icons.calendar_today,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.secondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMeasurements() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Measurements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildMeasurementItem(
            'Blood Pressure',
            '126/81 mmHg',
            'Today, 8:30 AM',
            Icons.favorite,
            Colors.red,
          ),
          const Divider(height: 16),
          _buildMeasurementItem(
            'Weight',
            '163.8 lbs',
            'Today, 7:45 AM',
            Icons.monitor_weight,
            Colors.blue,
          ),
          const Divider(height: 16),
          _buildMeasurementItem(
            'Heart Rate',
            '72 bpm',
            'Yesterday, 8:15 AM',
            Icons.monitor_heart,
            Colors.purple,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMeasurementItem(String type, String value, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
