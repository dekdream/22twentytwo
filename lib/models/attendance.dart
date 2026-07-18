class Attendance {
  const Attendance({
    required this.id,
    required this.employeeId,
    required this.workDate,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.note,
  });

  final int id;
  final String employeeId;
  final DateTime workDate;
  final String status;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String? note;

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'] as int,
      employeeId: (map['employee_id'] ?? '') as String,
      workDate: DateTime.parse(map['work_date'] as String),
      status: (map['status'] ?? '') as String,
      checkIn: map['check_in'] == null
          ? null
          : DateTime.parse(map['check_in'] as String),
      checkOut: map['check_out'] == null
          ? null
          : DateTime.parse(map['check_out'] as String),
      note: map['note'] as String?,
    );
  }
}
