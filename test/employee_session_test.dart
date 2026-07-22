import 'package:flutter_test/flutter_test.dart';
import 'package:hr_management_supabase/services/supabase_service.dart';

void main() {
  group('department access roles', () {
    test('department 1 is the owner', () {
      expect(
        EmployeeSession.roleFor({'department_id': 1}),
        EmployeeAccessRole.owner,
      );
    });

    test('department 2 is an employee without management access', () {
      expect(
        EmployeeSession.roleFor({'department_id': 2}),
        EmployeeAccessRole.employee,
      );
    });

    test('department 3 is an admin', () {
      expect(
        EmployeeSession.roleFor({'department_id': 3}),
        EmployeeAccessRole.admin,
      );
    });

    test('other or missing departments have no access role', () {
      expect(
        EmployeeSession.roleFor({'department_id': 99}),
        EmployeeAccessRole.unknown,
      );
      expect(EmployeeSession.roleFor(null), EmployeeAccessRole.unknown);
    });
  });
}
