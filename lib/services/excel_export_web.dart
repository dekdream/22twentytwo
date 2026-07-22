// ignore: deprecated_member_use
import 'dart:html' as html;
import 'dart:convert';

void downloadSpreadsheet(String fileName, String content) {
  final bytes = utf8.encode('\ufeff$content');
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
