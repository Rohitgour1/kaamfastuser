// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Kaam Fast';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get chooseLanguageSubtitle => 'You can change this later from Profile';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get continueLabel => 'Continue';

  @override
  String get getStarted => 'Get Started';

  @override
  String get onboardingTitle => 'Everything you need,\nin one app';

  @override
  String get onboardingSubtitle =>
      'From laundry to deep cleaning, manage your home with a few taps.';

  @override
  String get onboardingLaundry => 'Laundry';

  @override
  String get onboardingQuality => 'Quality';

  @override
  String get onboardingDelivery => 'Delivery';

  @override
  String get loginHeadline =>
      'Laundry, cleaning, helpers & more — booked in minutes.';

  @override
  String get continueWithPhone => 'Continue with phone';

  @override
  String get phoneHint => '10-digit mobile number';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get invalidPhone => 'Enter a valid 10-digit phone number';

  @override
  String get otpTitle => 'Verify OTP';

  @override
  String otpSubtitle(String phone) {
    return 'Enter the code sent to $phone';
  }

  @override
  String get verifyOtp => 'Verify';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get navHome => 'Home';

  @override
  String get navOrders => 'Orders';

  @override
  String get navTracking => 'Tracking';

  @override
  String get navProfile => 'Profile';

  @override
  String get profileTitle => 'Profile';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get editProfileSubtitle => 'Name, email & photo';

  @override
  String get inviteEarn => 'Invite & Earn';

  @override
  String get inviteEarnSubtitle => 'Share your code and earn on every booking';

  @override
  String get savedAddresses => 'Saved addresses';

  @override
  String get wallet => 'Wallet';

  @override
  String get marketplace => 'Marketplace';

  @override
  String get marketplaceChip => 'Market';

  @override
  String get marketplaceSubtitle => 'For Sale, Wanted & chats';

  @override
  String get myMarketplacePosts => 'My marketplace posts';

  @override
  String get marketplaceChats => 'Marketplace chats';

  @override
  String get support => 'Support';

  @override
  String get logout => 'Logout';

  @override
  String get language => 'Language';

  @override
  String languageSubtitle(String current) {
    return 'App language · $current';
  }

  @override
  String get forSale => 'For Sale';

  @override
  String get wanted => 'Wanted';

  @override
  String get browse => 'Browse';

  @override
  String get sellItem => 'Sell item';

  @override
  String get postRequest => 'Post request';

  @override
  String get myPosts => 'My posts';

  @override
  String get chats => 'Chats';

  @override
  String get seeAll => 'See all';

  @override
  String get chatWithSeller => 'Chat with seller';

  @override
  String get iHaveThis => 'I have this';

  @override
  String get typeAMessage => 'Type a message';

  @override
  String get makeAnOffer => 'Make an offer';

  @override
  String sendOffer(String amount) {
    return 'Send offer ₹$amount';
  }

  @override
  String listedAt(String amount) {
    return 'Listed at ₹$amount';
  }

  @override
  String get tapToChangeBy10 => 'Tap − / + to change by 10%';

  @override
  String get listedPrice => 'Listed price';

  @override
  String get decrease10 => '-10%';

  @override
  String get increase10 => '+10%';

  @override
  String offerMessageBuyer(String amount) {
    return 'I would like to offer ₹$amount for this.';
  }

  @override
  String offerMessageSeller(String amount) {
    return 'I can do ₹$amount for this.';
  }

  @override
  String get qrIsItAvailable => 'Is it available?';

  @override
  String get qrIsItAvailableMsg => 'Hi, is this still available?';

  @override
  String get qrCanWeMeet => 'Can we meet?';

  @override
  String get qrCanWeMeetMsg => 'Can we meet and check it?';

  @override
  String get qrFinalPrice => 'Final price?';

  @override
  String get qrFinalPriceMsg => 'What is your final price?';

  @override
  String get qrCondition => 'Condition?';

  @override
  String get qrConditionMsg => 'Can you share more about the condition?';

  @override
  String get qrWhereToSee => 'Where to see?';

  @override
  String get qrWhereToSeeMsg => 'Where can I see this item?';

  @override
  String get qrIHaveThis => 'I have this';

  @override
  String get qrIHaveThisMsg => 'Hi, I have this item.';

  @override
  String get qrStillNeeded => 'Still needed?';

  @override
  String get qrStillNeededMsg => 'Is this still needed?';

  @override
  String get qrBudgetFlexible => 'Budget flexible?';

  @override
  String get qrBudgetFlexibleMsg => 'Is your budget flexible?';

  @override
  String get qrYesAvailable => 'Yes, available';

  @override
  String get qrYesAvailableMsg => 'Yes, it is still available.';

  @override
  String get qrYourBestOffer => 'Your best offer?';

  @override
  String get qrYourBestOfferMsg => 'What is your best offer?';

  @override
  String get qrCanMeetSeller => 'Can we meet?';

  @override
  String get qrCanMeetSellerMsg => 'Yes, we can meet and you can check it.';

  @override
  String get qrPriceNegotiable => 'Price negotiable';

  @override
  String get qrPriceNegotiableMsg => 'Price is negotiable. Share your offer.';

  @override
  String get qrPriceFirm => 'Price firm';

  @override
  String get qrPriceFirmMsg => 'The listed price is firm.';

  @override
  String get qrWhereToMeet => 'Where to meet?';

  @override
  String get qrWhereToMeetMsg => 'Please share a nearby place to meet.';

  @override
  String get qrSoldAlready => 'Sold already';

  @override
  String get qrSoldAlreadyMsg => 'Sorry, this item is already sold.';

  @override
  String get qrStillNeededYes => 'Still needed';

  @override
  String get qrStillNeededYesMsg => 'Yes, I still need this.';

  @override
  String get qrYourPrice => 'Your price?';

  @override
  String get qrYourPriceMsg => 'What price are you expecting?';

  @override
  String get qrSharePhotos => 'Share photos';

  @override
  String get qrSharePhotosMsg => 'Please share clear photos of the item.';

  @override
  String get qrNotNeeded => 'Not needed now';

  @override
  String get qrNotNeededMsg => 'Thanks, I no longer need this.';

  @override
  String get chatClosed => 'Chat closed';

  @override
  String get sayHello => 'Say hello to start the conversation';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get status => 'Status';

  @override
  String get searchItems => 'Search items';

  @override
  String get searchRequests => 'Search requests';

  @override
  String get noItemsForSale => 'No items for sale';

  @override
  String get noRequestsYet => 'No requests yet';

  @override
  String get location => 'LOCATION';

  @override
  String get completeProfile => 'Complete profile';

  @override
  String get name => 'Name';

  @override
  String get email => 'Email';
}
