import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Kaam Fast'**
  String get appName;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @chooseLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this later from Profile'**
  String get chooseLanguageSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get languageHindi;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Everything you need,\nin one app'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From laundry to deep cleaning, manage your home with a few taps.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingLaundry.
  ///
  /// In en, this message translates to:
  /// **'Laundry'**
  String get onboardingLaundry;

  /// No description provided for @onboardingQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get onboardingQuality;

  /// No description provided for @onboardingDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get onboardingDelivery;

  /// No description provided for @loginHeadline.
  ///
  /// In en, this message translates to:
  /// **'Laundry, cleaning, helpers & more — booked in minutes.'**
  String get loginHeadline;

  /// No description provided for @continueWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Continue with phone'**
  String get continueWithPhone;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'10-digit mobile number'**
  String get phoneHint;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit phone number'**
  String get invalidPhone;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to {phone}'**
  String otpSubtitle(String phone);

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyOtp;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// No description provided for @navTracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get navTracking;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, email & photo'**
  String get editProfileSubtitle;

  /// No description provided for @inviteEarn.
  ///
  /// In en, this message translates to:
  /// **'Invite & Earn'**
  String get inviteEarn;

  /// No description provided for @inviteEarnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share your code and earn on every booking'**
  String get inviteEarnSubtitle;

  /// No description provided for @savedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved addresses'**
  String get savedAddresses;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @marketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplace;

  /// No description provided for @marketplaceChip.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get marketplaceChip;

  /// No description provided for @marketplaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For Sale, Wanted & chats'**
  String get marketplaceSubtitle;

  /// No description provided for @myMarketplacePosts.
  ///
  /// In en, this message translates to:
  /// **'My marketplace posts'**
  String get myMarketplacePosts;

  /// No description provided for @marketplaceChats.
  ///
  /// In en, this message translates to:
  /// **'Marketplace chats'**
  String get marketplaceChats;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App language · {current}'**
  String languageSubtitle(String current);

  /// No description provided for @forSale.
  ///
  /// In en, this message translates to:
  /// **'For Sale'**
  String get forSale;

  /// No description provided for @wanted.
  ///
  /// In en, this message translates to:
  /// **'Wanted'**
  String get wanted;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @sellItem.
  ///
  /// In en, this message translates to:
  /// **'Sell item'**
  String get sellItem;

  /// No description provided for @postRequest.
  ///
  /// In en, this message translates to:
  /// **'Post request'**
  String get postRequest;

  /// No description provided for @myPosts.
  ///
  /// In en, this message translates to:
  /// **'My posts'**
  String get myPosts;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @chatWithSeller.
  ///
  /// In en, this message translates to:
  /// **'Chat with seller'**
  String get chatWithSeller;

  /// No description provided for @iHaveThis.
  ///
  /// In en, this message translates to:
  /// **'I have this'**
  String get iHaveThis;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get typeAMessage;

  /// No description provided for @makeAnOffer.
  ///
  /// In en, this message translates to:
  /// **'Make an offer'**
  String get makeAnOffer;

  /// No description provided for @sendOffer.
  ///
  /// In en, this message translates to:
  /// **'Send offer ₹{amount}'**
  String sendOffer(String amount);

  /// No description provided for @listedAt.
  ///
  /// In en, this message translates to:
  /// **'Listed at ₹{amount}'**
  String listedAt(String amount);

  /// No description provided for @tapToChangeBy10.
  ///
  /// In en, this message translates to:
  /// **'Tap − / + to change by 10%'**
  String get tapToChangeBy10;

  /// No description provided for @listedPrice.
  ///
  /// In en, this message translates to:
  /// **'Listed price'**
  String get listedPrice;

  /// No description provided for @decrease10.
  ///
  /// In en, this message translates to:
  /// **'-10%'**
  String get decrease10;

  /// No description provided for @increase10.
  ///
  /// In en, this message translates to:
  /// **'+10%'**
  String get increase10;

  /// No description provided for @offerMessageBuyer.
  ///
  /// In en, this message translates to:
  /// **'I would like to offer ₹{amount} for this.'**
  String offerMessageBuyer(String amount);

  /// No description provided for @offerMessageSeller.
  ///
  /// In en, this message translates to:
  /// **'I can do ₹{amount} for this.'**
  String offerMessageSeller(String amount);

  /// No description provided for @qrIsItAvailable.
  ///
  /// In en, this message translates to:
  /// **'Is it available?'**
  String get qrIsItAvailable;

  /// No description provided for @qrIsItAvailableMsg.
  ///
  /// In en, this message translates to:
  /// **'Hi, is this still available?'**
  String get qrIsItAvailableMsg;

  /// No description provided for @qrCanWeMeet.
  ///
  /// In en, this message translates to:
  /// **'Can we meet?'**
  String get qrCanWeMeet;

  /// No description provided for @qrCanWeMeetMsg.
  ///
  /// In en, this message translates to:
  /// **'Can we meet and check it?'**
  String get qrCanWeMeetMsg;

  /// No description provided for @qrFinalPrice.
  ///
  /// In en, this message translates to:
  /// **'Final price?'**
  String get qrFinalPrice;

  /// No description provided for @qrFinalPriceMsg.
  ///
  /// In en, this message translates to:
  /// **'What is your final price?'**
  String get qrFinalPriceMsg;

  /// No description provided for @qrCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition?'**
  String get qrCondition;

  /// No description provided for @qrConditionMsg.
  ///
  /// In en, this message translates to:
  /// **'Can you share more about the condition?'**
  String get qrConditionMsg;

  /// No description provided for @qrWhereToSee.
  ///
  /// In en, this message translates to:
  /// **'Where to see?'**
  String get qrWhereToSee;

  /// No description provided for @qrWhereToSeeMsg.
  ///
  /// In en, this message translates to:
  /// **'Where can I see this item?'**
  String get qrWhereToSeeMsg;

  /// No description provided for @qrIHaveThis.
  ///
  /// In en, this message translates to:
  /// **'I have this'**
  String get qrIHaveThis;

  /// No description provided for @qrIHaveThisMsg.
  ///
  /// In en, this message translates to:
  /// **'Hi, I have this item.'**
  String get qrIHaveThisMsg;

  /// No description provided for @qrStillNeeded.
  ///
  /// In en, this message translates to:
  /// **'Still needed?'**
  String get qrStillNeeded;

  /// No description provided for @qrStillNeededMsg.
  ///
  /// In en, this message translates to:
  /// **'Is this still needed?'**
  String get qrStillNeededMsg;

  /// No description provided for @qrBudgetFlexible.
  ///
  /// In en, this message translates to:
  /// **'Budget flexible?'**
  String get qrBudgetFlexible;

  /// No description provided for @qrBudgetFlexibleMsg.
  ///
  /// In en, this message translates to:
  /// **'Is your budget flexible?'**
  String get qrBudgetFlexibleMsg;

  /// No description provided for @qrYesAvailable.
  ///
  /// In en, this message translates to:
  /// **'Yes, available'**
  String get qrYesAvailable;

  /// No description provided for @qrYesAvailableMsg.
  ///
  /// In en, this message translates to:
  /// **'Yes, it is still available.'**
  String get qrYesAvailableMsg;

  /// No description provided for @qrYourBestOffer.
  ///
  /// In en, this message translates to:
  /// **'Your best offer?'**
  String get qrYourBestOffer;

  /// No description provided for @qrYourBestOfferMsg.
  ///
  /// In en, this message translates to:
  /// **'What is your best offer?'**
  String get qrYourBestOfferMsg;

  /// No description provided for @qrCanMeetSeller.
  ///
  /// In en, this message translates to:
  /// **'Can we meet?'**
  String get qrCanMeetSeller;

  /// No description provided for @qrCanMeetSellerMsg.
  ///
  /// In en, this message translates to:
  /// **'Yes, we can meet and you can check it.'**
  String get qrCanMeetSellerMsg;

  /// No description provided for @qrPriceNegotiable.
  ///
  /// In en, this message translates to:
  /// **'Price negotiable'**
  String get qrPriceNegotiable;

  /// No description provided for @qrPriceNegotiableMsg.
  ///
  /// In en, this message translates to:
  /// **'Price is negotiable. Share your offer.'**
  String get qrPriceNegotiableMsg;

  /// No description provided for @qrPriceFirm.
  ///
  /// In en, this message translates to:
  /// **'Price firm'**
  String get qrPriceFirm;

  /// No description provided for @qrPriceFirmMsg.
  ///
  /// In en, this message translates to:
  /// **'The listed price is firm.'**
  String get qrPriceFirmMsg;

  /// No description provided for @qrWhereToMeet.
  ///
  /// In en, this message translates to:
  /// **'Where to meet?'**
  String get qrWhereToMeet;

  /// No description provided for @qrWhereToMeetMsg.
  ///
  /// In en, this message translates to:
  /// **'Please share a nearby place to meet.'**
  String get qrWhereToMeetMsg;

  /// No description provided for @qrSoldAlready.
  ///
  /// In en, this message translates to:
  /// **'Sold already'**
  String get qrSoldAlready;

  /// No description provided for @qrSoldAlreadyMsg.
  ///
  /// In en, this message translates to:
  /// **'Sorry, this item is already sold.'**
  String get qrSoldAlreadyMsg;

  /// No description provided for @qrStillNeededYes.
  ///
  /// In en, this message translates to:
  /// **'Still needed'**
  String get qrStillNeededYes;

  /// No description provided for @qrStillNeededYesMsg.
  ///
  /// In en, this message translates to:
  /// **'Yes, I still need this.'**
  String get qrStillNeededYesMsg;

  /// No description provided for @qrYourPrice.
  ///
  /// In en, this message translates to:
  /// **'Your price?'**
  String get qrYourPrice;

  /// No description provided for @qrYourPriceMsg.
  ///
  /// In en, this message translates to:
  /// **'What price are you expecting?'**
  String get qrYourPriceMsg;

  /// No description provided for @qrSharePhotos.
  ///
  /// In en, this message translates to:
  /// **'Share photos'**
  String get qrSharePhotos;

  /// No description provided for @qrSharePhotosMsg.
  ///
  /// In en, this message translates to:
  /// **'Please share clear photos of the item.'**
  String get qrSharePhotosMsg;

  /// No description provided for @qrNotNeeded.
  ///
  /// In en, this message translates to:
  /// **'Not needed now'**
  String get qrNotNeeded;

  /// No description provided for @qrNotNeededMsg.
  ///
  /// In en, this message translates to:
  /// **'Thanks, I no longer need this.'**
  String get qrNotNeededMsg;

  /// No description provided for @chatClosed.
  ///
  /// In en, this message translates to:
  /// **'Chat closed'**
  String get chatClosed;

  /// No description provided for @sayHello.
  ///
  /// In en, this message translates to:
  /// **'Say hello to start the conversation'**
  String get sayHello;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @searchItems.
  ///
  /// In en, this message translates to:
  /// **'Search items'**
  String get searchItems;

  /// No description provided for @searchRequests.
  ///
  /// In en, this message translates to:
  /// **'Search requests'**
  String get searchRequests;

  /// No description provided for @noItemsForSale.
  ///
  /// In en, this message translates to:
  /// **'No items for sale'**
  String get noItemsForSale;

  /// No description provided for @noRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get noRequestsYet;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'LOCATION'**
  String get location;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get completeProfile;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
