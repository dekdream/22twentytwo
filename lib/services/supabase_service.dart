import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://pcsvnczvoydvdgwsvuwb.supabase.co',
  );
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_dVh07CIeKv9npp-I5K_p3Q_21A2_b4z',
  );
  static final authNotifier = ValueNotifier<int>(0);
  static bool _isInitialized = false;

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
  static bool get isInitialized => _isInitialized;

  static SupabaseClient? get client {
    if (!isConfigured || !_isInitialized) return null;
    return Supabase.instance.client;
  }

  static Future<void> initialize() async {
    if (!isConfigured) return;
    await Supabase.initialize(url: url, publishableKey: publishableKey);
    _isInitialized = true;
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      authNotifier.value++;
    });
  }
}

class HrRepository {
  const HrRepository();

  static const _lineNotificationFunction = 'send-line';
  static const _uuid = Uuid();

  SupabaseClient get _client {
    final client = SupabaseService.client;
    if (client == null) {
      throw StateError('Supabase is not configured.');
    }
    return client;
  }

  Future<List<Map<String, dynamic>>> list(String table,
      {String? orderBy}) async {
    if (!SupabaseService.isConfigured) return [];
    var query = _client.from(table).select();
    if (orderBy != null) {
      return List<Map<String, dynamic>>.from(await query.order(orderBy));
    }
    return List<Map<String, dynamic>>.from(await query);
  }

  Future<List<Map<String, dynamic>>> listWithEmployee(
    String table, {
    String? orderBy,
    Object? branchId,
  }) async {
    if (!SupabaseService.isConfigured) return [];
    var query = _client.from(table).select(
          branchId == null
              ? '*, employees(employee_code, first_name, last_name, branches(branch_code, branch_name))'
              : '*, employees!inner(employee_code, first_name, last_name, branch_id, branches(branch_code, branch_name))',
        );
    if (branchId != null) {
      if (orderBy != null) {
        return List<Map<String, dynamic>>.from(
          await query.eq('employees.branch_id', branchId).order(orderBy),
        );
      }
      return List<Map<String, dynamic>>.from(
        await query.eq('employees.branch_id', branchId),
      );
    }
    if (orderBy != null) {
      return List<Map<String, dynamic>>.from(await query.order(orderBy));
    }
    return List<Map<String, dynamic>>.from(await query);
  }

  Future<List<Map<String, dynamic>>> listEmployees({
    String? orderBy,
    Object? branchId,
  }) async {
    if (!SupabaseService.isConfigured) return [];
    var query = _client.from('employees').select(
          '*, departments(name), positions(name), branches(branch_code, branch_name)',
        );
    if (branchId != null) {
      if (orderBy != null) {
        return List<Map<String, dynamic>>.from(
          await query.eq('branch_id', branchId).order(orderBy),
        );
      }
      return List<Map<String, dynamic>>.from(
        await query.eq('branch_id', branchId),
      );
    }
    if (orderBy != null) {
      return List<Map<String, dynamic>>.from(await query.order(orderBy));
    }
    return List<Map<String, dynamic>>.from(await query);
  }

  Future<List<Map<String, dynamic>>> listCustomers({
    String? orderBy,
    Object? branchId,
  }) async {
    if (!SupabaseService.isConfigured) return [];
    var query = _client
        .from('customers')
        .select('*, branches(branch_code, branch_name)');
    if (branchId != null) {
      if (orderBy != null) {
        return List<Map<String, dynamic>>.from(
          await query.eq('branch_id', branchId).order(orderBy),
        );
      }
      return List<Map<String, dynamic>>.from(
        await query.eq('branch_id', branchId),
      );
    }
    if (orderBy != null) {
      return List<Map<String, dynamic>>.from(await query.order(orderBy));
    }
    return List<Map<String, dynamic>>.from(await query);
  }

  Future<List<Map<String, dynamic>>> listBranches({
    String? orderBy,
    Object? branchId,
  }) async {
    if (!SupabaseService.isConfigured) return [];
    var query = _client.from('branches').select();
    if (branchId != null) {
      if (orderBy != null) {
        return List<Map<String, dynamic>>.from(
          await query.eq('id', branchId).order(orderBy),
        );
      }
      return List<Map<String, dynamic>>.from(await query.eq('id', branchId));
    }
    if (orderBy != null) {
      return List<Map<String, dynamic>>.from(await query.order(orderBy));
    }
    return List<Map<String, dynamic>>.from(await query);
  }

  Future<List<Map<String, dynamic>>> listPayroll({
    String? orderBy,
    Object? branchId,
  }) async {
    if (!SupabaseService.isConfigured) return [];
    var query = _client.from('payroll').select(
          branchId == null
              ? '*, employees(employee_code, first_name, last_name, branches(branch_code, branch_name))'
              : '*, employees!inner(employee_code, first_name, last_name, branch_id, branches(branch_code, branch_name))',
        );
    if (branchId != null) {
      if (orderBy != null) {
        return List<Map<String, dynamic>>.from(
          await query.eq('employees.branch_id', branchId).order(orderBy),
        );
      }
      return List<Map<String, dynamic>>.from(
        await query.eq('employees.branch_id', branchId),
      );
    }
    if (orderBy != null) {
      return List<Map<String, dynamic>>.from(await query.order(orderBy));
    }
    return List<Map<String, dynamic>>.from(await query);
  }

  Future<void> insert(String table, Map<String, dynamic> data) async {
    final scopedData = Map<String, dynamic>.from(data);
    if (EmployeeSession.isAdmin) {
      if (table == 'branches') {
        throw StateError('Only the owner can add a branch.');
      }
      if (table == 'employees' || table == 'customers') {
        scopedData['branch_id'] = EmployeeSession.branchId;
      }
    }
    await _client.from(table).insert(scopedData);
  }

  Future<Map<String, dynamic>> insertReturning(
    String table,
    Map<String, dynamic> data,
  ) async {
    final scopedData = Map<String, dynamic>.from(data);
    if (EmployeeSession.isAdmin && (table == 'employees' || table == 'customers')) {
      scopedData['branch_id'] = EmployeeSession.branchId;
    }
    return Map<String, dynamic>.from(
      await _client.from(table).insert(scopedData).select().single(),
    );
  }

  /// Sends an administrator notification through the LINE Edge Function.
  ///
  /// Notifications are deliberately sent after the database write, so a
  /// temporary LINE/API failure never prevents the HR record from being saved.
  Future<void> sendLineNotification(String message) async {
    final response = await _client.functions.invoke(
      _lineNotificationFunction,
      body: {'message': message},
    );

    if (response.status < 200 || response.status >= 300) {
      throw StateError('LINE notification failed (${response.status}).');
    }
  }

  Future<void> update(
      String table, Object id, Map<String, dynamic> data) async {
    await _client.from(table).update(data).eq('id', id);
  }

  /// Uploads an employee avatar and returns its public URL.
  ///
  /// The `profile` bucket is public, so the saved value can be rendered
  /// directly with an `Image.network`/`CachedNetworkImage` widget.
  Future<String> uploadEmployeeProfileImage({
    required Object employeeId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    final safeExtension = switch (extension) {
      'png' || 'webp' || 'gif' || 'jpg' || 'jpeg' => extension,
      _ => 'jpg',
    };
    final contentType = switch (safeExtension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
    // A changing filename prevents clients from displaying an old cached photo.
    final path = 'employees/$employeeId/${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
    final storage = _client.storage.from('profile');
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: false),
    );
    final publicUrl = storage.getPublicUrl(path);
    await update('employees', employeeId, {'profile_image': publicUrl});
    return publicUrl;
  }

  Future<void> delete(String table, Object id) async {
    await _client.from(table).delete().eq('id', id);
  }

  Future<Map<String, dynamic>?> findEmployeeForLogin({
    required String email,
    required String employeeCode,
  }) async {
    if (!SupabaseService.isConfigured) return null;
    return await _client
        .from('employees')
        .select(
          '*, departments(name), positions(name, salary), branches(branch_code, branch_name)',
        )
        .eq('email', email)
        .eq('employee_code', employeeCode)
        .eq('status', 'Active')
        .maybeSingle();
  }

  Future<List<Map<String, dynamic>>> listEmployeePayroll(
    Object employeeId,
  ) async {
    if (!SupabaseService.isConfigured) return [];
    return List<Map<String, dynamic>>.from(
      await _client
          .from('payroll')
          .select()
          .eq('employee_id', employeeId)
          .order('year', ascending: false)
          .order('month', ascending: false),
    );
  }

  Future<List<Map<String, dynamic>>> listEmployeeServices(
    Object employeeId,
  ) async {
    if (!SupabaseService.isConfigured) return [];
    return List<Map<String, dynamic>>.from(
      await _client
          .from('service_history')
          .select('*, services(name)')
          .eq('employee_id', employeeId)
          .order('service_date', ascending: false),
    );
  }

  Future<Map<String, dynamic>?> employeeAttendanceForDate(
    Object employeeId,
    DateTime date,
  ) async {
    final workDate = date.toIso8601String().substring(0, 10);
    return await _client
        .from('attendance')
        .select()
        .eq('employee_id', employeeId)
        .eq('work_date', workDate)
        .maybeSingle();
  }

  Future<void> employeeCheckIn(Object employeeId) async {
    final now = DateTime.now();
    final existing = await employeeAttendanceForDate(employeeId, now);
    if (existing?['check_in'] != null) {
      throw StateError('You have already checked in today.');
    }
    if (existing == null) {
      await _client.from('attendance').insert({
        'employee_id': employeeId,
        'work_date': now.toIso8601String().substring(0, 10),
        'check_in': now.toIso8601String(),
        'status': 'Present',
      });
      return;
    }
    await update('attendance', existing['id'], {
      'check_in': now.toIso8601String(),
      'status': 'Present',
    });
  }

  Future<void> employeeCheckOut(Object employeeId) async {
    final existing = await employeeAttendanceForDate(employeeId, DateTime.now());
    if (existing == null || existing['check_in'] == null) {
      throw StateError('Check in before checking out.');
    }
    if (existing['check_out'] != null) {
      throw StateError('You have already checked out today.');
    }
    await update('attendance', existing['id'], {
      'check_out': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> createAttendanceQr(Object branchId) async {
    final token = _uuid.v4();
    final expiresAt = DateTime.now().add(const Duration(seconds: 20));
    return Map<String, dynamic>.from(await _client
        .from('attendance_qr_sessions')
        .insert({'branch_id': branchId, 'token': token, 'expires_at': expiresAt.toIso8601String()})
        .select()
        .single());
  }

  Future<void> verifyQrAttendance({
    required Object employeeId,
    required Object branchId,
    required String token,
    required bool checkIn,
  }) async {
    final session = await _client.from('attendance_qr_sessions')
        .select()
        .eq('token', token).maybeSingle();
    if (session == null || session['branch_id']?.toString() != branchId.toString() ||
        DateTime.tryParse(session['expires_at']?.toString() ?? '')?.isBefore(DateTime.now()) != false) {
      throw StateError('QR is invalid or expired.');
    }
    final now = DateTime.now();
    final workDate = now.toIso8601String().substring(0, 10);
    final existing = await _client.from('attendance').select().eq('employee_id', employeeId).eq('work_date', workDate).maybeSingle();
    final data = checkIn
        ? {'check_in': now.toIso8601String(), 'status': 'Present', 'qr_session_id': session['id']}
        : {'check_out': now.toIso8601String(), 'qr_session_id': session['id']};
    if (existing == null && checkIn) {
      await _client.from('attendance').insert({...data, 'employee_id': employeeId, 'work_date': workDate});
    } else if (existing == null || (checkIn ? existing['check_in'] != null : existing['check_out'] != null)) {
      throw StateError(checkIn ? 'Already checked in today.' : 'Check in first, or you already checked out.');
    } else {
      await update('attendance', existing['id'], data);
    }
  }

  Future<int> count(String table) async {
    if (!SupabaseService.isConfigured) return 0;
    final response =
        await _client.from(table).select('id').count(CountOption.exact);
    return response.count;
  }

  Future<int> attendanceCount(String status, DateTime date) async {
    if (!SupabaseService.isConfigured) return 0;
    final day = date.toIso8601String().substring(0, 10);
    final response = await _client
        .from('attendance')
        .select('id')
        .eq('work_date', day)
        .eq('status', status)
        .count(CountOption.exact);
    return response.count;
  }
}

const hrRepository = HrRepository();

enum EmployeeAccessRole { owner, employee, admin, unknown }

enum ManagementArea { employee, store }

String employeeDisplayName(Map<String, dynamic> row) {
  final employee = row['employees'];
  if (employee is! Map) return row['employee_id']?.toString() ?? '-';

  final firstName = employee['first_name']?.toString() ?? '';
  final lastName = employee['last_name']?.toString() ?? '';
  final fullName = '$firstName $lastName'.trim();
  if (fullName.isNotEmpty) return fullName;

  return employee['employee_code']?.toString() ??
      row['employee_id']?.toString() ??
      '-';
}

String employeeBranchName(Map<String, dynamic> row) {
  final employee = row['employees'];
  if (employee is! Map) return '-';
  final branch = employee['branches'];
  if (branch is! Map) return '-';
  return branch['branch_name']?.toString() ?? '-';
}

class EmployeeSession {
  static final notifier = ValueNotifier<Map<String, dynamic>?>(null);
  static final managementAreaNotifier = ValueNotifier<ManagementArea?>(null);
  static final branchScopeNotifier = ValueNotifier<Map<String, dynamic>?>(null);
  static String? lastSignInError;

  // Department IDs in public.departments:
  // 1 = owner, 2 = employee, 3 = admin.
  static const ownerDepartmentId = 1;
  static const employeeDepartmentId = 2;
  static const adminDepartmentId = 3;

  static Map<String, dynamic>? get current => notifier.value;
  static bool get isLoggedIn => current != null;

  static EmployeeAccessRole roleFor(Map<String, dynamic>? employee) {
    final departmentId =
        int.tryParse(employee?['department_id']?.toString() ?? '');
    return switch (departmentId) {
      ownerDepartmentId => EmployeeAccessRole.owner,
      employeeDepartmentId => EmployeeAccessRole.employee,
      adminDepartmentId => EmployeeAccessRole.admin,
      _ => EmployeeAccessRole.unknown,
    };
  }

  static EmployeeAccessRole get role => roleFor(current);
  static bool get isOwner => role == EmployeeAccessRole.owner;
  static bool get isAdmin => role == EmployeeAccessRole.admin;
  static bool get isEmployee => role == EmployeeAccessRole.employee;
  static bool get canAccessManagement => isOwner || isAdmin;
  static ManagementArea? get managementArea => managementAreaNotifier.value;
  static bool get isEmployeeManagement =>
      managementArea == ManagementArea.employee;
  static bool get isStoreManagement => managementArea == ManagementArea.store;

  static void selectManagementArea(ManagementArea? area) {
    managementAreaNotifier.value = area;
  }

  static Object? get branchId => current?['branch_id'];
  static String get branchName {
    final branch = current?['branches'];
    if (branch is Map) return branch['branch_name']?.toString() ?? 'ทั้งหมด';
    return 'ทั้งหมด';
  }

  static Object? get activeBranchId {
    if (isOwner) return branchScopeNotifier.value?['id'];
    return branchId;
  }

  static String get activeBranchName {
    if (isOwner) {
      return branchScopeNotifier.value?['name']?.toString() ?? 'ทั้งหมด';
    }
    return branchName;
  }

  static void selectBranch(Object? id, {String? name}) {
    branchScopeNotifier.value =
        id == null ? null : {'id': id, 'name': name ?? '-'};
    final employee = current;
    if (employee != null) notifier.value = Map<String, dynamic>.from(employee);
  }

  static Future<bool> signIn({
    required String email,
    required String employeeCode,
  }) async {
    lastSignInError = null;
    final employee = await hrRepository.findEmployeeForLogin(
      email: email,
      employeeCode: employeeCode,
    );
    if (employee == null) {
      lastSignInError = 'อีเมลหรือรหัสพนักงานไม่ถูกต้อง';
      return false;
    }
    final employeeRole = roleFor(employee);
    if (employeeRole == EmployeeAccessRole.unknown) {
      lastSignInError = 'แผนกของบัญชีนี้ไม่ได้รับสิทธิ์เข้าใช้งาน';
      return false;
    }
    final employeeBranchId = employee['branch_id'];
    if (employeeRole == EmployeeAccessRole.admin &&
        (employeeBranchId == null ||
            employeeBranchId.toString().trim().isEmpty)) {
      lastSignInError = 'บัญชีแอดมินยังไม่ได้กำหนดสาขาที่รับผิดชอบ';
      return false;
    }
    selectBranch(null);
    selectManagementArea(null);
    notifier.value = employee;
    return true;
  }

  static void signOut() {
    selectBranch(null);
    selectManagementArea(null);
    notifier.value = null;
    lastSignInError = null;
  }
}
