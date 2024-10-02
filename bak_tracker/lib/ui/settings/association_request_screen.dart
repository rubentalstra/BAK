import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // For date formatting and localization

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
  bool _isLoadingRequests = true; // Start with loading true
  bool _canSubmitRequest = true;
  List<Map<String, dynamic>> _requests = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _preloadRequests(); // Preload requests during initialization
    _checkSubmissionEligibility(); // Check if the user can submit a request
  }

  @override
  void dispose() {
    _nameController.dispose();
    _websiteUrlController.dispose();
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.index == 1 && _requests.isEmpty) {
      _fetchRequests();
    }
  }

  // Preload the request data on initialization for better UX
  Future<void> _preloadRequests() async {
    await _fetchRequests();
  }

  Future<void> _checkSubmissionEligibility() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Fetch the user's pending requests
      final existingRequests = await Supabase.instance.client
          .from('association_requests')
          .select()
          .eq('user_id', userId)
          .eq('status', 'Pending')
          .order('created_at', ascending: false);

      final pendingRequests = List<Map<String, dynamic>>.from(existingRequests);

      // Check if the user has more than 3 pending requests
      if (pendingRequests.length >= 3) {
        setState(() {
          _canSubmitRequest = false;
        });
        return;
      }

      // Check if the last request was made within the last week
      if (pendingRequests.isNotEmpty) {
        final lastRequestDate =
            DateTime.parse(pendingRequests.first['created_at']);
        final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

        if (lastRequestDate.isAfter(oneWeekAgo)) {
          setState(() {
            _canSubmitRequest = false;
          });
          return;
        }
      }

      setState(() {
        _canSubmitRequest = true;
      });
    } catch (e) {
      _showSnackBar('Error checking request eligibility: $e');
    }
  }

  Future<void> _fetchRequests() async {
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
        _isLoadingRequests = false; // Stop loading once data is fetched
      });
    } catch (e) {
      _showSnackBar('Error fetching requests: $e');
      setState(() {
        _isLoadingRequests = false;
      });
    }
  }

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

      _tabController.animateTo(1); // Switch to "View Requests" tab
      await _fetchRequests(); // Fetch requests after submission
      _checkSubmissionEligibility(); // Re-check eligibility after submission
    } catch (e) {
      _showSnackBar('Failed to submit request: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _deleteRequest(String requestId) async {
    setState(() {
      _isLoadingRequests = true;
    });

    try {
      await Supabase.instance.client
          .from('association_requests')
          .delete()
          .eq('id', requestId);

      _showSnackBar('Request deleted successfully');
      await _fetchRequests(); // Refresh the list after deletion
      _checkSubmissionEligibility(); // Re-check eligibility after deletion
    } catch (e) {
      _showSnackBar('Failed to delete request: $e');
    } finally {
      setState(() {
        _isLoadingRequests = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final localDate = date.toLocal(); // Convert to local timezone

    final locale = Intl.getCurrentLocale();

    return DateFormat.Hm(locale).add_yMd().format(localDate);
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

  Widget _buildRequestForm() {
    if (_isLoadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_canSubmitRequest) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'You cannot submit more requests at this time.\nEither you have 3 pending requests or you submitted a request in the past week.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

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
          _buildTextField(
            controller: _nameController,
            labelText: 'Association Name',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _websiteUrlController,
            labelText: 'Association Website URL',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildRequestsList() {
    if (_isLoadingRequests) {
      // Show a centered loading spinner instead of a loading ListView
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
        final requestId = request['id'];
        final createdAt = request['created_at'];

        return Card(
          child: ListTile(
            title: Text(
              request['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Status: $status\nSubmitted: ${_formatDate(createdAt)}${status == 'Declined' && declineReason != null ? '\nReason: $declineReason' : ''}',
              style: TextStyle(
                color: status == 'Approved'
                    ? Colors.green
                    : status == 'Declined'
                        ? Colors.red
                        : Colors.grey,
              ),
            ),
            trailing: status == 'Pending'
                ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteRequest(requestId),
                  )
                : null,
          ),
        );
      },
    );
  }
}
