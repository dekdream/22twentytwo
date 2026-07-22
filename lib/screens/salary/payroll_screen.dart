import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/record_cards.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  Future<void> addPayroll() async {
    final values = await _showPayrollDialog(context);
    if (values == null || values['employee_id']!.isEmpty) return;

    final basic = double.tryParse(values['basic_salary'] ?? '') ?? 0;
    final overtime = double.tryParse(values['overtime'] ?? '') ?? 0;
    final bonus = double.tryParse(values['bonus'] ?? '') ?? 0;
    final deduction = double.tryParse(values['deduction'] ?? '') ?? 0;

    await hrRepository.insert('payroll', {
      'employee_id': values['employee_id'],
      'month': int.tryParse(values['month'] ?? '') ?? DateTime.now().month,
      'year': int.tryParse(values['year'] ?? '') ?? DateTime.now().year,
      'basic_salary': basic,
      'overtime': overtime,
      'bonus': bonus,
      'deduction': deduction,
      'total_salary': basic + overtime + bonus - deduction,
      'payment_date': DateTime.now().toIso8601String().substring(0, 10),
    });
    setState(() {});
  }

  Future<Map<String, String>?> _showPayrollDialog(BuildContext context) async {
    final employees = await hrRepository.listEmployees(
      orderBy: 'first_name',
      branchId: EmployeeSession.activeBranchId,
    );
    if (!context.mounted) return null;

    final monthController =
        TextEditingController(text: DateTime.now().month.toString());
    final yearController =
        TextEditingController(text: DateTime.now().year.toString());
    final basicController = TextEditingController();
    final overtimeController = TextEditingController(text: '0');
    final bonusController = TextEditingController(text: '0');
    final deductionController = TextEditingController(text: '0');
    String? selectedEmployeeId;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: const Text('เพิ่มเงินเดือน'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 440,
              maxHeight: MediaQuery.sizeOf(context).height * 0.66,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedEmployeeId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'พนักงาน',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: [
                      for (final employee in employees)
                        DropdownMenuItem(
                          value: employee['id']?.toString(),
                          child: Text(_employeeLabel(employee)),
                        ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => selectedEmployeeId = value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: monthController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'เดือน'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: yearController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'ปี'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: basicController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'เงินเดือนพื้นฐาน'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: overtimeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'โอที'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bonusController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'โบนัส'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deductionController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'หักเงิน'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: selectedEmployeeId == null
                  ? null
                  : () => Navigator.pop(context, {
                        'employee_id': selectedEmployeeId!,
                        'month': monthController.text.trim(),
                        'year': yearController.text.trim(),
                        'basic_salary': basicController.text.trim(),
                        'overtime': overtimeController.text.trim(),
                        'bonus': bonusController.text.trim(),
                        'deduction': deductionController.text.trim(),
                      }),
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );

    monthController.dispose();
    yearController.dispose();
    basicController.dispose();
    overtimeController.dispose();
    bonusController.dispose();
    deductionController.dispose();
    return result;
  }

  static String _employeeLabel(Map<String, dynamic> employee) {
    final code = employee['employee_code']?.toString() ?? '-';
    final firstName = employee['first_name']?.toString() ?? '';
    final lastName = employee['last_name']?.toString() ?? '';
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? code : '$name ($code)';
  }

  @override
  Widget build(BuildContext context) {
    return HrPage(
      title: 'เงินเดือน',
      subtitle: 'คำนวณเงินเดือน โบนัส หักเงิน และวันที่จ่าย',
      action: FilledButton.icon(
        onPressed: addPayroll,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่ม'),
      ),
      child: RecordCards(
        tableName: 'payroll',
        onChanged: () => setState(() {}),
        future: hrRepository.listPayroll(
          orderBy: 'year',
          branchId: EmployeeSession.activeBranchId,
        ),
        columns: const [
          DataColumn(label: Text('พนักงาน')),
          DataColumn(label: Text('รอบ')),
          DataColumn(label: Text('พื้นฐาน')),
          DataColumn(label: Text('โบนัส')),
          DataColumn(label: Text('หักเงิน')),
          DataColumn(label: Text('รวม')),
        ],
        builder: (context, row, onTap) => RecordCard(
          title: employeeDisplayName(row),
          subtitle: '${row['month'] ?? '-'}/${row['year'] ?? '-'} • เงินเดือนพื้นฐาน ฿${row['basic_salary'] ?? 0}',
          trailing: '฿${row['total_salary'] ?? 0}',
          icon: Icons.payments_outlined,
          onTap: onTap,
        ),
      ),
    );
  }
}
