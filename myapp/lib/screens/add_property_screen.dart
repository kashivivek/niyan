import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/property_model.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/widgets/responsive_centered.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  AddPropertyScreenState createState() => AddPropertyScreenState();
}

class AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _imageUrlController = TextEditingController();
  PropertyType _selectedType = PropertyType.house;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authService = context.read<AuthService>();
    final appMode = context.read<AppModeProvider>();
    final user = await authService.user.first;

    if (!mounted || user == null) return;

    final propertyToSave = PropertyModel(
      id: '', // Firestore will generate this
      name: _nameController.text,
      address: _addressController.text,
      city: _cityController.text,
      imageUrl: _imageUrlController.text,
      type: _selectedType,
      ownerId: user.uid,
      societyId: appMode.isSocietyMode ? appMode.activeSociety?.id : null,
    );

    await context.read<DatabaseService>().addProperty(propertyToSave);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Property'),
        backgroundColor: Colors.white,
        foregroundColor: ThemeProvider.primaryNavy,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Property Name',
                      hintText: 'e.g. Skyline Apartments',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ThemeProvider.primaryNavy, width: 2)),
                      prefixIcon: const Icon(Icons.business_rounded, color: ThemeProvider.primaryNavy),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Enter property name' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      hintText: 'Full street address',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ThemeProvider.primaryNavy, width: 2)),
                      prefixIcon: const Icon(Icons.location_on_rounded, color: ThemeProvider.primaryNavy),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Enter address' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'City',
                      hintText: 'e.g. San Francisco',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ThemeProvider.primaryNavy, width: 2)),
                      prefixIcon: const Icon(Icons.location_city_rounded, color: ThemeProvider.primaryNavy),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Enter city' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(
                      labelText: 'Image URL (Optional)',
                      hintText: 'https://...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ThemeProvider.primaryNavy, width: 2)),
                      prefixIcon: const Icon(Icons.image_outlined, color: ThemeProvider.primaryNavy),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<PropertyType>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Property Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ThemeProvider.primaryNavy, width: 2)),
                      prefixIcon: const Icon(Icons.category_outlined, color: ThemeProvider.primaryNavy),
                    ),
                    items: PropertyType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.toString().split('.').last.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeProvider.primaryNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('CREATE PROPERTY', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
