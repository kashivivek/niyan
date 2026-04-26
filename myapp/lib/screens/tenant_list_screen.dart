import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/tenant_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/screens/add_tenant_screen.dart';
import 'package:myapp/screens/tenant_detail_screen.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/providers/theme_provider.dart';

class TenantListScreen extends StatelessWidget {
  const TenantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final user = Provider.of<UserModel?>(context);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 160,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Image.asset('assets/images/logo_full.png', fit: BoxFit.contain),
        ),
        title: const SizedBox.shrink(),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<TenantModel>>(
              stream: databaseService.getAllTenants(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(context);
                }

                final tenants = snapshot.data!;
                final screenWidth = MediaQuery.of(context).size.width;
                final crossAxisCount = screenWidth > 1200 ? 3 : (screenWidth > 800 ? 2 : 1);

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 0,
                    mainAxisExtent: 105,
                  ),
                  itemCount: tenants.length,
                  itemBuilder: (context, index) {
                    return TenantCard(tenant: tenants[index]);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ThemeProvider.accentBlue,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTenantScreen())),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ThemeProvider.primaryNavy.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people_alt_rounded, size: 80, color: ThemeProvider.primaryNavy.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            Text(
              'No Tenants Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 12),
            Text(
              'You haven\'t added any tenants. Tap the + icon below to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class TenantCard extends StatelessWidget {
  final TenantModel tenant;

  const TenantCard({super.key, required this.tenant});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TenantDetailScreen(tenant: tenant))),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: ThemeProvider.primaryNavy.withOpacity(0.05),
                  backgroundImage: tenant.photoUrl != null && tenant.photoUrl!.isNotEmpty
                      ? NetworkImage(tenant.photoUrl!)
                      : null,
                  child: tenant.photoUrl == null || tenant.photoUrl!.isEmpty
                      ? Icon(Icons.person_outline_rounded, size: 35, color: ThemeProvider.primaryNavy.withOpacity(0.5))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tenant.phoneNumber ?? 'No phone listed',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: tenant.isAssignedToUnit ? Colors.teal.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tenant.isAssignedToUnit ? 'Assigned' : 'Unassigned',
                    style: TextStyle(
                      color: tenant.isAssignedToUnit ? Colors.teal.shade700 : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
