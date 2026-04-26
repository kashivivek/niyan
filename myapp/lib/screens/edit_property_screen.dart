import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/property_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/widgets/responsive_centered.dart';

class EditPropertyScreen extends StatefulWidget {
  final PropertyModel property;

  const EditPropertyScreen({super.key, required this.property});

  @override
  EditPropertyScreenState createState() => EditPropertyScreenState();
}

class EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _imageUrlController;
  late PropertyType _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.property.name);
    _addressController = TextEditingController(text: widget.property.address);
    _cityController = TextEditingController(text: widget.property.city);
    _imageUrlController = TextEditingController(text: widget.property.imageUrl);
    _selectedType = widget.property.type;
  }

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

    final updatedProperty = widget.property.copyWith(
      name: _nameController.text,
      address: _addressController.text,
      city: _cityController.text,
      imageUrl: _imageUrlController.text,
      type: _selectedType,
    );

    await context.read<DatabaseService>().updateProperty(updatedProperty);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Property'),
      ),
      body: ResponsiveCentered(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter an address' : null,
              ),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a city' : null,
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              DropdownButtonFormField<PropertyType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Property Type'),
                items: PropertyType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toString().split('.').last),
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
