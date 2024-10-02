import 'dart:io';
import 'dart:math';
import 'package:bak_tracker/models/invite_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'active_invites_tab.dart';
import 'expired_invites_tab.dart';
import 'package:bak_tracker/core/const/permissions_constants.dart';

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
  List<InviteModel> _activeInvites = [];
  List<InviteModel> _expiredInvites = [];
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

  // Create an invite with expiration date and permissions
  Future<void> _createInvite(
      DateTime? expiryDate, PermissionsModel permissions) async {
    final supabase = Supabase.instance.client;
    final String inviteKey = _generateInviteKey();

    try {
      await supabase.from('invites').insert({
        'association_id': widget.associationId,
        'invite_key': inviteKey,
        'expires_at': expiryDate?.toIso8601String(),
        'is_expired': false,
        'permissions': permissions.toMap(),
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
      final List<dynamic> activeResponse = await supabase
          .from('invites')
          .select()
          .eq('association_id', widget.associationId)
          .eq('is_expired', false);

      // Fetch expired invites
      final List<dynamic> expiredResponse = await supabase
          .from('invites')
          .select()
          .eq('association_id', widget.associationId)
          .eq('is_expired', true)
          .order('created_at', ascending: false);

      setState(() {
        // Convert response to InviteModel instances
        _activeInvites = activeResponse
            .map((inviteMap) => InviteModel.fromMap(inviteMap))
            .toList();
        _expiredInvites = expiredResponse
            .map((inviteMap) => InviteModel.fromMap(inviteMap))
            .toList();
        _loadingInvites = false;
      });
    } catch (e) {
      print('Error fetching invites: $e');
      setState(() {
        _loadingInvites = false;
      });
    }
  }

  // Delete an invite
  Future<void> _deleteInvite(String inviteId) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.from('invites').delete().eq('id', inviteId);

      _fetchInvites(); // Refresh the list after deleting
    } catch (e) {
      print('Error deleting invite: $e');
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

  // Date picker for selecting expiration date
  Future<DateTime?> _selectExpiryDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate =
        now.add(const Duration(seconds: 1)); // Add a small margin

    DateTime selectedDate = initialDate;

    if (Platform.isIOS) {
      return await showModalBottomSheet<DateTime>(
        context: context,
        backgroundColor: Colors.black, // Set background color
        isScrollControlled: true, // Allows full-height modal bottom sheet
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return SizedBox(
            height: 300,
            child: Column(
              children: [
                // The toolbar with Cancel and Done buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        Navigator.pop(
                            context); // Close the picker without selecting a date
                      },
                    ),
                    CupertinoButton(
                      child: const Text('Done',
                          style: TextStyle(color: Colors.blue)),
                      onPressed: () {
                        selectedDate = DateTime(selectedDate.year,
                            selectedDate.month, selectedDate.day, 23, 59, 59);
                        Navigator.pop(
                            context, selectedDate); // Return the selected date
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 180,
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(
                      brightness: Brightness.dark, // Light appearance
                      primaryColor: Colors.blue,
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: selectedDate,
                      minimumDate: now,
                      maximumDate: now.add(const Duration(days: 365)),
                      onDateTimeChanged: (DateTime dateTime) {
                        selectedDate = DateTime(dateTime.year, dateTime.month,
                            dateTime.day, 23, 59, 59);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)),
      );

      return pickedDate != null
          ? DateTime(
              pickedDate.year, pickedDate.month, pickedDate.day, 23, 59, 59)
          : null;
    }
  }

  // Show a dialog to select permissions and create invite
  Future<void> _showCreateInviteDialog() async {
    DateTime? selectedExpiryDate;
    PermissionsModel permissions = PermissionsModel();

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
                  if (selectedExpiryDate != null)
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
                  const Divider(),
                  const Text('Assign Permissions for this Invite:'),
                  ...PermissionEnum.values.map((permission) {
                    return CheckboxListTile(
                      title: Text(permission.toString().split('.').last),
                      value: permissions.permissions[permission],
                      onChanged: (bool? value) {
                        setState(() {
                          permissions.updatePermission(
                              permission, value ?? false);
                        });
                      },
                    );
                  }).toList(),
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
                    // Check if permissions are assigned
                    bool hasPermissions =
                        permissions.permissions.values.any((v) => v);

                    // Create invite if no permissions are set or if an expiration date is set
                    if (!hasPermissions || selectedExpiryDate != null) {
                      Navigator.of(context).pop(); // Close the dialog
                      _createInvite(
                          selectedExpiryDate, permissions); // Create the invite
                    } else {
                      // Show a SnackBar if permissions are set but no expiration date is provided
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please set an expiration date when assigning permissions.',
                          ),
                        ),
                      );
                    }
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0), // Reduced padding
                  child: ActiveInvitesTab(
                    invites: _activeInvites,
                    onCopyInviteKey: _copyInviteKey,
                    onShareInvite: _shareInvite,
                    onExpireInvite: _expireInvite,
                  ),
                ),
          _loadingInvites
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0), // Reduced padding
                  child: ExpiredInvitesTab(
                    invites: _expiredInvites,
                    onDeleteInvite: _deleteInvite, // Handle delete action
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateInviteDialog,
        tooltip: 'Generate Invite',
        child: const FaIcon(FontAwesomeIcons.plus),
      ),
    );
  }
}
