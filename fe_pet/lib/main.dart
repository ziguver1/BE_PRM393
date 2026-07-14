import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:provider/provider.dart' as provider_pkg;
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'core/configs/providers.dart';
import 'core/routes/app_router.dart';
import 'core/themes/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const PawMartApp(),
    ),
  );
}

class PawMartApp extends ConsumerWidget {
  const PawMartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterHelperProvider);
    
    return provider_pkg.MultiProvider(
      providers: [
        provider_pkg.ChangeNotifierProvider(create: (_) => CartProvider()),
        provider_pkg.ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'PawMart',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: router,
      ),
    );
  }
}