import 'excel_export_stub.dart' if (dart.library.html) 'excel_export_web.dart'
    as platform;

String _cell(Object? value) {
  final text = (value ?? '').toString().replaceAll('"', '""');
  return '"$text"';
}

void exportExcel(
    String fileName, List<String> headers, List<List<Object?>> rows) {
  final csv = [
    headers.map(_cell).join(','),
    ...rows.map((row) => row.map(_cell).join(',')),
  ].join('\r\n');
  platform.downloadSpreadsheet('$fileName.csv', csv);
}
