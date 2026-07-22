import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/supabase_service.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/record_cards.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  Future<void> addEmployee() async {
    final departments = await hrRepository.list('departments', orderBy: 'name');
    final positions = await hrRepository.list('positions', orderBy: 'name');
    final branches = await hrRepository.listBranches(
      orderBy: 'branch_code',
      branchId: EmployeeSession.activeBranchId,
    );
    final assignableDepartments = EmployeeSession.isAdmin
        ? departments
            .where((department) =>
                department['id']?.toString() ==
                EmployeeSession.employeeDepartmentId.toString())
            .toList()
        : departments;
    if (!mounted) return;
    final values = await showRecordDialog(
      context,
      title: 'Add Employee',
      fields: [
        const FieldConfig(
          'profile_image_path',
          'Add profile image',
          isImagePicker: true,
        ),
        FieldConfig('employee_code', 'Employee Code'),
        FieldConfig('first_name', 'First Name'),
        FieldConfig('last_name', 'Last Name'),
        FieldConfig('email', 'Email', keyboardType: TextInputType.emailAddress),
        FieldConfig('phone', 'Phone'),
        FieldConfig('branch_id', 'Branch', options: [
          for (final branch in branches)
            FieldOption(
              value: branch['id'].toString(),
              label:
                  '${branch['branch_code'] ?? ''} - ${branch['branch_name'] ?? '-'}',
            ),
        ]),
        FieldConfig('department_id', 'Department', options: [
          for (final department in assignableDepartments)
            FieldOption(
              value: department['id'].toString(),
              label: department['name']?.toString() ?? '-',
            ),
        ]),
        FieldConfig('position_id', 'Position', options: [
          for (final position in positions)
            FieldOption(
              value: position['id'].toString(),
              label: position['name']?.toString() ?? '-',
            ),
        ]),
      ],
    );
    if (values == null || values['employee_code']!.isEmpty) {
      return;
    }
    final imagePath = values.remove('profile_image_path');
    final employee = await hrRepository.insertReturning('employees', {
      ...values,
      'branch_id': int.tryParse(values['branch_id'] ?? ''),
      'department_id': int.tryParse(values['department_id'] ?? ''),
      'position_id': int.tryParse(values['position_id'] ?? ''),
      'hire_date': DateTime.now().toIso8601String().substring(0, 10),
      'status': 'Active',
    });
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        final image = XFile(imagePath);
        await hrRepository.uploadEmployeeProfileImage(
          employeeId: employee['id'],
          bytes: await image.readAsBytes(),
          fileName: image.name,
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('เพิ่มพนักงานแล้ว แต่ไม่สามารถอัปโหลดรูปได้'),
            ),
          );
        }
      }
    }
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return HrPage(
      title: 'Employees',
      subtitle: 'ข้อมูลพนักงาน ประวัติ และสถานะการทำงาน',
      action: FilledButton.icon(
          onPressed: addEmployee,
          icon: const Icon(Icons.add),
          label: const Text('Add')),
      child: RecordCards(
        tableName: 'employees',
        onChanged: () => setState(() {}),
        future: hrRepository.listEmployees(
          orderBy: 'created_at',
          branchId: EmployeeSession.activeBranchId,
        ),
        builder: (context, row, onTap) => RecordCard(
          title: '${row['first_name'] ?? ''} ${row['last_name'] ?? ''}'.trim(),
          subtitle: '${row['employee_code'] ?? '-'} • ${_relationName(row['positions'])}',
          trailing: '${row['status'] ?? 'Active'}',
          icon: Icons.badge_outlined,
          imageUrl: row['profile_image']?.toString(),
          onTap: onTap,
        ),
      ),
    );
  }

  String _relationName(dynamic relation) {
    if (relation is! Map) return '-';
    return relation['name']?.toString() ??
        relation['branch_name']?.toString() ??
        '-';
  }
}
