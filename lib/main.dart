import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:aspargo/core/theme/app_theme.dart';
import 'package:aspargo/core/providers/theme_provider.dart';
import 'package:aspargo/features/diagnosis/providers/diagnosis_provider.dart';
import 'package:aspargo/features/assistant/providers/chat_provider.dart';
import 'package:aspargo/core/services/api_service.dart';
import 'package:aspargo/core/services/storage_service.dart';
import 'package:aspargo/core/services/connectivity_service.dart';
import 'package:aspargo/features/diagnosis/services/image_service.dart'; // Added import
import 'package:aspargo/features/home/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await _initializeServices();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const AspargoApp()); // Updated runApp call
}

Future<void> _initializeServices() async {
  await StorageService.instance.init();
  
  ApiService.instance.init();
  
  ConnectivityService.instance.init();

  try {
    await ImageService().clearTemporaryFiles();
  } catch (e) {
    if (kDebugMode) {
      print('Failed to clear temporary files: $e');
    }
  }
}

class AspargoApp extends StatelessWidget {
  const AspargoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DiagnosisProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'aspargo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
