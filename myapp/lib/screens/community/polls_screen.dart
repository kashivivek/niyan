import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/poll_model.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/community_service.dart';

class PollsScreen extends StatelessWidget {
  const PollsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final appMode = Provider.of<AppModeProvider>(context);
    final communityService = Provider.of<CommunityService>(context, listen: false);

    if (user == null || appMode.activeSociety == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Community Polls', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<PollModel>>(
        stream: communityService.getPolls(appMode.activeSociety!.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final polls = snapshot.data ?? [];
          
          if (polls.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.how_to_vote_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No active polls', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade400)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: polls.length,
            itemBuilder: (context, index) {
              final poll = polls[index];
              return _PollCard(poll: poll, userId: user.uid);
            },
          );
        },
      ),
    );
  }
}

class _PollCard extends StatelessWidget {
  final PollModel poll;
  final String userId;

  const _PollCard({required this.poll, required this.userId});

  @override
  Widget build(BuildContext context) {
    final hasVoted = poll.votedUserIds.contains(userId);
    final isClosed = poll.status == PollStatus.closed || poll.isExpired;
    final totalVotes = poll.totalVotes;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  poll.question,
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
              ),
              if (isClosed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('CLOSED', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...poll.options.map((opt) {
            final percentage = totalVotes > 0 ? (opt.votes / totalVotes) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: hasVoted || isClosed
                  ? _buildResultBar(opt, percentage)
                  : _buildVotingOption(context, opt),
            );
          }),
          const SizedBox(height: 8),
          Text(
            '$totalVotes vote${totalVotes == 1 ? "" : "s"} • By ${poll.authorName}',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBar(PollOption opt, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(opt.text, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
            Text('${(percentage * 100).toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: ThemeProvider.accentBlue)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade100,
          color: ThemeProvider.accentBlue,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildVotingOption(BuildContext context, PollOption opt) {
    return InkWell(
      onTap: () async {
        try {
          await Provider.of<CommunityService>(context, listen: false).voteInPoll(
            societyId: poll.societyId,
            pollId: poll.id,
            optionId: opt.id,
            userId: userId,
          );
        } catch (e) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          opt.text,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}
