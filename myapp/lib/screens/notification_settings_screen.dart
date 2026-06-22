import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/notification_service.dart';
import 'package:myapp/l10n/generated/app_localizations.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = false;
  bool _isInitialized = false;
  
  bool _notificationsEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);
  String _notificationTimezone = 'UTC';
  String _notificationFrequency = 'Daily';

  static const _commonTimezones = [
    'Device Local Time', 'UTC', 'America/New_York', 'America/Los_Angeles', 'Europe/London', 
    'Europe/Berlin', 'Asia/Kolkata', 'Asia/Singapore', 'Australia/Sydney'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserModel?>(context);
    if (user != null && !_isInitialized) {
      _notificationsEnabled = user.notificationsEnabled;
      _notificationTimezone = user.notificationTimezone.isNotEmpty ? user.notificationTimezone : 'Device Local Time';
      _notificationFrequency = user.notificationFrequency;
      
      if (user.notificationTime.isNotEmpty) {
        try {
          final parts = user.notificationTime.split(':');
          _notificationTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        } catch (_) {}
      }
      _isInitialized = true;
    }
  }

  Future<void> _sendTestNotification() async {
    final success = await NotificationService().requestPermissions();
    if (success) {
      await NotificationService().sendTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test notification sent!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission denied. Please enable it in browser/system settings.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    final user = Provider.of<UserModel?>(context, listen: false);
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final updatedUser = user.copyWith(
      notificationsEnabled: _notificationsEnabled,
      notificationTime: '${_notificationTime.hour.toString().padLeft(2, '0')}:${_notificationTime.minute.toString().padLeft(2, '0')}',
      notificationTimezone: _notificationTimezone,
      notificationFrequency: _notificationFrequency,
    );

    try {
      await context.read<DatabaseService>().updateUser(updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification settings updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: isDark ? Colors.white70 : ThemeProvider.primaryNavy.withOpacity(0.5)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? ThemeProvider.accentTeal : ThemeProvider.primaryNavy, width: 2)),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.notificationSettings ?? 'Notification Settings', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark ? Colors.white : ThemeProvider.primaryNavy)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : ThemeProvider.primaryNavy),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: EdgeInsets.all(32.0),
            children: [
              SwitchListTile(
                title: Text(AppLocalizations.of(context)?.enableNotifications ?? 'Enable Notifications'),
                subtitle: Text(AppLocalizations.of(context)?.receiveReminders ?? 'Receive reminders about upcoming rent'),
                value: _notificationsEnabled,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
                activeColor: ThemeProvider.accentBlue,
              ),
              if (_notificationsEnabled) ...[
                SizedBox(height: 16),
                ListTile(
                  title: Text(AppLocalizations.of(context)?.reminderTime ?? 'Reminder Time'),
                  subtitle: Text(_notificationTime.format(context)),
                  trailing: Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: _notificationTime);
                    if (picked != null) setState(() => _notificationTime = picked);
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _commonTimezones.contains(_notificationTimezone) ? _notificationTimezone : 'Device Local Time',
                  decoration: _inputDecoration('Timezone', Icons.public),
                  items: _commonTimezones.map((tz) => DropdownMenuItem(value: tz, child: Text(tz))).toList(),
                  onChanged: (v) => setState(() => _notificationTimezone = v!),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _notificationFrequency,
                  decoration: _inputDecoration('Frequency', Icons.repeat),
                  items: ['Daily', 'Weekly'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) => setState(() => _notificationFrequency = v!),
                ),
                SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _sendTestNotification,
                  icon: Icon(Icons.notification_important_outlined),
                  label: Text(AppLocalizations.of(context)?.sendTestNotification ?? 'Send Test Notification'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
              SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeProvider.primaryNavy,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _saveSettings,
                child: _isLoading 
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Theme.of(context).cardColor, strokeWidth: 2))
                    : Text(AppLocalizations.of(context)?.saveSettings ?? 'Save Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
