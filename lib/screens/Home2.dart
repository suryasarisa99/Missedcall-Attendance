import 'package:attendance/services/attendance.dart';
import 'package:attendance/services/contact_manager.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  final ContactManager _contactManager = ContactManager();
  bool _isLoading = false;
  AttendanceResult? _attendanceResult;
  AttendanceStats? _attendanceStats;

  // Separate controllers for header and content
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _contentScrollController = ScrollController();

  // Tab controller for switching between table and stats
  late TabController _tabController;

  // Date selection
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  int? _selectedMonth;
  int? _selectedYear;
  String _selectionType =
      'current_month'; // current_month, specific_month, range

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkPermissions();
    _setupScrollSync();
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    _contentScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Setup bidirectional scroll synchronization
  void _setupScrollSync() {
    _headerScrollController.addListener(() {
      if (_contentScrollController.hasClients &&
          _headerScrollController.offset != _contentScrollController.offset) {
        _contentScrollController.jumpTo(_headerScrollController.offset);
      }
    });

    _contentScrollController.addListener(() {
      if (_headerScrollController.hasClients &&
          _contentScrollController.offset != _headerScrollController.offset) {
        _headerScrollController.jumpTo(_contentScrollController.offset);
      }
    });
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.phone.status;
    if (!status.isGranted) {
      await _requestPermission();
    }
    _loadCurrentMonthAttendance();
  }

  Future<void> _requestPermission() async {
    await Permission.phone.request();
  }

  Future<void> _loadCurrentMonthAttendance() async {
    setState(() {
      _isLoading = true;
      _selectionType = 'current_month';
    });

    final status = await Permission.phone.status;
    if (!status.isGranted) {
      await _requestPermission();
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final result = await AttendanceManager.getCurrentMonthAttendance();
      final stats = await AttendanceManager.getAttendanceStats(
        DateTime.now().copyWith(day: 1),
        DateTime.now(),
      );

      setState(() {
        _attendanceResult = result;
        _attendanceStats = stats;
      });

      Fluttertoast.showToast(
        msg: "Attendance loaded successfully!",
        toastLength: Toast.LENGTH_SHORT,
      );
    } catch (e) {
      debugPrint('Error loading attendance: $e');
      Fluttertoast.showToast(
        msg: "Error loading attendance: $e",
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSpecificMonthAttendance(int month, int year) async {
    setState(() {
      _isLoading = true;
      _selectionType = 'specific_month';
      _selectedMonth = month;
      _selectedYear = year;
    });

    try {
      final result = await AttendanceManager.getAttendanceOfMonth(month, year);
      final stats = await AttendanceManager.getAttendanceStats(
        DateTime(year, month, 1),
        DateTime(year, month + 1, 0),
      );

      setState(() {
        _attendanceResult = result;
        _attendanceStats = stats;
      });

      Fluttertoast.showToast(
        msg:
            "Attendance loaded for ${DateFormat('MMMM yyyy').format(DateTime(year, month))}",
        toastLength: Toast.LENGTH_SHORT,
      );
    } catch (e) {
      debugPrint('Error loading specific month attendance: $e');
      Fluttertoast.showToast(
        msg: "Error loading attendance: $e",
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRangeAttendance(
    DateTime startDate,
    DateTime endDate,
  ) async {
    setState(() {
      _isLoading = true;
      _selectionType = 'range';
      _selectedStartDate = startDate;
      _selectedEndDate = endDate;
    });

    try {
      final result = await AttendanceManager.getAttendanceInRange(
        startDate,
        endDate,
      );
      final stats = await AttendanceManager.getAttendanceStats(
        startDate,
        endDate,
      );

      setState(() {
        _attendanceResult = result;
        _attendanceStats = stats;
      });

      Fluttertoast.showToast(
        msg: "Attendance loaded for selected range",
        toastLength: Toast.LENGTH_SHORT,
      );
    } catch (e) {
      debugPrint('Error loading range attendance: $e');
      Fluttertoast.showToast(
        msg: "Error loading attendance: $e",
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMonthPicker() {
    final now = DateTime.now();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Month'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: YearPicker(
            firstDate: DateTime(2020),
            lastDate: now,
            selectedDate: DateTime(
              _selectedYear ?? now.year,
              _selectedMonth ?? now.month,
            ),
            onChanged: (date) {
              Navigator.pop(context);
              _showMonthPickerForYear(date.year);
            },
          ),
        ),
      ),
    );
  }

  void _showMonthPickerForYear(int year) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Month - $year'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: ListView.builder(
            itemCount: 12,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(months[index]),
                onTap: () {
                  Navigator.pop(context);
                  _loadSpecificMonthAttendance(index + 1, year);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedStartDate != null && _selectedEndDate != null
          ? DateTimeRange(start: _selectedStartDate!, end: _selectedEndDate!)
          : null,
    );

    if (picked != null) {
      _loadRangeAttendance(picked.start, picked.end);
    }
  }

  String _getAppBarTitle() {
    switch (_selectionType) {
      case 'current_month':
        return 'Current Month';
      case 'specific_month':
        return DateFormat(
          'MMMM yyyy',
        ).format(DateTime(_selectedYear!, _selectedMonth!));
      case 'range':
        return '${DateFormat('MMM d').format(_selectedStartDate!)} - ${DateFormat('MMM d').format(_selectedEndDate!)}';
      default:
        return 'Attendance Tracker';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_attendanceResult == null || _isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Attendance Tracker'),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _isLoading ? null : _loadCurrentMonthAttendance,
            ),
            PopupMenuButton<String>(
              enabled: !_isLoading,
              onSelected: (value) {
                switch (value) {
                  case 'current':
                    _loadCurrentMonthAttendance();
                    break;
                  case 'month':
                    _showMonthPicker();
                    break;
                  case 'range':
                    _showRangePicker();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'current',
                  child: Row(
                    children: [
                      Icon(Icons.today),
                      SizedBox(width: 8),
                      Text('Current Month'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'month',
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month),
                      SizedBox(width: 8),
                      Text('Pick Month'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'range',
                  child: Row(
                    children: [
                      Icon(Icons.date_range),
                      SizedBox(width: 8),
                      Text('Pick Range'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Center(
          child: _isLoading
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading attendance data...'),
                  ],
                )
              : const Text(
                  'Select a date range to view attendance.',
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              switch (_selectionType) {
                case 'current_month':
                  _loadCurrentMonthAttendance();
                  break;
                case 'specific_month':
                  _loadSpecificMonthAttendance(_selectedMonth!, _selectedYear!);
                  break;
                case 'range':
                  _loadRangeAttendance(_selectedStartDate!, _selectedEndDate!);
                  break;
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'current':
                  _loadCurrentMonthAttendance();
                  break;
                case 'month':
                  _showMonthPicker();
                  break;
                case 'range':
                  _showRangePicker();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'current',
                child: Row(
                  children: [
                    Icon(Icons.today),
                    SizedBox(width: 8),
                    Text('Current Month'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'month',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month),
                    SizedBox(width: 8),
                    Text('Pick Month'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'range',
                child: Row(
                  children: [
                    Icon(Icons.date_range),
                    SizedBox(width: 8),
                    Text('Pick Range'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.table_chart), text: 'Table'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTableView(), _buildStatisticsView()],
      ),
    );
  }

  Widget _buildTableView() {
    final dates = _attendanceResult!.dates;
    const double nameColumnWidth = 120;
    const double dateColumnWidth = 80;
    final double totalWidth =
        nameColumnWidth + (dates.length * dateColumnWidth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fixed Header
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
            controller: _headerScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              child: Row(
                children: [
                  // Name column header
                  Container(
                    width: nameColumnWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Name',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // Date column headers
                  ...dates.map(
                    (date) => Container(
                      width: dateColumnWidth,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      child: Text(
                        date,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            controller: _contentScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              child: ListView.builder(
                itemCount: _attendanceResult!.attendance.length + 1,
                itemBuilder: (context, index) {
                  if (index == _attendanceResult!.attendance.length) {
                    return _buildTotalRow(dates.length, dateColumnWidth);
                  }

                  final entry = _attendanceResult!.attendance.entries.elementAt(
                    index,
                  );
                  final contactName = _contactManager.contacts[index].name;

                  return Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Container(
                      // color: Colors.red,
                      child: Row(
                        children: [
                          // Name column
                          _buildNameCell(contactName, nameColumnWidth),
                          // Attendance columns
                          ...entry.value.asMap().entries.map((attendanceEntry) {
                            final present = attendanceEntry.value;
                            return _buildAttendanceCell(
                              present,
                              dateColumnWidth,
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsView() {
    if (_attendanceStats == null) {
      return const Center(child: Text('No statistics available'));
    }

    final stats = _attendanceStats!;
    final result = _attendanceResult!;

    return SingleChildScrollView(
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(height: 200, child: _buildDailyChart()),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...result.attendance.entries.map((entry) {
                    final phoneNumber = entry.key;
                    final attendance = entry.value;
                    final contactIndex = result.attendance.keys
                        .toList()
                        .indexOf(phoneNumber);
                    final contactName =
                        _contactManager.contacts[contactIndex].name;
                    final presentDays = attendance.where((p) => p).length;
                    final percentage = (presentDays / attendance.length * 100);

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

  // Widget _buildDailyChart() {
  //   if (_attendanceStats == null) return const SizedBox();

  //   final maxAttendance = _attendanceStats!.dailyTotals.isNotEmpty
  //       ? _attendanceStats!.dailyTotals.reduce((a, b) => a > b ? a : b)
  //       : 1;

  //   return Row(
  //     children: _attendanceStats!.dailyTotals.asMap().entries.map((entry) {
  //       final index = entry.key;
  //       final count = entry.value;
  //       final height = (count / maxAttendance) * 160;

  //       return Expanded(
  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 2),
  //           child: Column(
  //             mainAxisAlignment: MainAxisAlignment.end,
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Text('$count', style: const TextStyle(fontSize: 10)),
  //               Container(
  //                 height: height,
  //                 decoration: BoxDecoration(
  //                   color: Colors.blue.withOpacity(0.7),
  //                   borderRadius: BorderRadius.circular(2),
  //                 ),
  //               ),
  //               const SizedBox(height: 4),
  //               Text(
  //                 _attendanceResult!.dates[index].split(' ')[1],
  //                 style: const TextStyle(fontSize: 8),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     }).toList(),
  //   );
  // }

  Widget _buildDailyChart2() {
    if (_attendanceStats == null) return const SizedBox();

    final dailyTotals = _attendanceStats!.dailyTotals;
    if (dailyTotals.isEmpty) return const SizedBox();

    final maxAttendance = dailyTotals.reduce((a, b) => a > b ? a : b);
    debugPrint("max attendance: $maxAttendance");
    final safeMax = maxAttendance > 0 ? maxAttendance : 1;

    return SizedBox(
      height: 180, // give fixed height to chart
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, // align bars to bottom
        children: dailyTotals.asMap().entries.map((entry) {
          final index = entry.key;
          final count = entry.value;
          final height = (count / safeMax) * 160;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('$count', style: const TextStyle(fontSize: 10)),
                  Container(
                    height: height.isFinite ? height : 0, // prevent NaN
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _attendanceResult!.dates[index].split(' ')[1],
                    style: const TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDailyChart() {
    if (_attendanceStats == null) return const SizedBox();

    final dailyTotals = _attendanceStats!.dailyTotals;
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
                  final date = _attendanceResult!.dates[index].split(' ')[1];
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
            show: true,
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
                  if (index < 0 || index >= _attendanceResult!.dates.length) {
                    return const SizedBox();
                  }
                  final label = _attendanceResult!.dates[index].split(' ')[1];
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
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
              ),
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.3),
                    Colors.purple.withOpacity(0.1),
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

  Widget _buildNameCell(String name, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.only(left: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        name,
        style: const TextStyle(fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildAttendanceCell(bool present, double width) {
    return Container(
      width: width,
      alignment: Alignment.center,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: present
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: present ? Colors.green : Colors.red,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            present ? "P" : "A",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: present ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalRow(int totalDays, double dateColumnWidth) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildNameCell("Total", 120),
          // count of students present for each day
          ...List.generate(totalDays, (index) {
            final count = _attendanceResult!.getPresentCountForDay(index);
            return Container(
              width: dateColumnWidth,
              alignment: Alignment.center,
              child: Text(
                count.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }),
        ],
      ),
    );
  }
}
