import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/visitor_model.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/visitor_service.dart';

/// Resident screen to pre-approve a visitor and generate a QR pass.
class VisitorPreApproveScreen extends StatefulWidget {
  const VisitorPreApproveScreen({super.key});

  @override
  State<VisitorPreApproveScreen> createState() =>
      _VisitorPreApproveScreenState();
}

class _VisitorPreApproveScreenState extends State<VisitorPreApproveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _purposeController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _agencyController = TextEditingController();

  VisitorType _selectedType = VisitorType.guest;
  DateTime? _expectedAt;
  DateTime? _validUntil;
  bool _leaveAtGate = false;
  bool _isSaving = false;
  String? _createdVisitorId;
  String? _createdQrCode;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _purposeController.dispose();
    _vehicleController.dispose();
    _agencyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final user = context.read<UserModel?>();
    final appMode = context.read<AppModeProvider>();
    final visitorService = context.read<VisitorService>();

    if (user == null || appMode.activeSociety == null) return;

    try {
      final visitorId = await visitorService.preApproveVisitor(
        societyId: appMode.activeSociety!.id,
        unitId: user.uid, // In real flow: selected unit from membership
        propertyId: appMode.activeSociety!.id,
        residentId: user.uid,
        residentName: user.name ?? 'Resident',
        unitNumber: 'My Unit', // Would come from MemberModel
        visitorName: _nameController.text.trim(),
        visitorPhone: _phoneController.text.trim(),
        type: _selectedType,
        purpose: _purposeController.text.trim().isEmpty
            ? null
            : _purposeController.text.trim(),
        expectedAt: _expectedAt,
        validUntil: _validUntil,
        leaveAtGate: _leaveAtGate,
        deliveryAgency: _agencyController.text.trim().isEmpty
            ? null
            : _agencyController.text.trim(),
        vehicleNumber: _vehicleController.text.trim().isEmpty
            ? null
            : _vehicleController.text.trim(),
      );

      // Read back the QR code
      final snap = await visitorService.getVisitorStream(visitorId).first;

      setState(() {
        _createdVisitorId = visitorId;
        _createdQrCode = snap.qrCode;
        _isSaving = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_createdQrCode != null) {
      return _QrPassScreen(
        visitorName: _nameController.text,
        visitorPhone: _phoneController.text,
        type: _selectedType,
        expectedAt: _expectedAt,
        qrCode: _createdQrCode!,
        onClose: () => Navigator.of(context).pop(),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Invite Visitor',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Type picker
            _buildSectionLabel('Visitor Type'),
            const SizedBox(height: 10),
            _buildTypePicker(),
            const SizedBox(height: 20),

            // Basic info
            _buildSectionLabel('Visitor Details'),
            const SizedBox(height: 10),
            _buildField(_nameController, 'Full Name *', Icons.person_outline_rounded, required: true),
            const SizedBox(height: 12),
            _buildField(_phoneController, 'Phone Number *', Icons.phone_outlined,
                required: true, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _buildField(_purposeController, 'Purpose / Note', Icons.note_outlined),

            // Type-specific fields
            if (_selectedType == VisitorType.cab ||
                _selectedType == VisitorType.contractor) ...[
              const SizedBox(height: 12),
              _buildField(_vehicleController, 'Vehicle Number', Icons.directions_car_outlined),
            ],
            if (_selectedType == VisitorType.delivery) ...[
              const SizedBox(height: 12),
              _buildField(_agencyController, 'Delivery Agency (e.g. Amazon, Swiggy)',
                  Icons.local_shipping_outlined),
              const SizedBox(height: 12),
              _buildToggle(
                'Leave at Gate',
                'Guard will collect on my behalf',
                Icons.inbox_outlined,
                _leaveAtGate,
                (v) => setState(() => _leaveAtGate = v),
              ),
            ],

            const SizedBox(height: 20),
            _buildSectionLabel('Timing'),
            const SizedBox(height: 10),
            _buildDatePicker(
              label: 'Expected Arrival',
              value: _expectedAt,
              icon: Icons.schedule_outlined,
              onPick: (dt) => setState(() => _expectedAt = dt),
            ),
            const SizedBox(height: 12),
            _buildDatePicker(
              label: 'Pass Valid Until (optional — leave blank for one-time)',
              value: _validUntil,
              icon: Icons.event_outlined,
              onPick: (dt) => setState(() => _validUntil = dt),
            ),

            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.qr_code_rounded, color: Colors.white),
                label: Text(
                  _isSaving ? 'Generating Pass...' : 'Generate QR Pass',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeProvider.accentBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTypePicker() {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: VisitorType.values.map((type) {
          final isSelected = _selectedType == type;
          return GestureDetector(
            onTap: () => setState(() => _selectedType = type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? ThemeProvider.accentBlue : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? ThemeProvider.accentBlue : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: ThemeProvider.accentBlue.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(type.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(
                    type.label,
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _buildToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary)),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ThemeProvider.accentBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required IconData icon,
    required ValueChanged<DateTime> onPick,
  }) {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDateTimePicker(context, initialDate: now);
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade400, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value != null
                    ? DateFormat('d MMM yyyy, h:mm a').format(value)
                    : label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: value != null
                      ? ThemeProvider.primaryNavy
                      : Colors.grey.shade400,
                ),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () => setState(() {
                  if (label.contains('Expected')) {
                    _expectedAt = null;
                  } else {
                    _validUntil = null;
                  }
                }),
                child: Icon(Icons.close_rounded,
                    size: 18, color: Colors.grey.shade400),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade400,
          letterSpacing: 1.2),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ThemeProvider.accentBlue, width: 2),
      ),
    );
  }
}

/// Helper to pick date and time together.
Future<DateTime?> showDateTimePicker(BuildContext context,
    {required DateTime initialDate}) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 365)),
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initialDate),
  );
  if (time == null) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

/// Full-screen QR pass shown after successful pre-approval.
class _QrPassScreen extends StatelessWidget {
  final String visitorName;
  final String visitorPhone;
  final VisitorType type;
  final DateTime? expectedAt;
  final String qrCode;
  final VoidCallback onClose;

  const _QrPassScreen({
    required this.visitorName,
    required this.visitorPhone,
    required this.type,
    this.expectedAt,
    required this.qrCode,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeProvider.primaryNavy,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: onClose,
                  ),
                  Expanded(
                    child: Text(
                      'Visitor Pass',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          color: Theme.of(context).cardColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // QR Code card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Visitor info
                          Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: ThemeProvider.accentBlue
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(type.icon,
                                      style: const TextStyle(fontSize: 26)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(visitorName,
                                        style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Theme.of(context).colorScheme.primary)),
                                    Text(visitorPhone,
                                        style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: Colors.grey.shade500)),
                                    Text(type.label,
                                        style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: ThemeProvider.accentBlue,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 20),
                          // QR Code
                          QrImageView(
                            data: qrCode,
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            qrCode,
                            style: GoogleFonts.robotoMono(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                letterSpacing: 1),
                          ),
                          if (expectedAt != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.schedule_rounded,
                                      size: 16, color: Colors.orange.shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Expected ${DateFormat('d MMM, h:mm a').format(expectedAt!)}',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.orange.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Instructions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          _buildInstruction(
                              Icons.share_rounded,
                              'Share this pass with your visitor',
                              Colors.blue.shade300),
                          const SizedBox(height: 12),
                          _buildInstruction(
                              Icons.qr_code_scanner_rounded,
                              'Guard will scan the QR at the gate',
                              Colors.green.shade300),
                          const SizedBox(height: 12),
                          _buildInstruction(
                              Icons.notifications_outlined,
                              'You\'ll be notified when they arrive',
                              Colors.purple.shade300),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(text,
              style: GoogleFonts.inter(
                  color: Colors.white70, fontSize: 14)),
        ),
      ],
    );
  }
}
