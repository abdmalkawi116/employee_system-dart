import 'dart:io';

import 'models.dart';

// ALL UTILITIES: helpers for input and output.

// ======================================================================
// SECTION 1: Formatter (output / printing)
// ======================================================================

/// Shared output helpers (DRY: every screen prints through these).
class Formatter {
  /// 1234567.5 -> "1,234,567.50"
  static String money(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final whole = parts[0]
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return '$whole.${parts[1]}';
  }

  static void header(String title) => print('\n=== $title ===');

  static void printAll(String title, List<Employee> list) {
    header(title);
    if (list.isEmpty) {
      print('No results.');
      return;
    }
    for (final e in list) {
      e.printInfo();
    }
  }
}

// ======================================================================
// SECTION 2: InputHelper (keyboard input + validation)
// ======================================================================

/// All keyboard input goes through here: reading + validation + retry.
/// Every reader accepts [keep]: pressing Enter returns the current value (used in update).
class InputHelper {
  static T _read<T>(
    String prompt,
    T? Function(String) parse,
    String error, {
    T? keep,
  }) {
    while (true) {
      stdout.write(keep == null ? '$prompt: ' : '$prompt [$keep]: ');
      final line = stdin.readLineSync();
      if (line == null) {
        print('\nInput closed. Exiting.');
        exit(0);
      }
      final input = line.trim();
      if (input.isEmpty && keep != null) return keep;
      final value = parse(input);
      if (value != null) return value;
      print(error);
    }
  }

  static String readString(String prompt, {String? keep}) => _read<String>(
      prompt, (s) => s.isEmpty ? null : s, 'Value cannot be empty.',
      keep: keep);

  static int readInt(String prompt, {int min = 0, int? max, int? keep}) =>
      _read<int>(prompt, (s) {
        final n = int.tryParse(s);
        if (n == null || n < min || (max != null && n > max)) return null;
        return n;
      }, 'Enter a whole number${max != null ? ' between $min and $max' : ' of at least $min'}.',
          keep: keep);

  static double readDouble(String prompt, {double? keep}) =>
      _read<double>(prompt, (s) {
        final n = double.tryParse(s);
        return (n == null || n < 0) ? null : n;
      }, 'Enter a positive number.', keep: keep);

  static bool readYesNo(String prompt) => _read<bool>(prompt + ' (y/n)', (s) {
        final v = s.toLowerCase();
        if (['y', 'yes'].contains(v)) return true;
        if (['n', 'no'].contains(v)) return false;
        return null;
      }, 'Type y or n.');
}
