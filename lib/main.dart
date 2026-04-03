import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'services/content_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF060B1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await ContentService.instance.load();
  await StorageService().init();

  runApp(const AikaAscendApp());
}

class AikaAscendApp extends StatelessWidget {
  const AikaAscendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aika Ascend',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
