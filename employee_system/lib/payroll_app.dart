import 'models.dart';
import 'services.dart';
import 'utils.dart';

/// The interactive console application (menu + user flows).
class PayrollApp {
  final EmployeeManager _manager = EmployeeManager();
  final FileStorage _storage = FileStorage();

  void run() {
    print('******* Employee & Payroll System *******');
    _loadData(silent: true);

    var running = true;
    while (running) {
      _printMenu();
      final choice = InputHelper.readInt('Choose a number', max: 9);
      if (choice == 0) {
        running = false;
        continue;
      }
      try {
        _dispatch(choice);
      } on ArgumentError catch (e) {
        print('Invalid data: ${e.message}');
      } on StateError catch (e) {
        print('Error: ${e.message}');
      } on FormatException catch (e) {
        print('Bad data file: ${e.message}');
      }
    }

    _saveData();
    print('Goodbye!');
  }

  void _printMenu() {
    Formatter.header('Main Menu');
    print('''
    1) Add employee
    2) Remove employee
    3) Update employee
    4) Show all employees
    5) Search (ID / name / department)
    6) Sort by salary
    7) Salary reports
    8) Save data
    9) Load data
    0) Exit''');
  }

  void _dispatch(int choice) {
    switch (choice) {
      case 1:
        _addEmployee();
      case 2:
        _removeEmployee();
      case 3:
        _updateEmployee();
      case 4:
        Formatter.printAll('All employees', _manager.employees);
      case 5:
        _search();
      case 6:
        _sortBySalary();
      case 7:
        _showReports();
      case 8:
        _saveData();
      case 9:
        _loadData();
    }
  }

  // ------------------------------------------------------------ add
  void _addEmployee() {
    Formatter.header('Add employee');
    print('1) Full-time   2) Manager   3) Part-time');
    final type = InputHelper.readInt('Employee type', min: 1, max: 3);

    final id = _manager.nextId;
    final name = InputHelper.readString('Name');
    final dept = InputHelper.readString('Department');

    final employee = _buildEmployee(type, id, name, dept);
    _manager.addEmployee(employee);
    print('Employee added successfully (ID: $id)');
    employee.printInfo();
  }

  /// Reads only the fields that are specific to the chosen type.
  Employee _buildEmployee(int type, int id, String name, String dept) {
    if (type == 3) {
      return PartTimeEmployee(id, name, dept,
          InputHelper.readDouble('Hourly rate'),
          InputHelper.readDouble('Hours worked'));
    }
    final base = InputHelper.readDouble('Base salary');
    final bonus = InputHelper.readDouble('Bonus');
    if (type == 2) {
      final team = InputHelper.readInt('Team size');
      return Manager(id, name, base, dept, bonus, team);
    }
    return FullTimeEmployee(id, name, base, dept, bonus);
  }

  // --------------------- find helper ------------------------- 
  Employee? _askForEmployee() {
    final id = InputHelper.readInt('Employee ID', min: 1);
    final employee = _manager.findById(id);
    if (employee == null) print('No employee with this ID.');
    return employee;
  }

  // ------------------ remove ------------------------
  void _removeEmployee() {
    Formatter.header('Remove employee');
    final employee = _askForEmployee();
    if (employee == null) return;
    employee.printInfo();
    if (InputHelper.readYesNo('Are you sure you want to remove?')) {
      _manager.removeEmployee(employee.id);
      print('Removed.');
    } else {
      print('Cancelled.');
    }
  }

  // ------------------------------ update ----------------------------
  void _updateEmployee() {
    Formatter.header('Update employee (press Enter to keep the value)');
    final e = _askForEmployee();
    if (e == null) return;

    e.name = InputHelper.readString('Name', keep: e.name);
    e.department = InputHelper.readString('Department', keep: e.department);

    // Type checks are sequential on purpose: a Manager is also a FullTimeEmployee.
    if (e is FullTimeEmployee) {
      e.baseSalary =
          InputHelper.readDouble('Base salary', keep: e.baseSalary);
      e.bonus = InputHelper.readDouble('Bonus', keep: e.bonus);
    }
    if (e is Manager) {
      e.teamSize = InputHelper.readInt('Team size', keep: e.teamSize);
    }
    if (e is PartTimeEmployee) {
      e.hourlyRate = InputHelper.readDouble('Hourly rate', keep: e.hourlyRate);
      e.hours = InputHelper.readDouble('Hours worked', keep: e.hours);
    }
    print('Updated:');
    e.printInfo();
  }

  // ---------------------------------------------------------- search
  void _search() {
    Formatter.header('Search');
    print('1) By ID   2) By name   3) By department');
    switch (InputHelper.readInt('Search by', min: 1, max: 3)) {
      case 1:
        final e = _askForEmployee();
        Formatter.printAll('Search results', e == null ? [] : [e]);
      case 2:
        final q = InputHelper.readString('Name (or part of it)');
        Formatter.printAll('Search results', _manager.searchByName(q));
      case 3:
        print('Available departments: ${_manager.departments.join(', ')}');
        final d = InputHelper.readString('Department name');
        Formatter.printAll('Department $d', _manager.getByDepartment(d));
    }
  }

  // ------------------------------------------------------------ sort
  void _sortBySalary() {
    final desc = InputHelper.readYesNo('Sort from highest to lowest?');
    Formatter.printAll('Sorted by salary',
        _manager.sortedBySalary(descending: desc));
  }

  // --------------------------------------------------------- reports
  void _showReports() {
    final all = _manager.employees;
    Formatter.header('Salary reports');
    if (all.isEmpty) {
      print('No data.');
      return;
    }

    print('Number of employees: ${all.length}');
    _manager.countByRole().forEach((role, n) => print('  - $role: $n'));
    print('Total salaries: ${Formatter.money(PayrollService.getTotalSalary(all))}');
    print('Average salary: ${Formatter.money(PayrollService.getAverageSalary(all))}');
    print('Highest paid: ${PayrollService.getHighestPaid(all)}');
    print('Lowest paid: ${PayrollService.getLowestPaid(all)}');

    print('\nTotal salaries per department:');
    PayrollService.totalByDepartment(_manager.groupByDepartment()).forEach(
        (dept, total) => print('  - $dept: ${Formatter.money(total)}'));
  }

  // ----------------------------------------------------- persistence
  void _saveData() {
    _storage.save(_manager.employees);
    print('Data saved to ${_storage.path}');
  }

  void _loadData({bool silent = false}) {
    if (!_storage.exists) {
      if (silent) {
        // First run: start from the sample database.
        _manager.replaceAll(SampleDatabase.employees());
        print('Loaded starting data (${_manager.employees.length} employees).');
      } else {
        print('No saved file found.');
      }
      return;
    }
    _manager.replaceAll(_storage.load());
    print('Loaded ${_manager.employees.length} employees from ${_storage.path}');
  }
}
