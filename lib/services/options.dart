import 'package:attendance/main.dart';
import 'package:flutter/cupertino.dart';

class Options {
  Options._();

  static String _selectionType = 'current_month';

  static String get selectionType =>
      prefs?.getString('selectionType') ?? _selectionType;
  static set selectionType(String value) {
    _selectionType = value;
    debugPrint('Selection type set to: $value');
    prefs?.setString('selectionType', value);
  }

  static DateTime? get selectedStartDate {
    final timestamp = prefs?.getInt('selectedStartDate');
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  static set selectedStartDate(DateTime? value) {
    if (value != null) {
      prefs?.setInt('selectedStartDate', value.millisecondsSinceEpoch);
    } else {
      prefs?.remove('selectedStartDate');
    }
  }

  static DateTime? get selectedEndDate {
    final timestamp = prefs?.getInt('selectedEndDate');
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  static set selectedEndDate(DateTime? value) {
    if (value != null) {
      prefs?.setInt('selectedEndDate', value.millisecondsSinceEpoch);
    } else {
      prefs?.remove('selectedEndDate');
    }
  }

  static int? get selectedMonth => prefs?.getInt('selectedMonth');
  static set selectedMonth(int? value) {
    if (value != null) {
      prefs?.setInt('selectedMonth', value);
    } else {
      prefs?.remove('selectedMonth');
    }
  }

  static int? get selectedYear => prefs?.getInt('selectedYear');
  static set selectedYear(int? value) {
    if (value != null) {
      prefs?.setInt('selectedYear', value);
    } else {
      prefs?.remove('selectedYear');
    }
  }
}
