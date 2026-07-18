class Payroll {
  const Payroll({
    required this.id,
    required this.employeeId,
    required this.month,
    required this.year,
    required this.basicSalary,
    required this.totalSalary,
  });

  final int id;
  final String employeeId;
  final int month;
  final int year;
  final double basicSalary;
  final double totalSalary;

  factory Payroll.fromMap(Map<String, dynamic> map) {
    return Payroll(
      id: map['id'] as int,
      employeeId: (map['employee_id'] ?? '') as String,
      month: (map['month'] ?? 0) as int,
      year: (map['year'] ?? 0) as int,
      basicSalary: ((map['basic_salary'] ?? 0) as num).toDouble(),
      totalSalary: ((map['total_salary'] ?? 0) as num).toDouble(),
    );
  }
}
