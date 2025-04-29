// lib/widgets/charts/pet_drinking_pattern_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PetDrinkingPatternChart extends StatelessWidget {
  final List<dynamic> data;

  const PetDrinkingPatternChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('ยังไม่มีข้อมูลรูปแบบการดื่มน้ำ'),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxY(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = data[groupIndex];
              final hour = item['hour'] as int;
              final count = item['count'] as int;
              final formattedHour = _formatHour(hour);
              return BarTooltipItem(
                '$formattedHour: $count ครั้ง',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value.toInt() >= data.length || value.toInt() % 3 != 0) {
                  return const SizedBox();
                }
                final item = data[value.toInt()];
                final hour = item['hour'] as int;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '${hour}:00',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: _getBarGroups(context),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  double _getMaxY() {
    if (data.isEmpty) return 5;
    double maxY = 0;
    for (final item in data) {
      final count = item['count'] as int;
      if (count > maxY) {
        maxY = count.toDouble();
      }
    }
    return maxY + 1; // เพิ่มช่องว่างด้านบน
  }

  List<BarChartGroupData> _getBarGroups(BuildContext context) {
    final Color dayColor = Colors.blue;
    final Color nightColor = Colors.indigo;
    
    return List.generate(data.length, (index) {
      final item = data[index];
      final hour = item['hour'] as int;
      
      // สีต่างกันในแต่ละช่วงเวลา
      final color = (hour >= 6 && hour < 18) ? dayColor : nightColor;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (item['count'] as int).toDouble(),
            color: color,
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }
  
  String _formatHour(int hour) {
    return '$hour:00';
  }
}