// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'नियान';

  @override
  String welcomeUser(String name) {
    return 'स्वागत है, $name!';
  }

  @override
  String get portfolioSubtitle => 'आज आपके पोर्टफोलियो में क्या हो रहा है।';

  @override
  String get upcomingRents7Days => 'आगामी किराए (7 दिन)';

  @override
  String get allCaughtUp => 'सब अपडेट है!';

  @override
  String get noUpcomingRentPayments => 'कोई आगामी किराया भुगतान नहीं।';

  @override
  String get markReceived => 'प्राप्त चिह्नित करें';

  @override
  String get selectDateReceivedForEach =>
      'प्रत्येक भुगतान के लिए प्राप्ति तिथि चुनें:';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String selected(int count) {
    return '$count चयनित';
  }

  @override
  String paymentsRecordedSuccess(int count) {
    return '$count भुगतान सफलतापूर्वक दर्ज!';
  }

  @override
  String get rent => 'किराया';

  @override
  String get overdue => 'बकाया';

  @override
  String get due => 'देय';

  @override
  String get properties => 'संपत्तियां';

  @override
  String get occupancy => 'अधिभोग';

  @override
  String get pendingRents => 'लंबित किराए';

  @override
  String get collected => 'एकत्रित';

  @override
  String get societyModeAvailable => 'सोसायटी मोड उपलब्ध';

  @override
  String get switchToManageSociety =>
      'अपनी सोसायटी प्रबंधित करने के लिए स्विच करें';

  @override
  String get switchButton => 'स्विच';

  @override
  String get home => 'होम';

  @override
  String get tenants => 'किरायेदार';

  @override
  String get finance => 'वित्त';

  @override
  String get alerts => 'अलर्ट';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get noTenantsFound => 'कोई किरायेदार नहीं मिला';

  @override
  String get addTenant => 'किरायेदार जोड़ें';

  @override
  String get assigned => 'नियुक्त';

  @override
  String get unassigned => 'अनियुक्त';

  @override
  String get addProperty => 'संपत्ति जोड़ें';

  @override
  String get noPropertiesFound => 'अभी तक कोई संपत्ति नहीं जोड़ी गई।';

  @override
  String get addYourFirstProperty =>
      'शुरू करने के लिए अपनी पहली संपत्ति जोड़ें।';

  @override
  String get noNotifications => 'कोई सूचनाएं नहीं';

  @override
  String get allCaughtUpNotifications => 'आप अप टू डेट हैं!';

  @override
  String get applyRentIncrease => '5% वृद्धि लागू करें';

  @override
  String get dismiss => 'खारिज करें';

  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get profileInformation => 'प्रोफ़ाइल जानकारी';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get emailAddress => 'ईमेल पता';

  @override
  String get saveChanges => 'परिवर्तन सहेजें';

  @override
  String get profileUpdated => 'प्रोफ़ाइल सफलतापूर्वक अपडेट!';

  @override
  String get pleaseEnterName => 'कृपया अपना नाम दर्ज करें';

  @override
  String get appSettings => 'ऐप सेटिंग्स';

  @override
  String get preferences => 'प्राथमिकताएं';

  @override
  String get notificationSettings => 'सूचना सेटिंग्स';

  @override
  String get accountAndSecurity => 'खाता और सुरक्षा';

  @override
  String get accountSecurity => 'खाता सुरक्षा';

  @override
  String get communityAndSociety => 'समुदाय और सोसायटी';

  @override
  String get switchPropertyMode => 'प्रॉपर्टी मोड बदलें';

  @override
  String get documentLibrary => 'दस्तावेज़ पुस्तकालय';

  @override
  String get inviteNewMember => 'नया सदस्य आमंत्रित करें';

  @override
  String get societySettings => 'सोसायटी सेटिंग्स';

  @override
  String get support => 'सहायता';

  @override
  String get helpCenter => 'सहायता केंद्र';

  @override
  String get reportAnIssue => 'समस्या की रिपोर्ट करें';

  @override
  String get logOut => 'लॉग आउट';

  @override
  String get appPreferences => 'ऐप प्राथमिकताएं';

  @override
  String get appearance => 'दिखावट';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get darkModeSubtitle => 'पूरे ऐप में डार्क थीम सक्षम करें';

  @override
  String get localization => 'स्थानीयकरण';

  @override
  String get preferredCurrency => 'पसंदीदा मुद्रा';

  @override
  String currentCurrency(String symbol, String code) {
    return 'वर्तमान: $symbol ($code)';
  }

  @override
  String get selectCurrency => 'मुद्रा चुनें';

  @override
  String get appLanguage => 'ऐप भाषा';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get enableNotifications => 'सूचनाएं सक्षम करें';

  @override
  String get receiveReminders => 'आगामी किराये की याद दिलाएं';

  @override
  String get reminderTime => 'अनुस्मारक समय';

  @override
  String get timezone => 'समय क्षेत्र';

  @override
  String get frequency => 'आवृत्ति';

  @override
  String get sendTestNotification => 'परीक्षण सूचना भेजें';

  @override
  String get testNotificationSent => 'परीक्षण सूचना भेजी गई!';

  @override
  String get saveSettings => 'सेटिंग्स सहेजें';

  @override
  String get notificationSettingsUpdated => 'सूचना सेटिंग्स अपडेट!';

  @override
  String get addTransactions => 'लेनदेन जोड़ें';

  @override
  String get income => 'आय';

  @override
  String get expense => 'व्यय';

  @override
  String get description => 'विवरण';

  @override
  String get amount => 'राशि';

  @override
  String get date => 'तारीख';

  @override
  String get month => 'महीना';

  @override
  String get noTransactions => 'कोई लेनदेन नहीं मिला';

  @override
  String get propertyName => 'संपत्ति का नाम';

  @override
  String get propertyAddress => 'संपत्ति का पता';

  @override
  String get city => 'शहर';

  @override
  String get state => 'राज्य';

  @override
  String get units => 'इकाइयां';

  @override
  String get addUnit => 'इकाई जोड़ें';

  @override
  String get unitNumber => 'इकाई नंबर';

  @override
  String get monthlyRent => 'मासिक किराया';

  @override
  String get rentDueDate => 'किराया देय तिथि';

  @override
  String get vacant => 'खाली';

  @override
  String get occupied => 'अधिकृत';

  @override
  String get tenantName => 'किरायेदार का नाम';

  @override
  String get phoneNumber => 'फोन नंबर';

  @override
  String get moveInDate => 'प्रवेश तिथि';

  @override
  String get securityDeposit => 'सुरक्षा जमा';

  @override
  String get rentAmount => 'किराया राशि';

  @override
  String get annualIncrement => 'वार्षिक वृद्धि (%)';

  @override
  String get leaseEndDate => 'पट्टा समाप्ति तिथि';

  @override
  String get testNotificationTitle => 'परीक्षण सूचना';

  @override
  String get testNotificationBody =>
      'यह नियान प्रॉपर्टी मैनेजमेंट से एक परीक्षण सूचना है।';

  @override
  String get language_en => 'English';

  @override
  String get language_hi => 'हिन्दी (Hindi)';

  @override
  String get language_mr => 'मराठी (Marathi)';
}
