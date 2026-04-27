
import 'dart:io';
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

class AddTenantScreen extends StatefulWidget {
  const AddTenantScreen({super.key});

  @override
  AddTenantScreenState createState() => AddTenantScreenState();
}

class AddTenantScreenState extends State<AddTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController(); // #6
  DateTime? _moveInDate;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
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
        dueDate: DateTime.now(), // placeholder; due date is now per unit
        moveInDate: _moveInDate!,
        ownerId: user.uid,
        isAssignedToUnit: false,
        propertyId: '',
        assignedUnitId: '',
      );

      try {
        final databaseService = context.read<DatabaseService>();
        final imageService = context.read<ImageService>();

        final tenantRef = await databaseService.addTenant(newTenant);

        if (_image != null) {
          final imageUrl =
              await imageService.uploadTenantPhoto(tenantRef.id, _image!);
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
      } catch (e, s) {
        developer.log(
          'Failed to add tenant',
          name: 'add_tenant.error',
          error: e,
          stackTrace: s,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add tenant: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Tenant'),
      ),
      body: ResponsiveCentered(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _image != null ? FileImage(_image!) : null,
                    child: _image == null
                        ? Icon(Icons.camera_alt,
                            color: Colors.grey[800], size: 40)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              // #6: Alternate phone number field
              TextFormField(
                controller: _altPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Alternate Phone Number (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_forwarded_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              // #7: Rent Amount field removed — rent is managed at unit level
              _buildDatePicker(
                context: context,
                label: 'Move-in Date',
                date: _moveInDate,
                onPressed: () => _selectDate(context),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Add Tenant', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null ? DateFormat.yMMMd().format(date) : 'Select a date',
          style: TextStyle(
            color: date != null
                ? Theme.of(context).textTheme.bodyLarge?.color
                : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}
