import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/database_service.dart';

Future<void> showFeedbackDialog(BuildContext context, UserModel user) async {
  final commentController = TextEditingController();
  var rating = 5;
  var category = 'General';
  var isSubmitting = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Share feedback'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How useful is Niyan for you?'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (index) {
                    final value = index + 1;
                    return IconButton(
                      tooltip: '$value out of 5',
                      onPressed: () => setDialogState(() => rating = value),
                      icon: Icon(value <= rating ? Icons.star : Icons.star_border, color: Colors.amber.shade700, size: 30),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'General', child: Text('General')),
                    DropdownMenuItem(value: 'Bug', child: Text('Bug or issue')),
                    DropdownMenuItem(value: 'Feature', child: Text('Feature request')),
                    DropdownMenuItem(value: 'Usability', child: Text('Usability')),
                  ],
                  onChanged: (value) => setDialogState(() => category = value ?? 'General'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  maxLength: 2000,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Comments',
                    hintText: 'Tell us what is working or what needs improvement',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: isSubmitting
                ? null
                : () async {
                    final comment = commentController.text.trim();
                    if (comment.length < 3) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter at least 3 characters.')));
                      return;
                    }
                    setDialogState(() => isSubmitting = true);
                    try {
                      await context.read<DatabaseService>().submitFeedback(
                            userId: user.uid,
                            userEmail: user.email ?? '',
                            rating: rating,
                            category: category,
                            comment: comment,
                          );
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks, your feedback was sent.')));
                    } catch (error) {
                      if (dialogContext.mounted) setDialogState(() => isSubmitting = false);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not send feedback: $error')));
                    }
                  },
            child: isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send'),
          ),
        ],
      ),
    ),
  );
  commentController.dispose();
}
