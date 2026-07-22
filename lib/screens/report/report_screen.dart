import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/excel_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/page_scaffold.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late Future<List<Map<String, dynamic>>> _future = _load();
  Future<List<Map<String, dynamic>>> _load() =>
      hrRepository.listServiceReport(branchId: EmployeeSession.activeBranchId);

  @override
  Widget build(BuildContext context) => HrPage(
        title: 'รายงานยอดขาย',
        subtitle: 'ติดตามยอดขายรายวัน รายเดือน พนักงาน และบริการที่ขายดี',
        action: FilledButton.icon(
          onPressed: () async {
            final rows = await _future;
            exportExcel(
                'sales_report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
                ['วันที่', 'พนักงาน', 'บริการ', 'ลูกค้า', 'ยอดขาย', 'ค่าคอม'],
                rows
                    .map((r) => [
                          _date(r['service_date']),
                          employeeDisplayName(r),
                          (r['services'] as Map?)?['name'],
                          r['customer_name'],
                          r['price'],
                          r['commission']
                        ])
                    .toList());
          },
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('Export Excel'),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final rows = snapshot.data!;
            final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
            final month = today.substring(0, 7);
            double sum(Iterable<Map<String, dynamic>> data) => data.fold(0,
                (v, r) => v + (num.tryParse('${r['price']}')?.toDouble() ?? 0));
            final byEmployee = <String, double>{};
            final byService = <String, double>{};
            for (final r in rows) {
              byEmployee.update(
                  employeeDisplayName(r), (v) => v + _money(r['price']),
                  ifAbsent: () => _money(r['price']));
              final service =
                  (r['services'] as Map?)?['name']?.toString() ?? '-';
              byService.update(service, (v) => v + _money(r['price']),
                  ifAbsent: () => _money(r['price']));
            }
            final employees = byEmployee.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            final services = byService.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            return ListView(children: [
              Wrap(spacing: 14, runSpacing: 14, children: [
                _Metric(
                    'ยอดขายวันนี้',
                    sum(rows.where((r) => _date(r['service_date']) == today)),
                    Icons.today),
                _Metric(
                    'ยอดขายเดือนนี้',
                    sum(rows.where(
                        (r) => _date(r['service_date']).startsWith(month))),
                    Icons.calendar_month),
                _Metric('ยอดขายทั้งหมด', sum(rows), Icons.payments_outlined),
                _Metric('จำนวนบริการ', rows.length.toDouble(),
                    Icons.receipt_long_outlined,
                    money: false),
              ]),
              const SizedBox(height: 24),
              _Ranking(title: 'พนักงานทำยอดสูงสุด', entries: employees),
              const SizedBox(height: 18),
              _Ranking(title: 'บริการขายดี', entries: services),
            ]);
          },
        ),
      );

  static double _money(Object? v) => num.tryParse('$v')?.toDouble() ?? 0;
  static String _date(Object? v) =>
      (v ?? '').toString().split('T').first.split(' ').first;
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon, {this.money = true});
  final String label;
  final double value;
  final IconData icon;
  final bool money;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 230,
      child: Card(
          child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Icon(icon, color: const Color(0xffd4537e)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label, style: const TextStyle(color: Colors.grey)),
                Text(
                    money
                        ? '฿${NumberFormat('#,##0.00').format(value)}'
                        : value.toInt().toString(),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold))
              ]))
        ]),
      )));
}

class _Ranking extends StatelessWidget {
  const _Ranking({required this.title, required this.entries});
  final String title;
  final List<MapEntry<String, double>> entries;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const Text('ยังไม่มีข้อมูล')
            else
              for (var i = 0; i < entries.take(10).length; i++)
                ListTile(
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(entries[i].key),
                    trailing: Text(
                        '฿${NumberFormat('#,##0.00').format(entries[i].value)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)))
          ])));
}
