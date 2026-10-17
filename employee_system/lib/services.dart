import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'employees_data.dart';
import 'models.dart';

// ALL SERVICES: the logic that works on the employees.

// ======================================================================
// SECTION 1: EmployeeManager (List / Map / Set)
// ======================================================================

/// "Database" of employees using the three collections: List, Map and Set.
class EmployeeManager {
  final List<Employee> _employees = []; // keeps insertion order
  final Map<int, Employee> _byId = {}; // fast lookup by id

  List<Employee> get employees => List.unmodifiable(_employees);
  bool get isEmpty => _employees.isEmpty;

  /// Set => unique departments (always up to date, even after an update).
  Set<String> get departments => _employees.map((e) => e.department).toSet();

  /// Next free id (auto-generated so the user never types it).
  int get nextId => _byId.isEmpty ? 1 : _byId.keys.reduce(max) + 1;

  void addEmployee(Employee e) {
    if (_byId.containsKey(e.id)) {
      throw StateError('Employee ID ${e.id} already exists');
    }
    _employees.add(e);
    _byId[e.id] = e;
  }

  bool removeEmployee(int id) {
    final e = _byId.remove(id);
    if (e == null) return false;
    _employees.remove(e);
    return true;
  }

  Employee? findById(int id) => _byId[id];

  List<Employee> searchByName(String query) {
    final q = query.toLowerCase();
    return _employees.where((e) => e.name.toLowerCase().contains(q)).toList();
  }

  List<Employee> getByDepartment(String dept) =>
      _employees.where((e) => e.department == dept).toList();

  List<Employee> sortedBySalary({bool descending = true}) {
    final sorted = [..._employees];
    sorted.sort((a, b) => descending
        ? b.calculateSalary().compareTo(a.calculateSalary())
        : a.calculateSalary().compareTo(b.calculateSalary()));
    return sorted;
  }

  Map<String, List<Employee>> groupByDepartment() {
    final groups = <String, List<Employee>>{};
    for (final e in _employees) {
      groups.putIfAbsent(e.department, () => []).add(e);
    }
    return groups;
  }

  Map<String, int> countByRole() {
    final counts = <String, int>{};
    for (final e in _employees) {
      counts[e.role] = (counts[e.role] ?? 0) + 1;
    }
    return counts;
  }

  void replaceAll(List<Employee> list) {
    _employees.clear();
    _byId.clear();
    list.forEach(addEmployee);
  }
}

// ======================================================================
// SECTION 2: PayrollService (salary calculations)
// ======================================================================

/// Payroll calculations (static helpers, no state).
class PayrollService {
  static double getTotalSalary(List<Employee> list) =>
      list.fold<double>(0, (sum, e) => sum + e.calculateSalary());

  static double getAverageSalary(List<Employee> list) =>
      list.isEmpty ? 0 : getTotalSalary(list) / list.length;

  // One private picker used by both highest and lowest (DRY).
  static Employee? _pick(
      List<Employee> list, bool Function(double a, double b) isBetter) {
    if (list.isEmpty) return null;
    return list.reduce((best, e) =>
        isBetter(e.calculateSalary(), best.calculateSalary()) ? e : best);
  }

  static Employee? getHighestPaid(List<Employee> list) =>
      _pick(list, (a, b) => a > b);

  static Employee? getLowestPaid(List<Employee> list) =>
      _pick(list, (a, b) => a < b);

  static Map<String, double> totalByDepartment(
          Map<String, List<Employee>> groups) =>
      groups.map((dept, list) => MapEntry(dept, getTotalSalary(list)));
}

// ======================================================================
// SECTION 3: FileStorage (save / load JSON)
// ======================================================================

/// Saves / loads employees as JSON so data survives closing the program.
class FileStorage {
  final String path;

  FileStorage([this.path = 'employees.json']);

  bool get exists => File(path).existsSync();

  void save(List<Employee> list) {
    final json = const JsonEncoder.withIndent('  ')
        .convert(list.map((e) => e.toMap()).toList());
    File(path).writeAsStringSync(json);
  }

  List<Employee> load() {
    if (!exists) return [];
    final data = jsonDecode(File(path).readAsStringSync()) as List<dynamic>;
    return data
        .map((m) => EmployeeFactory.fromMap(m as Map<String, dynamic>))
        .toList();
  }
}

// ======================================================================
// SECTION 4: SampleDatabase (turns employees_data.dart into objects)
// ======================================================================

/// Turns the raw data in employees_data.dart into real Employee objects.
class SampleDatabase {
  static List<Employee> employees() =>
      employeesData.map(EmployeeFactory.fromMap).toList();
}
