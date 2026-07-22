import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../widgets/form_dialog.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  late Future<_CustomerData> _dataFuture;
  String _query = '';
  String _level = 'ทั้งหมด';

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
    EmployeeSession.branchScopeNotifier.addListener(_reloadForBranch);
  }

  @override
  void dispose() {
    EmployeeSession.branchScopeNotifier.removeListener(_reloadForBranch);
    super.dispose();
  }

  void _reloadForBranch() {
    if (mounted) setState(() => _dataFuture = _load());
  }

  Future<_CustomerData> _load() async {
    final result = await Future.wait([
      hrRepository.listCustomers(
        orderBy: 'created_at',
        branchId: EmployeeSession.activeBranchId,
      ),
      hrRepository.listWithEmployee(
        'service_history',
        orderBy: 'service_date',
        branchId: EmployeeSession.activeBranchId,
      ),
    ]);
    return _CustomerData(
      customers: result[0],
      histories: result[1],
    );
  }

  Future<void> _addCustomer() async {
    final branches = await hrRepository.listBranches(
      orderBy: 'branch_code',
      branchId: EmployeeSession.activeBranchId,
    );
    if (!mounted) return;
    final values = await showRecordDialog(
      context,
      title: 'เพิ่มลูกค้าใหม่',
      fields: [
        const FieldConfig('customer_code', 'รหัสลูกค้า'),
        const FieldConfig('first_name', 'ชื่อ'),
        const FieldConfig('last_name', 'นามสกุล'),
        const FieldConfig('phone', 'เบอร์โทรศัพท์', keyboardType: TextInputType.phone),
        const FieldConfig('email', 'อีเมล', keyboardType: TextInputType.emailAddress),
        FieldConfig('branch_id', 'สาขา', options: [
          for (final branch in branches)
            FieldOption(
              value: branch['id'].toString(),
              label: '${branch['branch_code'] ?? ''} - ${branch['branch_name'] ?? '-'}',
            ),
        ]),
        const FieldConfig('member_level', 'ระดับสมาชิก (Silver / Gold / Platinum)'),
        const FieldConfig('points', 'แต้มสะสม', keyboardType: TextInputType.number),
      ],
    );
    if (values == null || values['customer_code']!.isEmpty || values['first_name']!.isEmpty || values['last_name']!.isEmpty) return;
    await hrRepository.insert('customers', {
      ...values,
      'branch_id': int.tryParse(values['branch_id'] ?? ''),
      'member_level': values['member_level']!.isEmpty ? 'Silver' : values['member_level'],
      'points': int.tryParse(values['points'] ?? '') ?? 0,
    });
    if (mounted) setState(() => _dataFuture = _load());
  }

  Future<void> _editCustomer(Map<String, dynamic> customer) async {
    final values = await showRecordDialog(
      context,
      title: 'Edit customer',
      initialValues: customer,
      fields: const [
        FieldConfig('customer_code', 'Customer Code'),
        FieldConfig('first_name', 'First Name'),
        FieldConfig('last_name', 'Last Name'),
        FieldConfig('phone', 'Phone'),
        FieldConfig('email', 'Email'),
        FieldConfig('member_level', 'Member Level'),
        FieldConfig('points', 'Points', keyboardType: TextInputType.number),
      ],
    );
    if (values == null) return;
    await hrRepository.update('customers', customer['id'], {
      ...values,
      'points': int.tryParse(values['points'] ?? '') ?? 0,
    });
    if (mounted) setState(() => _dataFuture = _load());
  }

  Future<void> _deleteCustomer(Map<String, dynamic> customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete customer?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await hrRepository.delete('customers', customer['id']);
    if (mounted) setState(() => _dataFuture = _load());
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          color: const Color(0xfffffcfa),
          child: FutureBuilder<_CustomerData>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text('โหลดข้อมูลลูกค้าไม่สำเร็จ: ${snapshot.error}'));
              return _CustomerContent(
                data: snapshot.data ?? const _CustomerData(),
                query: _query,
                level: _level,
                onQueryChanged: (value) => setState(() => _query = value),
                onLevelChanged: (value) => setState(() => _level = value ?? 'ทั้งหมด'),
                onAddCustomer: _addCustomer,
                onEditCustomer: _editCustomer,
                onDeleteCustomer: _deleteCustomer,
              );
            },
          ),
        ),
      );
}

class _CustomerContent extends StatelessWidget {
  const _CustomerContent({required this.data, required this.query, required this.level, required this.onQueryChanged, required this.onLevelChanged, required this.onAddCustomer, required this.onEditCustomer, required this.onDeleteCustomer});
  final _CustomerData data;
  final String query;
  final String level;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String?> onLevelChanged;
  final VoidCallback onAddCustomer;
  final ValueChanged<Map<String, dynamic>> onEditCustomer;
  final ValueChanged<Map<String, dynamic>> onDeleteCustomer;

  @override
  Widget build(BuildContext context) {
    final lowerQuery = query.trim().toLowerCase();
    final customers = data.customers.where((customer) {
      final name = '${customer['first_name'] ?? ''} ${customer['last_name'] ?? ''}'.toLowerCase();
      final phone = customer['phone']?.toString() ?? '';
      return (lowerQuery.isEmpty || name.contains(lowerQuery) || phone.contains(lowerQuery)) &&
          (level == 'ทั้งหมด' || customer['member_level']?.toString() == level);
    }).toList();
    final now = DateTime.now();
    final joinedThisMonth = data.customers.where((customer) {
      final created = DateTime.tryParse(customer['created_at']?.toString() ?? '');
      return created != null && created.year == now.year && created.month == now.month;
    }).length;
    final vipCount = data.customers.where((customer) => ['Gold', 'Platinum'].contains(customer['member_level'])).length;
    final points = data.customers.fold<num>(0, (sum, customer) => sum + ((customer['points'] as num?) ?? 0));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('จัดการลูกค้า', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Wrap(spacing: 18, runSpacing: 18, children: [
              _MetricCard(icon: Icons.groups_2_outlined, label: 'ลูกค้าทั้งหมด', value: '${data.customers.length}'),
              _MetricCard(icon: Icons.star_rounded, label: 'ลูกค้า VIP', value: '$vipCount', iconColor: const Color(0xffd9a710)),
              _MetricCard(icon: Icons.calendar_month_outlined, label: 'เข้าร้านเดือนนี้', value: '$joinedThisMonth', iconColor: const Color(0xffd4537e)),
              _MetricCard(icon: Icons.workspace_premium_outlined, label: 'ยอดสะสมรวม', value: '${points.toInt()} P', highlight: true),
            ]),
            const SizedBox(height: 28),
            _CustomerFilters(level: level, onQueryChanged: onQueryChanged, onLevelChanged: onLevelChanged, onAddCustomer: onAddCustomer),
            const SizedBox(height: 22),
            _CustomerTable(customers: customers, histories: data.histories, onEdit: onEditCustomer, onDelete: onDeleteCustomer),
          ]),
        ),
      ),
    );
  }

}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.label, required this.value, this.iconColor, this.highlight = false});
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final bool highlight;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: MediaQuery.sizeOf(context).width < 520
            ? (MediaQuery.sizeOf(context).width - 66) / 2
            : 260,
        height: 122,
        child: Card(
          color: highlight ? const Color(0xffb53b67) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(icon, size: 19, color: highlight ? const Color(0xffffd7e4) : (iconColor ?? const Color(0xffd4537e))),
                const SizedBox(width: 7),
                Expanded(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: MediaQuery.sizeOf(context).width < 520 ? 11 : 14, color: highlight ? const Color(0xffffd7e4) : const Color(0xff714858)))),
              ]),
              const SizedBox(height: 11),
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: highlight ? Colors.white : const Color(0xff282126))),
            ]),
          ),
        ),
      );
}

class _CustomerFilters extends StatelessWidget {
  const _CustomerFilters({required this.level, required this.onQueryChanged, required this.onLevelChanged, required this.onAddCustomer});
  final String level;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String?> onLevelChanged;
  final VoidCallback onAddCustomer;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: compact ? constraints.maxWidth : 420,
                child: TextField(
                  onChanged: onQueryChanged,
                  decoration: const InputDecoration(
                    hintText: 'ค้นหาชื่อ หรือเบอร์โทร...',
                    prefixIcon: Icon(Icons.search, color: Color(0xff8a5b87)),
                  ),
                ),
              ),
              _FilterSelect(value: level, values: const ['ทั้งหมด', 'Silver', 'Gold', 'Platinum'], onChanged: onLevelChanged),
              FilledButton.icon(onPressed: onAddCustomer, icon: const Icon(Icons.add), label: const Text('เพิ่มลูกค้าใหม่')),
            ],
          );
        },
      );
}

class _FilterSelect extends StatelessWidget {
  const _FilterSelect({required this.value, required this.values, required this.onChanged});
  final String value;
  final List<String> values;
  final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(width: 180, child: DropdownButtonFormField<String>(value: value, isExpanded: true, items: values.map((item) => DropdownMenuItem(value: item, child: Text(item, overflow: TextOverflow.ellipsis))).toList(), onChanged: onChanged));
}

class _CustomerTable extends StatelessWidget {
  const _CustomerTable({required this.customers, required this.histories, required this.onEdit, required this.onDelete});
  final List<Map<String, dynamic>> customers;
  final List<Map<String, dynamic>> histories;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final customer = customers[index];
        final history = _latestHistory(customer['id']);
        final name = '${customer['first_name'] ?? ''} ${customer['last_name'] ?? ''}'.trim();
        return Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(name.isEmpty ? 'รายละเอียดลูกค้า' : name),
                content: Text('โทรศัพท์: ${customer['phone'] ?? '-'}\nระดับสมาชิก: ${customer['member_level'] ?? 'Silver'}\nแต้มสะสม: ${customer['points'] ?? 0} P\nบริการล่าสุด: ${history?['service_id'] ?? '-'}'),
                actions: [TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: const Text('ปิด'))],
              ),
            ),
            leading: const CircleAvatar(backgroundColor: Color(0xfffff0f5), child: Icon(Icons.person_outline, color: Color(0xffd4537e))),
            title: Text(name.isEmpty ? '-' : name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${customer['phone'] ?? '-'} • ${customer['member_level'] ?? 'Silver'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${customer['points'] ?? 0} P', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xffd4537e))),
                PopupMenuButton<String>(
                  onSelected: (action) => action == 'edit' ? onEdit(customer) : onDelete(customer),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _legacyBuild(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _ResponsiveCustomerTable(
            child: DataTable(
              columnSpacing: 34,
              horizontalMargin: 18,
              headingRowColor: WidgetStateProperty.all(const Color(0xffffeff4)),
              headingTextStyle: const TextStyle(color: Color(0xff993556), fontWeight: FontWeight.w700),
              columns: const [DataColumn(label: Text('ชื่อลูกค้า')), DataColumn(label: Text('เบอร์โทร')), DataColumn(label: Text('ประเภท')), DataColumn(label: Text('สาขา')), DataColumn(label: Text('บริการที่ชอบ')), DataColumn(label: Text('เข้าร้านล่าสุด')), DataColumn(label: Text('ยอดสะสม'))],
              rows: customers.map((customer) {
                final history = _latestHistory(customer['id']);
                final branch = customer['branches'];
                return DataRow(cells: [
                  DataCell(Text('${customer['first_name'] ?? ''} ${customer['last_name'] ?? ''}')),
                  DataCell(Text('${customer['phone'] ?? '-'}')),
                  DataCell(Text('${customer['member_level'] ?? 'Silver'}')),
                  DataCell(Text(branch is Map ? branch['branch_name']?.toString() ?? '-' : '-')),
                  DataCell(Text(history == null ? '-' : 'บริการ #${history['service_id'] ?? '-'}')),
                  DataCell(Text(_shortDate(history?['service_date']))),
                  DataCell(Text('${customer['points'] ?? 0} P')),
                ]);
              }).toList(),
            ),
        ),
      )
      );

  Map<String, dynamic>? _latestHistory(Object? customerId) {
    final matching = histories.where((item) => item['customer_id']?.toString() == customerId?.toString());
    return matching.isEmpty ? null : matching.last;
  }

  String _shortDate(Object? value) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? '-' : text.substring(0, text.length < 10 ? text.length : 10);
  }
}

class _ResponsiveCustomerTable extends StatelessWidget {
  const _ResponsiveCustomerTable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 520) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topLeft,
        child: child,
      );
    }
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: child);
  }
}

class _CustomerData {
  const _CustomerData({this.customers = const [], this.histories = const []});
  final List<Map<String, dynamic>> customers;
  final List<Map<String, dynamic>> histories;
}
