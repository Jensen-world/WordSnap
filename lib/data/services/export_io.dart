import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<String> writeExportFile(String filename, String content) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsString(content);
  return file.path;
}
