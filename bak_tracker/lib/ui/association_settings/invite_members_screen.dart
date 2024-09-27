import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart'; // For date formatting

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

  // Your _createInvite method will accept the expiration date
  Future<void> _createInvite(DateTime? expiryDate) async {
    final supabase = Supabase.instance.client;
    final String userId = supabase.auth.currentUser!.id;
    final String inviteKey = _generateInviteKey();

    try {
      await supabase.from('invites').insert({
        'association_id': widget.associationId,
        'invite_key': inviteKey,
        'created_by': userId,
        'expires_at':
            expiryDate?.toIso8601String(), // Add expiration date if available
        'is_expired': false,
      });

      _fetchInvites(); // Refresh the list of invites
    } catch (e) {
      print('Error creating invite: $e');
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
        'Join our association using this invite key: $inviteKey.\n'
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
    return invites.isEmpty
        ? Center(
            child: Text(
              isExpired ? 'No expired invites.' : 'No active invites.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
        : ListView.separated(
            itemCount: invites.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final invite = invites[index];
              final inviteKey = invite['invite_key'];
              final inviteId = invite['id'];

              return ListTile(
                title: Text(
                  'Invite Key: $inviteKey',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  isExpired ? 'Expired' : 'Active',
                  style: TextStyle(
                      color: isExpired ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w600),
                ),
                trailing: isExpired
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.copy),
                            onPressed: () => _copyInviteKey(inviteKey),
                            tooltip: 'Copy Invite Key',
                          ),
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.share),
                            onPressed: () => _shareInvite(inviteKey),
                            tooltip: 'Share Invite',
                          ),
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.xmark),
                            onPressed: () => _expireInvite(inviteId),
                            tooltip: 'Expire Invite',
                          ),
                        ],
                      ),
              );
            },
          );
  }

  // Date picker for selecting expiration date
  Future<DateTime?> _selectExpiryDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    return pickedDate; // Return the picked date directly
  }

// Dialog for creating an invite with expiration date
  Future<void> _showCreateInviteDialog() async {
    DateTime? selectedExpiryDate;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create Invite'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Would you like to set an expiration date?'),
                  const SizedBox(height: 10),
                  selectedExpiryDate != null
                      ? Text(
                          'Expiry Date: ${DateFormat('dd-MM-yyyy').format(selectedExpiryDate!)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : const Text('No expiry date set.'),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Set Expiry Date'),
                    onPressed: () async {
                      final pickedDate = await _selectExpiryDate(context);
                      if (pickedDate != null) {
                        setState(() {
                          selectedExpiryDate = pickedDate;
                        });
                      }
                    },
                  ),
                  if (selectedExpiryDate !=
                      null) // Option to remove expiry date
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedExpiryDate = null;
                        });
                      },
                      child: const Text(
                        'Remove Expiration Date',
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Create Invite'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Use selectedExpiryDate to create the invite with or without an expiry date
                    _createInvite(selectedExpiryDate);
                  },
                ),
              ],
            );
          },
        );
      },
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
        onPressed: _isLoading ? null : _showCreateInviteDialog,
        tooltip: 'Generate Invite',
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const FaIcon(FontAwesomeIcons.plus),
      ),
    );
  }
}
