import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<String> writeExportFile(String filename, String content) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsString(content);
  return file.path;
}

Future<String> readImportFile(PlatformFile picked) async {
  if (picked.path != null) {
    return File(picked.path!).readAsString();
  }
  throw Exception('无法读取文件');
}
