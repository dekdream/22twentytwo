import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/record_cards.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  Future<void> _review(Map<String, dynamic> row) async {
    final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('อนุมัติคำขอลางาน'),
              content: Text(
                  '${employeeDisplayName(row)}\n${row['start_date']} ถึง ${row['end_date']}\n${row['reason'] ?? '-'}'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ปิด')),
                OutlinedButton(
                    onPressed: () => Navigator.pop(context, 'Rejected'),
                    child: const Text('ไม่อนุมัติ')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, 'Approved'),
                    child: const Text('อนุมัติ'))
              ],
            ));
    if (result == null) return;
    await hrRepository.update('leave_requests', row['id'], {
      'status': result,
    });
    await hrRepository.insert('notifications', {
      'employee_id': row['employee_id'],
      'title': result == 'Approved'
          ? 'อนุมัติการลาแล้ว'
          : 'คำขอลาไม่ได้รับการอนุมัติ',
      'message': 'คำขอลาวันที่ ${row['start_date']} ถึง ${row['end_date']}',
      'notification_type': 'Leave'
    });
    if (mounted) setState(() {});
  }

  Future<void> addLeave() async {
    final employees = await hrRepository.listEmployees(
      orderBy: 'first_name',
      branchId: EmployeeSession.activeBranchId,
    );
    final leaveTypes = await hrRepository.list('leave_type', orderBy: 'name');
    if (!mounted) return;
    final values = await showRecordDialog(
      context,
      title: 'Add Leave Request',
      fields: [
        FieldConfig('employee_id', 'Employee', options: [
          for (final employee in employees)
            FieldOption(
              value: employee['id'].toString(),
              label: _employeeLabel(employee),
            ),
        ]),
        FieldConfig('leave_type_id', 'Leave Type', options: [
          for (final leaveType in leaveTypes)
            FieldOption(
              value: leaveType['id'].toString(),
              label: leaveType['name']?.toString() ?? '-',
            ),
        ]),
        FieldConfig('start_date', 'Start Date yyyy-mm-dd'),
        FieldConfig('end_date', 'End Date yyyy-mm-dd'),
        FieldConfig('reason', 'Reason', maxLines: 3),
      ],
    );
    if (values == null || values['employee_id']!.isEmpty) return;
    final employee = _employeeNotificationLabel(
      employees,
      values['employee_id']!,
    );
    await hrRepository.insert('leave_requests', {
      'employee_id': values['employee_id'],
      'leave_type_id': int.tryParse(values['leave_type_id'] ?? '') ?? 1,
      'start_date': values['start_date'],
      'end_date': values['end_date'],
      'reason': values['reason'],
      'status': 'Pending',
    });
    await _sendLineNotification(
      'มีคำขอลางานใหม่\n'
      'พนักงาน: $employee\n'
      'วันที่ลา: ${values['start_date']} ถึง ${values['end_date']}\n'
      'เหตุผล: ${values['reason']?.isEmpty ?? true ? '-' : values['reason']}',
    );
    setState(() {});
  }

  static String _employeeLabel(Map<String, dynamic> employee) {
    final name =
        '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'.trim();
    final code = employee['employee_code']?.toString() ?? '-';
    return name.isEmpty ? code : '$name ($code)';
  }

  static String _employeeNotificationLabel(
    List<Map<String, dynamic>> employees,
    String employeeId,
  ) {
    final match =
        employees.where((employee) => employee['id']?.toString() == employeeId);
    if (match.isEmpty) return employeeId;

    final employee = match.first;
    final code = employee['employee_code']?.toString() ?? '-';
    final name =
        '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'.trim();
    return name.isEmpty ? code : '$code - $name';
  }

  Future<void> _sendLineNotification(String message) async {
    try {
      await hrRepository.sendLineNotification(message);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึกคำขอลาแล้ว แต่ส่ง LINE แจ้งเตือนไม่สำเร็จ'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return HrPage(
      title: 'Leave',
      subtitle: 'คำขอลางาน ประเภทการลา และสถานะการอนุมัติ',
      action: FilledButton.icon(
          onPressed: addLeave,
          icon: const Icon(Icons.add),
          label: const Text('Request')),
      child: RecordCards(
        tableName: 'leave_requests',
        onChanged: () => setState(() {}),
        future: hrRepository.listWithEmployee(
          'leave_requests',
          orderBy: 'created_at',
          branchId: EmployeeSession.activeBranchId,
          employeeForeignKey: 'leave_requests_employee_id_fkey',
        ),
        columns: const [
          DataColumn(label: Text('Employee')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Start')),
          DataColumn(label: Text('End')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Reason')),
        ],
        builder: (context, row, onTap) => RecordCard(
          title: employeeDisplayName(row),
          subtitle: '${row['start_date'] ?? '-'} - ${row['end_date'] ?? '-'}',
          trailing: '${row['status'] ?? 'Pending'}',
          icon: Icons.event_note_outlined,
          onTap: () => _review(row),
        ),
      ),
    );
  }
}
