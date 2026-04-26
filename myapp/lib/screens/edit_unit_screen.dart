import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/unit_model.dart';
import '../services/database_service.dart';
import 'package:myapp/widgets/responsive_centered.dart';

class EditUnitScreen extends StatefulWidget {
  final UnitModel unit;

  const EditUnitScreen({super.key, required this.unit});

  @override
  State<EditUnitScreen> createState() => _EditUnitScreenState();
}

class _EditUnitScreenState extends State<EditUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _unitNumberController;
  late TextEditingController _monthlyRentController;
  late TextEditingController _sqftController;
  late int _bedrooms;
  late int _bathrooms;
  late int _rentDueDate;

  @override
  void initState() {
    super.initState();
    _unitNumberController = TextEditingController(text: widget.unit.unitNumber);
    _monthlyRentController = TextEditingController(text: widget.unit.monthlyRent.toString());
    _sqftController = TextEditingController(text: widget.unit.sqft.toString());
    _bedrooms = widget.unit.bedrooms;
    _bathrooms = widget.unit.bathrooms;
    _rentDueDate = widget.unit.rentDueDate;
  }

  @override
  void dispose() {
    _unitNumberController.dispose();
    _monthlyRentController.dispose();
    _sqftController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedUnit = widget.unit.copyWith(
        unitNumber: _unitNumberController.text,
        monthlyRent: double.parse(_monthlyRentController.text),
        sqft: int.tryParse(_sqftController.text) ?? 0,
        bedrooms: _bedrooms,
        bathrooms: _bathrooms,
        rentDueDate: _rentDueDate,
      );
      try {
        await context.read<DatabaseService>().updateUnit(updatedUnit);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unit updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update unit: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Unit', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ResponsiveCentered(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Editing Unit ${widget.unit.unitNumber}',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _unitNumberController,
                decoration: const InputDecoration(
                  labelText: 'Unit Number',
                  prefixIcon: Icon(Icons.tag_outlined),
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
                  if (value == null || value.isEmpty) return 'Please enter the rent';
                  if (double.tryParse(value) == null) return 'Enter a valid number';
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
                  if (value != null) setState(() => _rentDueDate = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sqftController,
                decoration: const InputDecoration(
                  labelText: 'Square Footage',
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
                icon: const Icon(Icons.save_alt_outlined),
                onPressed: _saveChanges,
                label: const Text('Save Changes'),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
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
