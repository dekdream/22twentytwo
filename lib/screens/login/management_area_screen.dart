import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/supabase_service.dart';

class ManagementAreaScreen extends StatelessWidget {
  const ManagementAreaScreen({super.key});

  void _select(BuildContext context, ManagementArea area) {
    EmployeeSession.selectManagementArea(area);
    context.go(area == ManagementArea.store ? '/services' : '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: Image.asset('assets/images/twenty_two_studio.jpg', width: 72, height: 72, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Twenty Two HR',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'สวัสดี ${_displayName()} เลือกส่วนที่ต้องการจัดการ',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xff777777)),
                  ),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cards = [
                        _AreaCard(
                          icon: Icons.badge_outlined,
                          title: 'จัดการพนักงาน',
                          description:
                              'ข้อมูลพนักงาน แผนก ตำแหน่ง ลงเวลา ลางาน เงินเดือน และค่าคอม',
                          onTap: () =>
                              _select(context, ManagementArea.employee),
                        ),
                        _AreaCard(
                          icon: Icons.storefront_outlined,
                          title: 'จัดการร้าน',
                          description:
                              'บริการ ประวัติบริการ ลูกค้า สาขา และประกาศของร้าน',
                          onTap: () => _select(context, ManagementArea.store),
                        ),
                      ];
                      if (constraints.maxWidth < 620) {
                        return Column(
                          children: [
                            cards.first,
                            const SizedBox(height: 14),
                            cards.last,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: cards.first),
                          const SizedBox(width: 16),
                          Expanded(child: cards.last),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  TextButton.icon(
                    onPressed: () {
                      EmployeeSession.signOut();
                      context.go('/login');
                    },
                    icon: const Icon(Icons.logout_outlined),
                    label: const Text('ออกจากระบบ'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _displayName() {
    final employee = EmployeeSession.current;
    final firstName = employee?['first_name']?.toString() ?? '';
    final lastName = employee?['last_name']?.toString() ?? '';
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'ผู้ใช้งาน' : name;
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xffffedf3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 30, color: const Color(0xffd4537e)),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xff777777), height: 1.5),
              ),
              const SizedBox(height: 18),
              const Icon(Icons.arrow_forward, color: Color(0xffd4537e)),
            ],
          ),
        ),
      ),
    );
  }
}
