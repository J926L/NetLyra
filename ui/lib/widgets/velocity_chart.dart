import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:netlyra_ui/theme/colors.dart';

/// Real-time packet velocity line chart.
class VelocityChart extends StatelessWidget {
  const VelocityChart({super.key, required this.dataPoints});

  final List<FlSpot> dataPoints;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: dataPoints.isEmpty ? 0 : dataPoints.first.x,
        maxX: dataPoints.isEmpty ? 10 : dataPoints.last.x,
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: dataPoints,
            isCurved: true,
            color: NetLyraColors.accent,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: NetLyraColors.accent.withAlpha(50),
            ),
          ),
        ],
      ),
    );
  }
}
