import 'package:intl/intl.dart';

enum AppDateFormat {
  automatic('automatic', 'MMM d, yyyy (Default)'),
  dayMonthYear('dayMonthYear', 'DD/MM/YYYY'),
  monthDayYear('monthDayYear', 'MM/DD/YYYY'),
  yearMonthDay('yearMonthDay', 'YYYY-MM-DD'),
  longDate('longDate', 'EEEE, MMM d, yyyy');

  const AppDateFormat(this.storageValue, this.label);
  final String storageValue;
  final String label;

  static AppDateFormat fromStorage(String? value) {
    return AppDateFormat.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => AppDateFormat.automatic,
    );
  }

  String format(DateTime date) {
    return switch (this) {
      AppDateFormat.automatic => DateFormat('MMM d, yyyy').format(date),
      AppDateFormat.dayMonthYear => DateFormat('dd/MM/yyyy').format(date),
      AppDateFormat.monthDayYear => DateFormat('MM/dd/yyyy').format(date),
      AppDateFormat.yearMonthDay => DateFormat('yyyy-MM-dd').format(date),
      AppDateFormat.longDate => DateFormat('EEEE, MMM d, yyyy').format(date),
    };
  }

  String formatShort(DateTime date) {
    return switch (this) {
      AppDateFormat.automatic => DateFormat('MMM d').format(date),
      AppDateFormat.dayMonthYear => DateFormat('dd/MM').format(date),
      AppDateFormat.monthDayYear => DateFormat('MM/dd').format(date),
      AppDateFormat.yearMonthDay => DateFormat('yyyy-MM-dd').format(date),
      AppDateFormat.longDate => DateFormat('EEE, MMM d').format(date),
    };
  }
}
