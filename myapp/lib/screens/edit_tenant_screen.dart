import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/services/image_service.dart';
import 'package:intl/intl.dart';
import 'package:myapp/widgets/responsive_centered.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;

class EditTenantScreen extends StatefulWidget {
  final TenantModel tenant;
  const EditTenantScreen({super.key, required this.tenant});

  @override
  EditTenantScreenState createState() => EditTenantScreenState();
}

class EditTenantScreenState extends State<EditTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _altPhoneController;
  late TextEditingController _depositController;
  DateTime? _moveInDate;
  XFile? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tenant.name);
    _phoneController = TextEditingController(text: widget.tenant.phoneNumber ?? '');
    _altPhoneController = TextEditingController(text: widget.tenant.alternatePhone ?? '');
    _depositController = TextEditingController(text: widget.tenant.securityDeposit.toString());
    _moveInDate = widget.tenant.moveInDate;
  }

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
    if (_formKey.currentState!.validate()) {
      if (_moveInDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a move-in date.')),
        );
        return;
      }

      final updatedTenant = widget.tenant.copyWith(
        name: _nameController.text,
        phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        alternatePhone: _altPhoneController.text.isNotEmpty ? _altPhoneController.text : null,
        moveInDate: _moveInDate!,
        securityDeposit: double.tryParse(_depositController.text) ?? widget.tenant.securityDeposit,
      );

      try {
        final databaseService = context.read<DatabaseService>();
        final imageService = context.read<ImageService>();

        await databaseService.updateTenant(updatedTenant);

        if (_image != null) {
          final imageUrl = await imageService.uploadTenantPhoto(widget.tenant.id, _image);
          if (imageUrl != null) {
            await databaseService.updateTenantPhotoUrl(widget.tenant.id, imageUrl);
          }
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tenant updated successfully!')),
          );
        }
      } catch (e) {
        developer.log('Error updating tenant: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating tenant: $e')),
          );
        }
      }
    }
  }

  Widget _buildImagePreview() {
    if (_image == null) {
      if (widget.tenant.photoUrl != null && widget.tenant.photoUrl!.isNotEmpty) {
        return Image.network(widget.tenant.photoUrl!, fit: BoxFit.cover);
      }
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
        title: const Text('Edit Tenant'),
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
                  child: const Text('Update Tenant'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
