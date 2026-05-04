import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/unit_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/property_model.dart';
import 'package:myapp/widgets/responsive_centered.dart';

class AddUnitScreen extends StatefulWidget {
  final String propertyId;
  final PropertyModel? property;

  const AddUnitScreen({super.key, required this.propertyId, this.property});

  @override
  State<AddUnitScreen> createState() => _AddUnitScreenState();
}

class _AddUnitScreenState extends State<AddUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _unitNumberController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  final _sqftController = TextEditingController();
  int _bedrooms = 1;
  int _bathrooms = 1;
  int _rentDueDate = 1;

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final ownerId = context.read<AuthService>().currentUser?.uid;
      if (ownerId == null) return;

      final newUnit = UnitModel(
        id: '',
        propertyId: widget.propertyId,
        ownerId: ownerId,
        unitNumber: _unitNumberController.text,
        monthlyRent: double.parse(_monthlyRentController.text),
        sqft: int.tryParse(_sqftController.text) ?? 0,
        bedrooms: _bedrooms,
        bathrooms: _bathrooms,
        rentDueDate: _rentDueDate,
      );

      context.read<DatabaseService>().addUnit(newUnit, ownerId).then((_) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unit added successfully!')),
          );
        }
      }).catchError((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add unit: $error')),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Unit', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: ResponsiveCentered(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _unitNumberController,
                  decoration: const InputDecoration(labelText: 'Unit Number', border: OutlineInputBorder()),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _monthlyRentController,
                  decoration: const InputDecoration(labelText: 'Monthly Rent', border: OutlineInputBorder(), prefixText: '\u20b9 '),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sqftController,
                  decoration: const InputDecoration(labelText: 'Square Feet', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bedrooms', style: TextStyle(fontWeight: FontWeight.bold)),
                          Slider(
                            value: _bedrooms.toDouble(),
                            min: 0,
                            max: 10,
                            divisions: 10,
                            label: _bedrooms.toString(),
                            onChanged: (v) => setState(() => _bedrooms = v.round()),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bathrooms', style: TextStyle(fontWeight: FontWeight.bold)),
                          Slider(
                            value: _bathrooms.toDouble(),
                            min: 0,
                            max: 10,
                            divisions: 10,
                            label: _bathrooms.toString(),
                            onChanged: (v) => setState(() => _bathrooms = v.round()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Rent Due Date (Day of Month)', style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: _rentDueDate.toDouble(),
                  min: 1,
                  max: 31,
                  divisions: 30,
                  label: _rentDueDate.toString(),
                  onChanged: (v) => setState(() => _rentDueDate = v.round()),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add Unit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
