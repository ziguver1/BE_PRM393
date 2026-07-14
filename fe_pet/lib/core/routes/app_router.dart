import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/auth/splash_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/register_screen.dart';
import '../../presentation/auth/forgot_password_screen.dart';
import '../../presentation/home/main_navigation_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/search/search_screen.dart';
import '../../presentation/favorite/favorites_screen.dart';
import '../../presentation/cart/cart_screen.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/profile/address_book_screen.dart';
import '../../presentation/profile/change_password_screen.dart';
import '../../presentation/category/category_detail_screen.dart';
import '../../presentation/product/product_detail_loader.dart';
import '../../presentation/checkout/checkout_screen.dart';
import '../../presentation/checkout/payment_webview_screen.dart';
import '../../presentation/order/order_history_screen.dart';
import '../../presentation/notifications/notifications_screen.dart';
import '../../presentation/chat/chat_screen.dart';
import '../../presentation/auth/providers/auth_provider.dart';
import '../../data/models/product_model.dart';


class RouterTransitionNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterTransitionNotifier(this._ref) {
    _ref.listen(
      authNotifierProvider,
      (previous, next) {
        notifyListeners();
      },
    );
  }
}

final routerTransitionNotifierProvider = Provider<RouterTransitionNotifier>((ref) {
  return RouterTransitionNotifier(ref);
});

final appRouterHelperProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(routerTransitionNotifierProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      
      final isAuthPath = state.matchedLocation == '/login' ||
                         state.matchedLocation == '/register' ||
                         state.matchedLocation == '/forgot-password' ||
                         state.matchedLocation == '/splash';

      // Keep showing splash or loading indicator during session restore
      if (authState.status == AuthStatus.initial || authState.status == AuthStatus.loading) {
        return null;
      }

      // If user is unauthenticated, redirect to /login unless they are already on an auth form route
      if (authState.status == AuthStatus.unauthenticated) {
        final isAuthFormPath = state.matchedLocation == '/login' ||
                               state.matchedLocation == '/register' ||
                               state.matchedLocation == '/forgot-password';
        return isAuthFormPath ? null : '/login';
      }

      // If user is authenticated and trying to access login/register/splash, redirect to home
      if (authState.status == AuthStatus.authenticated) {
        return isAuthPath ? '/home' : null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      
      // Bottom navigation tabs shell route
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: '/cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      
      // Inner detail routes
      GoRoute(
        path: '/category/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final name = state.uri.queryParameters['name'] ?? 'Category';
          return CategoryDetailScreen(categoryId: id, categoryName: name);
        },
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final productId = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          // If a full ProductModel was passed via extra, use it directly (no extra fetch needed)
          final extra = state.extra;
          final initialProduct = extra is ProductModel ? extra : null;
          return ProductDetailLoader(
            productId: productId,
            initialProduct: initialProduct,
          );
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/checkout/payment-webview',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final checkoutUrl = extra['checkoutUrl'] as String;
          final orderId = extra['orderId'] as int;
          return PaymentWebViewScreen(
            checkoutUrl: checkoutUrl,
            orderId: orderId,
          );
        },
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/profile/addresses',
        builder: (context, state) => const AddressBookScreen(),
      ),
      GoRoute(
        path: '/profile/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatScreen(),
      ),
    ],
  );
});
