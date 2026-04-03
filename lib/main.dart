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
    final storage = StorageService();
    final initialSettings = storage.getAppSettings();

    return StreamBuilder<void>(
      stream: storage.settingsChanges,
      initialData: null,
      builder: (context, _) {
        final settings = storage.getAppSettings();
        final fontScale = (settings['fontScale'] as num?)?.toDouble() ?? (initialSettings['fontScale'] as num?)?.toDouble() ?? 1.0;
        final highContrast = (settings['highContrastMode'] as bool?) ?? false;
        final reducedMotion = (settings['reducedMotion'] as bool?) ?? false;

        return MaterialApp(
          title: 'Aika Ascend',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(highContrast: highContrast),
          themeAnimationDuration: reducedMotion ? Duration.zero : const Duration(milliseconds: 250),
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(textScaler: TextScaler.linear(fontScale.clamp(0.8, 1.3))),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
