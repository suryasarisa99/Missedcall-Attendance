import 'package:attendance/main.dart';
import 'package:flutter/cupertino.dart';

class Options {
  // singleton pattern
  static final Options i = Options._();
  Options._() {
    _reverseColumns = prefs?.getBool('reverseColumns') ?? true;
  }

  late bool _reverseColumns;

  static String get selectionType =>
      prefs?.getString('selectionType') ?? 'current_month';
  static set selectionType(String value) {
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

  static bool get confirmSwipeToDelete =>
      prefs?.getBool('confirmSwipeToDelete') ?? true;
  static set confirmSwipeToDelete(bool value) {
    prefs?.setBool('confirmSwipeToDelete', value);
  }

  static bool get reloadOnAppResume =>
      prefs?.getBool('reloadOnAppResume') ?? true;
  static set reloadOnAppResume(bool value) {
    prefs?.setBool('reloadOnAppResume', value);
    debugPrint('Reload on app resume set to: $value');
  }

  static bool get reloadOnPhoneCall =>
      prefs?.getBool('reloadOnPhoneCall') ?? true;
  static set reloadOnPhoneCall(bool value) {
    prefs?.setBool('reloadOnPhoneCall', value);
    debugPrint('Reload on phone call set to: $value');
  }

  bool get reverseColumns => i._reverseColumns;
  set reverseColumns(bool value) {
    i._reverseColumns = value;
    prefs?.setBool('reverseColumns', value);
    debugPrint('Reverse columns set to: $value');
  }
}
