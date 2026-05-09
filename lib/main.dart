import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const App());
}
