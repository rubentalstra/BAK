import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart'; // For copying text to the clipboard
import 'dart:math';

class InviteMembersScreen extends StatefulWidget {
  final String associationId;

  const InviteMembersScreen({
    super.key,
    required this.associationId,
  });

  @override
  _InviteMembersScreenState createState() => _InviteMembersScreenState();
}

class _InviteMembersScreenState extends State<InviteMembersScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  List<Map<String, dynamic>> _activeInvites = [];
  List<Map<String, dynamic>> _expiredInvites = [];
  bool _loadingInvites = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchInvites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

      setState(() {});
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

  // Share the invite key with a deep link
  void _shareInvite(String inviteKey) {
    final String deepLink = 'https://baktracker.com/invite/$inviteKey';
    final String shareText =
        'Join our association using this invite key: $inviteKey. '
        'Click here to join: $deepLink';
    Share.share(shareText);
  }

  // Copy invite key to clipboard
  void _copyInviteKey(String inviteKey) {
    Clipboard.setData(ClipboardData(text: inviteKey));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite key copied to clipboard!')),
    );
  }

  // UI to show active and expired invites
  Widget _buildInviteList(List<Map<String, dynamic>> invites, bool isExpired) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  _copyInviteKey(inviteKey);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.share),
                                onPressed: () {
                                  _shareInvite(inviteKey);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.timer_off_outlined),
                                onPressed: () {
                                  _expireInvite(inviteId);
                                },
                              ),
                            ],
                          ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Members'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active Invites'),
            Tab(text: 'Expired Invites'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _loadingInvites
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildInviteList(_activeInvites, false),
                ),
          _loadingInvites
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildInviteList(_expiredInvites, true),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _createInvite,
        tooltip: 'Generate Invite',
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.add),
      ),
    );
  }
}
