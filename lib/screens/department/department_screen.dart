import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/record_cards.dart';

class DepartmentScreen extends StatefulWidget {
  const DepartmentScreen({super.key});

  @override
  State<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends State<DepartmentScreen> {
  Future<void> addDepartment() async {
    final values = await showRecordDialog(
      context,
      title: 'Add Department',
      fields: const [
        FieldConfig('name', 'Name'),
        FieldConfig('description', 'Description', maxLines: 3)
      ],
    );
    if (values == null || values['name']!.isEmpty) return;
    await hrRepository.insert('departments', values);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return HrPage(
      title: 'Departments',
      subtitle: 'จัดการหน่วยงานและโครงสร้างองค์กร',
      action: FilledButton.icon(
          onPressed: addDepartment,
          icon: const Icon(Icons.add),
          label: const Text('Add')),
      child: RecordCards(
        tableName: 'departments',
        onChanged: () => setState(() {}),
        future: hrRepository.list('departments', orderBy: 'id'),
        builder: (context, row, onTap) => RecordCard(
          title: '${row['name'] ?? '-'}',
          subtitle: '${row['description'] ?? 'ไม่มีคำอธิบาย'}',
          trailing: '#${row['id'] ?? '-'}',
          icon: Icons.apartment_outlined,
          onTap: onTap,
        ),
      ),
    );
  }
}
