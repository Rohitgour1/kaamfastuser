// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'काम फास्ट';

  @override
  String get chooseLanguage => 'अपनी भाषा चुनें';

  @override
  String get chooseLanguageSubtitle => 'बाद में प्रोफ़ाइल से बदल सकते हैं';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get continueLabel => 'आगे बढ़ें';

  @override
  String get getStarted => 'शुरू करें';

  @override
  String get onboardingTitle => 'जो चाहिए सब,\nएक ऐप में';

  @override
  String get onboardingSubtitle =>
      'लॉन्ड्री से डीप क्लीनिंग तक — घर का काम कुछ टैप में।';

  @override
  String get onboardingLaundry => 'लॉन्ड्री';

  @override
  String get onboardingQuality => 'क्वालिटी';

  @override
  String get onboardingDelivery => 'डिलीवरी';

  @override
  String get loginHeadline =>
      'लॉन्ड्री, सफाई, हेल्पर और और भी — मिनटों में बुक करें।';

  @override
  String get continueWithPhone => 'फ़ोन से जारी रखें';

  @override
  String get phoneHint => '10 अंकों का मोबाइल नंबर';

  @override
  String get sendOtp => 'OTP भेजें';

  @override
  String get invalidPhone => 'सही 10 अंकों का फ़ोन नंबर डालें';

  @override
  String get otpTitle => 'OTP वेरिफ़ाई करें';

  @override
  String otpSubtitle(String phone) {
    return '$phone पर भेजा गया कोड डालें';
  }

  @override
  String get verifyOtp => 'वेरिफ़ाई करें';

  @override
  String get resendOtp => 'OTP फिर भेजें';

  @override
  String get navHome => 'होम';

  @override
  String get navOrders => 'ऑर्डर';

  @override
  String get navTracking => 'ट्रैकिंग';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get profileTitle => 'प्रोफ़ाइल';

  @override
  String get editProfile => 'प्रोफ़ाइल बदलें';

  @override
  String get editProfileSubtitle => 'नाम, ईमेल और फ़ोटो';

  @override
  String get inviteEarn => 'इनवाइट करें और कमाएँ';

  @override
  String get inviteEarnSubtitle => 'कोड शेयर करें और हर बुकिंग पर कमाएँ';

  @override
  String get savedAddresses => 'सेव्ड पते';

  @override
  String get wallet => 'वॉलेट';

  @override
  String get marketplace => 'मार्केटप्लेस';

  @override
  String get marketplaceChip => 'मार्केट';

  @override
  String get marketplaceSubtitle => 'बेचें, खरीदें और चैट';

  @override
  String get myMarketplacePosts => 'मेरी पोस्ट्स';

  @override
  String get marketplaceChats => 'मार्केटप्लेस चैट';

  @override
  String get support => 'सपोर्ट';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get language => 'भाषा';

  @override
  String languageSubtitle(String current) {
    return 'ऐप की भाषा · $current';
  }

  @override
  String get forSale => 'बिकने के लिए';

  @override
  String get wanted => 'चाहिए';

  @override
  String get browse => 'देखें';

  @override
  String get sellItem => 'आइटम बेचें';

  @override
  String get postRequest => 'रिक्वेस्ट डालें';

  @override
  String get myPosts => 'मेरी पोस्ट्स';

  @override
  String get chats => 'चैट';

  @override
  String get seeAll => 'सभी देखें';

  @override
  String get chatWithSeller => 'विक्रेता से चैट करें';

  @override
  String get iHaveThis => 'यह मेरे पास है';

  @override
  String get typeAMessage => 'संदेश लिखें';

  @override
  String get makeAnOffer => 'ऑफ़र करें';

  @override
  String sendOffer(String amount) {
    return 'ऑफ़र भेजें ₹$amount';
  }

  @override
  String listedAt(String amount) {
    return 'लिस्टेड कीमत ₹$amount';
  }

  @override
  String get tapToChangeBy10 => '− / + से 10% बदलें';

  @override
  String get listedPrice => 'लिस्टेड कीमत';

  @override
  String get decrease10 => '-10%';

  @override
  String get increase10 => '+10%';

  @override
  String offerMessageBuyer(String amount) {
    return 'मैं इसके लिए ₹$amount ऑफ़र करता/करती हूँ।';
  }

  @override
  String offerMessageSeller(String amount) {
    return 'मैं इसके लिए ₹$amount कर सकता/सकती हूँ।';
  }

  @override
  String get qrIsItAvailable => 'उपलब्ध है?';

  @override
  String get qrIsItAvailableMsg => 'नमस्ते, क्या यह अभी उपलब्ध है?';

  @override
  String get qrCanWeMeet => 'मिल सकते हैं?';

  @override
  String get qrCanWeMeetMsg => 'क्या हम मिलकर चेक कर सकते हैं?';

  @override
  String get qrFinalPrice => 'अंतिम कीमत?';

  @override
  String get qrFinalPriceMsg => 'आपकी अंतिम कीमत क्या है?';

  @override
  String get qrCondition => 'हालत कैसी है?';

  @override
  String get qrConditionMsg => 'कृपया कंडीशन के बारे में और बताएँ।';

  @override
  String get qrWhereToSee => 'कहाँ देखें?';

  @override
  String get qrWhereToSeeMsg => 'यह आइटम कहाँ देख सकता/सकती हूँ?';

  @override
  String get qrIHaveThis => 'मेरे पास है';

  @override
  String get qrIHaveThisMsg => 'नमस्ते, यह आइटम मेरे पास है।';

  @override
  String get qrStillNeeded => 'अभी चाहिए?';

  @override
  String get qrStillNeededMsg => 'क्या यह अभी भी चाहिए?';

  @override
  String get qrBudgetFlexible => 'बजट लचीला?';

  @override
  String get qrBudgetFlexibleMsg => 'क्या आपका बजट लचीला है?';

  @override
  String get qrYesAvailable => 'हाँ, उपलब्ध है';

  @override
  String get qrYesAvailableMsg => 'हाँ, यह अभी उपलब्ध है।';

  @override
  String get qrYourBestOffer => 'आपका बेस्ट ऑफ़र?';

  @override
  String get qrYourBestOfferMsg => 'आपका बेस्ट ऑफ़र क्या है?';

  @override
  String get qrCanMeetSeller => 'मिल सकते हैं?';

  @override
  String get qrCanMeetSellerMsg => 'हाँ, मिल सकते हैं और आप चेक कर सकते हैं।';

  @override
  String get qrPriceNegotiable => 'कीमत बातचीत योग्य';

  @override
  String get qrPriceNegotiableMsg => 'कीमत पर बात हो सकती है। अपना ऑफ़र बताएँ।';

  @override
  String get qrPriceFirm => 'कीमत फिक्स';

  @override
  String get qrPriceFirmMsg => 'लिस्टेड कीमत फिक्स है।';

  @override
  String get qrWhereToMeet => 'कहाँ मिलें?';

  @override
  String get qrWhereToMeetMsg => 'कृपया मिलने की जगह बताएँ।';

  @override
  String get qrSoldAlready => 'पहले ही बिक गया';

  @override
  String get qrSoldAlreadyMsg => 'माफ़ कीजिए, यह आइटम बिक चुका है।';

  @override
  String get qrStillNeededYes => 'अभी चाहिए';

  @override
  String get qrStillNeededYesMsg => 'हाँ, मुझे अभी भी चाहिए।';

  @override
  String get qrYourPrice => 'आपकी कीमत?';

  @override
  String get qrYourPriceMsg => 'आप कितने में देंगे?';

  @override
  String get qrSharePhotos => 'फ़ोटो भेजें';

  @override
  String get qrSharePhotosMsg => 'कृपया आइटम की साफ़ फ़ोटो भेजें।';

  @override
  String get qrNotNeeded => 'अब नहीं चाहिए';

  @override
  String get qrNotNeededMsg => 'धन्यवाद, अब इसकी ज़रूरत नहीं।';

  @override
  String get chatClosed => 'चैट बंद है';

  @override
  String get sayHello => 'बात शुरू करने के लिए नमस्ते कहें';

  @override
  String get retry => 'फिर से कोशिश करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सेव करें';

  @override
  String get edit => 'एडिट';

  @override
  String get status => 'स्टेटस';

  @override
  String get searchItems => 'आइटम खोजें';

  @override
  String get searchRequests => 'रिक्वेस्ट खोजें';

  @override
  String get noItemsForSale => 'बेचने के लिए कुछ नहीं';

  @override
  String get noRequestsYet => 'अभी कोई रिक्वेस्ट नहीं';

  @override
  String get location => 'लोकेशन';

  @override
  String get completeProfile => 'प्रोफ़ाइल पूरी करें';

  @override
  String get name => 'नाम';

  @override
  String get email => 'ईमेल';
}
