import 'package:file_picker/file_picker.dart';

Future<String> writeExportFile(String filename, String content) async {
  return content;
}

Future<String> readImportFile(PlatformFile picked) async {
  if (picked.bytes != null) {
    return String.fromCharCodes(picked.bytes!);
  }
  throw Exception('无法读取文件');
}
