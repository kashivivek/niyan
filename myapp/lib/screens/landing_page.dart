import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/theme_provider.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildNavbar(context, isMobile),
            _buildHero(context, isMobile),
            _buildCapabilitySection(
              context,
              isMobile,
              title: 'For Individual Landlords',
              subtitle: 'Effortless Property Management',
              description: 'Manage your personal portfolio with automated rent collection, digital ledgers, and tenant tracking.',
              features: ['Automated Rent Invoicing', 'Digital Payment Receipts', 'Tenant KYC & Documents', 'Financial Insights'],
              image: Icons.home_work_rounded,
              isReversed: false,
            ),
            _buildCapabilitySection(
              context,
              isMobile,
              title: 'For Housing Societies',
              subtitle: 'Advanced ERP & Security',
              description: 'Digitize your entire community. From gate security to automated billing and resident engagement.',
              features: ['Smart Gate & Visitor Logs', 'Automated Maintenance Billing', 'Community Forum & Notices', 'Helpdesk & Amenity Booking'],
              image: Icons.apartment_rounded,
              isReversed: true,
              color: ThemeProvider.accentTeal,
            ),
            _buildFooter(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildNavbar(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40, vertical: 24),
      child: Row(
        children: [
          Image.asset('assets/images/logo_full.png', height: isMobile ? 32 : 40, errorBuilder: (c, e, s) => Text('NIYAN', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy))),
          const Spacer(),
          if (!isMobile) ...[
            TextButton(onPressed: () => context.push('/login'), child: Text('Sign In', style: GoogleFonts.outfit(color: ThemeProvider.primaryNavy, fontWeight: FontWeight.w600))),
            const SizedBox(width: 24),
          ],
          ElevatedButton(
            onPressed: () => context.push('/register'),
            style: ElevatedButton.styleFrom(backgroundColor: ThemeProvider.primaryNavy, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 32, vertical: isMobile ? 12 : 16), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text(isMobile ? 'Get Started' : 'Launch App', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40, vertical: isMobile ? 80 : 120),
      decoration: BoxDecoration(
        color: ThemeProvider.primaryNavy,
        image: DecorationImage(
          image: const AssetImage('assets/images/logo_icon.png'),
          opacity: 0.05,
          scale: 0.5,
          alignment: Alignment.centerRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(30)),
            child: Text('THE FUTURE OF REAL ESTATE MANAGEMENT', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: isMobile ? 9 : 10, fontWeight: FontWeight.w800, color: ThemeProvider.accentTeal, letterSpacing: 2)),
          ),
          const SizedBox(height: 32),
          Text(
            'Digitize Your Portfolio.\nElevate Your Community.', 
            textAlign: TextAlign.center, 
            style: GoogleFonts.outfit(fontSize: isMobile ? 36 : 64, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1, letterSpacing: -1)
          ),
          const SizedBox(height: 32),
          Text(
            'The definitive ecosystem for individual landlords and gated communities.\nSeamlessly bridge Security, Finance, and Resident Engagement.', 
            textAlign: TextAlign.center, 
            style: GoogleFonts.inter(fontSize: isMobile ? 16 : 20, color: Colors.white70, height: 1.6)
          ),
          SizedBox(height: isMobile ? 48 : 64),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _HeroButton(label: 'Society ERP Mode', color: ThemeProvider.accentBlue, onTap: () => context.push('/register'), isMobile: isMobile),
              _HeroButton(label: 'Individual Landlord', color: Colors.white, isOutlined: true, onTap: () => context.push('/register'), isMobile: isMobile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilitySection(BuildContext context, bool isMobile, {required String title, required String subtitle, required String description, required List<String> features, required IconData image, bool isReversed = false, Color color = ThemeProvider.primaryNavy}) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(subtitle.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.5)),
        ),
        const SizedBox(height: 24),
        Text(title, style: GoogleFonts.outfit(fontSize: isMobile ? 32 : 44, fontWeight: FontWeight.bold, color: ThemeProvider.primaryNavy, height: 1.1)),
        const SizedBox(height: 20),
        Text(description, style: GoogleFonts.inter(fontSize: isMobile ? 16 : 18, color: Colors.grey.shade600, height: 1.6)),
        const SizedBox(height: 40),
        ...features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(children: [Icon(Icons.check_circle_rounded, color: color, size: 22), const SizedBox(width: 14), Expanded(child: Text(f, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: ThemeProvider.primaryNavy)))]),
        )),
      ],
    );

    final imageWidget = Center(
      child: Container(
        padding: EdgeInsets.all(isMobile ? 40 : 60),
        decoration: BoxDecoration(color: color.withOpacity(0.05), shape: BoxShape.circle),
        child: Icon(image, size: isMobile ? 80 : 120, color: color),
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 60 : 100),
      child: isMobile 
        ? Column(
            children: [
              imageWidget,
              const SizedBox(height: 48),
              content,
            ],
          )
        : Row(
            children: [
              if (isReversed) ...[Expanded(child: imageWidget), const SizedBox(width: 80)],
              Expanded(child: content),
              if (!isReversed) ...[const SizedBox(width: 80), Expanded(child: imageWidget)],
            ],
          ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 40 : 60),
      width: double.infinity,
      color: ThemeProvider.primaryNavy,
      child: Column(
        children: [
          Text('Ready to elevate your property management?', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          Text('© 2026 Niyan ERP. All rights reserved.', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isOutlined;
  final VoidCallback onTap;
  final bool isMobile;
  const _HeroButton({required this.label, required this.color, this.isOutlined = false, required this.onTap, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isMobile ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : color,
          foregroundColor: isOutlined ? Colors.white : ThemeProvider.primaryNavy,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: isMobile ? 16 : 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: isOutlined ? const BorderSide(color: Colors.white) : BorderSide.none),
          elevation: 0,
        ),
        child: Text(label, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
