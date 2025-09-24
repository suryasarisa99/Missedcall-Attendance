import 'dart:developer';

import 'package:attendance/services/contact_manager.dart';
import 'package:call_log/call_log.dart';
import 'package:intl/intl.dart';

class AttendanceManager {
  static final AttendanceManager _instance = AttendanceManager._internal();
  factory AttendanceManager() => _instance;

  AttendanceManager._internal();

  /// get attendance of a specific month and year
  /// from [1st] to [end of month].
  static Future<AttendanceResult> getAttendanceOfMonth(
    int month,
    int year,
  ) async {
    final now = DateTime.now();
    final startDate = DateTime(year, month, 1);
    final monthEndDate = DateTime(year, month + 1, 0); // Last day of the month
    final endDate = now.isBefore(monthEndDate) ? now : monthEndDate;

    return await getAttendanceInRange(startDate, endDate);
  }

  /// get attendance of this month
  /// from [1st] to [currentDate].
  static Future<AttendanceResult> getCurrentMonthAttendance() async {
    final now = DateTime.now();
    return await getAttendanceOfMonth(now.month, now.year);
  }

  ///  get attendance from [startDate] to [endDate]
  static Future<AttendanceResult> getAttendanceInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final contactManager = ContactManager.instance;
      final now = DateTime.now();

      // Check if the end date includes current date
      final hasCurrentDate =
          endDate.year == now.year &&
          endDate.month == now.month &&
          endDate.day == now.day;

      // set time to last of the day, 11:59:59.999 PM
      endDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
        999,
      );
      // day start time 00:00:00.000 AM
      startDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        0,
        0,
        0,
        0,
      );

      // Query call logs
      final Iterable<CallLogEntry> callLogs = await CallLog.query(
        dateFrom: startDate.millisecondsSinceEpoch,
        dateTo: endDate.millisecondsSinceEpoch,
        type: CallType.missed,
      );

      // Get dates in range
      final dates = getDatesInRange(startDate, endDate);
      final totalDays = dates.length;

      // Initialize attendance map
      final Map<String, List<int?>> attendance = {};

      for (var contact in contactManager.contacts) {
        attendance[contact.phoneNumber] = List.generate(totalDays, (_) => null);
      }

      // Process call logs
      for (final entry in callLogs) {
        final String? number = entry.number;
        if (number == null) continue;

        if (attendance.containsKey(number)) {
          final logDate = DateTime.fromMillisecondsSinceEpoch(
            entry.timestamp ?? 0,
          );

          // Calculate which day this log belongs to
          final dayIndex = _getDayIndex(startDate, logDate);

          if (dayIndex >= 0 && dayIndex < totalDays) {
            attendance[number]![dayIndex] = entry.timestamp;
          }
        }
      }

      return AttendanceResult(
        attendance: attendance,
        dates: dates,
        hasCurrentDate: hasCurrentDate,
      );
    } catch (e) {
      throw Exception('Error getting attendance: $e');
    }
  }

  /// Helper method to calculate day index from start date
  static int _getDayIndex(DateTime startDate, DateTime logDate) {
    // Normalize both dates to start of day for comparison
    final startDateNormalized = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final logDateNormalized = DateTime(
      logDate.year,
      logDate.month,
      logDate.day,
    );

    return logDateNormalized.difference(startDateNormalized).inDays;
  }

  /// Get list of formatted date strings in range
  static List<String> getDatesInRange(DateTime startDate, DateTime endDate) {
    final List<String> dates = [];
    final formatter = DateFormat('MMM d');

    for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
      dates.add(formatter.format(startDate.add(Duration(days: i))));
    }

    return dates;
  }

  /// Get attendance entries for easy access
  static Future<List<AttendanceEntry>> getAttendanceEntries(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final result = await getAttendanceInRange(startDate, endDate);
    return result.attendance.entries.map((entry) {
      return AttendanceEntry(phoneNumber: entry.key, attendance: entry.value);
    }).toList();
  }

  /// Get attendance statistics for a date range
  static Future<AttendanceStats> getAttendanceStats(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final result = await getAttendanceInRange(startDate, endDate);

    final totalStudents = result.attendance.length;
    final totalDays = result.dates.length;

    // Calculate daily totals
    final dailyTotals = List.generate(totalDays, (dayIndex) {
      return result.attendance.values
          .where((attendance) => attendance[dayIndex] != null)
          .length;
    });

    // Calculate student totals
    final studentTotals = result.attendance.map((phoneNumber, attendance) {
      final presentDays = attendance.where((present) => present != null).length;
      return MapEntry(phoneNumber, presentDays);
    });

    return AttendanceStats(
      totalStudents: totalStudents,
      totalDays: totalDays,
      dailyTotals: dailyTotals,
      studentTotals: studentTotals,
      attendanceResult: result,
    );
  }
}

class AttendanceResult {
  final Map<String, List<int?>> attendance;
  final List<String> dates;
  final bool hasCurrentDate;

  AttendanceResult({
    required this.attendance,
    required this.dates,
    required this.hasCurrentDate,
  });

  /// Get total present count for a specific day
  int getPresentCountForDay(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= dates.length) return 0;

    return attendance.values
        .where((attendance) => attendance[dayIndex] != null)
        .length;
  }

  /// Get total present days for a specific student
  int getPresentDaysForStudent(String phoneNumber) {
    final studentAttendance = attendance[phoneNumber];
    if (studentAttendance == null) return 0;

    return studentAttendance.where((present) => present != null).length;
  }

  /// Get attendance percentage for a student
  double getAttendancePercentage(String phoneNumber) {
    final presentDays = getPresentDaysForStudent(phoneNumber);
    return dates.isEmpty ? 0.0 : (presentDays / dates.length) * 100;
  }

  /// Get overall attendance percentage
  double getOverallAttendancePercentage() {
    if (attendance.isEmpty || dates.isEmpty) return 0.0;

    final totalPossibleAttendance = attendance.length * dates.length;
    final totalPresentAttendance = attendance.values
        .expand((attendance) => attendance)
        .where((present) => present != null)
        .length;

    return (totalPresentAttendance / totalPossibleAttendance) * 100;
  }
}

// for user attendance entry
class AttendanceEntry {
  final String phoneNumber;
  final List<int?> attendance;

  AttendanceEntry({required this.phoneNumber, required this.attendance});

  /// Get total present days for this entry
  int get totalPresentDays =>
      attendance.where((present) => present != null).length;

  /// Get attendance percentage for this entry
  double get attendancePercentage =>
      attendance.isEmpty ? 0.0 : (totalPresentDays / attendance.length) * 100;
}

/// Statistics class for attendance data
class AttendanceStats {
  final int totalStudents;
  final int totalDays;
  final List<int> dailyTotals;
  final Map<String, int> studentTotals;
  final AttendanceResult attendanceResult;

  AttendanceStats({
    required this.totalStudents,
    required this.totalDays,
    required this.dailyTotals,
    required this.studentTotals,
    required this.attendanceResult,
  });

  /// Get average attendance per day
  double get averageAttendancePerDay {
    if (dailyTotals.isEmpty) return 0.0;
    final total = dailyTotals.reduce((a, b) => a + b);
    return total / dailyTotals.length;
  }

  /// Get the day with highest attendance
  int get bestAttendanceDay {
    if (dailyTotals.isEmpty) return -1;
    int maxIndex = 0;
    for (int i = 1; i < dailyTotals.length; i++) {
      if (dailyTotals[i] > dailyTotals[maxIndex]) {
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  /// Get the day with lowest attendance
  int get worstAttendanceDay {
    if (dailyTotals.isEmpty) return -1;
    int minIndex = 0;
    for (int i = 1; i < dailyTotals.length; i++) {
      if (dailyTotals[i] < dailyTotals[minIndex]) {
        minIndex = i;
      }
    }
    return minIndex;
  }
}
