import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:arco/core/theme/app_theme.dart';
import 'package:arco/core/providers/theme_provider.dart';
import 'package:arco/features/diagnosis/providers/diagnosis_provider.dart';
import 'package:arco/features/assistant/providers/chat_provider.dart';
import 'package:arco/core/services/api_service.dart';
import 'package:arco/core/services/storage_service.dart';
import 'package:arco/core/services/connectivity_service.dart';
import 'package:arco/features/home/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await _initializeServices();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const ArcoApp());
}

Future<void> _initializeServices() async {
  // Initialize storage
  await StorageService.instance.init();
  
  // Initialize API service
  ApiService.instance.init();
  
  // Initialize connectivity monitoring
  ConnectivityService.instance.init();
}

class ArcoApp extends StatelessWidget {
  const ArcoApp({super.key});

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
            title: 'Arco',
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