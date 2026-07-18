import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/supabase_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late final Future<List<Map<String, dynamic>>> _employeesFuture;
  String? _employeeId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _employeesFuture = hrRepository.listEmployees(
      orderBy: 'first_name',
      branchId: EmployeeSession.activeBranchId,
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(context: context, initialTime: _selectedTime);
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _checkIn(List<Map<String, dynamic>> employees) async {
    if (_employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกชื่อช่าง')),
      );
      return;
    }

    final checkIn = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    await hrRepository.insert('attendance', {
      'employee_id': _employeeId,
      'work_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'check_in': checkIn.toIso8601String(),
      'status': 'Present',
    });

    final employee = employees.firstWhere((item) => item['id'].toString() == _employeeId);
    await _sendLineNotification(
      'ลงเวลาเข้างาน\n'
      'พนักงาน: ${_employeeLabel(employee)}\n'
      'เวลา: ${DateFormat('dd/MM/yyyy HH:mm').format(checkIn)}',
    );
    if (mounted) setState(() => _refreshKey++);
  }

  Future<void> _sendLineNotification(String message) async {
    try {
      await hrRepository.sendLineNotification(message);
    } catch (_) {
      // The attendance record was saved; a LINE notification is optional.
    }
  }

  Future<void> _showBranchQr() async {
    final branchId = EmployeeSession.activeBranchId;
    if (branchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกสาขาก่อนสร้าง QR')));
      return;
    }
    try {
      final qr = await hrRepository.createAttendanceQr(branchId);
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('QR ลงเวลา (หมดอายุใน 5 นาที)'),
          content: SizedBox(
            width: 280,
            height: 320,
            child: Column(
              children: [
                SizedBox(
                  width: 240,
                  height: 240,
                  child: QrImageView(data: qr['token'].toString()),
                ),
                const SizedBox(height: 14),
                const Text('ให้พนักงานสแกนจากมือถือ'),
              ],
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่สามารถสร้าง QR ได้')));
    }
  }

  static String _employeeLabel(Map<String, dynamic> employee) {
    final name = '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'.trim();
    return name.isEmpty ? (employee['employee_code']?.toString() ?? '-') : name;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          color: const Color(0xfffffcfa),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(alignment: Alignment.centerRight, child: OutlinedButton.icon(onPressed: _showBranchQr, icon: const Icon(Icons.qr_code_2), label: const Text('สร้าง QR ลงเวลา'))),
              const SizedBox(height: 12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _employeesFuture,
                builder: (context, snapshot) => _CheckInForm(
                  employees: snapshot.data ?? const [],
                  employeeId: _employeeId,
                  selectedDate: _selectedDate,
                  selectedTime: _selectedTime,
                  onEmployeeChanged: (value) => setState(() => _employeeId = value),
                  onDateTap: _selectDate,
                  onTimeTap: _selectTime,
                  onCheckIn: snapshot.hasData ? () => _checkIn(snapshot.data!) : null,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(child: _AttendanceTable(key: ValueKey(_refreshKey))),
            ],
          ),
        ),
      );
}

class _CheckInForm extends StatelessWidget {
  const _CheckInForm({
    required this.employees,
    required this.employeeId,
    required this.selectedDate,
    required this.selectedTime,
    required this.onEmployeeChanged,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onCheckIn,
  });

  final List<Map<String, dynamic>> employees;
  final String? employeeId;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final ValueChanged<String?> onEmployeeChanged;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final VoidCallback? onCheckIn;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              final fieldWidth = compact ? constraints.maxWidth : (constraints.maxWidth - 106) / 3;
              return Wrap(
                spacing: 12,
                runSpacing: 14,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  SizedBox(
                    width: constraints.maxWidth,
                    child: const Row(children: [
                      Icon(Icons.circle, size: 16, color: Color(0xffe85076)),
                      SizedBox(width: 8),
                      Text('ลงเวลาเข้างาน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<String>(
                      value: employeeId,
                      decoration: const InputDecoration(labelText: 'ชื่อช่าง', hintText: 'ชื่อ'),
                      items: employees
                          .map((employee) => DropdownMenuItem(
                                value: employee['id'].toString(),
                                child: Text(_AttendanceScreenState._employeeLabel(employee)),
                              ))
                          .toList(),
                      onChanged: onEmployeeChanged,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _PickerField(
                      label: 'วันที่',
                      value: DateFormat('dd/MM/yyyy').format(selectedDate),
                      icon: Icons.calendar_today_outlined,
                      onTap: onDateTap,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _PickerField(
                      label: 'เวลา',
                      value: selectedTime.format(context),
                      icon: Icons.access_time_outlined,
                      onTap: onTimeTap,
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: onCheckIn,
                      child: const Text('เข้างาน'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
}

class _PickerField extends StatelessWidget {
  const _PickerField({required this.label, required this.value, required this.icon, required this.onTap});

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, suffixIcon: Icon(icon, size: 19)),
          child: Text(value),
        ),
      );
}

class _AttendanceTable extends StatelessWidget {
  const _AttendanceTable({super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: hrRepository.listWithEmployee(
          'attendance',
          orderBy: 'work_date',
          branchId: EmployeeSession.activeBranchId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text('โหลดข้อมูลไม่สำเร็จ: ${snapshot.error}'));
          final rows = snapshot.data ?? const [];
          return Card(
            margin: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Column(children: [
                const SizedBox.shrink(),
                Expanded(
                  child: rows.isEmpty
                      ? const Center(child: Text('⏰ ยังไม่มี', style: TextStyle(color: Color(0xff999999))))
                      : ListView.separated(
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) => _AttendanceCard(row: rows[index]),
                        ),
                ),
              ]),
            ),
          );
        },
      );
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.row});
  final Map<String, dynamic> row;

  String _time(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date == null ? '-' : DateFormat('HH:mm').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('รายละเอียดการลงเวลา'),
              content: Text('พนักงาน: ${employeeDisplayName(row)}\nสาขา: ${employeeBranchName(row)}\nเวลาเข้า: ${_time(row['check_in'])}\nเวลาออก: ${_time(row['check_out'])}\nสถานะ: ${row['status'] ?? '-'}'),
              actions: [TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: const Text('ปิด'))],
            ),
          ),
          leading: const CircleAvatar(backgroundColor: Color(0xfffff0f5), child: Icon(Icons.schedule_outlined, color: Color(0xffd4537e))),
          title: Text(employeeDisplayName(row), style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${employeeBranchName(row)} • เข้า ${_time(row['check_in'])} • ออก ${_time(row['check_out'])}'),
          trailing: Text('${row['status'] ?? '-'}', style: const TextStyle(color: Color(0xffd4537e), fontWeight: FontWeight.w700)),
        ),
      );
}

class _AttendanceHeader extends StatelessWidget {
  const _AttendanceHeader();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: Color(0xfffce4ec),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            Expanded(flex: 2, child: Text('ชื่อ', style: _headerStyle)),
            Expanded(child: Text('สาขา', style: _headerStyle)),
            Expanded(child: Text('เข้า', style: _headerStyle)),
            Expanded(child: Text('ออก', style: _headerStyle)),
            Expanded(child: Text('ชม.', style: _headerStyle)),
          ]),
        ),
      );
}

const _headerStyle = TextStyle(color: Color(0xff993556), fontWeight: FontWeight.w600);

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.row});
  final Map<String, dynamic> row;

  String _time(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date == null ? '-' : DateFormat('HH:mm').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(children: [
          Expanded(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(employeeDisplayName(row)),
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(employeeBranchName(row)),
            ),
          ),
          Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: Text(_time(row['check_in'])))),
          Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: Text(_time(row['check_out'])))),
          const Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: Text('-'))),
        ]),
      );
}
