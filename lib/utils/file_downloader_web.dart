import 'dart:html' as html;

Future<String> downloadResumeFile(String url, String? token, String defaultFilename) async {
  final separator = url.contains('?') ? '&' : '?';
  final downloadUrl = token != null ? '$url${separator}token=$token' : url;
  
  final anchor = html.AnchorElement(href: downloadUrl)
    ..target = '_blank'
    ..download = defaultFilename;
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  
  return 'opened in new tab';
}

Future<void> openUrlInNewTab(String url) async {
  html.window.open(url, '_blank');
}

