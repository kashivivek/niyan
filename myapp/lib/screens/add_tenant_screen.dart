import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/services/image_service.dart';
import 'package:intl/intl.dart';
import 'package:myapp/widgets/responsive_centered.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;

class AddTenantScreen extends StatefulWidget {
  const AddTenantScreen({super.key});

  @override
  AddTenantScreenState createState() => AddTenantScreenState();
}

class AddTenantScreenState extends State<AddTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController();
  final _depositController = TextEditingController(text: '0.0');
  DateTime? _moveInDate;
  XFile? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _moveInDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _moveInDate = picked;
      });
    }
  }

  void _submitForm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add a tenant.')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (_moveInDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a move-in date.')),
        );
        return;
      }

      final newTenant = TenantModel(
        id: '',
        name: _nameController.text,
        phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        alternatePhone: _altPhoneController.text.isNotEmpty ? _altPhoneController.text : null,
        rentAmount: 0.0,
        dueDate: DateTime.now(), 
        moveInDate: _moveInDate!,
        ownerId: user.uid,
        isAssignedToUnit: false,
        propertyId: '',
        assignedUnitId: '',
        securityDeposit: double.tryParse(_depositController.text) ?? 0.0,
      );

      try {
        final databaseService = context.read<DatabaseService>();
        final imageService = context.read<ImageService>();

        final tenantRef = await databaseService.addTenant(newTenant);

        if (_image != null) {
          final imageUrl = await imageService.uploadTenantPhoto(tenantRef.id, _image);
          if (imageUrl != null) {
            await databaseService.updateTenantPhotoUrl(tenantRef.id, imageUrl);
          }
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tenant added successfully!')),
          );
        }
      } catch (e) {
        developer.log('Error adding tenant: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding tenant: $e')),
          );
        }
      }
    }
  }

  Widget _buildImagePreview() {
    if (_image == null) {
      return const Icon(Icons.add_a_photo, size: 50, color: Colors.grey);
    }
    if (kIsWeb) {
      return Image.network(_image!.path, fit: BoxFit.cover);
    } else {
      return Image.file(io.File(_image!.path), fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Tenant'),
      ),
      body: ResponsiveCentered(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildImagePreview(),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _altPhoneController,
                  decoration: const InputDecoration(labelText: 'Alternate Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _depositController,
                  decoration: const InputDecoration(labelText: 'Security Deposit'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Please enter a deposit amount' : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Move-In Date'),
                  subtitle: Text(_moveInDate == null
                      ? 'Not selected'
                      : DateFormat('MMM dd, yyyy').format(_moveInDate!)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Add Tenant'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
