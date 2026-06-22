import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/l10n/generated/app_localizations.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final Map<String, String> _currencies = {
    'USD': '\$',
    'INR': '₹',
    'EUR': '€',
    'GBP': '£',
    'CAD': '\$',
    'AUD': '\$',
  };

  static const List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी'},
    {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी'},
    {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు'},
    {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்'},
    {'code': 'es', 'name': 'Spanish', 'native': 'Español'},
    {'code': 'zh', 'name': 'Chinese', 'native': '中文'},
  ];

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Preferences'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Appearance'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark Mode'),
              subtitle: const Text('Enable dark theme across the app'),
              trailing: Switch(
                value: user.isDarkMode,
                activeColor: ThemeProvider.accentTeal,
                onChanged: (value) async {
                  await databaseService.updateUser(user.copyWith(isDarkMode: value));
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Localization'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.attach_money),
              title: Text(AppLocalizations.of(context)?.preferredCurrency ?? 'Preferred Currency'),
              subtitle: Text('${AppLocalizations.of(context)?.currentCurrency(_currencies[user.currency] ?? '\$', user.currency) ?? 'Current: ${_currencies[user.currency] ?? '\$'} (${user.currency})'}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showCurrencyPicker(context, user, databaseService),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_rounded),
              title: Text(AppLocalizations.of(context)?.appLanguage ?? 'App Language'),
              subtitle: Text(_languages.firstWhere((l) => l['code'] == user.language, orElse: () => _languages.first)['native']!),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguagePicker(context, user, databaseService),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyMedium?.color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, UserModel user, DatabaseService db) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Select Currency', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _currencies.keys.length,
                  itemBuilder: (context, index) {
                    final code = _currencies.keys.elementAt(index);
                    final symbol = _currencies[code];
                    final isSelected = user.currency == code;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? ThemeProvider.accentTeal.withOpacity(0.1) : Colors.grey.shade100,
                        child: Text(symbol!, style: TextStyle(color: isSelected ? ThemeProvider.accentTeal : Colors.black87)),
                      ),
                      title: Text(code),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: ThemeProvider.accentTeal) : null,
                      onTap: () async {
                        Navigator.pop(context);
                        if (!isSelected) {
                          await db.updateUser(user.copyWith(currency: code));
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguagePicker(BuildContext context, UserModel user, DatabaseService db) {
    String selectedLanguage = user.language ?? 'en';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                AppLocalizations.of(context)?.selectLanguage ?? 'Select Language',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _languages.map((lang) {
                    return RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(lang['native']!),
                      subtitle: Text(lang['name']!),
                      value: lang['code']!,
                      groupValue: selectedLanguage,
                      activeColor: ThemeProvider.accentTeal,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedLanguage = value;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeProvider.accentTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    if (selectedLanguage != user.language) {
                      await db.updateUser(user.copyWith(language: selectedLanguage));
                    }
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
