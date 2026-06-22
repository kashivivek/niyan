import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/services/image_service.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;
import 'package:myapp/l10n/generated/app_localizations.dart';

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
      _currentUserId = user.uid;
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      
      if (pickedFile != null) {
        setState(() => _isLoading = true);
        final user = Provider.of<UserModel?>(context, listen: false);
        if (user == null) return;

        final imageService = ImageService();
        final url = await imageService.uploadProfilePhoto(user.uid, pickedFile);
        
        if (url != null) {
          await context.read<DatabaseService>().updateUser(user.copyWith(photoUrl: url));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated!')));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload photo. Storage rules may be denying access.')));
          }
        }
      }
    } catch (e) {
      developer.log('Error uploading photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading photo: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.editProfile ?? 'Edit Profile', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark ? Colors.white : ThemeProvider.primaryNavy)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : ThemeProvider.primaryNavy),
      ),
      body: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(32.0),
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
                              ? Icon(Icons.person_outline_rounded, size: 60, color: isDark ? Colors.white54 : ThemeProvider.primaryNavy.withOpacity(0.5))
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: ThemeProvider.accentBlue,
                            radius: 18,
                            child: IconButton(
                              icon: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  _buildSectionTitle(AppLocalizations.of(context)?.profileInformation ?? 'Profile Information'),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(AppLocalizations.of(context)?.fullName ?? 'Full Name', Icons.person_outline),
                    validator: (v) => v!.isEmpty ? (AppLocalizations.of(context)?.pleaseEnterName ?? 'Please enter your name') : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    initialValue: user.email,
                    enabled: false,
                    decoration: _inputDecoration(AppLocalizations.of(context)?.emailAddress ?? 'Email Address', Icons.email_outlined),
                  ),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeProvider.primaryNavy,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isLoading ? null : _saveSettings,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(AppLocalizations.of(context)?.saveChanges ?? 'Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : ThemeProvider.primaryNavy.withOpacity(0.6), letterSpacing: 1.2));
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: isDark ? Colors.white54 : ThemeProvider.primaryNavy.withOpacity(0.5)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: ThemeProvider.accentBlue, width: 2)),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
    );
  }
}
