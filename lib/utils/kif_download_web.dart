// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadKif(String filename, String content) {
  final bytes = html.Blob([content], 'text/plain');
  final url = html.Url.createObjectUrlFromBlob(bytes);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
