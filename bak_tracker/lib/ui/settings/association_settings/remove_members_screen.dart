import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RemoveMembersScreen extends StatefulWidget {
  final String associationId;

  const RemoveMembersScreen({super.key, required this.associationId});

  @override
  _RemoveMembersScreenState createState() => _RemoveMembersScreenState();
}

class _RemoveMembersScreenState extends State<RemoveMembersScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  String? _currentUserId; // To store the logged-in user's ID

  @override
  void initState() {
    super.initState();
    _fetchMembers();
    _getCurrentUserId(); // Get the current user's ID when the screen loads
  }

  // Fetch the logged-in user's ID
  Future<void> _getCurrentUserId() async {
    final supabase = Supabase.instance.client;
    setState(() {
      _currentUserId = supabase.auth.currentUser?.id;
    });
  }

  // Fetch association members from Supabase
  Future<void> _fetchMembers() async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('association_members')
          .select('user_id (id, name)')
          .eq('association_id', widget.associationId);

      setState(() {
        _members = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching members: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Remove a member from the association
  Future<void> _removeMember(String userId) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase
          .from('association_members')
          .delete()
          .eq('user_id', userId)
          .eq('association_id', widget.associationId);
      _fetchMembers(); // Refresh the member list
    } catch (e) {
      print('Error removing member: $e');
    }
  }

  // Show confirmation dialog
  Future<void> _confirmRemoveMember(
      BuildContext context, String userId, String memberName) async {
    final bool? shouldRemove = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Removal'),
          content: Text('Are you sure you want to remove $memberName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (shouldRemove == true) {
      // If confirmed, remove the member
      _removeMember(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remove Members'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                final memberId = member['user_id']['id'];
                final memberName = member['user_id']['name'];

                return ListTile(
                  title: Text(memberName),
                  trailing: memberId == _currentUserId
                      ? const IconButton(
                          icon: Icon(
                            Icons.block,
                            color: Colors.grey,
                          ),
                          onPressed: null, // Current user cannot be removed
                        )
                      : IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _confirmRemoveMember(
                              context, memberId, memberName),
                        ),
                );
              },
            ),
    );
  }
}
