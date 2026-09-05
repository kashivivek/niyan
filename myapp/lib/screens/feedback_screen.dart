import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/widgets/feedback_dialog.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel?>();
    return Scaffold(
      appBar: AppBar(title: const Text('Report an Issue')),
      body: Center(
        child: FilledButton.icon(
          onPressed: user == null ? null : () => showFeedbackDialog(context, user),
          icon: const Icon(Icons.feedback_outlined),
          label: const Text('Open feedback form'),
        ),
      ),
    );
  }
}
