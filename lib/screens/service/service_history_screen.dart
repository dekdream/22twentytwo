import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../widgets/data_panel.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/record_cards.dart';

class ServiceHistoryScreen extends StatefulWidget {
  const ServiceHistoryScreen({super.key, this.historyOnly = false});

  final bool historyOnly;

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  Future<void> addService() async {
    final values = await showRecordDialog(
      context,
      title: 'เพิ่มบริการ',
      fields: const [
        FieldConfig('name', 'ชื่อบริการ'),
        FieldConfig('price', 'ราคา', keyboardType: TextInputType.number),
      ],
    );
    if (values == null || values['name']!.isEmpty) return;
    await hrRepository.insert('services', {
      'name': values['name'],
      'price': double.tryParse(values['price'] ?? '') ?? 0,
    });
    if (mounted) setState(() {});
  }

  Future<void> addHistory() async {
    final employees = await hrRepository.listEmployees(
      orderBy: 'first_name',
      branchId: EmployeeSession.activeBranchId,
    );
    final services = await hrRepository.list('services', orderBy: 'name');
    final customers = await hrRepository.listCustomers(
      orderBy: 'first_name',
      branchId: EmployeeSession.activeBranchId,
    );
    if (!mounted) return;
    final values = await _showServiceHistoryDialog(employees, services, customers);
    if (values == null || values['employee_id']!.isEmpty) return;
    await hrRepository.insert('service_history', {
      'employee_id': values['employee_id'],
      'service_id': int.tryParse(values['service_id'] ?? ''),
      'customer_id': int.tryParse(values['customer_id'] ?? ''),
      'customer_name': values['customer_name'],
      'price': double.tryParse(values['price'] ?? '') ?? 0,
      'commission': double.tryParse(values['commission'] ?? '') ?? 0,
    });
    if (mounted) setState(() {});
  }

  Future<Map<String, String>?> _showServiceHistoryDialog(
    List<Map<String, dynamic>> employees,
    List<Map<String, dynamic>> services,
    List<Map<String, dynamic>> customers,
  ) {
    final employee = TextEditingController();
    final service = TextEditingController();
    final customerName = TextEditingController();
    final price = TextEditingController();
    final commission = TextEditingController();
    var isExistingCustomer = false;
    String? customerId;

    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: const Text('เพิ่มประวัติบริการ'),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 420, maxHeight: MediaQuery.sizeOf(context).height * .62),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogSelect('พนักงาน', employee, [for (final item in employees) FieldOption(value: item['id'].toString(), label: _employeeLabel(item))], setDialogState),
                  _dialogSelect('บริการ', service, [for (final item in services) FieldOption(value: item['id'].toString(), label: item['name']?.toString() ?? '-')], setDialogState),
                  DropdownButtonFormField<bool>(
                    value: isExistingCustomer,
                    decoration: const InputDecoration(labelText: 'ประเภทลูกค้า', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: false, child: Text('ลูกค้าใหม่')),
                      DropdownMenuItem(value: true, child: Text('ลูกค้าเก่า')),
                    ],
                    onChanged: (value) => setDialogState(() {
                      isExistingCustomer = value ?? false;
                      customerId = null;
                      customerName.clear();
                    }),
                  ),
                  const SizedBox(height: 10),
                  if (isExistingCustomer)
                    Autocomplete<Map<String, dynamic>>(
                      displayStringForOption: _customerLabel,
                      optionsBuilder: (text) {
                        final query = text.text.trim().toLowerCase();
                        if (query.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
                        return customers.where((item) => _customerLabel(item).toLowerCase().contains(query));
                      },
                      onSelected: (item) => setDialogState(() {
                        customerId = item['id'].toString();
                        customerName.text = _customerLabel(item);
                      }),
                      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                        if (customerName.text.isNotEmpty && controller.text.isEmpty) controller.text = customerName.text;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(labelText: 'ค้นหาชื่อลูกค้า', hintText: 'พิมพ์ชื่อหรือเบอร์โทร', border: OutlineInputBorder()),
                          onChanged: (_) => setDialogState(() => customerId = null),
                        );
                      },
                    )
                  else
                    TextField(controller: customerName, decoration: const InputDecoration(labelText: 'ชื่อลูกค้าใหม่', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ราคา', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: commission, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ค่าคอม', border: OutlineInputBorder())),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: const Text('ยกเลิก')),
            FilledButton(
              onPressed: isExistingCustomer && customerId == null
                  ? null
                  : () => Navigator.of(context, rootNavigator: true).pop({
                        'employee_id': employee.text,
                        'service_id': service.text,
                        'customer_id': customerId ?? '',
                        'customer_name': customerName.text,
                        'price': price.text,
                        'commission': commission.text,
                      }),
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      employee.dispose();
      service.dispose();
      customerName.dispose();
      price.dispose();
      commission.dispose();
    });
  }

  Widget _dialogSelect(String label, TextEditingController controller, List<FieldOption> options, StateSetter setDialogState) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonFormField<String>(
          value: controller.text.isEmpty ? null : controller.text,
          isExpanded: true,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          items: [for (final option in options) DropdownMenuItem(value: option.value, child: Text(option.label))],
          onChanged: (value) => setDialogState(() => controller.text = value ?? ''),
        ),
      );

  static String _customerLabel(Map<String, dynamic> customer) {
    final name = '${customer['first_name'] ?? ''} ${customer['last_name'] ?? ''}'.trim();
    final phone = customer['phone']?.toString() ?? '';
    return phone.isEmpty ? name : '$name ($phone)';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.historyOnly) {
      return HrPage(
        title: 'ประวัติบริการ',
        subtitle: '',
        action: FilledButton.icon(
          onPressed: addHistory,
          icon: const Icon(Icons.receipt_long_outlined),
          label: const Text('เพิ่มประวัติบริการ'),
        ),
        child: DataPanel(
          future: hrRepository.listWithEmployee(
            'service_history',
            orderBy: 'service_date',
            branchId: EmployeeSession.activeBranchId,
          ),
          columns: const [
            DataColumn(label: Text('วันที่')),
            DataColumn(label: Text('พนักงาน')),
            DataColumn(label: Text('สาขา')),
            DataColumn(label: Text('บริการ')),
            DataColumn(label: Text('ลูกค้า')),
            DataColumn(label: Text('ราคา')),
            DataColumn(label: Text('ค่าคอม')),
          ],
          rowBuilder: _historyRow,
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;

    return HrPage(
      title: 'บริการ',
      subtitle: 'รายการบริการ ประวัติการขาย และค่าคอมต่อรายการ',
      action: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: addService,
            icon: const Icon(Icons.add),
            label: const Text('เพิ่มบริการ'),
          ),
          FilledButton.icon(
            onPressed: addHistory,
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('เพิ่มประวัติ'),
          ),
        ],
      ),
      child: ListView(
        children: [
          Wrap(
            spacing: 18,
            runSpacing: 18,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              _Section(
                title: 'รายการบริการ',
                width: (width - 28).clamp(280, 430).toDouble(),
                height: 260,
                child: DataPanel(
                  future: hrRepository.list('services', orderBy: 'id'),
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('ชื่อบริการ')),
                    DataColumn(label: Text('ราคา')),
                  ],
                  rowBuilder: (row) => [
                    DataCell(Text('${row['id']}')),
                    DataCell(Text('${row['name'] ?? ''}')),
                    DataCell(Text('${row['price'] ?? 0}')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _Section(
            title: 'ประวัติบริการ',
            height: 300,
            child: DataPanel(
              future: hrRepository.listWithEmployee(
                'service_history',
                orderBy: 'service_date',
                branchId: EmployeeSession.activeBranchId,
              ),
              columns: const [
                DataColumn(label: Text('วันที่')),
                DataColumn(label: Text('พนักงาน')),
                DataColumn(label: Text('สาขา')),
                DataColumn(label: Text('บริการ')),
                DataColumn(label: Text('ลูกค้า')),
                DataColumn(label: Text('ราคา')),
                DataColumn(label: Text('ค่าคอม')),
              ],
              rowBuilder: _historyRow,
            ),
          ),
        ],
      ),
    );
  }

  static String _shortDate(Object? value) {
    final text = value?.toString() ?? '';
    if (text.length <= 16) return text;
    return text.substring(0, 16).replaceFirst('T', ' ');
  }

  static List<DataCell> _historyRow(Map<String, dynamic> row) => [
        DataCell(Text(_shortDate(row['service_date']))),
        DataCell(Text(employeeDisplayName(row))),
        DataCell(Text(employeeBranchName(row))),
        DataCell(Text('${row['service_id'] ?? '-'}')),
        DataCell(Text('${row['customer_name'] ?? ''}')),
        DataCell(Text('${row['price'] ?? 0}')),
        DataCell(Text('${row['commission'] ?? 0}')),
      ];

  static String _employeeLabel(Map<String, dynamic> employee) {
    final name = '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'
        .trim();
    final code = employee['employee_code']?.toString() ?? '-';
    return name.isEmpty ? code : '$name ($code)';
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    required this.height,
    this.width,
  });

  final String title;
  final Widget child;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xff2b2025),
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(height: height, child: child),
      ],
    );

    if (width == null) return content;
    return SizedBox(width: width, child: content);
  }
}
