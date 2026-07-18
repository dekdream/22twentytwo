import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../services/supabase_service.dart';
import 'qr_attendance_screen.dart';

class EmployeePortalScreen extends StatefulWidget {
  const EmployeePortalScreen({super.key});

  @override
  State<EmployeePortalScreen> createState() => _EmployeePortalScreenState();
}

class _EmployeePortalScreenState extends State<EmployeePortalScreen> {
  static const _navItems = [
    _PortalNav('หน้าหลัก', Icons.home_rounded),
    _PortalNav('งานบริการ', Icons.auto_awesome_rounded),
    _PortalNav('เงินเดือน', Icons.account_balance_wallet_rounded),
    _PortalNav('ข่าวสาร', Icons.newspaper_rounded),
    _PortalNav('โปรไฟล์', Icons.person_rounded),
  ];

  int _selectedIndex = 0;
  late Future<List<Map<String, dynamic>>> _services;
  late Future<List<Map<String, dynamic>>> _payroll;
  late Future<List<Map<String, dynamic>>> _announcements;

  Map<String, dynamic> get _employee => EmployeeSession.current ?? const {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final employeeId = _employee['id'];
    _services = employeeId == null
        ? Future.value([])
        : hrRepository.listEmployeeServices(employeeId);
    _payroll = employeeId == null
        ? Future.value([])
        : hrRepository.listEmployeePayroll(employeeId);
    _announcements = hrRepository.list('announcements', orderBy: 'created_at');
  }

  Future<void> _refresh() async {
    setState(_loadData);
    await Future.wait([_services, _payroll, _announcements]);
  }

  void _signOut() {
    EmployeeSession.signOut();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 920;
    final pages = [
      _HomePage(
        employee: _employee,
        services: _services,
        payroll: _payroll,
        announcements: _announcements,
        onOpen: (index) => setState(() => _selectedIndex = index),
      ),
      _ServicesPage(future: _services),
      _SalaryPage(future: _payroll),
      _NewsPage(future: _announcements),
      _ProfilePage(employee: _employee),
    ];

    return Scaffold(
      backgroundColor: const Color(0xfffff9fb),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: const Color(0xfffff9fb),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              titleSpacing: 20,
              title: const _Brand(),
              actions: [
                IconButton(
                  tooltip: 'ออกจากระบบ',
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded),
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop)
              _DesktopNavigation(
                selectedIndex: _selectedIndex,
                employee: _employee,
                onSelected: (index) => setState(() => _selectedIndex = index),
                onSignOut: _signOut,
              ),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xffd4537e),
                onRefresh: _refresh,
                child: IndexedStack(index: _selectedIndex, children: pages),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              height: 72,
              elevation: 0,
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xfffff0f5),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              destinations: [
                for (final item in _navItems)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon:
                        Icon(item.icon, color: const Color(0xffd4537e)),
                    label: item.label,
                  ),
              ],
            ),
    );
  }
}

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation({
    required this.selectedIndex,
    required this.employee,
    required this.onSelected,
    required this.onSignOut,
  });

  final int selectedIndex;
  final Map<String, dynamic> employee;
  final ValueChanged<int> onSelected;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => Container(
        width: 264,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0d22223b),
              blurRadius: 30,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: _Brand(),
            ),
            const SizedBox(height: 32),
            for (var i = 0;
                i < _EmployeePortalScreenState._navItems.length;
                i++)
              _DesktopNavButton(
                item: _EmployeePortalScreenState._navItems[i],
                selected: selectedIndex == i,
                onTap: () => onSelected(i),
              ),
            const Spacer(),
            _MiniProfile(employee: employee),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout_rounded, size: 19),
              label: const Text('ออกจากระบบ'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xff8f8fa3),
                alignment: Alignment.centerLeft,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              ),
            ),
          ],
        ),
      );
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.asset(
              'assets/images/twenty_two_studio.jpg',
              width: 42,
              height: 42,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Twenty Two',
                style: TextStyle(
                  color: Color(0xff252437),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'MY WORKSPACE',
                style: TextStyle(
                  color: Color(0xffa09daf),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ],
      );
}

class _DesktopNavButton extends StatelessWidget {
  const _DesktopNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _PortalNav item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: selected ? const Color(0xfffff0f5) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 22,
                    color: selected
                        ? const Color(0xffd4537e)
                        : const Color(0xff9997a7),
                  ),
                  const SizedBox(width: 13),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xffd4537e)
                          : const Color(0xff666577),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.employee,
    required this.services,
    required this.payroll,
    required this.announcements,
    required this.onOpen,
  });

  final Map<String, dynamic> employee;
  final Future<List<Map<String, dynamic>>> services;
  final Future<List<Map<String, dynamic>>> payroll;
  final Future<List<Map<String, dynamic>>> announcements;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final firstName = employee['first_name']?.toString().trim();
    final name = firstName == null || firstName.isEmpty ? 'คนเก่ง' : firstName;
    return _PageCanvas(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'สวัสดี $name 👋',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xff29283a),
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'วันนี้ขอให้เป็นอีกวันที่ดีของคุณ',
            style: TextStyle(color: Color(0xff8e8c9d), fontSize: 15),
          ),
          const SizedBox(height: 24),
          _WelcomeBanner(employee: employee),
          const SizedBox(height: 16),
          _EmployeeAttendanceCard(employeeId: employee['id']),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth < 620
                  ? (constraints.maxWidth - 12) / 2
                  : (constraints.maxWidth - 36) / 4;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricFuture(
                    width: width,
                    icon: Icons.auto_awesome_rounded,
                    color: const Color(0xffd4537e),
                    future: services,
                    value: (data) => '${data.length}',
                    label: 'งานบริการทั้งหมด',
                  ),
                  _MetricFuture(
                    width: width,
                    icon: Icons.savings_rounded,
                    color: const Color(0xfff19a4b),
                    future: services,
                    value: (data) => _money(data.fold<num>(
                        0, (sum, row) => sum + _number(row['commission']))),
                    label: 'ค่าคอมสะสม',
                  ),
                  _MetricFuture(
                    width: width,
                    icon: Icons.account_balance_wallet_rounded,
                    color: const Color(0xff25ad83),
                    future: payroll,
                    value: (data) => data.isEmpty
                        ? '฿0'
                        : _money(_number(data.first['total_salary'])),
                    label: 'เงินเดือนล่าสุด',
                  ),
                  _MetricFuture(
                    width: width,
                    icon: Icons.notifications_active_rounded,
                    color: const Color(0xffef6b8c),
                    future: announcements,
                    value: (data) => '${data.length}',
                    label: 'ข่าวสารทั้งหมด',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 30),
          const _SectionTitle(title: 'เมนูของฉัน', onViewAll: null),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickMenu(
                label: 'งานบริการ',
                caption: 'ดูประวัติและค่าคอม',
                icon: Icons.auto_awesome_rounded,
                color: const Color(0xffd4537e),
                onTap: () => onOpen(1),
              ),
              _QuickMenu(
                label: 'สลิปเงินเดือน',
                caption: 'ดูรายรับและรายการหัก',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xff25ad83),
                onTap: () => onOpen(2),
              ),
              _QuickMenu(
                label: 'ข่าวสาร',
                caption: 'ไม่พลาดทุกอัปเดต',
                icon: Icons.campaign_rounded,
                color: const Color(0xffef6b8c),
                onTap: () => onOpen(3),
              ),
              _QuickMenu(
                label: 'ข้อมูลส่วนตัว',
                caption: 'ตรวจสอบโปรไฟล์ของคุณ',
                icon: Icons.person_rounded,
                color: const Color(0xfff19a4b),
                onTap: () => onOpen(4),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _SectionTitle(title: 'ข่าวล่าสุด', onViewAll: () => onOpen(3)),
          const SizedBox(height: 12),
          _AsyncList(
            future: announcements,
            emptyTitle: 'ยังไม่มีข่าวใหม่',
            builder: (data) => Column(
              children: [
                for (final item in data.reversed.take(2))
                  _AnnouncementCard(item: item, compact: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeAttendanceCard extends StatefulWidget {
  const _EmployeeAttendanceCard({this.employeeId});

  final Object? employeeId;

  @override
  State<_EmployeeAttendanceCard> createState() => _EmployeeAttendanceCardState();
}

class _EmployeeAttendanceCardState extends State<_EmployeeAttendanceCard> {
  late Future<Map<String, dynamic>?> _attendance;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _attendance = _load();
  }

  Future<Map<String, dynamic>?> _load() {
    final id = widget.employeeId;
    return id == null
        ? Future.value(null)
        : hrRepository.employeeAttendanceForDate(id, DateTime.now());
  }

  Future<void> _submit({required bool checkIn}) async {
    final id = widget.employeeId;
    if (id == null) return;
    setState(() => _saving = true);
    try {
      if (checkIn) {
        await hrRepository.employeeCheckIn(id);
      } else {
        await hrRepository.employeeCheckOut(id);
      }
      if (!mounted) return;
      setState(() => _attendance = _load());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(checkIn ? 'เช็กอินเรียบร้อย' : 'เช็กเอาต์เรียบร้อย')),
      );
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message.toString())),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถบันทึกเวลาได้')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _time(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    return date == null ? '-' : DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
        future: _attendance,
        builder: (context, snapshot) {
          final row = snapshot.data;
          final checkedIn = row?['check_in'] != null;
          final checkedOut = row?['check_out'] != null;
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xffffdce8)),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.schedule_rounded, color: Color(0xffd4537e), size: 30),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 200, maxWidth: 460),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ลงเวลาทำงานวันนี้', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('เข้า ${_time(row?['check_in'])}  •  ออก ${_time(row?['check_out'])}', style: const TextStyle(color: Color(0xff8e8c9d))),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _saving || checkedIn ? null : () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const QrAttendanceScreen(checkIn: true))); if (mounted) setState(() => _attendance = _load()); },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('เช็กอิน'),
                ),
                OutlinedButton.icon(
                  onPressed: _saving || !checkedIn || checkedOut ? null : () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const QrAttendanceScreen(checkIn: false))); if (mounted) setState(() => _attendance = _load()); },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('เช็กเอาต์'),
                ),
              ],
            ),
          );
        },
      );
}

class _ServicesPage extends StatelessWidget {
  const _ServicesPage({required this.future});
  final Future<List<Map<String, dynamic>>> future;

  @override
  Widget build(BuildContext context) => _PageCanvas(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PageHeading(
              title: 'งานบริการของฉัน',
              subtitle: 'ดูผลงาน รายได้ และค่าคอมมิชชันจากงานบริการ',
            ),
            const SizedBox(height: 22),
            _AsyncList(
              future: future,
              emptyTitle: 'ยังไม่มีประวัติงานบริการ',
              builder: (data) {
                final sales = data.fold<num>(
                    0, (sum, item) => sum + _number(item['price']));
                final commission = data.fold<num>(
                    0, (sum, item) => sum + _number(item['commission']));
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            label: 'ยอดบริการรวม',
                            value: _money(sales),
                            color: const Color(0xffd4537e),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            label: 'ค่าคอมรวม',
                            value: _money(commission),
                            color: const Color(0xff25ad83),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    for (final item in data) _ServiceCard(item: item),
                  ],
                );
              },
            ),
          ],
        ),
      );
}

class _SalaryPage extends StatelessWidget {
  const _SalaryPage({required this.future});
  final Future<List<Map<String, dynamic>>> future;

  @override
  Widget build(BuildContext context) => _PageCanvas(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PageHeading(
              title: 'เงินเดือนของฉัน',
              subtitle: 'รายละเอียดรายรับ โบนัส โอที และรายการหักในแต่ละเดือน',
            ),
            const SizedBox(height: 22),
            _AsyncList(
              future: future,
              emptyTitle: 'ยังไม่มีข้อมูลเงินเดือน',
              builder: (data) => Column(
                children: [
                  if (data.isNotEmpty) _LatestSalaryCard(item: data.first),
                  const SizedBox(height: 22),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ประวัติเงินเดือน',
                      style: TextStyle(
                        color: Color(0xff29283a),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final item in data) _PayslipCard(item: item),
                ],
              ),
            ),
          ],
        ),
      );
}

class _NewsPage extends StatelessWidget {
  const _NewsPage({required this.future});
  final Future<List<Map<String, dynamic>>> future;

  @override
  Widget build(BuildContext context) => _PageCanvas(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PageHeading(
              title: 'ข่าวสารและประกาศ',
              subtitle: 'เรื่องสำคัญและอัปเดตล่าสุดจาก Twenty Two',
            ),
            const SizedBox(height: 22),
            _AsyncList(
              future: future,
              emptyTitle: 'ยังไม่มีประกาศ',
              builder: (data) => Column(
                children: [
                  for (final item in data.reversed)
                    _AnnouncementCard(item: item),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({required this.employee});
  final Map<String, dynamic> employee;

  @override
  Widget build(BuildContext context) {
    final department = employee['departments'];
    final position = employee['positions'];
    final branch = employee['branches'];
    return _PageCanvas(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PageHeading(
            title: 'ข้อมูลส่วนตัว',
            subtitle: 'ตรวจสอบข้อมูลการทำงานและข้อมูลติดต่อของคุณ',
          ),
          const SizedBox(height: 22),
          _ProfileHero(employee: employee),
          const SizedBox(height: 18),
          _ContentCard(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.badge_rounded,
                  label: 'รหัสพนักงาน',
                  value: _text(employee['employee_code']),
                ),
                _InfoRow(
                  icon: Icons.work_rounded,
                  label: 'ตำแหน่ง',
                  value: position is Map ? _text(position['name']) : '-',
                ),
                _InfoRow(
                  icon: Icons.groups_rounded,
                  label: 'แผนก',
                  value: department is Map ? _text(department['name']) : '-',
                ),
                _InfoRow(
                  icon: Icons.store_rounded,
                  label: 'สาขา',
                  value: branch is Map ? _text(branch['branch_name']) : '-',
                ),
                _InfoRow(
                  icon: Icons.mail_rounded,
                  label: 'อีเมล',
                  value: _text(employee['email']),
                ),
                _InfoRow(
                  icon: Icons.phone_rounded,
                  label: 'เบอร์โทร',
                  value: _text(employee['phone']),
                ),
                _InfoRow(
                  icon: Icons.calendar_month_rounded,
                  label: 'วันที่เริ่มงาน',
                  value: _date(employee['hire_date']),
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'หากข้อมูลไม่ถูกต้อง กรุณาติดต่อผู้จัดการสาขาเพื่อแก้ไข',
            style: TextStyle(color: Color(0xff9a98a8), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _PageCanvas extends StatelessWidget {
  const _PageCanvas({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          MediaQuery.sizeOf(context).width < 600 ? 18 : 36,
          28,
          MediaQuery.sizeOf(context).width < 600 ? 18 : 36,
          44,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: child,
          ),
        ),
      );
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.employee});
  final Map<String, dynamic> employee;

  @override
  Widget build(BuildContext context) {
    final position = employee['positions'];
    final branch = employee['branches'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffc74370), Color(0xffe36f96), Color(0xfff69ab6)],
          stops: [0, .58, 1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33d4537e),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          _Avatar(employee: employee, radius: 34, light: true),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fullName(employee),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${position is Map ? _text(position['name']) : 'พนักงาน'} • ${branch is Map ? _text(branch['branch_name']) : '-'}',
                  style: const TextStyle(color: Color(0xddffffff)),
                ),
              ],
            ),
          ),
          const Icon(Icons.bubble_chart_rounded,
              size: 62, color: Color(0x33ffffff)),
        ],
      ),
    );
  }
}

class _MetricFuture extends StatelessWidget {
  const _MetricFuture({
    required this.width,
    required this.icon,
    required this.color,
    required this.future,
    required this.value,
    required this.label,
  });
  final double width;
  final IconData icon;
  final Color color;
  final Future<List<Map<String, dynamic>>> future;
  final String Function(List<Map<String, dynamic>>) value;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: _ContentCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBox(icon: icon, color: color),
              const SizedBox(height: 18),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: future,
                builder: (context, snapshot) => Text(
                  snapshot.hasData ? value(snapshot.data!) : '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff29283a),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xff9492a1), fontSize: 12),
              ),
            ],
          ),
        ),
      );
}

class _QuickMenu extends StatelessWidget {
  const _QuickMenu({
    required this.label,
    required this.caption,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final String caption;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: MediaQuery.sizeOf(context).width < 600 ? double.infinity : 250,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Row(
                children: [
                  _IconBox(icon: icon, color: color),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                color: Color(0xff343244),
                                fontWeight: FontWeight.w700)),
                        Text(caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xff9a98a8), fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xffb1afbc)),
                ],
              ),
            ),
          ),
        ),
      );
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final service = item['services'];
    final serviceName = service is Map ? _text(service['name']) : 'งานบริการ';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _ContentCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const _IconBox(
              icon: Icons.content_cut_rounded,
              color: Color(0xffd4537e),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(serviceName,
                      style: const TextStyle(
                          color: Color(0xff343244),
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    '${_date(item['service_date'])} • ${_text(item['customer_name'], fallback: 'ลูกค้าทั่วไป')}',
                    style:
                        const TextStyle(color: Color(0xff9694a4), fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_money(_number(item['price'])),
                    style: const TextStyle(
                        color: Color(0xff343244), fontWeight: FontWeight.w800)),
                Text('+${_money(_number(item['commission']))} ค่าคอม',
                    style: const TextStyle(
                        color: Color(0xff25ad83), fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestSalaryCard extends StatelessWidget {
  const _LatestSalaryCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff178d70), Color(0xff33bd91)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ยอดรับสุทธิ • ${_period(item)}',
                style: const TextStyle(color: Color(0xddffffff))),
            const SizedBox(height: 6),
            Text(
              _money(_number(item['total_salary'])),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 22,
              runSpacing: 10,
              children: [
                _SalaryMini('เงินเดือน', item['basic_salary']),
                _SalaryMini('โอที', item['overtime']),
                _SalaryMini('โบนัส', item['bonus']),
                _SalaryMini('รายการหัก', item['deduction']),
              ],
            ),
          ],
        ),
      );
}

class _PayslipCard extends StatelessWidget {
  const _PayslipCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _ContentCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const _IconBox(
                icon: Icons.receipt_long_rounded,
                color: Color(0xff25ad83),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_period(item),
                        style: const TextStyle(
                            color: Color(0xff343244),
                            fontWeight: FontWeight.w700)),
                    Text('จ่ายเมื่อ ${_date(item['payment_date'])}',
                        style: const TextStyle(
                            color: Color(0xff9694a4), fontSize: 12)),
                  ],
                ),
              ),
              Text(_money(_number(item['total_salary'])),
                  style: const TextStyle(
                      color: Color(0xff178d70),
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item, this.compact = false});
  final Map<String, dynamic> item;
  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ContentCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _IconBox(
                icon: Icons.campaign_rounded,
                color: Color(0xffef6b8c),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text(item['title'], fallback: 'ประกาศ'),
                      maxLines: compact ? 1 : null,
                      overflow: compact ? TextOverflow.ellipsis : null,
                      style: const TextStyle(
                        color: Color(0xff343244),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _text(item['detail'], fallback: 'ไม่มีรายละเอียด'),
                      maxLines: compact ? 2 : null,
                      overflow: compact ? TextOverflow.ellipsis : null,
                      style: const TextStyle(
                          color: Color(0xff737182), height: 1.45),
                    ),
                    const SizedBox(height: 9),
                    Text(_date(item['created_at']),
                        style: const TextStyle(
                            color: Color(0xffaaa8b5), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.employee});
  final Map<String, dynamic> employee;

  @override
  Widget build(BuildContext context) => _ContentCard(
        child: Row(
          children: [
            _Avatar(employee: employee, radius: 42),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_fullName(employee),
                      style: const TextStyle(
                          color: Color(0xff29283a),
                          fontSize: 21,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(_text(employee['email']),
                      style: const TextStyle(color: Color(0xff8f8d9d))),
                  const SizedBox(height: 9),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xffe8faf4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('●  Active',
                        style: TextStyle(
                            color: Color(0xff178d70),
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xffd4537e), size: 21),
                const SizedBox(width: 13),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width < 480 ? 94 : 140,
                  child: Text(label,
                      style: const TextStyle(color: Color(0xff9997a6))),
                ),
                Expanded(
                  child: Text(value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          color: Color(0xff3b394b),
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          if (showDivider) const Divider(height: 1, color: Color(0xfff0eff5)),
        ],
      );
}

class _MiniProfile extends StatelessWidget {
  const _MiniProfile({required this.employee});
  final Map<String, dynamic> employee;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xfff7f6fb),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _Avatar(employee: employee, radius: 21),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_fullName(employee),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xff3b394b),
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  Text(_text(employee['employee_code']),
                      style: const TextStyle(
                          color: Color(0xffa09eac), fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Avatar extends StatelessWidget {
  const _Avatar(
      {required this.employee, required this.radius, this.light = false});
  final Map<String, dynamic> employee;
  final double radius;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final image = employee['profile_image']?.toString();
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          light ? const Color(0x33ffffff) : const Color(0xfffff0f5),
      backgroundImage: image != null && image.startsWith('http')
          ? NetworkImage(image)
          : null,
      child: image != null && image.startsWith('http')
          ? null
          : Text(
              _initials(employee),
              style: TextStyle(
                color: light ? Colors.white : const Color(0xffd4537e),
                fontSize: radius * .65,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

class _AsyncList extends StatelessWidget {
  const _AsyncList({
    required this.future,
    required this.emptyTitle,
    required this.builder,
  });
  final Future<List<Map<String, dynamic>>> future;
  final String emptyTitle;
  final Widget Function(List<Map<String, dynamic>>) builder;

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xffd4537e)),
              ),
            );
          }
          if (snapshot.hasError) {
            return const _EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'โหลดข้อมูลไม่สำเร็จ',
              caption: 'ลองลากหน้าจอลงเพื่อโหลดใหม่อีกครั้ง',
            );
          }
          final data = snapshot.data ?? const <Map<String, dynamic>>[];
          if (data.isEmpty) {
            return _EmptyState(
              icon: Icons.inbox_rounded,
              title: emptyTitle,
              caption: 'ข้อมูลจะแสดงที่นี่เมื่อมีรายการใหม่',
            );
          }
          return builder(data);
        },
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon, required this.title, required this.caption});
  final IconData icon;
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) => _ContentCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 34),
            child: Column(
              children: [
                Icon(icon, size: 44, color: const Color(0xffc2bfce)),
                const SizedBox(height: 12),
                Text(title,
                    style: const TextStyle(
                        color: Color(0xff555365), fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(caption,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xffa09eac), fontSize: 12)),
              ],
            ),
          ),
        ),
      );
}

class _ContentCard extends StatelessWidget {
  const _ContentCard(
      {required this.child, this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xffefedf4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0822223b),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: child,
      );
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: color.withOpacity(.11),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: color, size: 22),
      );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => _ContentCard(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Color(0xff9694a4), fontSize: 12)),
            const SizedBox(height: 5),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color, fontSize: 21, fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class _SalaryMini extends StatelessWidget {
  const _SalaryMini(this.label, this.value);
  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xbbffffff), fontSize: 11)),
          Text(_money(_number(value)),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      );
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xff29283a),
                    fontWeight: FontWeight.w800,
                  )),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(color: Color(0xff8e8c9d), fontSize: 15)),
        ],
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.onViewAll});
  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: Color(0xff29283a),
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
          ),
          if (onViewAll != null)
            TextButton(onPressed: onViewAll, child: const Text('ดูทั้งหมด')),
        ],
      );
}

class _PortalNav {
  const _PortalNav(this.label, this.icon);
  final String label;
  final IconData icon;
}

num _number(Object? value) => num.tryParse(value?.toString() ?? '') ?? 0;

String _money(num value) => '฿${NumberFormat('#,##0.##').format(value)}';

String _text(Object? value, {String fallback = '-'}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _fullName(Map<String, dynamic> employee) {
  final name =
      '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'.trim();
  return name.isEmpty ? 'พนักงาน Twenty Two' : name;
}

String _initials(Map<String, dynamic> employee) {
  final first = employee['first_name']?.toString().trim() ?? '';
  final last = employee['last_name']?.toString().trim() ?? '';
  if (first.isEmpty && last.isEmpty) return '22';
  return '${first.isEmpty ? '' : first[0]}${last.isEmpty ? '' : last[0]}';
}

String _date(Object? value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return '-';
  const months = [
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.'
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
}

String _period(Map<String, dynamic> item) {
  const months = [
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม'
  ];
  final month = int.tryParse(item['month']?.toString() ?? '') ?? 0;
  final year = int.tryParse(item['year']?.toString() ?? '') ?? 0;
  return '${month >= 1 && month <= 12 ? months[month - 1] : '-'} ${year == 0 ? '-' : year + 543}';
}
