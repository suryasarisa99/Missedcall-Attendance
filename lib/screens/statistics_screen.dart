import 'package:attendance/services/attendance.dart';
import 'package:attendance/services/contact_manager.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class Statisticsscreen extends StatelessWidget {
  final AttendanceResult result;
  final AttendanceStats stats;
  final ContactManager contactManager;
  final String title;

  const Statisticsscreen({
    super.key,
    required this.stats,
    required this.result,
    required this.contactManager,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text("Statistics - $title")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Students',
                      '${stats.totalStudents}',
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total Days',
                      '${stats.totalDays}',
                      Icons.calendar_today,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Avg Attendance',
                      '${stats.averageAttendancePerDay.toStringAsFixed(1)}',
                      Icons.trending_up,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Overall %',
                      '${result.getOverallAttendancePercentage().toStringAsFixed(1)}%',
                      Icons.percent,
                      Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Daily Attendance Chart
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Attendance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(height: 200, child: _buildDailyChart(cs)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Student Performance List
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Student Performance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...result.attendance.entries.map((entry) {
                        final phoneNumber = entry.key;
                        final attendance = entry.value;
                        final contactIndex = result.attendance.keys
                            .toList()
                            .indexOf(phoneNumber);
                        final contactName =
                            contactManager.contacts[contactIndex].name;
                        final presentDays = attendance
                            .where((p) => p != null)
                            .length;
                        final percentage =
                            (presentDays / attendance.length * 100);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: percentage >= 75
                                ? Colors.green
                                : percentage >= 50
                                ? Colors.orange
                                : Colors.red,
                            child: Text(
                              '${percentage.toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(contactName),
                          subtitle: Text(
                            '$presentDays / ${attendance.length} days',
                          ),
                          trailing: Icon(
                            percentage >= 75
                                ? Icons.trending_up
                                : percentage >= 50
                                ? Icons.trending_flat
                                : Icons.trending_down,
                            color: percentage >= 75
                                ? Colors.green
                                : percentage >= 50
                                ? Colors.orange
                                : Colors.red,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChart(ColorScheme cs) {
    final dailyTotals = stats.dailyTotals;
    if (dailyTotals.isEmpty) return const SizedBox();

    final maxAttendance = dailyTotals.reduce((a, b) => a > b ? a : b);
    final safeMax = maxAttendance > 0 ? maxAttendance : 1;
    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              // tooltipBgColor: Colors.black87,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  final date = result.dates[index].split(' ')[1];
                  return LineTooltipItem(
                    '$date\n${spot.y.toInt()} students',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            // show: false,
            horizontalInterval: (safeMax / 5).ceilToDouble(),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (safeMax / 5).ceilToDouble(),
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= result.dates.length) {
                    return const SizedBox();
                  }
                  final label = result.dates[index].split(' ')[1];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(label, style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: safeMax.toDouble() + 2,
          lineBarsData: [
            LineChartBarData(
              spots: dailyTotals.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.toDouble());
              }).toList(),
              isCurved: true,
              curveSmoothness: 0.4,
              gradient: LinearGradient(
                colors: [
                  // Colors.blue.shade400,
                  //  Colors.purple.shade400
                  cs.primary,
                  cs.tertiary,
                ],
              ),
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    // Colors.blue.withOpacity(0.3),
                    // Colors.purple.withOpacity(0.1),
                    cs.primary.withValues(alpha: 0.3),
                    cs.tertiary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
        // swapAnimationDuration: const Duration(milliseconds: 800),
        // swapAnimationCurve: Curves.easeOutCubic,
      ),
    );
  }
}
