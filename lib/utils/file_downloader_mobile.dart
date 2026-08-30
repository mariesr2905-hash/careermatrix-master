import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> downloadResumeFile(String url, String? token, String defaultFilename) async {
  final uri = Uri.parse(url);
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    if (token != null) request.headers.set('Authorization', 'Bearer $token');
    final response = await request.close();
    if (response.statusCode != 200) {
      final body = await response.transform(const Utf8Decoder()).join();
      String message = 'Could not download resume (${response.statusCode})';
      try {
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        message = decoded['message'] as String? ?? message;
      } catch (_) {}
      throw Exception(message);
    }
    final bytes = await response.fold<List<int>>(<int>[], (acc, chunk) => acc..addAll(chunk));
    final dir = await getApplicationDocumentsDirectory();
    String filename = defaultFilename;
    final disposition = response.headers.value('content-disposition');
    if (disposition != null) {
      final match = RegExp('filename="?([^"]+)"?').firstMatch(disposition);
      if (match != null) filename = match.group(1)!;
    }
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  } finally {
    client.close();
  }
}

Future<void> openUrlInNewTab(String url) async {
  // Safe stub for native. If URL launcher is not in dependencies, we just print or throw.
  // The UI is designed to only call this on kIsWeb, or fallback to the BottomSheet on native anyway.
  print('openUrlInNewTab is not supported on native: $url');
}

