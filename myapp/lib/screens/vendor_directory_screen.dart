import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/vendor_model.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/vendor_service.dart';

class VendorDirectoryScreen extends StatefulWidget {
  const VendorDirectoryScreen({super.key});

  @override
  State<VendorDirectoryScreen> createState() => _VendorDirectoryScreenState();
}

class _VendorDirectoryScreenState extends State<VendorDirectoryScreen> {
  VendorCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final appMode = Provider.of<AppModeProvider>(context);
    final vendorService = Provider.of<VendorService>(context, listen: false);

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final stream = appMode.isStandaloneMode
        ? vendorService.getVendorsByOwner(user.uid)
        : vendorService.getVendorsBySociety(appMode.activeSociety?.id ?? '');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Vendors',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vendors/add'),
        backgroundColor: ThemeProvider.accentBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add Vendor',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<VendorModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allVendors = snapshot.data ?? [];
          final filtered = allVendors.where((v) {
            final matchesCategory = _selectedCategory == null ||
                v.category == _selectedCategory;
            final matchesSearch = _searchQuery.isEmpty ||
                v.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                v.phone.contains(_searchQuery);
            return matchesCategory && matchesSearch;
          }).toList();

          return Column(
            children: [
              _buildSearchBar(),
              _buildCategoryFilter(),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) =>
                            _VendorCard(vendor: filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search vendors...',
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            borderSide: const BorderSide(color: ThemeProvider.accentBlue),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _FilterChip(
            label: 'All',
            selected: _selectedCategory == null,
            onTap: () => setState(() => _selectedCategory = null),
          ),
          ...VendorCategory.values.map((cat) => _FilterChip(
                label: '${cat.icon} ${cat.label}',
                selected: _selectedCategory == cat,
                onTap: () => setState(() =>
                    _selectedCategory = _selectedCategory == cat ? null : cat),
              )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No vendors found',
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade400)),
          const SizedBox(height: 8),
          Text('Add your first vendor to get started',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade300)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? ThemeProvider.accentBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? ThemeProvider.accentBlue : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  final VendorModel vendor;
  const _VendorCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/vendors/${vendor.id}', extra: vendor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: ThemeProvider.accentBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(vendor.category.icon,
                    style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vendor.name,
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: ThemeProvider.primaryNavy)),
                  const SizedBox(height: 2),
                  Text(vendor.category.label,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(vendor.phone,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (vendor.rating > 0) ...[
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(vendor.rating.toStringAsFixed(1),
                          style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ThemeProvider.primaryNavy)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${vendor.totalJobs} job${vendor.totalJobs != 1 ? 's' : ''}',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.grey.shade400)),
                ],
                const SizedBox(height: 8),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.grey, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
