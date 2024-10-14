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
  bool _isSubmitting = false;
  bool _isLoadingRequests = true;
  bool _canSubmitRequest = true;
  List<AssociationRequestModel> _requests = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _preloadRequests();
    _checkSubmissionEligibility();
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

  Future<void> _preloadRequests() async {
    await _fetchRequests();
  }

  Future<void> _checkSubmissionEligibility() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final existingRequests = await Supabase.instance.client
          .from('association_requests')
          .select()
          .eq('user_id', userId)
          .eq('status', 'Pending')
          .order('created_at', ascending: false);

      final pendingRequests = existingRequests
          .map<AssociationRequestModel>(
              (data) => AssociationRequestModel.fromMap(data))
          .toList();

      if (pendingRequests.length >= 3) {
        setState(() {
          _canSubmitRequest = false;
        });
        return;
      }

      final lastRequestDate = pendingRequests.firstOrNull?.createdAt;
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

      if (lastRequestDate != null && lastRequestDate.isAfter(oneWeekAgo)) {
        setState(() {
          _canSubmitRequest = false;
        });
        return;
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
        _requests = List<AssociationRequestModel>.from(
            response.map((data) => AssociationRequestModel.fromMap(data)));
        _isLoadingRequests = false;
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
      _tabController.animateTo(1);
      await _fetchRequests();
      _checkSubmissionEligibility();
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
      await _fetchRequests();
      _checkSubmissionEligibility();
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
            'You cannot submit more requests at this time.\nYou have 3 pending requests or you submitted a request in the past week.',
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_requests.isEmpty) {
      return const Center(
        child: Text(
          'No requests found. Submit a new request or wait for approval.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return Card(
          child: ListTile(
            title: Text(
              request.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Status: ${request.status}\nSubmitted: ${_formatDate(request.createdAt)}${request.status == 'Declined' && request.declineReason != null ? '\nReason: ${request.declineReason}' : ''}',
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
