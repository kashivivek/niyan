import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:myapp/utils/currency_helper.dart';

/// Builds and delivers plain-text rent reminders and receipts to tenants.
///
/// Delivery uses WhatsApp (preferred) then SMS via [url_launcher] so no extra
/// dependency or backend is required. Callers should handle a `false` result by
/// showing the message for manual copy.
class RentMessageHelper {
  const RentMessageHelper._();

  static String _digits(String phone) => phone.replaceAll(RegExp(r'[^0-9]'), '');

  static String receiptNumber(String recordId, DateTime date) {
    final shortId = recordId.length >= 6 ? recordId.substring(0, 6) : recordId;
    return 'RCPT-${shortId.toUpperCase()}-${DateFormat('yyyyMMdd').format(date)}';
  }

  static String buildReminderMessage({
    required String tenantName,
    required String landlordName,
    required double outstanding,
    required DateTime dueDate,
    required String propertyLabel,
    String? currency,
  }) {
    final amount = CurrencyHelper.format(outstanding, currency);
    final due = DateFormat('d MMM yyyy').format(dueDate);
    final overdue = DateTime.now().isAfter(dueDate);
    final line = overdue
        ? 'Your rent of $amount for $propertyLabel was due on $due and is now overdue.'
        : 'This is a friendly reminder that your rent of $amount for $propertyLabel is due on $due.';
    return 'Hi $tenantName,\n\n$line\n\nKindly arrange the payment at your earliest convenience.\n\nThank you,\n$landlordName';
  }

  static String buildReceiptMessage({
    required String tenantName,
    required String landlordName,
    required double paidAmount,
    required double billedAmount,
    required double outstanding,
    required DateTime paymentDate,
    required String period,
    required String propertyLabel,
    required String receiptNo,
    String? paymentMethod,
    String? currency,
  }) {
    final paid = CurrencyHelper.format(paidAmount, currency);
    final billed = CurrencyHelper.format(billedAmount, currency);
    final date = DateFormat('d MMM yyyy').format(paymentDate);

    final buffer = StringBuffer()
      ..writeln('*RENT RECEIPT*')
      ..writeln('Receipt No: $receiptNo')
      ..writeln('Date: $date')
      ..writeln('')
      ..writeln('Received from: $tenantName')
      ..writeln('Property: $propertyLabel')
      ..writeln('Period: $period')
      ..writeln('')
      ..writeln('Amount received: $paid')
      ..writeln('Billed amount: $billed');
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      buffer.writeln('Payment method: $paymentMethod');
    }
    if (outstanding > 0) {
      buffer.writeln('Balance due: ${CurrencyHelper.format(outstanding, currency)}');
    } else {
      buffer.writeln('Status: PAID IN FULL');
    }
    buffer
      ..writeln('')
      ..writeln('Received by: $landlordName');
    return buffer.toString();
  }

  /// Attempts to open WhatsApp, then SMS, pre-filled with [message].
  /// Returns false if no channel could be launched (e.g. no phone number).
  static Future<bool> sendToTenant({
    required String? phone,
    required String message,
  }) async {
    final trimmed = phone?.trim() ?? '';
    if (trimmed.isEmpty) return false;

    final encoded = Uri.encodeComponent(message);

    final whatsapp = Uri.parse('https://wa.me/${_digits(trimmed)}?text=$encoded');
    if (await canLaunchUrl(whatsapp)) {
      return launchUrl(whatsapp, mode: LaunchMode.externalApplication);
    }

    final sms = Uri.parse('sms:$trimmed?body=$encoded');
    if (await canLaunchUrl(sms)) {
      return launchUrl(sms, mode: LaunchMode.externalApplication);
    }

    return false;
  }
}
