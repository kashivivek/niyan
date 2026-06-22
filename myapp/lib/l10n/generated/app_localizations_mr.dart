// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appTitle => 'नियान';

  @override
  String welcomeUser(String name) {
    return 'स्वागत आहे, $name!';
  }

  @override
  String get portfolioSubtitle =>
      'आज तुमच्या पोर्टफोलिओमध्ये काय चालू आहे ते पहा.';

  @override
  String get upcomingRents7Days => 'आगामी भाडे (7 दिवस)';

  @override
  String get allCaughtUp => 'सर्व अपडेट आहे!';

  @override
  String get noUpcomingRentPayments => 'कोणतीही आगामी भाडे देयके नाहीत.';

  @override
  String get markReceived => 'प्राप्त म्हणून चिन्हांकित करा';

  @override
  String get selectDateReceivedForEach =>
      'प्रत्येक भुगतानासाठी प्राप्ती तारीख निवडा:';

  @override
  String get confirm => 'पुष्टी करा';

  @override
  String get cancel => 'रद्द करा';

  @override
  String selected(int count) {
    return '$count निवडलेले';
  }

  @override
  String paymentsRecordedSuccess(int count) {
    return '$count भुगतान यशस्वीरित्या नोंदवले!';
  }

  @override
  String get rent => 'भाडे';

  @override
  String get overdue => 'थकबाकी';

  @override
  String get due => 'देय';

  @override
  String get properties => 'मालमत्ता';

  @override
  String get occupancy => 'व्याप्ती';

  @override
  String get pendingRents => 'प्रलंबित भाडे';

  @override
  String get collected => 'जमा';

  @override
  String get societyModeAvailable => 'सोसायटी मोड उपलब्ध';

  @override
  String get switchToManageSociety =>
      'तुमची सोसायटी व्यवस्थापित करण्यासाठी स्विच करा';

  @override
  String get switchButton => 'स्विच';

  @override
  String get home => 'होम';

  @override
  String get tenants => 'भाडेकरू';

  @override
  String get finance => 'आर्थिक';

  @override
  String get alerts => 'सूचना';

  @override
  String get settings => 'सेटिंग्ज';

  @override
  String get noTenantsFound => 'कोणताही भाडेकरू सापडला नाही';

  @override
  String get addTenant => 'भाडेकरू जोडा';

  @override
  String get assigned => 'नियुक्त';

  @override
  String get unassigned => 'अनियुक्त';

  @override
  String get addProperty => 'मालमत्ता जोडा';

  @override
  String get noPropertiesFound => 'अजून कोणतीही मालमत्ता जोडलेली नाही.';

  @override
  String get addYourFirstProperty =>
      'सुरु करण्यासाठी तुमची पहिली मालमत्ता जोडा.';

  @override
  String get noNotifications => 'कोणत्याही सूचना नाहीत';

  @override
  String get allCaughtUpNotifications => 'तुम्ही अपडेट आहात!';

  @override
  String get applyRentIncrease => '5% वाढ लागू करा';

  @override
  String get dismiss => 'रद्द करा';

  @override
  String get editProfile => 'प्रोफाइल संपादित करा';

  @override
  String get profileInformation => 'प्रोफाइल माहिती';

  @override
  String get fullName => 'पूर्ण नाव';

  @override
  String get emailAddress => 'ईमेल पत्ता';

  @override
  String get saveChanges => 'बदल जतन करा';

  @override
  String get profileUpdated => 'प्रोफाइल यशस्वीरित्या अपडेट केली!';

  @override
  String get pleaseEnterName => 'कृपया तुमचे नाव प्रविष्ट करा';

  @override
  String get appSettings => 'ॲप सेटिंग्ज';

  @override
  String get preferences => 'प्राधान्ये';

  @override
  String get notificationSettings => 'सूचना सेटिंग्ज';

  @override
  String get accountAndSecurity => 'खाते आणि सुरक्षा';

  @override
  String get accountSecurity => 'खाते सुरक्षा';

  @override
  String get communityAndSociety => 'समुदाय आणि सोसायटी';

  @override
  String get switchPropertyMode => 'प्रॉपर्टी मोड बदला';

  @override
  String get documentLibrary => 'दस्तऐवज संग्रह';

  @override
  String get inviteNewMember => 'नवीन सदस्य आमंत्रित करा';

  @override
  String get societySettings => 'सोसायटी सेटिंग्ज';

  @override
  String get support => 'मदत';

  @override
  String get helpCenter => 'मदत केंद्र';

  @override
  String get reportAnIssue => 'समस्या कळवा';

  @override
  String get logOut => 'लॉग आउट';

  @override
  String get appPreferences => 'ॲप प्राधान्ये';

  @override
  String get appearance => 'दिसावट';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get darkModeSubtitle => 'संपूर्ण ॲपमध्ये डार्क थीम सक्षम करा';

  @override
  String get localization => 'स्थानिकीकरण';

  @override
  String get preferredCurrency => 'पसंतीचे चलन';

  @override
  String currentCurrency(String symbol, String code) {
    return 'सध्याचे: $symbol ($code)';
  }

  @override
  String get selectCurrency => 'चलन निवडा';

  @override
  String get appLanguage => 'ॲप भाषा';

  @override
  String get selectLanguage => 'भाषा निवडा';

  @override
  String get enableNotifications => 'सूचना सक्षम करा';

  @override
  String get receiveReminders => 'आगामी भाड्याबद्दल स्मरणपत्रे मिळवा';

  @override
  String get reminderTime => 'स्मरणपत्र वेळ';

  @override
  String get timezone => 'वेळ क्षेत्र';

  @override
  String get frequency => 'वारंवारता';

  @override
  String get sendTestNotification => 'चाचणी सूचना पाठवा';

  @override
  String get testNotificationSent => 'चाचणी सूचना पाठवली!';

  @override
  String get saveSettings => 'सेटिंग्ज जतन करा';

  @override
  String get notificationSettingsUpdated => 'सूचना सेटिंग्ज अपडेट!';

  @override
  String get addTransactions => 'व्यवहार जोडा';

  @override
  String get income => 'उत्पन्न';

  @override
  String get expense => 'खर्च';

  @override
  String get description => 'वर्णन';

  @override
  String get amount => 'रक्कम';

  @override
  String get date => 'तारीख';

  @override
  String get month => 'महिना';

  @override
  String get noTransactions => 'कोणताही व्यवहार सापडला नाही';

  @override
  String get propertyName => 'मालमत्तेचे नाव';

  @override
  String get propertyAddress => 'मालमत्तेचा पत्ता';

  @override
  String get city => 'शहर';

  @override
  String get state => 'राज्य';

  @override
  String get units => 'युनिट्स';

  @override
  String get addUnit => 'युनिट जोडा';

  @override
  String get unitNumber => 'युनिट क्रमांक';

  @override
  String get monthlyRent => 'मासिक भाडे';

  @override
  String get rentDueDate => 'भाडे देय तारीख';

  @override
  String get vacant => 'रिकामे';

  @override
  String get occupied => 'व्यापलेले';

  @override
  String get tenantName => 'भाडेकरूचे नाव';

  @override
  String get phoneNumber => 'फोन नंबर';

  @override
  String get moveInDate => 'प्रवेश तारीख';

  @override
  String get securityDeposit => 'सुरक्षा ठेव';

  @override
  String get rentAmount => 'भाडे रक्कम';

  @override
  String get annualIncrement => 'वार्षिक वाढ (%)';

  @override
  String get leaseEndDate => 'भाडेकरार समाप्ती तारीख';

  @override
  String get testNotificationTitle => 'चाचणी सूचना';

  @override
  String get testNotificationBody =>
      'ही नियान प्रॉपर्टी मॅनेजमेंटकडून चाचणी सूचना आहे.';

  @override
  String get language_en => 'English';

  @override
  String get language_hi => 'हिन्दी (Hindi)';

  @override
  String get language_mr => 'मराठी (Marathi)';
}
