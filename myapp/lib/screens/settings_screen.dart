import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/services/image_service.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile != null) {
      setState(() => _isLoading = true);
      final user = Provider.of<UserModel?>(context, listen: false);
      if (user == null) return;

      try {
        final imageService = ImageService();
        final url = await imageService.uploadProfilePhoto(user.uid, pickedFile);
        
        if (url != null) {
          await context.read<DatabaseService>().updateUser(user.copyWith(photoUrl: url));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated!')));
          }
        }
      } catch (e) {
        developer.log('Error uploading photo: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
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

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy)),
        backgroundColor: Colors.white,
        elevation: 0,
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
                          backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty) 
                              ? NetworkImage(user.photoUrl!) 
                              : null,
                          child: (user.photoUrl == null || user.photoUrl!.isEmpty) 
                              ? Icon(Icons.person_outline_rounded, size: 60, color: ThemeProvider.primaryNavy.withOpacity(0.5))
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: ThemeProvider.accentBlue,
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Profile Information'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration('Full Name', Icons.person_outline),
                    validator: (v) => v!.isEmpty ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: user.email,
                    enabled: false,
                    decoration: _inputDecoration('Email Address', Icons.email_outlined),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Preferences'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: _inputDecoration('Preferred Currency', Icons.payments_outlined),
                    items: _validCurrencyCodes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCurrency = v!),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Notifications'),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    subtitle: const Text('Receive reminders about upcoming rent'),
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                    activeColor: ThemeProvider.accentBlue,
                  ),
                  if (_notificationsEnabled) ...[
                    ListTile(
                      title: const Text('Reminder Time'),
                      subtitle: Text(_notificationTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: _notificationTime);
                        if (picked != null) setState(() => _notificationTime = picked);
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: _notificationFrequency,
                      decoration: _inputDecoration('Frequency', Icons.repeat),
                      items: ['Daily', 'Weekly'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (v) => setState(() => _notificationFrequency = v!),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _sendTestNotification,
                      icon: const Icon(Icons.notification_important_outlined),
                      label: const Text('Send Test Notification'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 48),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeProvider.primaryNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isLoading ? null : _saveSettings,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => authService.signOut(),
                    child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy.withOpacity(0.6), letterSpacing: 1.2));
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: ThemeProvider.primaryNavy.withOpacity(0.5)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: ThemeProvider.accentBlue, width: 2)),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
