import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _currentUserId;
  String _selectedCurrency = 'USD'; 
  bool _isLoading = false;
  bool _isInitialized = false;
  
  bool _notificationsEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 9, minute: 0);
  String _notificationFrequency = 'Daily';

  static const _validCurrencyCodes = [
    'USD', 'EUR', 'GBP', 'INR', 'JPY', 'CAD', 'AUD',
    'CHF', 'CNY', 'MXN', 'SGD', 'AED', 'BRL', 'ZAR', 'KES', 'NGN',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserModel?>(context);
    if (user != null && (!_isInitialized || _currentUserId != user.uid)) {
      _nameController.text = user.name ?? '';
      _selectedCurrency = _validCurrencyCodes.contains(user.currency) ? user.currency : 'USD';
      _notificationsEnabled = user.notificationsEnabled;
      _notificationFrequency = user.notificationFrequency;
      _currentUserId = user.uid;
      
      if (user.notificationTime.isNotEmpty) {
        try {
          final parts = user.notificationTime.split(':');
          _notificationTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        } catch (_) {}
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final user = Provider.of<UserModel?>(context, listen: false);
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final updatedUser = user.copyWith(
        name: _nameController.text.trim(),
        currency: _selectedCurrency,
        notificationsEnabled: _notificationsEnabled,
        notificationTime: '${_notificationTime.hour.toString().padLeft(2, '0')}:${_notificationTime.minute.toString().padLeft(2, '0')}',
        notificationFrequency: _notificationFrequency,
      );

      try {
        developer.log('Saving profile for user: ${updatedUser.uid}');
        await context.read<DatabaseService>().updateUser(updatedUser);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } catch (e) {
        developer.log('Error saving profile: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving profile: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = Provider.of<UserModel?>(context);
    final navigator = Navigator.of(context);

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leadingWidth: 160,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Image.asset('assets/images/logo_full.png', fit: BoxFit.contain),
        ),
        title: const SizedBox.shrink(),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        iconTheme: const IconThemeData(color: ThemeProvider.primaryNavy),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: ThemeProvider.primaryNavy.withOpacity(0.05),
                          child: Icon(Icons.person_outline_rounded, size: 60, color: ThemeProvider.primaryNavy.withOpacity(0.5)),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ThemeProvider.accentBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text('Personal Details', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy)),
                  const SizedBox(height: 16),
                  _buildInputField(
                    label: 'Display Name',
                    hint: 'Enter your full name',
                    icon: Icons.person_outline_rounded,
                    controller: _nameController,
                    validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    label: 'Email Address',
                    hint: user.email ?? '',
                    icon: Icons.email_outlined,
                    enabled: false,
                  ),
                  const SizedBox(height: 24),
                  Text('Preferences', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy)),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Currency', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.attach_money_rounded, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ThemeProvider.accentBlue, width: 2)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'USD', child: Text('USD — \$ (US Dollar)')),
                          DropdownMenuItem(value: 'EUR', child: Text('EUR — € (Euro)')),
                          DropdownMenuItem(value: 'GBP', child: Text('GBP — £ (British Pound)')),
                          DropdownMenuItem(value: 'INR', child: Text('INR — ₹ (Indian Rupee)')),
                          DropdownMenuItem(value: 'JPY', child: Text('JPY — ¥ (Japanese Yen)')),
                          DropdownMenuItem(value: 'CAD', child: Text('CAD — CA\$ (Canadian Dollar)')),
                          DropdownMenuItem(value: 'AUD', child: Text('AUD — A\$ (Australian Dollar)')),
                          DropdownMenuItem(value: 'CHF', child: Text('CHF — Fr (Swiss Franc)')),
                          DropdownMenuItem(value: 'CNY', child: Text('CNY — ¥ (Chinese Yuan)')),
                          DropdownMenuItem(value: 'MXN', child: Text('MXN — MX\$ (Mexican Peso)')),
                          DropdownMenuItem(value: 'SGD', child: Text('SGD — S\$ (Singapore Dollar)')),
                          DropdownMenuItem(value: 'AED', child: Text('AED — د.إ (UAE Dirham)')),
                          DropdownMenuItem(value: 'BRL', child: Text('BRL — R\$ (Brazilian Real)')),
                          DropdownMenuItem(value: 'ZAR', child: Text('ZAR — R (South African Rand)')),
                          DropdownMenuItem(value: 'KES', child: Text('KES — KSh (Kenyan Shilling)')),
                          DropdownMenuItem(value: 'NGN', child: Text('NGN — ₦ (Nigerian Naira)')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCurrency = value);
                          }
                        },
                        validator: (value) => value == null || value.isEmpty ? 'Please select a currency' : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Text('Notifications', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy)),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable Rent Reminders', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Get notified about upcoming and overdue rent.'),
                    value: _notificationsEnabled,
                    onChanged: (value) => setState(() => _notificationsEnabled = value),
                    activeColor: ThemeProvider.accentBlue,
                  ),
                  if (_notificationsEnabled) ...[
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reminder Time', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_notificationTime.format(context)),
                      trailing: const Icon(Icons.access_time_rounded),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _notificationTime,
                        );
                        if (picked != null) {
                          setState(() => _notificationTime = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _notificationFrequency,
                      decoration: InputDecoration(
                        labelText: 'Frequency',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      ),
                      items: ['Daily', 'Weekly', 'On Due Date'].map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _notificationFrequency = value);
                      },
                    ),
                  ],
                  const SizedBox(height: 48),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_rounded, color: Colors.white),
                      onPressed: _isLoading ? null : _saveSettings,
                      label: Text(_isLoading ? 'Saving...' : 'Save Changes', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeProvider.accentBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                      label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        await authService.signOut();
                        navigator.popUntil((route) => route.isFirst);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ThemeProvider.accentBlue, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ),
      ],
    );
  }
}
