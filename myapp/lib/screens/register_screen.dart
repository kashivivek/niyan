import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  AppRole _selectedRole = AppRole.owner; // Default to Property Owner

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        role: _selectedRole,
      );
      // Success: App state will automatically update via AuthService.user stream
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : ThemeProvider.primaryNavy;
    final inputFill = isDark ? const Color(0xFF1E293B) : Colors.grey.shade50;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Join Niyan', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor)),
                const SizedBox(height: 8),
                Text('Select how you will use the app', style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.grey.shade600)),
                const SizedBox(height: 32),
                
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        title: 'Landlord',
                        subtitle: 'Standalone Mode',
                        icon: Icons.home_work_rounded,
                        selected: _selectedRole == AppRole.owner,
                        onTap: () => setState(() => _selectedRole = AppRole.owner),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleCard(
                        title: 'Society',
                        subtitle: 'Society ERP',
                        icon: Icons.apartment_rounded,
                        selected: _selectedRole == AppRole.societyAdmin,
                        onTap: () => setState(() => _selectedRole = AppRole.societyAdmin),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: _selectedRole == AppRole.owner 
                    ? [
                        _bullet('Direct Landlord-Tenant management', isDark),
                        _bullet('Rent collection & automated receipts', isDark),
                        _bullet('Co-Owner property sharing & sync', isDark),
                        _bullet('Annual 5% rent increase reminders', isDark),
                      ]
                    : [
                        _bullet('Full Society Management (ERP)', isDark),
                        _bullet('Security & Visitor Management (Gate)', isDark),
                        _bullet('Society Notices & Community Board', isDark),
                        _bullet('Helpdesk, Amenities & Billing', isDark),
                      ],
                  ),
                ),
                
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: primaryColor),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600),
                    prefixIcon: Icon(Icons.person_outline_rounded, color: primaryColor),
                    filled: true,
                    fillColor: inputFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? ThemeProvider.accentTeal : ThemeProvider.primaryNavy, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  style: TextStyle(color: primaryColor),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600),
                    prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                    filled: true,
                    fillColor: inputFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? ThemeProvider.accentTeal : ThemeProvider.primaryNavy, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: TextStyle(color: primaryColor),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600),
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: primaryColor),
                    filled: true,
                    fillColor: inputFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? ThemeProvider.accentTeal : ThemeProvider.primaryNavy, width: 2)),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? ThemeProvider.accentTeal : ThemeProvider.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text('Already have an account? Login', style: TextStyle(color: isDark ? ThemeProvider.accentTeal : ThemeProvider.primaryNavy, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
 
  Widget _bullet(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: ThemeProvider.accentTeal),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade700))),
        ],
      ),
    );
  }
}
 
class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
 
  const _RoleCard({required this.title, required this.subtitle, required this.icon, required this.selected, required this.onTap});
 
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected 
              ? ThemeProvider.accentTeal.withOpacity(0.08) 
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? ThemeProvider.accentTeal : (isDark ? Colors.grey.shade800 : Colors.grey.shade200), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? ThemeProvider.accentTeal : Colors.grey.shade400, size: 32),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: selected ? ThemeProvider.accentTeal : (isDark ? Colors.white : ThemeProvider.primaryNavy))),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
