import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/supabase_service.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _sidebarCollapsed = false;

  static const _mainItems = [
    _NavItem('แดชบอร์ด', '/', Icons.dashboard_outlined),
    _NavItem('ลงเวลา', '/attendance', Icons.schedule_outlined),
    _NavItem('ลางาน', '/leave', Icons.event_note_outlined),
    _NavItem('พนักงาน', '/employees', Icons.badge_outlined),
    _NavItem('แผนก', '/departments', Icons.apartment_outlined),
    _NavItem('ตำแหน่ง', '/positions', Icons.work_outline),
    _NavItem('เงินเดือน', '/payroll', Icons.payments_outlined),
    _NavItem('ค่าคอม', '/commissions', Icons.percent_outlined),
    _NavItem('โปรไฟล์', '/profile', Icons.person_outline),
  ];

  static const _managementItems = [
    _NavItem('แดชบอร์ด', '/', Icons.dashboard_outlined),
    _NavItem('บริการ', '/services', Icons.design_services_outlined),
    _NavItem(
      'ประวัติบริการ',
      '/service-history',
      Icons.receipt_long_outlined,
    ),
    _NavItem('ลูกค้า', '/customers', Icons.groups_2_outlined),
    _NavItem('สาขา', '/branches', Icons.store_outlined),
    _NavItem('ประกาศ', '/announcements', Icons.campaign_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isPhone = MediaQuery.sizeOf(context).width < 800;

    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: EmployeeSession.branchScopeNotifier,
      builder: (context, _, __) {
        final isStoreOwner = EmployeeSession.isOwner;
        return Scaffold(
          backgroundColor: const Color(0xfffff9fb),
          appBar: _buildAppBar(context, isPhone),
          drawer: isPhone
              ? Drawer(
                  child: SafeArea(
                    child: _buildSidebar(
                      location,
                      isStoreOwner: isStoreOwner,
                      closeOnSelect: true,
                    ),
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!isPhone)
                Container(
                  width: _sidebarCollapsed ? 76 : 252,
                  margin: const EdgeInsets.all(16),
                  clipBehavior: Clip.antiAlias,
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
                  child: Material(
                    color: Colors.white,
                    child: _buildSidebar(
                      location,
                      isStoreOwner: isStoreOwner,
                      collapsed: _sidebarCollapsed,
                    ),
                  ),
                ),
              Expanded(
                child: KeyedSubtree(
                  key: ValueKey(EmployeeSession.activeBranchId),
                  child: widget.child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isPhone,
  ) =>
      AppBar(
        toolbarHeight: isPhone ? 58 : 74,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xfffff9fb),
        foregroundColor: const Color(0xff252437),
        surfaceTintColor: Colors.transparent,
        titleSpacing: isPhone ? 8 : 28,
        leading: isPhone
            ? null
            : IconButton(
                tooltip: _sidebarCollapsed ? 'ขยายเมนู' : 'ย่อเมนู',
                onPressed: () =>
                    setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                icon: Icon(_sidebarCollapsed ? Icons.menu : Icons.menu_open),
              ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.asset('assets/images/twenty_two_studio.jpg', width: 42, height: 42, fit: BoxFit.cover),
            ),
            const SizedBox(width: 11),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Twenty Two', style: TextStyle(color: Color(0xff252437), fontSize: 17, fontWeight: FontWeight.w800)),
                const Text('MANAGEMENT', style: TextStyle(color: Color(0xffa09daf), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
              ],
            ),
          ],
        ),
        actions: [
          if (!isPhone) ...[
            _ModeChip(
              isOwner: EmployeeSession.isOwner,
              isStoreManagement: EmployeeSession.isStoreManagement,
            ),
            const SizedBox(width: 18),
          ],
          IconButton(
            tooltip: 'เปลี่ยนส่วนจัดการ',
            onPressed: () {
              EmployeeSession.selectManagementArea(null);
              context.go('/access');
            },
            icon: const Icon(Icons.swap_horiz),
          ),
          IconButton(
            tooltip: 'ออกจากระบบ',
            onPressed: () {
              EmployeeSession.signOut();
              context.go('/login');
            },
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xffffedf0),
              foregroundColor: const Color(0xffe75b78),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.logout_outlined, size: 19),
          ),
          const SizedBox(width: 16),
        ],
      );

  void _navigate(BuildContext context, String path, bool closeOnSelect) {
    if (closeOnSelect) Navigator.of(context).pop();
    context.go(path);
  }

  Widget _buildSidebar(
    String location, {
    required bool isStoreOwner,
    bool closeOnSelect = false,
    bool collapsed = false,
  }) {
    final isStoreManagement = EmployeeSession.isStoreManagement;
    final visibleItems = isStoreManagement ? _managementItems : _mainItems;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (collapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
              child: Tooltip(
                message: isStoreManagement ? 'จัดการร้าน' : 'จัดการพนักงาน',
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xfffff0f5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isStoreManagement
                        ? Icons.storefront_outlined
                        : Icons.badge_outlined,
                    color: const Color(0xffd4537e),
                  ),
                ),
              ),
            ),
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 4),
              child: _ModeBanner(
                isOwner: EmployeeSession.isOwner,
                isStoreManagement: isStoreManagement,
              ),
            ),
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'สาขาที่กำลังดู',
                    style: TextStyle(color: Color(0xff9a7b86), fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    EmployeeSession.activeBranchName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xffd4537e),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isStoreOwner) ...[
                    const SizedBox(height: 8),
                    const _BranchSelector(compact: true),
                  ],
                ],
              ),
            ),
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
              child: Text(
                isStoreManagement ? 'เมนูจัดการร้าน' : 'เมนูจัดการพนักงาน',
                style: const TextStyle(
                  color: Color(0xff9a7b86),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .2,
                ),
              ),
            ),
          ...visibleItems.map((item) => _SidebarItem(
                item: item,
                selected: item.path == location,
                compact: collapsed,
                onTap: () => _navigate(context, item.path, closeOnSelect),
              )),
          if (!collapsed)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  Icon(Icons.content_cut, size: 14, color: Color(0xffb1a3a8)),
                  SizedBox(width: 7),
                  Text('22Twentytwo HR',
                      style: TextStyle(color: Color(0xffb1a3a8), fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeBanner extends StatelessWidget {
  const _ModeBanner({
    required this.isOwner,
    required this.isStoreManagement,
  });

  final bool isOwner;
  final bool isStoreManagement;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xfffff0f5), Color(0xfffff8fa)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xfff6c4d5)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                isStoreManagement
                    ? Icons.storefront_outlined
                    : Icons.badge_outlined,
                color: const Color(0xffd4537e),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isStoreManagement ? 'จัดการร้าน' : 'จัดการพนักงาน',
                    style: const TextStyle(
                      color: Color(0xff5a3442),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOwner
                        ? 'เจ้าของร้าน · ดูได้ทุกสาขา'
                        : 'แอดมิน · เฉพาะสาขาของคุณ',
                    style: const TextStyle(
                      color: Color(0xff9a7b86),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final _NavItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
        child: Material(
          color: selected ? const Color(0xfffff0f5) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: selected ? const Color(0xfff6c4d5) : Colors.transparent,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(item.icon,
                      size: 21,
                      color: selected
                          ? const Color(0xffd4537e)
                          : const Color(0xff8f8fa3)),
                  if (!compact) ...[
                    const SizedBox(width: 12),
                    Text(item.label,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xffd4537e)
                              : const Color(0xff535166),
                          fontSize: 15,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        )),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}

class _NavItem {
  const _NavItem(this.label, this.path, this.icon);
  final String label;
  final String path;
  final IconData icon;
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.isOwner,
    required this.isStoreManagement,
  });

  final bool isOwner;
  final bool isStoreManagement;

  @override
  Widget build(BuildContext context) => Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.82),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xffe6b7c6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isStoreManagement
                  ? Icons.storefront_outlined
                  : Icons.badge_outlined,
              size: 17,
              color: const Color(0xffa63f62),
            ),
            const SizedBox(width: 7),
            Text(
              '${isOwner ? 'เจ้าของร้าน' : 'แอดมิน'} · '
              '${isStoreManagement ? 'จัดการร้าน' : 'จัดการพนักงาน'}',
              style: const TextStyle(
                color: Color(0xff74344a),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

class _HeaderSelect extends StatelessWidget {
  const _HeaderSelect({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xff81626d))),
          const SizedBox(width: 7),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(7)),
            child: Row(children: [
              const Icon(Icons.lock_outline,
                  size: 15, color: Color(0xffd4537e)),
              const SizedBox(width: 6),
              Text(value, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 14),
              const Icon(Icons.keyboard_arrow_down, size: 18),
            ]),
          ),
        ],
      );
}

class _BranchSelector extends StatefulWidget {
  const _BranchSelector({this.compact = false});

  final bool compact;

  @override
  State<_BranchSelector> createState() => _BranchSelectorState();
}

class _BranchSelectorState extends State<_BranchSelector> {
  late final Future<List<Map<String, dynamic>>> _branchesFuture;

  @override
  void initState() {
    super.initState();
    _branchesFuture = hrRepository.listBranches(orderBy: 'branch_code');
  }

  @override
  Widget build(BuildContext context) {
    if (!EmployeeSession.isOwner) {
      return _HeaderSelect(
        label: 'สาขาของฉัน:',
        value: EmployeeSession.activeBranchName,
      );
    }

    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: EmployeeSession.branchScopeNotifier,
      builder: (context, _, __) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _branchesFuture,
        builder: (context, snapshot) {
          final branches = snapshot.data ?? const <Map<String, dynamic>>[];
          const allValue = '__all_branches__';
          final selectedId = EmployeeSession.activeBranchId?.toString();
          final hasSelectedBranch =
              branches.any((branch) => branch['id']?.toString() == selectedId);
          final value = hasSelectedBranch ? selectedId : allValue;

          final selector = Container(
            height: 38,
            width: widget.compact ? double.infinity : 180,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                items: [
                  const DropdownMenuItem(
                      value: allValue, child: Text('ทั้งหมด')),
                  for (final branch in branches)
                    DropdownMenuItem(
                      value: branch['id']?.toString(),
                      child: Text(
                        branch['branch_name']?.toString() ?? '-',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (selected) {
                  if (selected == null || selected == allValue) {
                    EmployeeSession.selectBranch(null);
                    return;
                  }
                  final branch = branches.firstWhere(
                    (item) => item['id']?.toString() == selected,
                  );
                  EmployeeSession.selectBranch(
                    branch['id'],
                    name: branch['branch_name']?.toString() ?? '-',
                  );
                },
              ),
            ),
          );

          if (widget.compact) return selector;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ดูข้อมูลสาขา:',
                style: TextStyle(fontSize: 12, color: Color(0xff81626d)),
              ),
              const SizedBox(width: 7),
              selector,
            ],
          );
        },
      ),
    );
  }
}
