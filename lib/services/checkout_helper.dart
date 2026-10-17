import 'package:kaamfast/models/booking.dart';
import 'package:kaamfast/services/api_services.dart';
import 'package:kaamfast/services/razorpay_checkout.dart';
import 'package:kaamfast/widgets/payment_method_picker.dart';

/// Shared checkout against live payment APIs.
///
/// - `wallet` / `cash`: no Razorpay
/// - `upi` / `card` / `netbanking` / `gateway`: Razorpay then confirm
Future<BookingModel> placeBookingAndPay({
  required BookingApi bookingApi,
  required Map<String, dynamic> createBody,
  required String method,
  String? photoPath,
  String? customerPhone,
  String? customerName,
  String? customerEmail,
}) async {
  if (customerName == null || customerName.trim().isEmpty) {
    throw Exception('Please update your profile name before booking a service.');
  }

  final body = Map<String, dynamic>.from(createBody)..remove('tax');
  final booking = await bookingApi.create(body);

  if (photoPath != null && photoPath.isNotEmpty) {
    try {
      await bookingApi.uploadMedia(booking.id, photoPath);
    } catch (_) {}
  }

  await payBooking(
    bookingApi: bookingApi,
    booking: booking,
    method: method,
    customerPhone: customerPhone,
    customerEmail: customerEmail,
  );

  return bookingApi.confirm(booking.id);
}

Future<void> payBooking({
  required BookingApi bookingApi,
  required BookingModel booking,
  required String method,
  String? customerPhone,
  String? customerEmail,
}) async {
  final payMethod = BookingPayMethods.normalize(method);
  final payment = await bookingApi.pay(booking.id, payMethod);
  final status = payment['status']?.toString().toLowerCase();

  // Wallet is already paid after initiate. Cash waits for partner collection.
  if (BookingPayMethods.noRazorpay.contains(payMethod) || status == 'paid') {
    return;
  }

  final paymentId = (payment['id'] as num?)?.toInt();
  final orderId = payment['gateway_order_id']?.toString() ?? '';
  var key = payment['razorpay_key']?.toString() ?? '';
  final paise =
      (payment['amount_paise'] as num?)?.toInt() ??
      (((payment['amount'] as num?)?.toDouble() ?? 0) * 100).round();
  if (paymentId == null) {
    throw Exception('Payment could not be started.');
  }
  if (key.trim().isEmpty) {
    try {
      final config = await bookingApi.paymentConfig();
      key = config['key_id']?.toString() ?? '';
    } catch (_) {}
  }
  if (key.trim().isEmpty) {
    throw Exception('Razorpay Key ID missing. Save it in Admin → Payments.');
  }

  final mock = payment['mock'] == true;
  final paid = await RazorpayCheckout().open(
    key: key,
    orderId: mock ? '' : orderId,
    amountPaise: paise,
    description: 'Booking ${booking.bookingNumber}',
    contact: customerPhone,
    email: customerEmail,
  );
  await bookingApi.confirmPayment(paymentId, {
    ...paid,
    'method': payMethod,
  });
}
