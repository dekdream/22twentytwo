import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/supabase_service.dart';
import 'form_dialog.dart';

/// A compact, responsive replacement for dense data tables. Tapping a card
/// opens the complete record without leaving the current page.
class RecordCards extends StatelessWidget {
  const RecordCards({super.key, required this.future, required this.builder, this.columns, this.tableName, this.onChanged, this.canManage = true});

  final Future<List<Map<String, dynamic>>> future;
  final Widget Function(BuildContext, Map<String, dynamic>, VoidCallback) builder;
  // Kept optional so existing data sources can be migrated incrementally.
  final List<DataColumn>? columns;
  final String? tableName;
  final VoidCallback? onChanged;
  final bool canManage;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text('โหลดข้อมูลไม่สำเร็จ: ${snapshot.error}'));
          final records = snapshot.data ?? const <Map<String, dynamic>>[];
          if (records.isEmpty) return const Center(child: Text('ยังไม่มีข้อมูล'));
          return LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1050 ? 3 : constraints.maxWidth >= 640 ? 2 : 1;
              return GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: 104,
                ),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return builder(context, record, () => showDialog<void>(
                        context: context,
                        builder: (_) => _RecordDialog(
                          record: record,
                          tableName: tableName,
                          canManage: canManage,
                          onChanged: onChanged,
                        ),
                      ));
                },
              );
            },
          );
        },
      );
}

class RecordCard extends StatelessWidget {
  const RecordCard({super.key, required this.title, required this.subtitle, required this.trailing, required this.onTap, this.icon = Icons.receipt_long_outlined, this.imageUrl});
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;
  final IconData icon;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              _RecordAvatar(imageUrl: imageUrl, icon: icon),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xff302d43))), const SizedBox(height: 5), Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff9693a8), fontSize: 12))])),
              Text(trailing, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xffd4537e))),
            ]),
          ),
        ),
      );
}

class _RecordAvatar extends StatelessWidget {
  const _RecordAvatar({this.imageUrl, required this.icon});
  final String? imageUrl;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xfffff0f5), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: const Color(0xffd4537e)));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: CachedNetworkImage(
        imageUrl: imageUrl!, width: 48, height: 48, fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(color: const Color(0xfffff0f5), child: Icon(icon, color: const Color(0xffd4537e))),
      ),
    );
  }
}

class _RecordDialog extends StatelessWidget {
  const _RecordDialog({required this.record, this.tableName, this.onChanged, required this.canManage});
  final Map<String, dynamic> record;
  final String? tableName;
  final VoidCallback? onChanged;
  final bool canManage;

  Future<void> _edit(BuildContext context) async {
    final values = await showRecordDialog(
      context,
      title: 'Edit record',
      initialValues: record,
      fields: [
        for (final entry in record.entries)
          if (entry.key != 'id' && entry.value is! Map && !_readOnlyField(entry.key))
            FieldConfig(entry.key, entry.key, maxLines: _isLongText(entry.key) ? 3 : 1),
      ],
    );
    if (values == null || tableName == null || record['id'] == null) return;
    await hrRepository.update(tableName!, record['id'], values);
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    onChanged?.call();
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete record?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || tableName == null || record['id'] == null) return;
    await hrRepository.delete(tableName!, record['id']);
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    onChanged?.call();
  }
  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('รายละเอียด'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: record.entries
                  .where((entry) => !_hiddenField(entry.key))
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _thaiField(entry.key),
                            style: const TextStyle(
                              color: Color(0xffd4537e),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(_thaiValue(entry.value)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          if (canManage && tableName != null) ...[
            TextButton.icon(onPressed: () => _edit(context), icon: const Icon(Icons.edit_outlined), label: const Text('Edit')),
            TextButton.icon(onPressed: () => _delete(context), icon: const Icon(Icons.delete_outline, color: Colors.red), label: const Text('Delete', style: TextStyle(color: Colors.red))),
          ],
          TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: const Text('Close')),
        ],
      );

  static String _thaiField(String key) => const {
        'id': 'รหัส',
        'employee_id': 'พนักงาน',
        'service_id': 'บริการ',
        'customer_name': 'ชื่อลูกค้า',
        'customer_id': 'รหัสลูกค้า',
        'price': 'ราคา',
        'commission': 'ค่าคอมมิชชั่น',
        'service_date': 'วันที่ให้บริการ',
        'branch_id': 'สาขา',
        'department_id': 'แผนก',
        'position_id': 'ตำแหน่ง',
        'status': 'สถานะ',
        'reason': 'เหตุผล',
        'name': 'หน้าที่',
        'salary': 'เงินเดือน',
        'year': 'ปี',
        'month': 'เดือน',
        'overtime': 'OT',
        'bonus': 'โบนัส',
        'deduction': 'หักเงิน',
        'total_sale': 'ยอดขายรวม',
        'commission_percent': '%ค่าคอมมิชชั่น',
        'commission_amount': 'จำนวนค่าคอมมิชชั่น',
        'basic_salary': 'เงินเดือนพื้นฐาน',
        'total_salary': 'เงินเดือนรวม',
        'created_at': 'วันที่สร้าง',
        'start_date': 'วันที่เริ่ม',
        'end_date': 'วันที่สิ้นสุด',
        'branch_name': 'สาขา',
        'branch_code': 'รหัสสาขา',
        'address': 'ที่อยู่',
        'phone': 'โทรศัพท์',
        'manager_name': 'ผู้จัดการ',
        'title': 'หัวข้อ',
        'detail': 'รายละเอียด',
        'hire_date': 'วันที่เริ่มงาน',
        'birth_date': 'วันเกิด',
        'gender': 'เพศ',
        'employee_code': 'รหัสพนักงาน',
        'first_name': 'ชื่อ',
        'last_name': 'นามสกุล',
        'email': 'อีเมล',
      }[key] ?? key;

  static bool _hiddenField(String key) {
    const hidden = {
      'id',
      'employee_id',
      'employees',
      'service_id',
      'customer_id',
      'branch_id',
      'branches',
      'department_id',
      'departments',
      'position_id',
      'positions',
      'leave_type_id',
      'profile_image',
    };
    return hidden.contains(key) || key.endsWith('_id');
  }

  static bool _readOnlyField(String key) => const {
        'created_at', 'updated_at', 'profile_image', 'commission_amount',
      }.contains(key);

  static bool _isLongText(String key) =>
      const {'description', 'detail', 'reason', 'address'}.contains(key);

  static String _thaiValue(Object? value) {
    final text = value?.toString() ?? '-';
    switch (text.trim().toLowerCase()) {
      case 'female':
        return 'หญิง';
      case 'male':
        return 'ชาย';
      default:
        return text;
    }
  }
}
