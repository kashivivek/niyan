import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/unit_model.dart';
import '../services/database_service.dart';
import '../models/property_model.dart';
import 'package:myapp/widgets/responsive_centered.dart';

class AddUnitScreen extends StatefulWidget {
  final String propertyId;
  final PropertyModel property;

  const AddUnitScreen({super.key, required this.propertyId, required this.property});

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
      final newUnit = UnitModel(
        id: ' ', // Firestore will generate this
        propertyId: widget.propertyId,
        ownerId: widget.property.ownerId,
        unitNumber: _unitNumberController.text,
        monthlyRent: double.parse(_monthlyRentController.text),
        sqft: int.tryParse(_sqftController.text) ?? 0,
        bedrooms: _bedrooms,
        bathrooms: _bathrooms,
        rentDueDate: _rentDueDate,
      );

      context.read<DatabaseService>().addUnit(newUnit, widget.property.ownerId).then((_) {
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
        title: Text('Add New Unit', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ResponsiveCentered(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Add a unit to ${widget.property.name}',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fill in the details for this individual unit.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _unitNumberController,
                decoration: const InputDecoration(
                  labelText: 'Unit Number',
                  prefixIcon: Icon(Icons.tag_outlined),
                  hintText: 'e.g., 101, Apt B',
                ),
                validator: (value) => value!.isEmpty ? 'Please enter a unit number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _monthlyRentController,
                decoration: const InputDecoration(
                  labelText: 'Monthly Rent',
                  prefixIcon: Icon(Icons.attach_money_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter the rent amount';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _rentDueDate,
                decoration: const InputDecoration(
                  labelText: 'Rent Due Day of Month',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                items: List.generate(28, (index) => index + 1)
                    .map((day) => DropdownMenuItem(value: day, child: Text(day.toString())))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _rentDueDate = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sqftController,
                decoration: const InputDecoration(
                  labelText: 'Square Footage (Optional)',
                  prefixIcon: Icon(Icons.square_foot_outlined),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              _buildCounter('Bedrooms', Icons.king_bed_outlined, _bedrooms, (val) => setState(() => _bedrooms = val)),
              const SizedBox(height: 16),
              _buildCounter('Bathrooms', Icons.bathtub_outlined, _bathrooms, (val) => setState(() => _bathrooms = val)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline_rounded),
                onPressed: _submitForm,
                label: const Text('Add Unit'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounter(String label, IconData icon, int value, ValueChanged<int> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            color: Theme.of(context).colorScheme.secondary,
          ),
          Text(value.toString(), style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => onChanged(value + 1),
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
