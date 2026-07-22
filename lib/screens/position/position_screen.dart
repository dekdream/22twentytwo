import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/record_cards.dart';

class PositionScreen extends StatefulWidget {
  const PositionScreen({super.key});

  @override
  State<PositionScreen> createState() => _PositionScreenState();
}

class _PositionScreenState extends State<PositionScreen> {
  Future<void> addPosition() async {
    final departments = await hrRepository.list('departments', orderBy: 'name');
    if (!mounted) return;
    final values = await showRecordDialog(
      context,
      title: 'Add Position',
      fields: [
        FieldConfig('department_id', 'Department', options: [
          for (final department in departments)
            FieldOption(
              value: department['id'].toString(),
              label: department['name']?.toString() ?? '-',
            ),
        ]),
        FieldConfig('name', 'Name'),
        FieldConfig('salary', 'Salary', keyboardType: TextInputType.number),
      ],
    );
    if (values == null || values['name']!.isEmpty) return;
    await hrRepository.insert('positions', {
      'department_id': int.tryParse(values['department_id'] ?? ''),
      'name': values['name'],
      'salary': double.tryParse(values['salary'] ?? '') ?? 0,
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return HrPage(
      title: 'Positions',
      subtitle: 'จัดการตำแหน่งงานและฐานเงินเดือน',
      action: FilledButton.icon(
          onPressed: addPosition,
          icon: const Icon(Icons.add),
          label: const Text('Add')),
      child: RecordCards(
        tableName: 'positions',
        onChanged: () => setState(() {}),
        future: hrRepository.list('positions', orderBy: 'id'),
        builder: (context, row, onTap) => RecordCard(
          title: '${row['name'] ?? '-'}',
          subtitle: 'แผนก #${row['department_id'] ?? '-'}',
          trailing: '฿${row['salary'] ?? 0}',
          icon: Icons.work_outline,
          onTap: onTap,
        ),
      ),
    );
  }
}
