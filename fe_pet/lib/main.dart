import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/api_client.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const PawMartApp());
}

class PawMartApp extends StatelessWidget {
  const PawMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (context, auth, cart) {
            final cartProvider = cart ?? CartProvider();
            // Automatically fetch cart when authenticated status changes
            if (auth.isAuthenticated) {
              cartProvider.fetchCart(silent: true);
            }
            return cartProvider;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PawMart',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          useMaterial3: true,
        ),
        builder: (context, child) {
          // Initialize ApiClient with backend token
          ApiClient().init(
            tokenGetter: () => Provider.of<AuthProvider>(context, listen: false).backendToken,
          );
          return child!;
        },
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.currentUser == null) {
              return const LoginScreen();
            }

            return const HomeScreen();
          },
        ),
      ),
    );
  }
}