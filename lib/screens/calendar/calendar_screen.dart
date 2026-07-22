import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../widgets/page_scaffold.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  Future<void> _add() async {
    final title = TextEditingController();
    final detail = TextEditingController();
    DateTime date = DateTime.now();
    String type = 'Work';
    final ok = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setLocal) => AlertDialog(
                    title: const Text('เพิ่มรายการในปฏิทิน'),
                    content: SizedBox(
                        width: 420,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          TextField(
                              controller: title,
                              decoration:
                                  const InputDecoration(labelText: 'หัวข้อ')),
                          const SizedBox(height: 10),
                          DropdownButtonFormField(
                              value: type,
                              decoration:
                                  const InputDecoration(labelText: 'ประเภท'),
                              items: const [
                                DropdownMenuItem(
                                    value: 'Work', child: Text('ตารางงาน')),
                                DropdownMenuItem(
                                    value: 'Holiday', child: Text('วันหยุด')),
                                DropdownMenuItem(
                                    value: 'Leave', child: Text('ลางาน'))
                              ],
                              onChanged: (v) => setLocal(() => type = v!)),
                          const SizedBox(height: 10),
                          ListTile(
                              title:
                                  Text(DateFormat('dd/MM/yyyy').format(date)),
                              leading: const Icon(Icons.event),
                              onTap: () async {
                                final d = await showDatePicker(
                                    context: context,
                                    initialDate: date,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100));
                                if (d != null) setLocal(() => date = d);
                              }),
                          TextField(
                              controller: detail,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                  labelText: 'รายละเอียด')),
                        ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('ยกเลิก')),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('บันทึก'))
                    ])));
    if (ok == true && title.text.trim().isNotEmpty) {
      await hrRepository.insert('calendar_events', {
        'title': title.text.trim(),
        'detail': detail.text.trim(),
        'event_type': type,
        'start_date': DateFormat('yyyy-MM-dd').format(date),
        'end_date': DateFormat('yyyy-MM-dd').format(date),
        'branch_id': EmployeeSession.activeBranchId
      });
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => HrPage(
      title: 'ปฏิทิน',
      subtitle: 'วันลา วันหยุด และตารางงาน',
      action: EmployeeSession.isEmployee
          ? null
          : FilledButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('เพิ่มรายการ')),
      child: FutureBuilder<List<Map<String, dynamic>>>(
          future: hrRepository.listCalendarEvents(
              branchId: EmployeeSession.activeBranchId),
          builder: (context, s) {
            if (!s.hasData)
              return const Center(child: CircularProgressIndicator());
            final events = s.data!;
            final first = DateTime(month.year, month.month, 1);
            final days = DateUtils.getDaysInMonth(month.year, month.month);
            final offset = first.weekday % 7;
            return ListView(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                    onPressed: () => setState(
                        () => month = DateTime(month.year, month.month - 1)),
                    icon: const Icon(Icons.chevron_left)),
                Text(DateFormat('MMMM yyyy', 'th').format(month),
                    style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                    onPressed: () => setState(
                        () => month = DateTime(month.year, month.month + 1)),
                    icon: const Icon(Icons.chevron_right))
              ]),
              const SizedBox(height: 12),
              GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7, childAspectRatio: 1.15),
                  itemCount: offset + days,
                  itemBuilder: (context, i) {
                    if (i < offset) return const SizedBox();
                    final day = i - offset + 1;
                    final key = DateFormat('yyyy-MM-dd')
                        .format(DateTime(month.year, month.month, day));
                    final items = events
                        .where((e) => ('${e['start_date']}').startsWith(key))
                        .toList();
                    return Card(
                        child: Padding(
                            padding: const EdgeInsets.all(7),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$day',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  for (final e in items.take(2))
                                    Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.all(3),
                                        color: const Color(0xffffedf3),
                                        child: Text('${e['title']}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xffa63f62))))
                                ])));
                  })
            ]);
          }));
}
