import 'package:flutter/material.dart';
import 'package:kaamfast/app.dart';
import 'package:kaamfast/services/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushService.init();
  runApp(const KaamFastApp());
}
