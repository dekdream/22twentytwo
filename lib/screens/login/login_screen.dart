import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final employeeCodeController = TextEditingController();
  bool loading = false;
  bool obscureCode = true;

  @override
  void dispose() {
    emailController.dispose();
    employeeCodeController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      final success = await EmployeeSession.signIn(
        email: emailController.text.trim(),
        employeeCode: employeeCodeController.text.trim(),
      );
      if (!mounted) return;
      if (success) {
        context.go(EmployeeSession.isEmployee ? '/employee' : '/access');
        return;
      }
      _showError(
          EmployeeSession.lastSignInError ?? 'อีเมลหรือรหัสพนักงานไม่ถูกต้อง');
    } catch (_) {
      if (mounted) {
        _showError('เข้าสู่ระบบไม่สำเร็จ กรุณาตรวจสอบการเชื่อมต่อแล้วลองใหม่');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: const Color(0xffd94b68),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      backgroundColor: const Color(0xfffff9fb),
      body: Stack(
        children: [
          const Positioned(
            top: -110,
            right: -80,
            child: _GlowOrb(size: 300, color: Color(0x24e47c9e)),
          ),
          const Positioned(
            bottom: -120,
            left: -90,
            child: _GlowOrb(size: 330, color: Color(0x22ff7497)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Container(
                    height: isWide ? 660 : null,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x142a2540),
                          blurRadius: 50,
                          offset: Offset(0, 20),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        if (isWide) const Expanded(child: _LoginVisual()),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWide ? 58 : 26,
                              vertical: isWide ? 48 : 38,
                            ),
                            child: _LoginForm(
                              formKey: _formKey,
                              emailController: emailController,
                              employeeCodeController: employeeCodeController,
                              loading: loading,
                              obscureCode: obscureCode,
                              onToggleCode: () =>
                                  setState(() => obscureCode = !obscureCode),
                              onSignIn: signIn,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.employeeCodeController,
    required this.loading,
    required this.obscureCode,
    required this.onToggleCode,
    required this.onSignIn,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController employeeCodeController;
  final bool loading;
  final bool obscureCode;
  final VoidCallback onToggleCode;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) => Form(
        key: formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Logo(),
            const SizedBox(height: 42),
            Text(
              'ยินดีต้อนรับ',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xff29283a),
                    fontWeight: FontWeight.w900,
                  ),
            ),

            const SizedBox(height: 30),
            const Text('อีเมล',
                style: TextStyle(
                    color: Color(0xff4c4a5a), fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'name@twentytwo.com',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'กรุณากรอกอีเมล';
                return null;
              },
            ),
            const SizedBox(height: 18),
            const Text('รหัสพนักงาน',
                style: TextStyle(
                    color: Color(0xff4c4a5a), fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextFormField(
              controller: employeeCodeController,
              obscureText: obscureCode,
              textCapitalization: TextCapitalization.characters,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => loading ? null : onSignIn(),
              decoration: InputDecoration(
                hintText: 'กรอกรหัสพนักงานของคุณ',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: obscureCode ? 'แสดงรหัส' : 'ซ่อนรหัส',
                  onPressed: onToggleCode,
                  icon: Icon(obscureCode
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                ),
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'กรุณากรอกรหัสพนักงาน'
                  : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: loading ? null : onSignIn,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xffd4537e),
                  disabledBackgroundColor: const Color(0xfff2b8ca),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('เข้าสู่ระบบ',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                          SizedBox(width: 9),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'หากคุณลืมรหัสพนักงาน กรุณาติดต่อผู้ดูแลระบบของบริษัท',
              style: TextStyle(color: Color(0xff9693a8), fontSize: 13),
            ),
          ],
        ),
      );
}

class _LoginVisual extends StatelessWidget {
  const _LoginVisual();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(44),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xffb83d68), Color(0xffdf668f), Color(0xfff19ab5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -70,
              top: -60,
              child: _GlowOrb(size: 240, color: Color(0x22ffffff)),
            ),
            const Positioned(
              left: -80,
              bottom: -100,
              child: _GlowOrb(size: 270, color: Color(0x18ffffff)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.17),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: Colors.white.withOpacity(.24)),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white),
                ),
                const Spacer(),
                const Text(
                  '22Twenty Two',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'ดูงานบริการ รายได้ ข่าวสาร และข้อมูลส่วนตัว\nได้ง่ายๆ จากทุกอุปกรณ์',
                  style: TextStyle(
                    color: Color(0xddffffff),
                    fontSize: 16,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 34),
                const Row(
                  children: [
                    _VisualPill(Icons.auto_awesome_rounded, 'งานบริการ'),
                    SizedBox(width: 9),
                    _VisualPill(Icons.wallet_rounded, 'เงินเดือน'),
                    SizedBox(width: 9),
                    _VisualPill(Icons.newspaper_rounded, 'ข่าวสาร'),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            child: Image.asset('assets/images/twenty_two_studio.jpg', width: 46, height: 46, fit: BoxFit.cover),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Twenty Two',
                  style: TextStyle(
                      color: Color(0xff29283a),
                      fontSize: 19,
                      fontWeight: FontWeight.w900)),
              Text('EMPLOYEE EXPERIENCE',
                  style: TextStyle(
                      color: Color(0xffa09ead),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.25)),
            ],
          ),
        ],
      );
}

class _VisualPill extends StatelessWidget {
  const _VisualPill(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      );
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
