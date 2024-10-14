import 'package:bak_tracker/models/association_request_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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
  late TabController _tabController;

  // Store futures to trigger re-fetching of data
  late Future<List<AssociationRequestModel>> _requestsFuture;
  late Future<bool> _canSubmitRequestFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _requestsFuture = _fetchRequests();
    _canSubmitRequestFuture = _canSubmitRequest();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _websiteUrlController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<List<AssociationRequestModel>> _fetchRequests() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await Supabase.instance.client
        .from('association_requests')
        .select()
        .eq('user_id', userId)
        .neq('status', 'Approved')
        .order('created_at', ascending: false);

    return List<AssociationRequestModel>.from(
        response.map((data) => AssociationRequestModel.fromMap(data)));
  }

  Future<bool> _canSubmitRequest() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return false;

      final existingRequests = await Supabase.instance.client
          .from('association_requests')
          .select()
          .eq('user_id', userId)
          .eq('status', 'Pending')
          .order('created_at', ascending: false);

      final pendingRequests = List<AssociationRequestModel>.from(
          existingRequests
              .map((data) => AssociationRequestModel.fromMap(data)));

      final lastRequestDate =
          pendingRequests.isNotEmpty ? pendingRequests.first.createdAt : null;
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

      return pendingRequests.length < 3 &&
          (lastRequestDate == null || !lastRequestDate.isAfter(oneWeekAgo));
    } catch (e) {
      _showSnackBar('Error checking request eligibility: $e');
      return false;
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

    try {
      await Supabase.instance.client.from('association_requests').insert({
        'user_id': userId,
        'website_url': websiteUrl,
        'name': name,
      });

      _showSnackBar('Request submitted successfully');
      _nameController.clear();
      _websiteUrlController.clear();
      _tabController
          .animateTo(1); // Switch to the requests tab after submission

      // Refresh both the requests and the submission eligibility future
      setState(() {
        _requestsFuture = _fetchRequests();
        _canSubmitRequestFuture = _canSubmitRequest();
      });
    } catch (e) {
      _showSnackBar('Failed to submit request: $e');
    }
  }

  Future<void> _deleteRequest(String requestId) async {
    try {
      await Supabase.instance.client
          .from('association_requests')
          .delete()
          .eq('id', requestId);

      _showSnackBar('Request deleted successfully');

      // Refresh both the requests and the submission eligibility future
      setState(() {
        _requestsFuture = _fetchRequests();
        _canSubmitRequestFuture = _canSubmitRequest();
      });
    } catch (e) {
      _showSnackBar('Failed to delete request: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    return DateFormat('HH:mm dd-MM-yyyy').format(localDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Association Requests'),
        bottom: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Request New'),
            Tab(text: 'View Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FutureBuilder<bool>(
            future: _canSubmitRequestFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error.toString()}'));
              } else if (snapshot.data == false) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'You cannot submit more requests at this time.\n'
                      'You have 3 pending requests or you submitted a request in the past week.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              } else {
                return _buildRequestForm();
              }
            },
          ),
          FutureBuilder<List<AssociationRequestModel>>(
            future: _requestsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error.toString()}'));
              } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No requests found. Submit a new request or wait for approval.',
                    textAlign: TextAlign.center,
                  ),
                );
              } else {
                return _buildRequestsList(snapshot.data!);
              }
            },
          ),
        ],
      ),
    );
  }

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
            onPressed: _submitRequest,
            child: const Text('Submit Request'),
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

  Widget _buildRequestsList(List<AssociationRequestModel> requests) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Card(
          child: ListTile(
            title: Text(
              request.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Status: ${request.status}\n'
              'Submitted: ${_formatDate(request.createdAt)}${request.status == 'Declined' && request.declineReason != null ? '\nReason: ${request.declineReason}' : ''}',
              style: TextStyle(
                color: request.status == 'Approved'
                    ? Colors.green
                    : request.status == 'Declined'
                        ? Colors.red
                        : Colors.grey,
              ),
            ),
            trailing: request.status == 'Pending'
                ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteRequest(request.id),
                  )
                : null,
          ),
        );
      },
    );
  }
}
