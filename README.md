# Kaam Fast User App

Flutter customer app for Kaam Fast marketplace.

## Run

1. Start backend: `cd ../kamzo_backend && php artisan serve`
2. Run app:

```bash
# Windows / desktop / chrome
flutter run -d windows
# or
flutter run -d chrome

# Android emulator (use host loopback)
flutter run -d emulator-5554 --dart-define=API_BASE=http://10.0.2.2:8000/api/v1

# Physical phone on same Wi-Fi
flutter run --dart-define=API_BASE=http://YOUR_LAN_IP:8000/api/v1
```

## Flows ready

- Phone OTP login (dev OTP often `123456`)
- Home modules
- Laundry book: items + address + quote + pay (cash/wallet/upi/gateway)
- Bookings list + detail + cancel + multi rating
- Wallet ledger
- Profile + addresses

Default API: `http://127.0.0.1:8000/api/v1`

## Maps / current location

1. Admin → **Settings → Maps**: enable + set Google **browser/mobile key** (Geocoding + Maps SDK).
2. Android map tiles need the same key in `android/local.properties`:

```properties
GOOGLE_MAPS_API_KEY=your_key_here
```

3. In app: **Addresses → Use current location** or **Pick on map**.
   Laundry booking also has **Use current location**.

App reads key from `GET /api/v1/maps/config` for reverse geocoding.
