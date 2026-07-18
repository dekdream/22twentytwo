import 'package:mobile_scanner/src/mobile_scanner_platform_interface.dart';
import 'package:mobile_scanner/src/web/mobile_scanner_web.dart';

/// Forces plugin registration for Flutter web builds served as static files.
void registerMobileScannerWeb() {
  MobileScannerPlatform.instance = MobileScannerWeb();
}
