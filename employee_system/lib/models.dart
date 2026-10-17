import 'utils.dart';

// ALL MODELS: the classes that describe an employee.

// ======================================================================
// SECTION 1: Payable (interface)
// ======================================================================

/// Contract: anything that can be paid must be able to calculate its salary.
abstract class Payable {
  double calculateSalary();
}

// ======================================================================
// SECTION 2: Taxable (mixin)
// ======================================================================

/// Mixin that gives any class tax-calculation behaviour (code reuse without inheritance).
mixin Taxable {
  double taxRate = 0.05;

  double calculateTax(double amount) => amount * taxRate;

  double applyTax(double amount) => amount - calculateTax(amount);
}

// ======================================================================
// SECTION 3: Employee (abstract base class)
// ======================================================================

/// Base class of all employees (abstraction + encapsulation).
abstract class Employee implements Payable {
  final int id;
  String _name;
  double _baseSalary;
  String _department;

  Employee(this.id, String name, double baseSalary, String department)
      : _name = _validateText(name, 'Name'),
        _baseSalary = _validateAmount(baseSalary, 'Base salary'),
        _department = _validateText(department, 'Department');

  // ---- validation helpers (used by constructor and setters => DRY) ----
  static String _validateText(String value, String field) {
    final text = value.trim();
    if (text.isEmpty) throw ArgumentError('$field cannot be empty');
    return text;
  }

  static double _validateAmount(double value, String field) {
    if (value < 0) throw ArgumentError('$field cannot be negative');
    return value;
  }

  // ---- getters / setters (encapsulation) ----
  String get name => _name;
  set name(String value) => _name = _validateText(value, 'Name');

  double get baseSalary => _baseSalary;
  set baseSalary(double value) =>
      _baseSalary = _validateAmount(value, 'Base salary');

  String get department => _department;
  set department(String value) => _department = _validateText(value, 'Department');

  /// Label shown to the user (each subclass defines its own).
  String get role;

  /// Key used when saving to a file.
  String get typeKey;

  /// Converts the object to a Map so it can be saved as JSON.
  Map<String, dynamic> toMap() => {
        'type': typeKey,
        'id': id,
        'name': name,
        'baseSalary': baseSalary,
        'department': department,
      };

  void printInfo() => print(this);

  @override
  String toString() =>
      '[$id] $name | $role | $department | Salary: ${Formatter.money(calculateSalary())}';
}

// ======================================================================
// SECTION 4: FullTimeEmployee
// ======================================================================

/// Full-time employee: salary = (base + bonus) - tax.
class FullTimeEmployee extends Employee with Taxable {
  double bonus;

  FullTimeEmployee(
    super.id,
    super.name,
    super.baseSalary,
    super.department,
    this.bonus,
  );

  @override
  String get role => 'Full-time';

  @override
  String get typeKey => 'fulltime';

  @override
  double calculateSalary() => applyTax(baseSalary + bonus);

  @override
  Map<String, dynamic> toMap() => {...super.toMap(), 'bonus': bonus};
}

// ======================================================================
// SECTION 5: Manager
// ======================================================================

/// Manager: a full-time employee + an allowance for every team member.
class Manager extends FullTimeEmployee {
  static const double allowancePerMember = 20000;

  int teamSize;

  Manager(
    super.id,
    super.name,
    super.baseSalary,
    super.department,
    super.bonus,
    this.teamSize,
  );

  @override
  String get role => 'Manager';

  @override
  String get typeKey => 'manager';

  @override
  double calculateSalary() =>
      super.calculateSalary() + teamSize * allowancePerMember;

  @override
  Map<String, dynamic> toMap() => {...super.toMap(), 'teamSize': teamSize};
}

// ======================================================================
// SECTION 6: PartTimeEmployee
// ======================================================================

/// Part-time employee: salary = hourly rate x hours worked.
class PartTimeEmployee extends Employee {
  double hourlyRate;
  double hours;

  PartTimeEmployee(
    int id,
    String name,
    String department,
    this.hourlyRate,
    this.hours,
  ) : super(id, name, 0, department);

  @override
  String get role => 'Part-time';

  @override
  String get typeKey => 'parttime';

  @override
  double calculateSalary() => hourlyRate * hours;

  @override
  Map<String, dynamic> toMap() =>
      {...super.toMap(), 'hourlyRate': hourlyRate, 'hours': hours};
}

// ======================================================================
// SECTION 7: EmployeeFactory (builds objects from saved data)
// ======================================================================

/// Factory pattern: builds the correct Employee subclass from saved data.
class EmployeeFactory {
  static double _num(Map<String, dynamic> m, String key) =>
      (m[key] as num).toDouble();

  static Employee fromMap(Map<String, dynamic> m) {
    final id = m['id'] as int;
    final name = m['name'] as String;
    final dept = m['department'] as String;

    switch (m['type']) {
      case 'fulltime':
        return FullTimeEmployee(
            id, name, _num(m, 'baseSalary'), dept, _num(m, 'bonus'));
      case 'manager':
        return Manager(id, name, _num(m, 'baseSalary'), dept,
            _num(m, 'bonus'), m['teamSize'] as int);
      case 'parttime':
        return PartTimeEmployee(
            id, name, dept, _num(m, 'hourlyRate'), _num(m, 'hours'));
      default:
        throw FormatException('Unknown employee type: ${m['type']}');
    }
  }
}
