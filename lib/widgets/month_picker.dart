import 'package:flutter/material.dart';

const _months = [
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

const _shortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

enum MonthDisplayMode { list, grid }

Future<({int month, int year})?> showMonthPicker({
  required BuildContext context,
  int? year,
  int? month,
}) {
  return showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        child: MonthYearPicker(initialMonth: month, initialYear: year),
      );
    },
  );
}

class MonthYearPicker extends StatefulWidget {
  const MonthYearPicker({
    super.key,
    this.initialMonth,
    this.initialYear,
    this.startsWithMonth = true,
    this.displayMode = MonthDisplayMode.grid,
  });
  final bool startsWithMonth;
  final int? initialYear;
  final int? initialMonth;
  final MonthDisplayMode displayMode;

  @override
  State<MonthYearPicker> createState() => _MonthYearPickerState();
}

class _MonthYearPickerState extends State<MonthYearPicker> {
  late bool startsWithMonth = widget.startsWithMonth;
  late int? selectedMonth = widget.initialMonth;
  late int? selectedYear = widget.initialYear;

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final dividerHeight = 16.0;
    final now = DateTime.now();
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            const SizedBox(width: 20),

            _builtBtn(
              _shortMonths[(selectedMonth ?? now.month) - 1],
              enabled: !startsWithMonth,
              onPressed: () {
                setState(() {
                  startsWithMonth = true;
                });
              },
            ),
            Text("-"),
            _builtBtn(
              (selectedYear ?? now.year).toString(),
              enabled: startsWithMonth,
              onPressed: () {
                setState(() {
                  startsWithMonth = false;
                });
              },
            ),
          ],
        ),
        if (startsWithMonth) Divider(height: dividerHeight),
        SizedBox(
          width: 300,
          height: startsWithMonth ? 300 - (dividerHeight * 2) : 300,
          child: startsWithMonth
              ? (widget.displayMode == MonthDisplayMode.list
                    ? buildListMonthPicker()
                    : buildGridMonthPicker())
              : YearPicker(
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  selectedDate: DateTime(
                    selectedYear ?? DateTime.now().year,
                    selectedMonth ?? DateTime.now().month,
                  ),
                  onChanged: (date) {
                    setState(() {
                      selectedYear = date.year;
                      startsWithMonth = true;
                    });
                  },
                ),
        ),
        if (startsWithMonth) Divider(height: dividerHeight),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CANCEL'),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: (selectedMonth != null && selectedYear != null)
                  ? () {
                      Navigator.pop(context, (
                        month: selectedMonth!,
                        year: selectedYear!,
                      ));
                    }
                  : null,
              child: const Text('OK'),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ],
    );
  }

  Widget buildListMonthPicker() {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: List.generate(12, (index) {
          bool isSelected = selectedMonth == index + 1;
          bool isCurrentMonth =
              now.month == index + 1 && now.year == selectedYear;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                setState(() {
                  selectedMonth = index + 1;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: isSelected ? cs.primary : null,
                  border: isCurrentMonth
                      ? Border.all(color: cs.primary, width: 0.75)
                      : null,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 28,
                ),
                child: Text(
                  _months[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                    fontWeight: isSelected
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget buildGridMonthPicker() {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    return GridView.count(
      crossAxisCount: 3,
      childAspectRatio: 2.5,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      mainAxisSpacing: 30,
      crossAxisSpacing: 8,
      children: List.generate(12, (index) {
        bool isSelected = selectedMonth == index + 1;
        bool isCurrentMonth =
            now.month == index + 1 && now.year == selectedYear;
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            setState(() {
              selectedMonth = index + 1;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: isSelected ? cs.primary : null,
              border: isCurrentMonth
                  ? Border.all(color: cs.primary, width: 0.75)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              _shortMonths[index],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }

  _builtBtn(String text, {required bool enabled, VoidCallback? onPressed}) {
    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
