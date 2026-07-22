class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.reason,
  });

  final int id;
  final String employeeId;
  final int leaveTypeId;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String? reason;

  factory LeaveRequest.fromMap(Map<String, dynamic> map) {
    return LeaveRequest(
      id: map['id'] as int,
      employeeId: (map['employee_id'] ?? '') as String,
      leaveTypeId: (map['leave_type_id'] ?? 0) as int,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      status: (map['status'] ?? 'Pending') as String,
      reason: map['reason'] as String?,
    );
  }
}
