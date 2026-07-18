class Employee {
  const Employee({
    required this.id,
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.departmentId,
    this.positionId,
    required this.status,
  });

  final String id;
  final String employeeCode;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final int? departmentId;
  final int? positionId;
  final String status;

  String get fullName => '$firstName $lastName'.trim();

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: (map['id'] ?? '') as String,
      employeeCode: (map['employee_code'] ?? '') as String,
      firstName: (map['first_name'] ?? '') as String,
      lastName: (map['last_name'] ?? '') as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      departmentId: map['department_id'] as int?,
      positionId: map['position_id'] as int?,
      status: (map['status'] ?? 'Active') as String,
    );
  }
}
