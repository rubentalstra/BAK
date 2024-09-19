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

  // Handle tab switching logic
  void _handleTabSelection() {
    if (_tabController.index == 1 && _requests.isEmpty) {
      _fetchRequests(); // Fetch requests only when the "View Requests" tab is selected
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
      print('Error fetching requests: $e');
      setState(() {
        _isLoadingRequests = false;
      });
    }
  }

  // Submit a new request to join an association
  Future<void> _submitRequest() async {
    final name = _nameController.text;
    final websiteUrl = _websiteUrlController.text;
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (name.isEmpty || websiteUrl.isEmpty || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all fields')),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted successfully')),
      );

      _nameController.clear();
      _websiteUrlController.clear();

      _tabController.animateTo(1); // Switch to the "View Requests" tab
      _fetchRequests(); // Fetch requests after submitting
    } catch (e) {
      print('Error submitting request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit request: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
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
          // Tab 1: Submit New Association Request
          Padding(
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
          ),

          // Tab 2: View Existing Requests
          _isLoadingRequests
              ? const Center(child: CircularProgressIndicator())
              : _requests.isEmpty
                  ? const Center(child: Text('No requests found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final request = _requests[index];
                        final status = request['status'];
                        final declineReason = request['decline_reason'];

                        return Card(
                          child: ListTile(
                            title: Text(request['name']),
                            subtitle: Text(
                              'Status: $status${status == 'Declined' && declineReason != null ? '\nReason: $declineReason' : ''}',
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
