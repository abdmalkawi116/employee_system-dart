// DATA ONLY: names, departments and numbers live here, with no logic.
// To add or change a starting employee, edit this list.
//
// type: 'fulltime' | 'manager' | 'parttime'
//  fulltime  -> baseSalary, bonus
//  manager   -> baseSalary, bonus, teamSize
//  parttime  -> hourlyRate, hours
const List<Map<String, dynamic>> employeesData = [
  {
    'type': 'fulltime',
    'id': 1,
    'name': 'Ahmed',
    'department': 'Accounting',
    'baseSalary': 800000,
    'bonus': 100000,
  },
  {
    'type': 'manager',
    'id': 2,
    'name': 'Sara',
    'department': 'Accounting',
    'baseSalary': 1200000,
    'bonus': 150000,
    'teamSize': 4,
  },
  {
    'type': 'parttime',
    'id': 3,
    'name': 'Ali',
    'department': 'Sales',
    'baseSalary': 0,
    'hourlyRate': 5000,
    'hours': 80,
  },
];
