import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/services/image_service.dart';
import 'package:intl/intl.dart';
import 'package:myapp/widgets/responsive_centered.dart';

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
  late TextEditingController _altPhoneController; // #6
  DateTime? _moveInDate;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tenant.name);
    _phoneController = TextEditingController(text: widget.tenant.phoneNumber ?? '');
    _altPhoneController = TextEditingController(text: widget.tenant.alternatePhone ?? '');
    _moveInDate = widget.tenant.moveInDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    super.dispose();
  }

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
    if (_formKey.currentState!.validate()) {
      if (_moveInDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a move-in date.')),
        );
        return;
      }

      setState(() => _isLoading = true);

      final updatedTenant = widget.tenant.copyWith(
        name: _nameController.text,
        phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        alternatePhone: _altPhoneController.text.isNotEmpty ? _altPhoneController.text : null,
        // due date is now per unit — keep existing value
        moveInDate: _moveInDate!,
      );

      try {
        final databaseService = context.read<DatabaseService>();
        final imageService = context.read<ImageService>();

        await databaseService.updateTenant(updatedTenant);

        if (_image != null) {
          final imageUrl = await imageService.uploadTenantPhoto(updatedTenant.id, _image!);
          if (imageUrl != null) {
            await databaseService.updateTenantPhotoUrl(updatedTenant.id, imageUrl);
          }
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tenant updated successfully!')),
          );
        }
      } catch (e, s) {
        developer.log('Failed to update tenant', name: 'edit_tenant.error', error: e, stackTrace: s);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update tenant: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Tenant'),
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
                    backgroundImage: _image != null
                        ? FileImage(_image!)
                        : (widget.tenant.photoUrl != null && widget.tenant.photoUrl!.isNotEmpty
                            ? NetworkImage(widget.tenant.photoUrl!) as ImageProvider
                            : null),
                    child: _image == null && (widget.tenant.photoUrl == null || widget.tenant.photoUrl!.isEmpty)
                        ? Icon(Icons.camera_alt, color: Colors.grey[800], size: 40)
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
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
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
              // #7: Rent Amount field removed — managed at unit level
              _buildDatePicker(
                context: context,
                label: 'Move-in Date',
                date: _moveInDate,
                onPressed: () => _selectDate(context),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Changes', style: TextStyle(fontSize: 16)),
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
            color: date != null ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}
