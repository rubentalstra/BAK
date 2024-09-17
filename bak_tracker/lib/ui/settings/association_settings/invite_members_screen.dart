import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';

// Invite page
class InviteMembersScreen extends StatefulWidget {
  final String associationId;

  const InviteMembersScreen({
    super.key,
    required this.associationId,
  });

  @override
  _InviteMembersScreenState createState() => _InviteMembersScreenState();
}

class _InviteMembersScreenState extends State<InviteMembersScreen> {
  String? _inviteKey;
  bool _isLoading = false;
  List<Map<String, dynamic>> _activeInvites = [];
  List<Map<String, dynamic>> _expiredInvites = [];
  bool _loadingInvites = true;

  @override
  void initState() {
    super.initState();
    _fetchInvites();
  }

  // Generate a random 6-character invite key
  String _generateInviteKey() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  // Create an invite in the Supabase database
  Future<void> _createInvite() async {
    final supabase = Supabase.instance.client;
    final String userId = supabase.auth.currentUser!.id;
    final String inviteKey = _generateInviteKey();

    setState(() {
      _isLoading = true;
    });

    try {
      await supabase.from('invites').insert({
        'association_id': widget.associationId,
        'invite_key': inviteKey,
        'created_by': userId,
        'expires_at': null,
        'is_expired': false,
      });

      setState(() {
        _inviteKey = inviteKey;
      });
      _fetchInvites(); // Refresh the list of invites
    } catch (e) {
      print('Error creating invite: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch active and expired invites
  Future<void> _fetchInvites() async {
    final supabase = Supabase.instance.client;

    try {
      setState(() {
        _loadingInvites = true;
      });

      // Fetch active invites
      final List<Map<String, dynamic>> activeResponse = await supabase
          .from('invites')
          .select()
          .eq('association_id', widget.associationId)
          .eq('is_expired', false);

      // Fetch expired invites
      final List<Map<String, dynamic>> expiredResponse = await supabase
          .from('invites')
          .select()
          .eq('association_id', widget.associationId)
          .eq('is_expired', true);

      setState(() {
        _activeInvites = List<Map<String, dynamic>>.from(activeResponse);
        _expiredInvites = List<Map<String, dynamic>>.from(expiredResponse);
        _loadingInvites = false;
      });
    } catch (e) {
      print('Error fetching invites: $e');
      setState(() {
        _loadingInvites = false;
      });
    }
  }

  // Force expire an invite
  Future<void> _expireInvite(String inviteId) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase
          .from('invites')
          .update({'is_expired': true}).eq('id', inviteId);

      _fetchInvites(); // Refresh the list of invites
    } catch (e) {
      print('Error expiring invite: $e');
    }
  }

  // Share the invite key
  void _shareInvite(String inviteKey) {
    final String shareText =
        'Join our association using this invite key: $inviteKey';
    Share.share(shareText);
  }

  // UI to show active and expired invites
  Widget _buildInviteList(List<Map<String, dynamic>> invites, bool isExpired) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isExpired ? 'Expired Invites' : 'Active Invites',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        invites.isEmpty
            ? Text(isExpired ? 'No expired invites.' : 'No active invites.')
            : Column(
                children: invites.map((invite) {
                  final inviteKey = invite['invite_key'];
                  final inviteId = invite['id'];
                  return ListTile(
                    title: Text('Invite Key: $inviteKey'),
                    subtitle: isExpired
                        ? const Text('Expired')
                        : const Text('Active'),
                    trailing: isExpired
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.timer_off_outlined),
                            onPressed: () {
                              _expireInvite(inviteId);
                            },
                          ),
                  );
                }).toList(),
              ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Members'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _createInvite,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Generate Invite Key'),
            ),
            if (_inviteKey != null) ...[
              const SizedBox(height: 20),
              Text(
                'Invite Key: $_inviteKey',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _shareInvite(_inviteKey!),
                icon: const Icon(Icons.share),
                label: const Text('Share Invite'),
              ),
            ],
            const SizedBox(height: 30),
            _loadingInvites
                ? const CircularProgressIndicator()
                : Expanded(
                    child: ListView(
                      children: [
                        _buildInviteList(_activeInvites, false),
                        _buildInviteList(_expiredInvites, true),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
