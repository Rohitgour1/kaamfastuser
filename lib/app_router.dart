import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/features/addresses/addresses_screen.dart';
import 'package:kaamfast/features/addresses/location_picker_screen.dart';
import 'package:kaamfast/features/auth/complete_profile_screen.dart';
import 'package:kaamfast/features/auth/language_select_screen.dart';
import 'package:kaamfast/features/auth/login_screen.dart';
import 'package:kaamfast/features/auth/onboarding_screen.dart';
import 'package:kaamfast/features/auth/otp_screen.dart';
import 'package:kaamfast/features/auth/splash_screen.dart';
import 'package:kaamfast/features/bookings/bookings_screen.dart';
import 'package:kaamfast/features/home/home_screen.dart';
import 'package:kaamfast/features/cleaning/cleaning_booking_screen.dart';
import 'package:kaamfast/features/delivery/delivery_booking_screen.dart';
import 'package:kaamfast/features/helper/helper_booking_screen.dart';
import 'package:kaamfast/features/laundry/laundry_booking_screen.dart';
import 'package:kaamfast/features/laundry/laundry_pickup_screen.dart';
import 'package:kaamfast/features/marketplace/marketplace_chat_thread_screen.dart';
import 'package:kaamfast/features/marketplace/marketplace_chats_screen.dart';
import 'package:kaamfast/features/marketplace/marketplace_list_screen.dart';
import 'package:kaamfast/features/marketplace/marketplace_my_posts_screen.dart';
import 'package:kaamfast/features/marketplace/marketplace_post_detail_screen.dart';
import 'package:kaamfast/features/marketplace/marketplace_post_form_screen.dart';
import 'package:kaamfast/features/profile/edit_profile_screen.dart';
import 'package:kaamfast/features/profile/invite_earn_screen.dart';
import 'package:kaamfast/features/profile/profile_screen.dart';
import 'package:kaamfast/features/service_requests/service_requests_screen.dart';
import 'package:kaamfast/features/shell/main_shell.dart';
import 'package:kaamfast/features/support/support_chat_screen.dart';
import 'package:kaamfast/features/support/support_screen.dart';
import 'package:kaamfast/features/support/support_ticket_screen.dart';
import 'package:kaamfast/features/tracking/live_tracking_detail_screen.dart';
import 'package:kaamfast/features/tracking/tracking_screen.dart';
import 'package:kaamfast/features/wallet/payment_method_screen.dart';
import 'package:kaamfast/features/wallet/wallet_screen.dart';
import 'package:kaamfast/features/notifications/notifications_screen.dart';
import 'package:kaamfast/core/ads/route_banner_slot.dart';
import 'package:kaamfast/providers/auth_provider.dart';
import 'package:kaamfast/providers/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

GoRouter createRouter(
  AuthProvider auth, {
  required LocaleProvider locale,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/splash',
    refreshListenable: Listenable.merge([auth, locale]),
    redirect: (context, state) async {
      final loc = state.matchedLocation;
      if (!auth.bootstrapped) {
        return loc == '/splash' ? null : '/splash';
      }

      final prefs = await SharedPreferences.getInstance();
      final languageSelected =
          prefs.getBool(LocaleProvider.selectedPrefKey) ?? false;
      final onboardingDone = prefs.getBool(OnboardingScreen.prefKey) ?? false;
      final languageEdit = state.uri.queryParameters['edit'] == '1';

      final publicRoutes = {
        '/splash',
        '/login',
        '/otp',
        '/onboarding',
        '/language',
      };
      final loggingIn = publicRoutes.contains(loc);

      if (loc == '/splash') {
        if (!languageSelected) return '/language';
        if (!onboardingDone) return '/onboarding';
        if (!auth.isLoggedIn) return '/login';
        return auth.needsProfile ? '/complete-profile' : '/home';
      }

      if (!languageSelected && loc != '/language') {
        return '/language';
      }

      if (languageSelected && loc == '/language' && !languageEdit) {
        if (!onboardingDone) return '/onboarding';
        if (!auth.isLoggedIn) return '/login';
        return auth.needsProfile ? '/complete-profile' : '/home';
      }

      if (!onboardingDone && loc != '/onboarding' && loc != '/language') {
        return '/onboarding';
      }
      if (onboardingDone && loc == '/onboarding') {
        if (!auth.isLoggedIn) return '/login';
        return auth.needsProfile ? '/complete-profile' : '/home';
      }
      if (!auth.isLoggedIn && !loggingIn) return '/login';
      if (auth.isLoggedIn && auth.needsProfile && loc != '/complete-profile') {
        return '/complete-profile';
      }
      if (auth.isLoggedIn && !auth.needsProfile && loc == '/complete-profile') {
        return '/home';
      }
      if (auth.isLoggedIn && (loc == '/login' || loc == '/otp')) {
        return auth.needsProfile ? '/complete-profile' : '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => routeWithBanner('/splash', const SplashScreen()),
      ),
      GoRoute(
        path: '/language',
        builder: (_, state) {
          final fromSettings = state.uri.queryParameters['edit'] == '1';
          return routeWithBanner(
            '/language',
            LanguageSelectScreen(fromSettings: fromSettings),
          );
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, _) =>
            routeWithBanner('/onboarding', const OnboardingScreen()),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => routeWithBanner('/login', const LoginScreen()),
      ),
      GoRoute(
        path: '/otp',
        builder: (_, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          final debugOtp = state.uri.queryParameters['debug_otp'];
          return routeWithBanner(
            '/otp',
            OtpScreen(phone: phone, debugOtp: debugOtp),
          );
        },
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (_, _) =>
            routeWithBanner('/complete-profile', const CompleteProfileScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(shell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookings',
                builder: (_, _) => const BookingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tracking',
                builder: (_, _) => const TrackingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/laundry',
        builder: (_, state) {
          final service = state.uri.queryParameters['service'];
          final atRaw = state.uri.queryParameters['at'];
          DateTime? at;
          if (atRaw != null && atRaw.isNotEmpty) {
            at = DateTime.tryParse(atRaw);
          }
          return routeWithBanner(
            '/laundry',
            LaundryBookingScreen(
              serviceName: service,
              scheduledAt: at,
              instant: state.uri.queryParameters['instant'] == '1',
              couponCode: state.uri.queryParameters['coupon'],
              addressId: int.tryParse(state.uri.queryParameters['address_id'] ?? ''),
            ),
          );
        },
      ),
      GoRoute(
        path: '/laundry/pickup',
        builder: (_, state) => routeWithBanner(
          '/laundry/pickup',
          LaundryPickupScreen(
            serviceName: state.uri.queryParameters['service'],
            couponCode: state.uri.queryParameters['coupon'],
          ),
        ),
      ),
      GoRoute(
        path: '/delivery',
        builder: (_, state) => routeWithBanner(
          '/delivery',
          DeliveryBookingScreen(
            initialTypeIndex: int.tryParse(state.uri.queryParameters['size'] ?? ''),
          ),
        ),
      ),
      GoRoute(
        path: '/cleaning',
        builder: (_, state) {
          final category = state.uri.queryParameters['category'];
          return routeWithBanner(
            '/cleaning',
            CleaningBookingScreen(categorySlug: category),
          );
        },
      ),
      GoRoute(
        path: '/helper',
        builder: (_, state) {
          final hint = state.uri.queryParameters['service'];
          return routeWithBanner(
            '/helper',
            HelperBookingScreen(
              initialServiceHint: hint,
              serviceId: int.tryParse(state.uri.queryParameters['service_id'] ?? ''),
            ),
          );
        },
      ),
      GoRoute(
        path: '/bookings/:id',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return routeWithBanner(
            '/bookings/:id',
            LiveTrackingDetailScreen(bookingId: id),
          );
        },
      ),
      GoRoute(
        path: '/tracking/:id',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return routeWithBanner(
            '/tracking/:id',
            LiveTrackingDetailScreen(bookingId: id),
          );
        },
      ),
      GoRoute(
        path: '/addresses',
        builder: (_, _) =>
            routeWithBanner('/addresses', const AddressesScreen()),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) =>
            routeWithBanner('/profile/edit', const EditProfileScreen()),
      ),
      GoRoute(
        path: '/invite',
        builder: (_, _) => routeWithBanner('/invite', const InviteEarnScreen()),
      ),
      GoRoute(
        path: '/location-picker',
        builder: (_, _) =>
            routeWithBanner('/location-picker', const LocationPickerScreen()),
      ),
      GoRoute(
        path: '/wallet',
        builder: (_, _) => routeWithBanner('/wallet', const WalletScreen()),
      ),
      GoRoute(
        path: '/wallet/payment-method',
        builder: (_, _) => routeWithBanner(
          '/wallet/payment-method',
          const PaymentMethodScreen(),
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) =>
            routeWithBanner('/notifications', const NotificationsScreen()),
      ),
      GoRoute(
        path: '/support',
        builder: (_, _) => routeWithBanner('/support', const SupportScreen()),
      ),
      GoRoute(
        path: '/support/chat',
        builder: (_, _) =>
            routeWithBanner('/support/chat', const SupportChatScreen()),
      ),
      GoRoute(
        path: '/support/ticket',
        builder: (_, _) =>
            routeWithBanner('/support/ticket', const SupportTicketScreen()),
      ),
      GoRoute(
        path: '/service-requests',
        builder: (_, _) => routeWithBanner(
          '/service-requests',
          const ServiceRequestsScreen(),
        ),
      ),
      GoRoute(
        path: '/service-requests/new',
        builder: (_, _) => routeWithBanner(
          '/service-requests/new',
          const ServiceRequestFormScreen(),
        ),
      ),
      GoRoute(
        path: '/service-requests/:id',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return routeWithBanner(
            '/service-requests/:id',
            ServiceRequestDetailScreen(id: id),
          );
        },
      ),
      GoRoute(
        path: '/marketplace/sale',
        builder: (_, _) => routeWithBanner(
          '/marketplace/sale',
          const MarketplaceListScreen(type: 'sale'),
        ),
      ),
      GoRoute(
        path: '/marketplace/wanted',
        builder: (_, _) => routeWithBanner(
          '/marketplace/wanted',
          const MarketplaceListScreen(type: 'request'),
        ),
      ),
      GoRoute(
        path: '/marketplace/mine',
        builder: (_, _) => routeWithBanner(
          '/marketplace/mine',
          const MarketplaceMyPostsScreen(),
        ),
      ),
      GoRoute(
        path: '/marketplace/chats',
        builder: (_, _) => routeWithBanner(
          '/marketplace/chats',
          const MarketplaceChatsScreen(),
        ),
      ),
      GoRoute(
        path: '/marketplace/chats/:id',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return routeWithBanner(
            '/marketplace/chats/:id',
            MarketplaceChatThreadScreen(chatId: id),
          );
        },
      ),
      GoRoute(
        path: '/marketplace/posts/new',
        builder: (_, state) {
          final type = state.uri.queryParameters['type'] ?? 'sale';
          return routeWithBanner(
            '/marketplace/posts/new',
            MarketplacePostFormScreen(initialType: type),
          );
        },
      ),
      GoRoute(
        path: '/marketplace/posts/:id/edit',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return routeWithBanner(
            '/marketplace/posts/:id/edit',
            MarketplacePostFormScreen(postId: id),
          );
        },
      ),
      GoRoute(
        path: '/marketplace/posts/:id',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return routeWithBanner(
            '/marketplace/posts/:id',
            MarketplacePostDetailScreen(postId: id),
          );
        },
      ),
    ],
  );
}
