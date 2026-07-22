import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';
import 'package:mobile_scanner/src/web/mobile_scanner_web.dart';

/// Forces plugin registration for Flutter web builds served as static files.
bool _isRegistered = false;

void registerMobileScannerWeb() {
  if (_isRegistered) return;
  MobileScannerPlatform.instance = MobileScannerWeb();
  _isRegistered = true;
}
