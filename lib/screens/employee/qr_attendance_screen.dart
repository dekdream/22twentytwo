import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/mobile_scanner_registration.dart';
import '../../services/supabase_service.dart';

class QrAttendanceScreen extends StatefulWidget {
  const QrAttendanceScreen({super.key, required this.checkIn});

  final bool checkIn;

  @override
  State<QrAttendanceScreen> createState() => _QrAttendanceScreenState();
}

class _QrAttendanceScreenState extends State<QrAttendanceScreen> {
  final _manualQrController = TextEditingController();
  final _cameraController = MobileScannerController(autoStart: false);
  bool _saving = false;
  bool _startingCamera = false;
  String _cameraMessage = 'กำลังเปิดกล้อง...';

  @override
  void initState() {
    super.initState();
    registerMobileScannerWeb();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCamera());
  }

  Future<void> _startCamera() async {
    if (!mounted || _startingCamera || _cameraController.value.isRunning) return;
    _startingCamera = true;
    setState(() => _cameraMessage = 'กำลังเปิดกล้อง...');
    try {
      await _cameraController.start();
    } catch (error) {
      if (mounted) setState(() => _cameraMessage = 'เปิดกล้องไม่สำเร็จ: $error');
    } finally {
      _startingCamera = false;
    }
  }

  /// On web the previous MediaStream must completely stop before it starts
  /// again. Otherwise the browser can show a blank preview.
  Future<void> _restartCamera() async {
    if (_startingCamera) return;
    _startingCamera = true;
    if (mounted) setState(() => _cameraMessage = 'กำลังเริ่มกล้องใหม่...');
    try {
      await _cameraController.stop();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      await _cameraController.start();
    } catch (error) {
      if (mounted) setState(() => _cameraMessage = 'เปิดกล้องไม่สำเร็จ: $error');
    } finally {
      _startingCamera = false;
    }
  }

  Future<void> _closeScanner([bool completed = false]) async {
    try {
      await _cameraController.stop();
    } catch (_) {
      // The stream can already be gone after a camera error.
    }
    if (mounted) Navigator.pop(context, completed ? true : null);
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

    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _saving = true);
    try {
      await hrRepository.verifyQrAttendance(
        employeeId: employee['id'],
        branchId: employee['branch_id'],
        token: token,
        checkIn: widget.checkIn,
      );
      await _closeScanner(true);
    } catch (error) {
      messenger?.showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: () async {
          await _cameraController.stop();
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _closeScanner,
            ),
            title: Text(widget.checkIn ? 'สแกน QR เช็กอิน' : 'สแกน QR เช็กเอาต์'),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) => SizedBox.expand(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _cameraController,
                    fit: BoxFit.cover,
                    placeholderBuilder: (_, __) => _cameraPlaceholder(),
                    errorBuilder: (_, error, __) => _cameraError(error),
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
        ),
      );

  Widget _cameraPlaceholder() => ColoredBox(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(_cameraMessage, style: const TextStyle(color: Colors.white)),
              TextButton(
                onPressed: _restartCamera,
                child: const Text('ลองเปิดกล้องอีกครั้ง'),
              ),
            ],
          ),
        ),
      );

  Widget _cameraError(MobileScannerException error) => ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off_outlined,
                    color: Colors.white, size: 42),
                const SizedBox(height: 12),
                Text(error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white)),
                TextButton(onPressed: _restartCamera, child: const Text('ลองใหม่')),
              ],
            ),
          ),
        ),
      );
}
