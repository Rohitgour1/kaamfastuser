import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:kaamfast/services/push_service.dart';

/// FCM + Firebase RTDB live events so bookings, tracking, and wallet refresh instantly.
class LiveSync extends ChangeNotifier {
  LiveSync();

  final List<StreamSubscription<dynamic>> _subs = [];
  StreamSubscription<DatabaseEvent>? _bookingSub;
  int tick = 0;
  int pushTick = 0;
  String? lastTitle;
  String? lastBody;
  Map<String, String> lastData = {};

  Future<void> startUser(int userId) async {
    await stop();
    await PushService.init();
    _listenPush();
    _listenPath('live/users/$userId/latest');
  }

  Future<void> startPartner(int partnerId) async {
    await stop();
    await PushService.init();
    _listenPush();
    _listenPath('live/partners/$partnerId/latest');
  }

  void watchBooking(int bookingId) {
    _bookingSub?.cancel();
    try {
      _bookingSub = FirebaseDatabase.instance
          .ref('live/bookings/$bookingId')
          .onValue
          .listen((_) => _bump());
    } catch (e) {
      debugPrint('Live booking listen skipped: $e');
    }
  }

  void _listenPush() {
    _subs.add(PushService.foreground.listen(_onMessage));
    _subs.add(PushService.opened.listen(_onMessage));
  }

  void _listenPath(String path) {
    try {
      _subs.add(
        FirebaseDatabase.instance.ref(path).onValue.listen((_) => _bump()),
      );
    } catch (e) {
      debugPrint('Live path listen skipped: $e');
    }
  }

  void _onMessage(RemoteMessage message) {
    lastTitle = message.notification?.title;
    lastBody = message.notification?.body;
    lastData = message.data.map((key, value) => MapEntry(key, '$value'));
    pushTick++;
    _bump();
  }

  void _bump() {
    tick++;
    notifyListeners();
  }

  Future<void> stop() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
    await _bookingSub?.cancel();
    _bookingSub = null;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
