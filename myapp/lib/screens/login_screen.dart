import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _performLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await context.read<AuthService>().signInWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text,
          );
      // Signal successful autofill so OS prompts to save credentials
      TextInput.finishAutofillContext();
      if (user != null && _rememberMe) {
        await context.read<AuthService>().saveRememberMeCredentials(
              _emailController.text.trim(),
              _passwordController.text,
            );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage;
      String errorTitle = "Login Error";
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = 'Incorrect credentials. Please try again.';
        errorTitle = "Incorrect Credentials";
      } else {
        errorMessage = 'An unknown error occurred. Please try again later.';
        errorTitle = "Authentication Error";
      }
      _showErrorDialog(errorTitle, errorMessage);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog("Authentication Error",
          'An unknown error occurred. Please try again later.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset Password',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: 'Enter your email',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeProvider.accentBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final authService = context.read<AuthService>();
              if (emailController.text.trim().isEmpty) return;
              try {
                await authService
                    .sendPasswordResetEmail(emailController.text.trim());
                if (!mounted) return;
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                      content: Text('Password reset link sent to your email.')),
                );
              } catch (e) {
                if (!mounted) return;
                navigator.pop();
                _showErrorDialog('Authentication Error',
                    'Failed to send reset link. Please try again.');
              }
            },
            child:
                Text('Send Reset Link', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formTextColor = isDark ? Colors.white : ThemeProvider.primaryNavy;
    final labelColor = isDark ? Colors.white70 : Colors.grey.shade700;
    final inputBg = isDark ? const Color(0xFF1E293B) : Colors.grey.shade50;
    final inputBorderColor =
        isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.all(12.0),
          child:
              Image.asset('assets/images/logo_icon.png', fit: BoxFit.contain),
        ),
      ),
      body: Row(
        children: [
          if (isDesktop)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=1600&q=80'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.7)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: EdgeInsets.all(64),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(height: 24),
                      Text(
                        'Efficiency in Property.\nHarmony in Community.',
                        style: GoogleFonts.inter(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).cardColor,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'The ultimate dual-mode ecosystem. Standalone Landlord Mode for automated rent tracking and co-owner sync. Society ERP Mode for security, billing, and community engagement.',
                        style: GoogleFonts.inter(
                            fontSize: 20, color: Colors.white70),
                      ),
                      SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 48, vertical: 64),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 32.0),
                              child: Image.asset('assets/images/logo_full.png',
                                  height: 56),
                            ),
                          ),
                          Text(
                            'Welcome back',
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: formTextColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Please enter your details to sign in.',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white60
                                    : Colors.grey.shade600,
                                fontSize: 16),
                          ),
                          SizedBox(height: 48),
                          Text('Email Address',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: labelColor)),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            style: TextStyle(color: formTextColor),
                            decoration: InputDecoration(
                              hintText: 'Enter your email',
                              hintStyle: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.grey),
                              prefixIcon: Icon(Icons.email_outlined,
                                  color: Colors.grey),
                              filled: true,
                              fillColor: inputBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: inputBorderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: inputBorderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: isDark
                                        ? ThemeProvider.accentTeal
                                        : ThemeProvider.primaryNavy,
                                    width: 2),
                              ),
                            ),
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Enter your email'
                                : null,
                          ),
                          SizedBox(height: 24),
                          Text('Password',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: labelColor)),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(color: formTextColor),
                            autofillHints: const [AutofillHints.password],
                            enableSuggestions: false,
                            autocorrect: false,
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              hintStyle: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.grey),
                              prefixIcon: Icon(Icons.lock_outline_rounded,
                                  color: Colors.grey),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: inputBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: inputBorderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: inputBorderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: isDark
                                        ? ThemeProvider.accentTeal
                                        : ThemeProvider.primaryNavy,
                                    width: 2),
                              ),
                            ),
                            textInputAction: TextInputAction.go,
                            onFieldSubmitted: (_) => _performLogin(),
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Enter your password'
                                : null,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: isDark
                                          ? ThemeProvider.accentTeal
                                          : ThemeProvider.primaryNavy,
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Remember Me',
                                    style: GoogleFonts.inter(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.grey.shade700,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: _showForgotPasswordDialog,
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                      color: isDark
                                          ? ThemeProvider.accentTeal
                                          : ThemeProvider.primaryNavy,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 32),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _performLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? ThemeProvider.accentTeal
                                    : ThemeProvider.primaryNavy,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                          color: Theme.of(context).cardColor,
                                          strokeWidth: 2),
                                    )
                                  : Text(
                                      'Sign In',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                            ),
                          ),
                          SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account?",
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.grey.shade600)),
                              TextButton(
                                onPressed: () => context.go('/register'),
                                child: Text(
                                  'Sign up',
                                  style: TextStyle(
                                      color: isDark
                                          ? ThemeProvider.accentTeal
                                          : ThemeProvider.primaryNavy,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
