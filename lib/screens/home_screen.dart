import 'package:attendance/screens/statistics_screen.dart';
import 'package:attendance/services/attendance.dart';
import 'package:attendance/services/contact_manager.dart';
import 'package:attendance/services/options.dart';
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
    with WidgetsBindingObserver {
  final ContactManager _contactManager = ContactManager();
  bool _isLoading = false;
  AttendanceResult? _attendanceResult;
  AttendanceStats? _attendanceStats;
  var scaffoldKey = GlobalKey<ScaffoldState>();
  // Separate controllers for header and content
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _contentScrollController = ScrollController();

  // Tab controller for switching between table and stats
  // late TabController _tabController;

  // Date selection
  DateTime? _selectedStartDate = Options.selectedStartDate;
  DateTime? _selectedEndDate = Options.selectedEndDate;
  int? _selectedMonth = Options.selectedMonth;
  int? _selectedYear = Options.selectedYear;
  String _selectionType =
      Options.selectionType; // current_month, specific_month, range

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
    _setupScrollSync();
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    _contentScrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_attendanceResult?.hasCurrentDate ?? false) {
        loadData();
      }
    } else if (state == AppLifecycleState.paused) {
      // App is in background
    }
  }

  Future<void> loadData() async {
    debugPrint("================================================");
    debugPrint("loading...");
    debugPrint("================================================");
    switch (_selectionType) {
      case 'current_month':
        await _loadCurrentMonthAttendance();
        break;
      case 'specific_month':
        await _loadSpecificMonthAttendance(_selectedMonth!, _selectedYear!);
        break;
      case 'range':
        await _loadRangeAttendance(_selectedStartDate!, _selectedEndDate!);
        break;
    }
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
    loadData();
  }

  Future<void> _requestPermission() async {
    await Permission.phone.request();
  }

  Future<void> _loadCurrentMonthAttendance() async {
    setState(() {
      _isLoading = true;
      _selectionType = 'current_month';
      Options.selectionType = _selectionType;
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
      Options.selectionType = _selectionType;
      Options.selectedMonth = month;
      Options.selectedYear = year;
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
      Options.selectionType = _selectionType;
      Options.selectedStartDate = startDate;
      Options.selectedEndDate = endDate;
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
    final selectionTitle = _getAppBarTitle();
    final appBarColor = Theme.of(
      context,
    ).colorScheme.primaryContainer.withValues(alpha: 0.3);
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: Text(selectionTitle, style: TextStyle(fontSize: 20)),
        actions: [
          IconButton(
            onPressed: _attendanceResult == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Statisticsscreen(
                          result: _attendanceResult!,
                          stats: _attendanceStats!,
                          contactManager: _contactManager,
                          title: selectionTitle,
                        ),
                      ),
                    );
                  },
            icon: Icon(Icons.analytics),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadData),
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
      ),
      body: _attendanceResult == null
          ? const Center(child: CircularProgressIndicator())
          : _buildTableView(),
    );
  }

  Widget _buildTableView() {
    final dates = _attendanceResult!.dates;
    const double nameColumnWidth = 120;
    const double dateColumnWidth = 80;
    final double totalWidth =
        nameColumnWidth + (dates.length * dateColumnWidth);
    final cs = Theme.of(context).colorScheme;
    final appBarColor = cs.primaryContainer.withValues(alpha: 0.22);
    final dividerClr = Theme.of(context).dividerColor.withValues(alpha: 0.2);
    final border = BorderSide(color: dividerClr, width: 0.5);
    final titlesClr = cs.onPrimaryContainer.withValues(alpha: 0.9);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fixed Header
        Container(
          width: double.infinity,
          height: 38,
          decoration: BoxDecoration(
            color: appBarColor,
            // color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(color: dividerClr, width: 1),
              bottom: BorderSide(color: dividerClr, width: 1),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Name',
                      style: TextStyle(
                        color: titlesClr,
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
                        style: TextStyle(
                          color: titlesClr,
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
        // Scrollable Content with RefreshIndicator as the top-level parent
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                controller: _contentScrollController,
                scrollDirection: Axis.horizontal,
                child: RefreshIndicator(
                  onRefresh: loadData,
                  backgroundColor: Colors.red,
                  color: Colors.blue,
                  displacement: 100,
                  elevation: 3,
                  child: SizedBox(
                    width: totalWidth,
                    height: constraints.maxHeight,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _attendanceResult!.attendance.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _attendanceResult!.attendance.length) {
                          return _buildTotalRow(dates.length, dateColumnWidth);
                        }

                        final entry = _attendanceResult!.attendance.entries
                            .elementAt(index);
                        final contactName =
                            _contactManager.contacts[index].name;

                        return Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: index % 2 == 1
                                ? Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerLow
                                      .withValues(alpha: 0.2)
                                : null,
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Name column
                              _buildNameCell(
                                contactName,
                                nameColumnWidth,
                                color: cs.onSurfaceVariant,
                              ),
                              // Attendance columns
                              ...entry.value.asMap().entries.map((
                                attendanceEntry,
                              ) {
                                final present = attendanceEntry.value;
                                return _buildAttendanceCell(
                                  present,
                                  dateColumnWidth,
                                  name: contactName,
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNameCell(String name, double width, {Color? color}) {
    return Container(
      width: width,
      padding: const EdgeInsets.only(left: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        name,
        style: TextStyle(fontSize: 13, color: color),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildAttendanceCell(
    bool present,
    double width, {
    required String name,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderClr = present
        ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
        : (isDark
              ? const Color.fromARGB(255, 196, 102, 102)
              : Colors.red.shade700);
    final bgClr = present
        ? (isDark
              ? Colors.green.withValues(alpha: 0.2)
              : const Color.fromARGB(255, 56, 179, 73).withValues(alpha: 0.2))
        : (isDark
              ? Colors.red.withValues(alpha: 0.2)
              : const Color.fromARGB(255, 255, 70, 56).withValues(alpha: 0.2));
    final textClr = present
        ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
        : (isDark ? Colors.red.shade300 : Colors.red.shade700);
    return GestureDetector(
      onTap: () {
        debugPrint("bottom");
        scaffoldKey.currentState!.showBottomSheet((context) {
          return Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    present ? "Present" : "Absent",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textClr,
                    ),
                  ),
                ],
              ),
            ),
          );
        }, backgroundColor: Colors.transparent);
      },
      child: Container(
        width: width,
        alignment: Alignment.center,
        child: Container(
          width: 28,
          height: 26,
          decoration: BoxDecoration(
            color: bgClr,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderClr, width: 1),
          ),
          child: Center(
            child: Text(
              present ? "P" : "A",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textClr,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalRow(int totalDays, double dateColumnWidth) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.12),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
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
