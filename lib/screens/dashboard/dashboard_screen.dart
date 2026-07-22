import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          color: const Color(0xfffffcfa),
          child: FutureBuilder<_DashboardData>(
            future: _loadDashboard(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('โหลดข้อมูลภาพรวมไม่สำเร็จ: ${snapshot.error}'));
              }
              return _DashboardContent(
                data: snapshot.data ?? const _DashboardData(),
                storeMode: EmployeeSession.isStoreManagement,
              );
            },
          ),
        ),
      );

  Future<_DashboardData> _loadDashboard() async {
    final result = await Future.wait([
      hrRepository.listBranches(
        orderBy: 'branch_code',
        branchId: EmployeeSession.activeBranchId,
      ),
      hrRepository.listWithEmployee(
        'attendance',
        orderBy: 'work_date',
        branchId: EmployeeSession.activeBranchId,
      ),
      hrRepository.listWithEmployee(
        'service_history',
        orderBy: 'service_date',
        branchId: EmployeeSession.activeBranchId,
      ),
    ]);
    final now = DateTime.now();
    final day = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final attendance = result[1]
        .where((row) => row['work_date']?.toString() == day && row['status']?.toString() == 'Present')
        .toList();
    final services = result[2]
        .where((row) => row['service_date']?.toString().startsWith(day) ?? false)
        .toList();
    final sales = services.fold<num>(0, (sum, row) => sum + ((row['price'] as num?) ?? 0));
    final commission = services.fold<num>(
      0,
      (sum, row) => sum + ((row['commission'] as num?) ?? 0),
    );
    final customers = services
        .map((row) => row['customer_id'] ?? row['customer_name'])
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .toSet()
        .length;
    return _DashboardData(
      branches: result[0],
      attendance: attendance,
      servicesToday: services,
      salesToday: sales,
      commissionToday: commission,
      customersToday: customers,
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data, required this.storeMode});
  final _DashboardData data;
  final bool storeMode;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                final cardWidth = compact
                    ? (constraints.maxWidth - 14) / 2
                    : (constraints.maxWidth - 42) / 4;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroCard(sales: data.salesToday, compact: compact),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        _MetricCard(width: cardWidth, icon: Icons.receipt_long_outlined, label: 'รายการบริการ', value: '${data.servicesToday.length}', color: const Color(0xffd18a28)),
                        if (storeMode) ...[
                          _MetricCard(width: cardWidth, icon: Icons.groups_2_outlined, label: 'ลูกค้าวันนี้', value: '${data.customersToday}', color: const Color(0xffd4537e)),
                          _MetricCard(width: cardWidth, icon: Icons.percent_outlined, label: 'ค่าคอมวันนี้', value: '${data.commissionToday.toStringAsFixed(0)} ฿', color: const Color(0xffd4537e)),
                        ] else ...[
                          _MetricCard(width: cardWidth, icon: Icons.groups_2_outlined, label: 'พนักงานเข้างาน', value: '${data.attendance.length}', color: const Color(0xffd4537e)),
                          _MetricCard(width: cardWidth, icon: Icons.storefront_outlined, label: 'สาขาที่ใช้งาน', value: '${data.branches.length}', color: const Color(0xff2d9c83)),
                        ],
                        _MetricCard(width: cardWidth, icon: Icons.payments_outlined, label: 'ยอดขายวันนี้', value: '${data.salesToday.toStringAsFixed(0)} ฿', color: const Color(0xffb53663), tint: true),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _SectionTitle(title: 'ภาพรวมสาขา', subtitle: 'การเข้างานและจำนวนบริการของวันนี้'),
                    const SizedBox(height: 12),
                    _BranchOverview(branches: data.branches, attendance: data.attendance, services: data.servicesToday),
                    const SizedBox(height: 30),
                    _SectionTitle(title: 'รายการบริการล่าสุดวันนี้', subtitle: 'อัปเดตจากประวัติบริการ'),
                    const SizedBox(height: 12),
                    _RecentServices(items: data.servicesToday),
                  ],
                );
              },
            ),
          ),
        ),
      );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.sales, required this.compact});
  final num sales;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 20 : 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xffd4537e), Color(0xffa9345e)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ภาพรวมธุรกิจวันนี้', style: TextStyle(color: Color(0xfffff0f5), fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text('${sales.toStringAsFixed(0)} ฿', style: TextStyle(color: Colors.white, fontSize: compact ? 32 : 40, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('ยอดขายจากรายการบริการของวันนี้', style: TextStyle(color: Color(0xfffff0f5))),
          ])),
          if (!compact)
            Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.insights_outlined, color: Colors.white, size: 34)),
        ]),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.width, required this.icon, required this.label, required this.value, required this.color, this.tint = false});
  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool tint;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: 132,
        child: Card(
          margin: EdgeInsets.zero,
          color: tint ? const Color(0xffffedf3) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
              const Spacer(),
              Text(value, style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: tint ? const Color(0xff8f2c50) : const Color(0xff28223a))),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xff8a8497))),
            ]),
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xff28223a))), const SizedBox(height: 2), Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xff8a8497)))]);
}

class _BranchOverview extends StatelessWidget {
  const _BranchOverview({required this.branches, required this.attendance, required this.services});
  final List<Map<String, dynamic>> branches;
  final List<Map<String, dynamic>> attendance;
  final List<Map<String, dynamic>> services;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: branches.isEmpty
            ? const _DashboardEmpty(message: 'ยังไม่มีข้อมูลสาขา')
            : Column(children: [
                for (final branch in branches)
                  ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xfffff0f5), child: Icon(Icons.storefront_outlined, color: Color(0xffd4537e))),
                    title: Text(branch['branch_name']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(branch['branch_code']?.toString() ?? ''),
                    trailing: Wrap(spacing: 14, children: [
                      _Count(label: 'เข้างาน', value: attendance.where((row) => employeeBranchName(row) == branch['branch_name']).length),
                      _Count(label: 'บริการ', value: services.where((row) => employeeBranchName(row) == branch['branch_name']).length),
                    ]),
                  ),
              ]),
      );
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [Text('$value', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), Text(label, style: const TextStyle(fontSize: 10, color: Color(0xff8a8497)))]);
}

class _RecentServices extends StatelessWidget {
  const _RecentServices({required this.items});
  final List<Map<String, dynamic>> items;
  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: items.isEmpty
            ? const _DashboardEmpty(message: 'ยังไม่มีรายการบริการวันนี้')
            : Column(children: [
                for (final item in items.take(6))
                  ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xffffedf3), child: Icon(Icons.content_cut_outlined, color: Color(0xffb53663))),
                    title: Text(item['customer_name']?.toString().isNotEmpty == true ? item['customer_name'].toString() : 'ลูกค้าหน้าร้าน'),
                    subtitle: Text(employeeDisplayName(item)),
                    trailing: Text('${item['price'] ?? 0} ฿', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xff8f2c50))),
                  ),
              ]),
      );
}

class _DashboardEmpty extends StatelessWidget {
  const _DashboardEmpty({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.inbox_outlined, size: 38, color: Color(0xffb4adbd)), const SizedBox(height: 8), Text(message, style: const TextStyle(color: Color(0xff8a8497)))])),
      );
}

class _DashboardData {
  const _DashboardData({this.branches = const [], this.attendance = const [], this.servicesToday = const [], this.salesToday = 0, this.commissionToday = 0, this.customersToday = 0});
  final List<Map<String, dynamic>> branches;
  final List<Map<String, dynamic>> attendance;
  final List<Map<String, dynamic>> servicesToday;
  final num salesToday;
  final num commissionToday;
  final int customersToday;
}
