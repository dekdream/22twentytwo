import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../widgets/form_dialog.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/record_cards.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  Future<void> addAnnouncement() async {
    final values = await showRecordDialog(
      context,
      title: 'Add Announcement',
      fields: const [
        FieldConfig('title', 'Title'),
        FieldConfig('detail', 'Detail', maxLines: 4)
      ],
    );
    if (values == null || values['title']!.isEmpty) return;
    await hrRepository.insert('announcements', values);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return HrPage(
      title: 'Announcements',
      subtitle: 'ประกาศข่าวสารภายในองค์กร',
      action: FilledButton.icon(
          onPressed: addAnnouncement,
          icon: const Icon(Icons.add),
          label: const Text('Add')),
      child: RecordCards(
        tableName: 'announcements',
        onChanged: () => setState(() {}),
        future: hrRepository.list('announcements', orderBy: 'created_at'),
        builder: (context, row, onTap) => RecordCard(
          title: '${row['title'] ?? '-'}',
          subtitle: '${row['created_at'] ?? '-'}',
          trailing: 'อ่านรายละเอียด',
          icon: Icons.campaign_outlined,
          onTap: onTap,
        ),
      ),
    );
  }
}
