import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/supabase_service.dart';

const _attendanceStatuses = <String, String>{
  'Present': 'มาทำงาน',
  'Late': 'มาสาย',
  'Leave': 'ลา',
  'Absent': 'ขาด',
};

String _attendanceStatusLabel(Object? status) =>
    _attendanceStatuses[status?.toString()] ?? status?.toString() ?? '-';

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
  String _selectedStatus = 'Present';
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
    final time =
        await showTimePicker(context: context, initialTime: _selectedTime);
    if (time != null) setState(() => _selectedTime = time);
  }

  void _selectToday() => setState(() => _selectedDate = DateTime.now());

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
    await hrRepository.saveAttendanceStatus(
      employeeId: _employeeId!,
      workDate: _selectedDate,
      status: _selectedStatus,
      checkIn: checkIn,
    );

    final employee =
        employees.firstWhere((item) => item['id'].toString() == _employeeId);
    await _sendLineNotification(
      'บันทึกสถานะการทำงาน\n'
      'พนักงาน: ${_employeeLabel(employee)}\n'
      'สถานะ: ${_attendanceStatusLabel(_selectedStatus)}\n'
      'วันที่: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'
      '${_selectedStatus == 'Present' || _selectedStatus == 'Late' ? '\nเวลา: ${DateFormat('HH:mm').format(checkIn)}' : ''}',
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกสาขาก่อนสร้าง QR')));
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => _RotatingBranchQrDialog(branchId: branchId),
    );
  }

  static String _employeeLabel(Map<String, dynamic> employee) {
    final name =
        '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'.trim();
    return name.isEmpty ? (employee['employee_code']?.toString() ?? '-') : name;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          color: const Color(0xfffffcfa),
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                      onPressed: _showBranchQr,
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('สร้าง QR ลงเวลา'))),
              const SizedBox(height: 12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _employeesFuture,
                builder: (context, snapshot) => _CheckInForm(
                  employees: snapshot.data ?? const [],
                  employeeId: _employeeId,
                  selectedDate: _selectedDate,
                  selectedTime: _selectedTime,
                  selectedStatus: _selectedStatus,
                  onEmployeeChanged: (value) =>
                      setState(() => _employeeId = value),
                  onStatusChanged: (value) =>
                      setState(() => _selectedStatus = value ?? 'Present'),
                  onDateTap: _selectDate,
                  onTimeTap: _selectTime,
                  onCheckIn:
                      snapshot.hasData ? () => _checkIn(snapshot.data!) : null,
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                height: 260,
                child: _MonthlyAttendanceSummary(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 420,
                child: _AttendanceTable(
                  key: ValueKey(
                      '$_refreshKey-${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
                  selectedDate: _selectedDate,
                  onDateTap: _selectDate,
                  onTodayTap: _selectToday,
                ),
              ),
            ],
          ),
        ),
      );
}

class _RotatingBranchQrDialog extends StatefulWidget {
  const _RotatingBranchQrDialog({required this.branchId});

  final Object branchId;

  @override
  State<_RotatingBranchQrDialog> createState() =>
      _RotatingBranchQrDialogState();
}

class _RotatingBranchQrDialogState extends State<_RotatingBranchQrDialog> {
  Timer? _refreshTimer;
  String? _token;
  Object? _sessionId;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _refreshQr();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 20), (_) => _refreshQr());
  }

  Future<void> _refreshQr() async {
    try {
      final qr = await hrRepository.createAttendanceQr(widget.branchId);
      if (mounted)
        setState(() {
          _token = qr['token'].toString();
          _sessionId = qr['id'];
          _error = null;
        });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _deleteQr() async {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    try {
      await hrRepository.deleteAttendanceQr(sessionId);
      _refreshTimer?.cancel();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบ QR นี้ไม่ได้ เพราะมีการใช้งานแล้ว')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('QR ลงเวลา'),
        content: SizedBox(
          width: 280,
          height: 320,
          child: Column(
            children: [
              SizedBox(
                width: 240,
                height: 240,
                child: _token != null
                    ? QrImageView(data: _token!)
                    : Center(
                        child: _error == null
                            ? const CircularProgressIndicator()
                            : Text('ไม่สามารถสร้าง QR ได้: $_error',
                                textAlign: TextAlign.center),
                      ),
              ),
              const SizedBox(height: 14),
              const Text('QR จะเปลี่ยนใหม่ทุก 20 วินาที'),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _sessionId == null ? null : _deleteQr,
            icon: const Icon(Icons.delete_outline),
            label: const Text('ลบ QR นี้'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      );
}

class _CheckInForm extends StatelessWidget {
  const _CheckInForm({
    required this.employees,
    required this.employeeId,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedStatus,
    required this.onEmployeeChanged,
    required this.onStatusChanged,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onCheckIn,
  });

  final List<Map<String, dynamic>> employees;
  final String? employeeId;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final String selectedStatus;
  final ValueChanged<String?> onEmployeeChanged;
  final ValueChanged<String?> onStatusChanged;
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
              const actionWidth = 100.0;
              final compact = constraints.maxWidth < 900;
              final fieldWidth = compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - actionWidth - 48) / 4;
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
                      Text('ลงเวลาเข้างาน',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<String>(
                      value: employeeId,
                      decoration: const InputDecoration(
                          labelText: 'ชื่อช่าง', hintText: 'ชื่อ'),
                      items: employees
                          .map((employee) => DropdownMenuItem(
                                value: employee['id'].toString(),
                                child: Text(
                                    _AttendanceScreenState._employeeLabel(
                                        employee)),
                              ))
                          .toList(),
                      onChanged: onEmployeeChanged,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: 'สถานะ'),
                      items: _attendanceStatuses.entries
                          .map((entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ))
                          .toList(),
                      onChanged: onStatusChanged,
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
                    width: compact ? constraints.maxWidth : actionWidth,
                    height: 56,
                    child: FilledButton(
                      onPressed: onCheckIn,
                      child: const Text('บันทึก'),
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
  const _PickerField(
      {required this.label,
      required this.value,
      required this.icon,
      required this.onTap});

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: InputDecoration(
              labelText: label, suffixIcon: Icon(icon, size: 19)),
          child: Text(value),
        ),
      );
}

class _MonthlyAttendanceSummary extends StatefulWidget {
  const _MonthlyAttendanceSummary();

  @override
  State<_MonthlyAttendanceSummary> createState() =>
      _MonthlyAttendanceSummaryState();
}

class _MonthlyAttendanceSummaryState extends State<_MonthlyAttendanceSummary> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late Future<List<_EmployeeMonthlyAttendance>> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final lastDay = DateTime(_month.year, _month.month + 1, 0);
    _summaryFuture = Future.wait([
      hrRepository.listEmployees(
        orderBy: 'first_name',
        branchId: EmployeeSession.activeBranchId,
      ),
      hrRepository.listWithEmployee(
        'attendance',
        branchId: EmployeeSession.activeBranchId,
        workDateFrom: DateFormat('yyyy-MM-dd').format(_month),
        workDateTo: DateFormat('yyyy-MM-dd').format(lastDay),
      ),
      hrRepository.listApprovedLeaveForRange(
        startDate: _month,
        endDate: lastDay,
        branchId: EmployeeSession.activeBranchId,
      ),
    ]).then((result) {
      final employees = result[0];
      final attendance = result[1];
      final approvedLeave = result[2];
      return employees.map((employee) {
        final employeeRows = attendance
            .where(
              (row) =>
                  row['employee_id']?.toString() == employee['id']?.toString(),
            )
            .toList();
        int count(String status) =>
            employeeRows.where((row) => row['status'] == status).length;
        final today = DateTime.now();
        final startOfToday = DateTime(today.year, today.month, today.day);
        final monthEnd = DateTime(_month.year, _month.month + 1, 0);
        final lastCompletedDay = startOfToday.subtract(const Duration(days: 1));
        final countThrough =
            monthEnd.isBefore(lastCompletedDay) ? monthEnd : lastCompletedDay;
        final completedDays =
            countThrough.isBefore(_month) ? 0 : countThrough.day;
        final recordedDates = employeeRows
            .map((row) => row['work_date']?.toString())
            .whereType<String>()
            .toSet();
        final approvedLeaveDates = <String>{};
        for (final leave in approvedLeave.where((row) =>
            row['employee_id']?.toString() == employee['id']?.toString())) {
          final leaveStart = DateTime.tryParse('${leave['start_date']}');
          final leaveEnd = DateTime.tryParse('${leave['end_date']}');
          if (leaveStart == null || leaveEnd == null) continue;
          var date = leaveStart.isBefore(_month) ? _month : leaveStart;
          final rangeEnd = leaveEnd.isAfter(monthEnd) ? monthEnd : leaveEnd;
          while (!date.isAfter(rangeEnd)) {
            approvedLeaveDates.add(DateFormat('yyyy-MM-dd').format(date));
            date = date.add(const Duration(days: 1));
          }
        }
        final leaveDatesWithoutAttendance = approvedLeaveDates
            .where((date) => !recordedDates.contains(date))
            .toSet();
        var missingDays = 0;
        for (var day = 1; day <= completedDays; day++) {
          final date = DateFormat('yyyy-MM-dd')
              .format(DateTime(_month.year, _month.month, day));
          if (!recordedDates.contains(date) &&
              !leaveDatesWithoutAttendance.contains(date)) {
            missingDays++;
          }
        }
        return _EmployeeMonthlyAttendance(
          name: _AttendanceScreenState._employeeLabel(employee),
          present: count('Present'),
          leave: count('Leave') + leaveDatesWithoutAttendance.length,
          absent: count('Absent') + missingDays,
          late: count('Late'),
        );
      }).toList();
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
      _reload();
    });
  }

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'สรุปการทำงานรายเดือน',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    tooltip: 'เดือนก่อนหน้า',
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    DateFormat('MM/yyyy').format(_month),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    tooltip: 'เดือนถัดไป',
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<List<_EmployeeMonthlyAttendance>>(
                  future: _summaryFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                            'โหลดสรุปรายเดือนไม่สำเร็จ: ${snapshot.error}'),
                      );
                    }
                    final rows = snapshot.data ?? const [];
                    if (rows.isEmpty) {
                      return const Center(child: Text('ยังไม่มีข้อมูลพนักงาน'));
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: constraints.maxWidth < 680
                              ? 680
                              : constraints.maxWidth,
                          child: Column(
                            children: [
                              const _MonthlySummaryRow(header: true),
                              const Divider(height: 1),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: rows.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (_, index) =>
                                      _MonthlySummaryRow(data: rows[index]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
}

class _EmployeeMonthlyAttendance {
  const _EmployeeMonthlyAttendance({
    required this.name,
    required this.present,
    required this.leave,
    required this.absent,
    required this.late,
  });

  final String name;
  final int present;
  final int leave;
  final int absent;
  final int late;
}

class _MonthlySummaryRow extends StatelessWidget {
  const _MonthlySummaryRow({this.data, this.header = false});

  final _EmployeeMonthlyAttendance? data;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: header ? FontWeight.w700 : FontWeight.w400,
      color: header ? const Color(0xff993556) : null,
    );
    Widget cell(String value, {int flex = 1}) => Expanded(
          flex: flex,
          child: Text(value,
              textAlign: flex == 1 ? TextAlign.center : null, style: style),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Row(
        children: [
          cell(header ? 'พนักงาน' : data!.name, flex: 2),
          cell(header ? 'มาทำงาน' : '${data!.present} วัน'),
          cell(header ? 'ลา' : '${data!.leave} วัน'),
          cell(header ? 'ขาด' : '${data!.absent} วัน'),
          cell(header ? 'มาสาย' : '${data!.late} วัน'),
        ],
      ),
    );
  }
}

class _AttendanceTable extends StatefulWidget {
  const _AttendanceTable({
    super.key,
    required this.selectedDate,
    required this.onDateTap,
    required this.onTodayTap,
  });

  final DateTime selectedDate;
  final VoidCallback onDateTap;
  final VoidCallback onTodayTap;

  @override
  State<_AttendanceTable> createState() => _AttendanceTableState();
}

class _AttendanceTableState extends State<_AttendanceTable> {
  late Future<List<Map<String, dynamic>>> _rowsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final day = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    _rowsFuture = Future.wait([
      hrRepository.listEmployees(
        orderBy: 'first_name',
        branchId: EmployeeSession.activeBranchId,
      ),
      hrRepository.listWithEmployee(
        'attendance',
        orderBy: 'work_date',
        branchId: EmployeeSession.activeBranchId,
        workDate: day,
      ),
      hrRepository.listApprovedLeaveForRange(
        startDate: widget.selectedDate,
        endDate: widget.selectedDate,
        branchId: EmployeeSession.activeBranchId,
      ),
    ]).then((result) {
      final employees = result[0];
      final attendance = result[1];
      final approvedLeaveEmployeeIds = result[2]
          .map((row) => row['employee_id']?.toString())
          .whereType<String>()
          .toSet();
      final today = DateTime.now();
      final selectedDay = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
      );
      final startOfToday = DateTime(today.year, today.month, today.day);
      final isPastDay = selectedDay.isBefore(startOfToday);

      final recordedEmployeeIds = attendance
          .map((row) => row['employee_id']?.toString())
          .whereType<String>()
          .toSet();
      final missingRows = employees.where((employee) {
        final employeeId = employee['id']?.toString();
        return !recordedEmployeeIds.contains(employeeId) &&
            (isPastDay || approvedLeaveEmployeeIds.contains(employeeId));
      }).map((employee) => <String, dynamic>{
            'id': null,
            'employee_id': employee['id'],
            'work_date': day,
            'status':
                approvedLeaveEmployeeIds.contains(employee['id']?.toString())
                    ? 'Leave'
                    : 'Absent',
            'employees': employee,
          });
      return [...attendance, ...missingRows];
    });
  }

  Future<void> _changeStatus(Map<String, dynamic> row, String status) async {
    try {
      if (row['id'] == null) {
        await hrRepository.saveAttendanceStatus(
          employeeId: row['employee_id'],
          workDate: widget.selectedDate,
          status: status,
        );
      } else {
        await hrRepository.updateAttendanceStatus(row['id'], status);
      }
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกสถานะไม่สำเร็จ: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _rowsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError)
            return Center(
                child: Text('โหลดข้อมูลไม่สำเร็จ: ${snapshot.error}'));
          final rows = snapshot.data ?? const [];
          return Card(
            margin: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'รายการลงเวลาประจำวันที่',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: widget.onDateTap,
                        icon:
                            const Icon(Icons.calendar_today_outlined, size: 18),
                        label: Text(DateFormat('dd/MM/yyyy')
                            .format(widget.selectedDate)),
                      ),
                      IconButton(
                        onPressed: widget.onTodayTap,
                        tooltip: 'กลับมาวันนี้',
                        icon: const Icon(Icons.today_outlined),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: rows.isEmpty
                      ? const Center(
                          child: Text('⏰ ยังไม่มี',
                              style: TextStyle(color: Color(0xff999999))))
                      : ListView.separated(
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) => _AttendanceCard(
                            row: rows[index],
                            onStatusChanged: (status) =>
                                _changeStatus(rows[index], status),
                          ),
                        ),
                ),
              ]),
            ),
          );
        },
      );
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({
    required this.row,
    required this.onStatusChanged,
  });
  final Map<String, dynamic> row;
  final ValueChanged<String> onStatusChanged;

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
              content: Text(
                  'พนักงาน: ${employeeDisplayName(row)}\nสาขา: ${employeeBranchName(row)}\nเวลาเข้า: ${_time(row['check_in'])}\nเวลาออก: ${_time(row['check_out'])}\nสถานะ: ${row['status'] ?? '-'}'),
              actions: [
                TextButton(
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                    child: const Text('ปิด'))
              ],
            ),
          ),
          leading: const CircleAvatar(
              backgroundColor: Color(0xfffff0f5),
              child: Icon(Icons.schedule_outlined, color: Color(0xffd4537e))),
          title: Text(employeeDisplayName(row),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(
              '${employeeBranchName(row)} • เข้า ${_time(row['check_in'])} • ออก ${_time(row['check_out'])}'),
          trailing: SizedBox(
            width: 120,
            child: DropdownButton<String>(
              value: _attendanceStatuses.containsKey(row['status'])
                  ? row['status'] as String
                  : null,
              hint: const Text('เลือกสถานะ'),
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: _attendanceStatuses.entries
                  .map((entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null && value != row['status']) {
                  onStatusChanged(value);
                }
              },
            ),
          ),
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

const _headerStyle =
    TextStyle(color: Color(0xff993556), fontWeight: FontWeight.w600);

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
          Expanded(
              child: FittedBox(
                  fit: BoxFit.scaleDown, child: Text(_time(row['check_in'])))),
          Expanded(
              child: FittedBox(
                  fit: BoxFit.scaleDown, child: Text(_time(row['check_out'])))),
          const Expanded(
              child: FittedBox(fit: BoxFit.scaleDown, child: Text('-'))),
        ]),
      );
}
