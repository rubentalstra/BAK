import 'package:bak_tracker/core/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssociationRequestScreen extends StatefulWidget {
  const AssociationRequestScreen({super.key});

  @override
  _AssociationRequestScreenState createState() =>
      _AssociationRequestScreenState();
}

class _AssociationRequestScreenState extends State<AssociationRequestScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _websiteUrlController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoadingRequests = false;
  List<Map<String, dynamic>> _requests = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _websiteUrlController.dispose();
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  // Handle tab switching
  void _handleTabSelection() {
    if (_tabController.index == 1 && _requests.isEmpty) {
      _fetchRequests();
    }
  }

  // Fetch existing association requests
  Future<void> _fetchRequests() async {
    setState(() {
      _isLoadingRequests = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('association_requests')
          .select()
          .eq('user_id', userId)
          .neq('status', 'Approved')
          .order('created_at', ascending: false);

      setState(() {
        _requests = List<Map<String, dynamic>>.from(response);
        _isLoadingRequests = false;
      });
    } catch (e) {
      _showSnackBar('Error fetching requests: $e');
      setState(() {
        _isLoadingRequests = false;
      });
    }
  }

  // Submit a new request to join an association
  Future<void> _submitRequest() async {
    final name = _nameController.text.trim();
    final websiteUrl = _websiteUrlController.text.trim();
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (name.isEmpty || websiteUrl.isEmpty || userId == null) {
      _showSnackBar('Please fill in all the fields');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await Supabase.instance.client.from('association_requests').insert({
        'user_id': userId,
        'website_url': websiteUrl,
        'name': name,
      });

      _showSnackBar('Request submitted successfully');
      _nameController.clear();
      _websiteUrlController.clear();

      _tabController.animateTo(1); // Switch to the "View Requests" tab
      await _fetchRequests(); // Fetch requests after submitting
    } catch (e) {
      _showSnackBar('Failed to submit request: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Helper to show SnackBar messages
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Association Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Request New'),
            Tab(text: 'View Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestForm(),
          _buildRequestsList(),
        ],
      ),
    );
  }

  // Build the request form UI
  Widget _buildRequestForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Request a New Association',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Association Name',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _websiteUrlController,
            decoration: const InputDecoration(
              labelText: 'Association Website URL',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitRequest,
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  // Build the list of existing requests
  Widget _buildRequestsList() {
    if (_isLoadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_requests.isEmpty) {
      return const Center(
        child: Text(
          'No requests found.\nSubmit a new request or wait for approval.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        final status = request['status'];
        final declineReason = request['decline_reason'];

        return Card(
          child: ListTile(
            title: Text(
              request['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.lightPrimary,
              ),
            ),
            subtitle: Text(
              'Status: $status${status == 'Declined' && declineReason != null ? '\nReason: $declineReason' : ''}',
              style: TextStyle(
                color: status == 'Approved'
                    ? Colors.green
                    : status == 'Declined'
                        ? Colors.red
                        : Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }
}
