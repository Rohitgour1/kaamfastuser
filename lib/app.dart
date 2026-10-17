import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:kaamfast/app_router.dart';
import 'package:kaamfast/core/ads/ad_config.dart';
import 'package:kaamfast/core/network/api_client.dart';
import 'package:kaamfast/core/storage/token_storage.dart';
import 'package:kaamfast/core/theme/app_theme.dart';
import 'package:kaamfast/features/tracking/searching_delivery_screen.dart';
import 'package:kaamfast/l10n/app_localizations.dart';
import 'package:kaamfast/providers/auth_provider.dart';
import 'package:kaamfast/providers/locale_provider.dart';
import 'package:kaamfast/providers/location_provider.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:kaamfast/services/auth_service.dart';
import 'package:kaamfast/services/live_sync.dart';
import 'package:kaamfast/services/location_service.dart';
import 'package:kaamfast/services/push_service.dart';
import 'package:provider/provider.dart';

class KaamFastApp extends StatefulWidget {
  const KaamFastApp({super.key});

  @override
  State<KaamFastApp> createState() => _KaamFastAppState();
}

class _KaamFastAppState extends State<KaamFastApp> {
  late final TokenStorage _tokens;
  late final ApiClient _api;
  late final AuthProvider _auth;
  late final AuthService _authService;
  late final LocationService _locationService;
  late final LocationProvider _location;
  late final LocaleProvider _locale;
  late final LiveSync _live;
  late final ProfileApi _profileApi;
  late final GoRouter _router;
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  final _rootNav = GlobalKey<NavigatorState>();
  int? _syncedUserId;
  int _lastPushTick = 0;
  int? _openedSearchingFor;

  @override
  void initState() {
    super.initState();
    _tokens = TokenStorage();
    _api = ApiClient(_tokens);
    _authService = AuthService(_api, _tokens);
    _auth = AuthProvider(_authService);
    _locationService = LocationService(_api);
    _location = LocationProvider(_locationService);
    _locale = LocaleProvider();
    _live = LiveSync();
    _profileApi = ProfileApi(_api);
    _router = createRouter(
      _auth,
      locale: _locale,
      navigatorKey: _rootNav,
    );
    _auth.addListener(_syncSession);
    _live.addListener(_onLiveEvent);
    _locale.load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdConfig.initialize();
    });
  }

  Future<void> _syncSession() async {
    final user = _auth.user;
    if (user == null) {
      _syncedUserId = null;
      await _live.stop();
      return;
    }
    if (_syncedUserId == user.id) return;
    _syncedUserId = user.id;
    await _live.startUser(user.id);
    try {
      final token = await PushService.token();
      if (token != null && token.isNotEmpty) {
        await _profileApi.registerDeviceToken(token);
      }
    } catch (_) {}
  }

  void _onLiveEvent() {
    if (_live.pushTick == _lastPushTick) return;
    _lastPushTick = _live.pushTick;

    final type = _live.lastData['type'];
    final bookingId = int.tryParse(_live.lastData['booking_id'] ?? '');
    final isSearching =
        type == 'booking.searching_delivery' ||
        (_live.lastTitle ?? '').toLowerCase().contains(
          'searching for delivery',
        );

    if (isSearching && bookingId != null) {
      _openSearching(bookingId, _live.lastData['offer_phase']);
      return;
    }

    final completed =
        type == 'booking.completed' ||
        (_live.lastTitle ?? '').toLowerCase().contains('booking completed');
    if (completed && bookingId != null) {
      _router.go('/tracking/$bookingId');
      return;
    }

    if (type == 'marketplace.chat') {
      final chatId = int.tryParse(_live.lastData['chat_id'] ?? '');
      if (chatId != null && chatId > 0) {
        final loc = _router.state.matchedLocation;
        if (loc == '/marketplace/chats/$chatId') return;
        _router.push('/marketplace/chats/$chatId');
        return;
      }
    }

    final title = _live.lastTitle;
    final body = _live.lastBody;
    if (title == null && body == null) return;
    _messenger.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          [
            title,
            body,
          ].whereType<String>().where((e) => e.isNotEmpty).join(' · '),
        ),
      ),
    );
  }

  void _openSearching(int bookingId, String? phase) {
    if (_openedSearchingFor == bookingId) return;
    _openedSearchingFor = bookingId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = _rootNav.currentState;
      if (nav == null) return;
      nav
          .push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  SearchingDeliveryScreen(bookingId: bookingId, phase: phase),
            ),
          )
          .whenComplete(() {
            if (_openedSearchingFor == bookingId) {
              _openedSearchingFor = null;
            }
          });
    });
  }

  @override
  void dispose() {
    _auth.removeListener(_syncSession);
    _live.removeListener(_onLiveEvent);
    _live.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: _api),
        Provider.value(value: _authService),
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _locale),
        ChangeNotifierProvider.value(value: _live),
        Provider(create: (_) => HomeService(_api)),
        Provider(create: (_) => ModuleService(_api)),
        Provider(create: (_) => BookingApi(_api)),
        Provider(create: (_) => AddressApi(_api)),
        Provider(create: (_) => VehicleApi(_api)),
        Provider(create: (_) => WalletApi(_api)),
        Provider.value(value: _profileApi),
        Provider(create: (_) => ReferralApi(_api)),
        Provider(create: (_) => NotificationApi(_api)),
        Provider(create: (_) => SupportApi(_api)),
        Provider(create: (_) => MarketplaceApi(_api)),
        Provider(create: (_) => ServiceRequestApi(_api)),
        Provider.value(value: _locationService),
        ChangeNotifierProvider.value(value: _location),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, locale, _) {
          return MaterialApp.router(
            title: 'Kaam Fast',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            locale: locale.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
            scaffoldMessengerKey: _messenger,
          );
        },
      ),
    );
  }
}
