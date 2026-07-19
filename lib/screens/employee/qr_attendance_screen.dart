import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/supabase_service.dart';
import '../../services/mobile_scanner_registration.dart';

class QrAttendanceScreen extends StatefulWidget {
  const QrAttendanceScreen({super.key, required this.checkIn});
  final bool checkIn;
  @override
  State<QrAttendanceScreen> createState() => _QrAttendanceScreenState();
}

class _QrAttendanceScreenState extends State<QrAttendanceScreen> {
  bool _saving = false;
  final _manualQrController = TextEditingController();
  final _cameraController = MobileScannerController(autoStart: false);
  String _cameraMessage = 'กำลังเปิดกล้อง...';

  @override
  void initState() {
    super.initState();
    registerMobileScannerWeb();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCamera());
  }

  Future<void> _startCamera() async {
    setState(() => _cameraMessage = 'กำลังเปิดกล้อง...');
    try {
      await _cameraController.start();
    } catch (error) {
      if (mounted) setState(() => _cameraMessage = 'เปิดกล้องไม่สำเร็จ: $error');
    }
  }

  @override
  void dispose() {
    _manualQrController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _scan(String? token) async {
    if (_saving || token == null || token.isEmpty) return;
    final employee = EmployeeSession.current;
    if (employee == null || employee['id'] == null || employee['branch_id'] == null) return;
    setState(() => _saving = true);
    try {
      await hrRepository.verifyQrAttendance(
        employeeId: employee['id'],
        branchId: employee['branch_id'],
        token: token,
        checkIn: widget.checkIn,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.checkIn ? 'สแกน QR เช็กอิน' : 'สแกน QR เช็กเอาต์')),
        body: LayoutBuilder(
          builder: (context, constraints) => SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _cameraController,
                  fit: BoxFit.cover,
                  placeholderBuilder: (_, __) => ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 16),
                        Text(_cameraMessage, style: const TextStyle(color: Colors.white)),
                        TextButton(onPressed: _startCamera, child: const Text('ลองเปิดกล้องอีกครั้ง')),
                      ]),
                    ),
                  ),
                  errorBuilder: (_, error, __) => ColoredBox(
                    color: Colors.black,
                    child: Center(child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.videocam_off_outlined, color: Colors.white, size: 42),
                        const SizedBox(height: 12),
                        Text(error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                        TextButton(onPressed: _startCamera, child: const Text('ลองใหม่')),
                      ]),
                    )),
                  ),
                  onDetect: (capture) =>
                      _scan(capture.barcodes.firstOrNull?.rawValue),
                ),
                Center(
                  child: SizedBox(
                    width: constraints.maxWidth.clamp(180, 280).toDouble(),
                    height: constraints.maxWidth.clamp(180, 280).toDouble(),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                if (_saving)
                  const Center(child: CircularProgressIndicator(color: Colors.white)),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      color: const Color(0xddffffff),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _manualQrController,
                              decoration: const InputDecoration(
                                hintText: 'กล้องดำ? วาง QR token ที่นี่',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _saving
                                ? null
                                : () => _scan(_manualQrController.text.trim()),
                            child: const Text('ยืนยัน'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
