import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/record_cards.dart';

class CommissionScreen extends StatefulWidget {
  const CommissionScreen({super.key});

  @override
  State<CommissionScreen> createState() => _CommissionScreenState();
}

class _CommissionScreenState extends State<CommissionScreen> {
  Future<void> addCommission() async {
    final employees = await hrRepository.listEmployees(
      orderBy: 'first_name',
      branchId: EmployeeSession.activeBranchId,
    );
    if (!mounted) return;
    final values = await showRecordDialog(
      context,
      title: 'Add Commission',
      fields: [
        FieldConfig('employee_id', 'Employee', options: [
          for (final employee in employees)
            FieldOption(
              value: employee['id'].toString(),
              label: _employeeLabel(employee),
            ),
        ]),
        FieldConfig('month', 'Month', keyboardType: TextInputType.number),
        FieldConfig('year', 'Year', keyboardType: TextInputType.number),
        FieldConfig('total_sales', 'Total Sales',
            keyboardType: TextInputType.number),
        FieldConfig('commission_percent', 'Commission Percent',
            keyboardType: TextInputType.number),
      ],
    );
    if (values == null || values['employee_id']!.isEmpty) return;
    final totalSales = double.tryParse(values['total_sales'] ?? '') ?? 0;
    final percent = double.tryParse(values['commission_percent'] ?? '') ?? 0;
    await hrRepository.insert('commission', {
      'employee_id': values['employee_id'],
      'month': int.tryParse(values['month'] ?? '') ?? DateTime.now().month,
      'year': int.tryParse(values['year'] ?? '') ?? DateTime.now().year,
      'total_sales': totalSales,
      'commission_percent': percent,
      'commission_amount': totalSales * percent / 100,
    });
    setState(() {});
  }

  static String _employeeLabel(Map<String, dynamic> employee) {
    final name = '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'
        .trim();
    final code = employee['employee_code']?.toString() ?? '-';
    return name.isEmpty ? code : '$name ($code)';
  }

  @override
  Widget build(BuildContext context) {
    return HrPage(
      title: 'Commissions',
      subtitle: 'สรุปยอดขายและค่าคอมมิชชั่นพนักงานรายเดือน',
      action: FilledButton.icon(
        onPressed: addCommission,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      child: RecordCards(
        tableName: 'commission',
        onChanged: () => setState(() {}),
        future: hrRepository.listWithEmployee(
          'commission',
          orderBy: 'year',
          branchId: EmployeeSession.activeBranchId,
        ),
        columns: const [
          DataColumn(label: Text('Employee')),
          DataColumn(label: Text('Period')),
          DataColumn(label: Text('Sales')),
          DataColumn(label: Text('Percent')),
          DataColumn(label: Text('Amount')),
        ],
        builder: (context, row, onTap) => RecordCard(
          title: employeeDisplayName(row),
          subtitle: '${row['month'] ?? '-'}/${row['year'] ?? '-'} • ยอดขาย ฿${row['total_sales'] ?? 0}',
          trailing: '฿${row['commission_amount'] ?? 0}',
          icon: Icons.percent_outlined,
          onTap: onTap,
        ),
      ),
    );
  }
}
