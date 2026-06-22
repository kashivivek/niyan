// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Niyan';

  @override
  String welcomeUser(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get portfolioSubtitle =>
      'Here is what is happening with your portfolio today.';

  @override
  String get upcomingRents7Days => 'Upcoming Rents (7 days)';

  @override
  String get allCaughtUp => 'All caught up!';

  @override
  String get noUpcomingRentPayments => 'No upcoming rent payments.';

  @override
  String get markReceived => 'Mark Received';

  @override
  String get selectDateReceivedForEach =>
      'Select date received for each payment:';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String selected(int count) {
    return '$count selected';
  }

  @override
  String paymentsRecordedSuccess(int count) {
    return '$count payment(s) recorded successfully!';
  }

  @override
  String get rent => 'Rent';

  @override
  String get overdue => 'Overdue';

  @override
  String get due => 'Due';

  @override
  String get properties => 'Properties';

  @override
  String get occupancy => 'Occupancy';

  @override
  String get pendingRents => 'Pending Rents';

  @override
  String get collected => 'Collected';

  @override
  String get societyModeAvailable => 'Society Mode Available';

  @override
  String get switchToManageSociety => 'Switch to manage your society';

  @override
  String get switchButton => 'SWITCH';

  @override
  String get home => 'Home';

  @override
  String get tenants => 'Tenants';

  @override
  String get finance => 'Finance';

  @override
  String get alerts => 'Alerts';

  @override
  String get settings => 'Settings';

  @override
  String get noTenantsFound => 'No tenants found';

  @override
  String get addTenant => 'Add Tenant';

  @override
  String get assigned => 'Assigned';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get addProperty => 'Add Property';

  @override
  String get noPropertiesFound => 'No properties added yet.';

  @override
  String get addYourFirstProperty => 'Add your first property to get started.';

  @override
  String get noNotifications => 'No Notifications';

  @override
  String get allCaughtUpNotifications => 'You\'re all caught up!';

  @override
  String get applyRentIncrease => 'Apply 5% Increase';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get profileInformation => 'Profile Information';

  @override
  String get fullName => 'Full Name';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get profileUpdated => 'Profile updated successfully!';

  @override
  String get pleaseEnterName => 'Please enter your name';

  @override
  String get appSettings => 'App Settings';

  @override
  String get preferences => 'Preferences';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get accountAndSecurity => 'Account & Security';

  @override
  String get accountSecurity => 'Account Security';

  @override
  String get communityAndSociety => 'Community & Society';

  @override
  String get switchPropertyMode => 'Switch Property Mode';

  @override
  String get documentLibrary => 'Document Library';

  @override
  String get inviteNewMember => 'Invite New Member';

  @override
  String get societySettings => 'Society Settings';

  @override
  String get support => 'Support';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get reportAnIssue => 'Report an Issue';

  @override
  String get logOut => 'LOG OUT';

  @override
  String get appPreferences => 'App Preferences';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeSubtitle => 'Enable dark theme across the app';

  @override
  String get localization => 'Localization';

  @override
  String get preferredCurrency => 'Preferred Currency';

  @override
  String currentCurrency(String symbol, String code) {
    return 'Current: $symbol ($code)';
  }

  @override
  String get selectCurrency => 'Select Currency';

  @override
  String get appLanguage => 'App Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get receiveReminders => 'Receive reminders about upcoming rent';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String get timezone => 'Timezone';

  @override
  String get frequency => 'Frequency';

  @override
  String get sendTestNotification => 'Send Test Notification';

  @override
  String get testNotificationSent => 'Test notification sent!';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get notificationSettingsUpdated => 'Notification settings updated!';

  @override
  String get addTransactions => 'Add Transaction';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get description => 'Description';

  @override
  String get amount => 'Amount';

  @override
  String get date => 'Date';

  @override
  String get month => 'Month';

  @override
  String get noTransactions => 'No transactions found';

  @override
  String get propertyName => 'Property Name';

  @override
  String get propertyAddress => 'Property Address';

  @override
  String get city => 'City';

  @override
  String get state => 'State';

  @override
  String get units => 'Units';

  @override
  String get addUnit => 'Add Unit';

  @override
  String get unitNumber => 'Unit Number';

  @override
  String get monthlyRent => 'Monthly Rent';

  @override
  String get rentDueDate => 'Rent Due Date';

  @override
  String get vacant => 'Vacant';

  @override
  String get occupied => 'Occupied';

  @override
  String get tenantName => 'Tenant Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get moveInDate => 'Move-in Date';

  @override
  String get securityDeposit => 'Security Deposit';

  @override
  String get rentAmount => 'Rent Amount';

  @override
  String get annualIncrement => 'Annual Increment (%)';

  @override
  String get leaseEndDate => 'Lease End Date';

  @override
  String get testNotificationTitle => 'Test Notification';

  @override
  String get testNotificationBody =>
      'This is a test notification from Niyan Property Management.';

  @override
  String get language_en => 'English';

  @override
  String get language_hi => 'हिन्दी (Hindi)';

  @override
  String get language_mr => 'मराठी (Marathi)';
}
