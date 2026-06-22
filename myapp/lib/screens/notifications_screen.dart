import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/notification_model.dart';
import 'package:myapp/services/database_service.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/utils/currency_helper.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import 'package:myapp/l10n/generated/app_localizations.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: StreamBuilder<List<NotificationModel>>(
            stream: databaseService.getNotifications(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(AppLocalizations.of(context)?.noNotifications ?? 'No Notifications',
                          style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Text(AppLocalizations.of(context)?.allCaughtUpNotifications ?? 'You\'re all caught up!',
                          style:
                              GoogleFonts.inter(color: Colors.grey.shade500)),
                    ],
                  ),
                );
              }

              final notifications = snapshot.data!;

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return _NotificationCard(
                    notification: notif,
                    databaseService: databaseService,
                    currency: user.currency,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatefulWidget {
  final NotificationModel notification;
  final DatabaseService databaseService;
  final String currency;

  const _NotificationCard({
    required this.notification,
    required this.databaseService,
    required this.currency,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _isProcessing = false;

  Future<void> _handleApplyIncrease() async {
    setState(() => _isProcessing = true);
    try {
      await widget.databaseService.applyRentIncrease(widget.notification);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rent increase applied successfully!')),
        );
      }
    } catch (e) {
      developer.log('Error applying rent increase: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply rent increase: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _markAsRead() async {
    try {
      await widget.databaseService
          .markNotificationAsRead(widget.notification.id);
    } catch (e) {
      developer.log('Error marking as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isRentIncrease =
        widget.notification.type == NotificationType.rentIncrease;
    final bool canApply = isRentIncrease && !widget.notification.isRead;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = widget.notification.isRead
        ? (Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface)
        : (isDark ? const Color(0xFF0F1E36) : Colors.blue.shade50);

    final borderColor = widget.notification.isRead
        ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
        : ThemeProvider.accentBlue.withOpacity(0.3);

    final titleColor = isDark ? Colors.white : ThemeProvider.primaryNavy;
    final bodyColor = isDark ? Colors.white70 : Colors.grey.shade700;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isRentIncrease
                      ? Colors.orange.withOpacity(0.1)
                      : ThemeProvider.accentBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRentIncrease
                      ? Icons.trending_up_rounded
                      : Icons.notifications_rounded,
                  color:
                      isRentIncrease ? Colors.orange : ThemeProvider.accentBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.notification.title,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: widget.notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, HH:mm')
                              .format(widget.notification.createdAt),
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.notification.body,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: bodyColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (canApply) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _markAsRead,
                  child: Text(AppLocalizations.of(context)?.dismiss ?? 'Dismiss',
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _handleApplyIncrease,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline),
                  label: Text(AppLocalizations.of(context)?.applyRentIncrease ?? 'Apply 5% Increase'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeProvider.accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ] else if (!widget.notification.isRead) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _markAsRead,
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text('Mark as Read'),
                  style: TextButton.styleFrom(
                    foregroundColor: ThemeProvider.accentBlue,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
