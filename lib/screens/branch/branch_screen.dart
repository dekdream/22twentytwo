import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/record_cards.dart';

class BranchScreen extends StatefulWidget {
  const BranchScreen({super.key});

  @override
  State<BranchScreen> createState() => _BranchScreenState();
}

class _BranchScreenState extends State<BranchScreen> {
  Future<void> _addBranch() async {
    final values = await showRecordDialog(
      context,
      title: 'เพิ่มสาขา',
      fields: const [
        FieldConfig('branch_code', 'รหัสสาขา'),
        FieldConfig('branch_name', 'ชื่อสาขา'),
        FieldConfig('address', 'ที่อยู่', maxLines: 2),
        FieldConfig('phone', 'เบอร์โทรศัพท์'),
        FieldConfig('manager_name', 'ผู้จัดการสาขา'),
      ],
    );
    if (values == null ||
        values['branch_code']!.isEmpty ||
        values['branch_name']!.isEmpty) {
      return;
    }
    await hrRepository.insert('branches', {...values, 'status': 'Active'});
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => HrPage(
        title: 'สาขา',
        subtitle: 'จัดการข้อมูลสาขาและผู้รับผิดชอบ',
        action: EmployeeSession.isOwner
            ? FilledButton.icon(
                onPressed: _addBranch,
                icon: const Icon(Icons.add),
                label: const Text('เพิ่มสาขา'),
              )
            : null,
        child: RecordCards(
          tableName: 'branches',
          onChanged: () => setState(() {}),
          canManage: EmployeeSession.isOwner,
          future: hrRepository.listBranches(
            orderBy: 'branch_code',
            branchId: EmployeeSession.activeBranchId,
          ),
          columns: const [
            DataColumn(label: Text('รหัสสาขา')),
            DataColumn(label: Text('ชื่อสาขา')),
            DataColumn(label: Text('ที่อยู่')),
            DataColumn(label: Text('โทรศัพท์')),
            DataColumn(label: Text('ผู้จัดการ')),
            DataColumn(label: Text('สถานะ')),
          ],
          builder: (context, row, onTap) => RecordCard(
            title: '${row['branch_name'] ?? '-'}',
            subtitle: '${row['branch_code'] ?? '-'} • ${row['manager_name'] ?? '-'}',
            trailing: '${row['status'] ?? 'Active'}',
            icon: Icons.store_outlined,
            onTap: onTap,
          ),
        ),
      );
}
