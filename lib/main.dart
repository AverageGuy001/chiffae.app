import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants.dart';
import 'screens/login_screen.dart';
import 'services/ai_triage_service.dart';
import 'services/gemini_service.dart';
import 'services/pharmacy_data_service.dart';
import 'services/voice_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await AiTriageService.instance.load();
  await PharmacyDataService.instance.load();
  final groqKey = dotenv.env['GROQ_API_KEY'] ?? dotenv.env['GEMINI_API_KEY'];
  if (groqKey == null || groqKey.isEmpty) {
    throw Exception('Missing GROQ_API_KEY in .env');
  }
  GeminiService.instance.init(groqKey);
  VoiceService.instance.init();
  runApp(const ChifaaeApp());
}

class ChifaaeApp extends StatelessWidget {
  const ChifaaeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(useMaterial3: true);

    return MaterialApp(
      title: 'Chifaae',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          onPrimary: AppColors.onPrimary,
          onSurface: AppColors.onBackground,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.montserratTextTheme(base.textTheme).apply(
          bodyColor: AppColors.onBackground,
          displayColor: AppColors.onBackground,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.montserrat(
            color: AppColors.onBackground,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          iconTheme: const IconThemeData(color: AppColors.onBackground),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
