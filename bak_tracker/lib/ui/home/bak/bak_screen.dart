import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/models/association_model.dart';

class BakScreen extends StatefulWidget {
  const BakScreen({super.key});

  @override
  _BakScreenState createState() => _BakScreenState();
}

class _BakScreenState extends State<BakScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _users = [];
  List<AssociationModel> _associations = [];
  String? _selectedReceiverId;
  String? _selectedAssociation;
  final _amountController = TextEditingController();

  late TabController _tabController;

  List<Map<String, dynamic>> _sentBakken = [];
  List<Map<String, dynamic>> _receivedBakken = [];
  List<Map<String, dynamic>> _receivedBakkenTransaction = [];
  bool _isLoadingSent = false;
  bool _isLoadingReceived = false;
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAssociations();

    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _fetchReceivedBakken(); // Fetch received bakken when this tab is selected
      } else if (_tabController.index == 2) {
        _fetchSentBakken(); // Fetch sent bakken (transactions) when this tab is selected
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Fetches the associations the user is part of.
  Future<void> _fetchAssociations() async {
    setState(() {
      _isLoadingSent = true;
      _isLoadingReceived = true;
    });

    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser!.id;

    // Fetch associations the user belongs to
    final List<dynamic> associationResponse = await supabase
        .from('association_members')
        .select('association_id, associations (id, name)')
        .eq('user_id', currentUserId);

    setState(() {
      _associations = associationResponse.map<AssociationModel>((data) {
        final association = data['associations'] as Map<String, dynamic>;
        return AssociationModel(
          id: association['id'],
          name: association['name'],
        );
      }).toList();

      if (_associations.length == 1) {
        // If the user is part of one association, select it automatically
        _selectedAssociation = _associations.first.id;
        _fetchUsers(); // Fetch users for the selected association
      } else {
        // If the user is part of more than one association, they need to select
        _selectedAssociation = null;
        _users
            .clear(); // Clear the list of users until an association is selected
      }
      _isLoadingSent = false;
      _isLoadingReceived = false;
    });
  }

  /// Fetches the users for the selected association.
  Future<void> _fetchUsers() async {
    if (_selectedAssociation == null) return;

    setState(() {
      _isLoadingUsers = true;
    });

    final supabase = Supabase.instance.client;
    final List<dynamic> userResponse = await supabase
        .from('association_members')
        .select('user_id (id, name)')
        .eq('association_id', _selectedAssociation!);

    setState(() {
      _users = userResponse.map((data) {
        final userMap = data['user_id'] as Map<String, dynamic>;
        return {
          'id': userMap['id'],
          'name': userMap['name'],
        };
      }).toList();
      _selectedReceiverId = _users.isNotEmpty ? _users.first['id'] : null;
      _isLoadingUsers = false;
    });
  }

  Future<void> sendBak({
    required String receiverId,
    required String associationId,
    required int amount,
    String? boardYearId,
  }) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    try {
      await supabase.from('bak_send').insert({
        'giver_id': userId,
        'receiver_id': receiverId,
        'association_id': associationId,
        'board_year_id': boardYearId,
        'amount': amount,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow; // Optional: Re-throw the error if needed for further handling
    }
  }

  Future<void> _fetchSentBakken() async {
    setState(() {
      _isLoadingSent = true;
    });

    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser!.id;

    final response = await supabase
        .from('bak_send')
        .select(
            'id, amount, status, created_at, receiver_id (id, name), giver_id (id, name)')
        .eq('giver_id', currentUserId)
        .order('created_at', ascending: false);

    final List<dynamic> receivedResponse = await supabase
        .from('bak_send')
        .select(
            'id, amount, status, created_at, receiver_id (id, name), giver_id (id, name)')
        .eq('receiver_id', currentUserId)
        .neq('status', 'pending') // Exclude pending baks
        .order('created_at', ascending: false);

    setState(() {
      _sentBakken = List<Map<String, dynamic>>.from(response);
      _receivedBakkenTransaction =
          List<Map<String, dynamic>>.from(receivedResponse);
      _isLoadingSent = false;
    });
  }

  Future<void> _fetchReceivedBakken() async {
    setState(() {
      _isLoadingReceived = true;
    });

    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('bak_send')
        .select(
            'id, amount, status, created_at, receiver_id (id, name), giver_id (id, name)')
        .eq('receiver_id', Supabase.instance.client.auth.currentUser!.id)
        .eq('status', 'pending') // Only fetch 'pending' baks
        .order('created_at', ascending: false);

    setState(() {
      _receivedBakken = List<Map<String, dynamic>>.from(response);
      _isLoadingReceived = false;
    });
  }

  // Approve Bak
  Future<void> approveBak(
      String bakId, String receiverId, String giverId) async {
    final supabase = Supabase.instance.client;

    try {
      // Update the bak_send table to mark the bak as approved
      await supabase
          .from('bak_send')
          .update({'status': 'approved'}).eq('id', bakId);

      // Get the current baks_received value for the receiver
      final receiverResponse = await supabase
          .from('association_members')
          .select('baks_received')
          .eq('user_id', receiverId)
          .single();

      if (receiverResponse['baks_received'] != null) {
        // Increment the baks_received value
        final updatedBaksReceived = receiverResponse['baks_received'] + 1;

        // Update the baks_received for the receiver
        await supabase.from('association_members').update({
          'baks_received': updatedBaksReceived,
        }).eq('user_id', receiverId);
      }

      // Refresh the data
      _fetchReceivedBakken();
      _fetchSentBakken();
    } catch (e) {
      print('Error approving bak: $e');
    }
  }

// Decline Bak
  Future<void> declineBak(String bakId, String giverId) async {
    final supabase = Supabase.instance.client;

    try {
      // Update the bak_send table to mark the bak as declined
      await supabase
          .from('bak_send')
          .update({'status': 'declined'}).eq('id', bakId);

      // Get the current baks_consumed value for the giver
      final giverResponse = await supabase
          .from('association_members')
          .select('baks_consumed')
          .eq('user_id', giverId)
          .single();

      if (giverResponse['baks_consumed'] != null) {
        // Increment the baks_consumed value
        final updatedBaksConsumed = giverResponse['baks_consumed'] + 1;

        // Update the baks_consumed for the giver
        await supabase.from('association_members').update({
          'baks_consumed': updatedBaksConsumed,
        }).eq('user_id', giverId);
      }

      // Refresh the data
      _fetchReceivedBakken();
      _fetchSentBakken();
    } catch (e) {
      print('Error declining bak: $e');
    }
  }

  Widget _buildSendBakTab(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Dismiss the keyboard
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_associations.length > 1) ...[
              Text(
                'Select Association',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8.0),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButton<String>(
                    value: _selectedAssociation,
                    hint: const Text('Choose an Association'),
                    onChanged: (value) {
                      setState(() {
                        _selectedAssociation = value;
                        _fetchUsers(); // Fetch users when the association changes
                      });
                    },
                    items: _associations.map((association) {
                      return DropdownMenuItem<String>(
                        value: association.id,
                        child: Text(association.name),
                      );
                    }).toList(),
                    isExpanded: true,
                    underline: Container(),
                    dropdownColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
            ],
            if (_selectedAssociation != null || _associations.length == 1) ...[
              Text(
                'Select Receiver',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8.0),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButton<String>(
                    value: _selectedReceiverId,
                    hint: const Text('Choose a Receiver'),
                    onChanged: (value) {
                      setState(() {
                        _selectedReceiverId = value;
                      });
                    },
                    items: _users.map((user) {
                      return DropdownMenuItem<String>(
                        value: user['id'],
                        child: Text(user['name']),
                      );
                    }).toList(),
                    isExpanded: true,
                    underline: Container(),
                    dropdownColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
            ],
            if (!_isLoadingUsers) ...[
              Text(
                'Amount',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8.0),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: 'Enter amount',
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              Align(
                alignment:
                    isSmallScreen ? Alignment.center : Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_selectedReceiverId == null ||
                        _selectedAssociation == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Please select both an association and a receiver.')),
                      );
                      return;
                    }
                    try {
                      await sendBak(
                        receiverId: _selectedReceiverId!,
                        associationId: _selectedAssociation!,
                        amount: int.parse(_amountController.text),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Bak sent successfully!'),
                        backgroundColor: Colors.green,
                      ));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error sending bak: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 12.0),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.send),
                  label: const Text('Send Bak'),
                ),
              ),
            ] else ...[
              const Center(child: CircularProgressIndicator())
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedBakTab() {
    return _isLoadingReceived
        ? const Center(child: CircularProgressIndicator())
        : _receivedBakken.isEmpty
            ? const Center(child: Text('No pending baks found.'))
            : ListView.builder(
                itemCount: _receivedBakken.length,
                itemBuilder: (context, index) {
                  final bak = _receivedBakken[index];
                  final date = DateTime.parse(bak['created_at']).toLocal();
                  final formattedDate =
                      '${date.day}/${date.month}/${date.year}';

                  return ListTile(
                    title: Text('Received from: ${bak['giver_id']['name']}'),
                    subtitle:
                        Text('Amount: ${bak['amount']} | Date: $formattedDate'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => approveBak(bak['id'],
                              bak['receiver_id']['id'], bak['giver_id']['id']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () =>
                              declineBak(bak['id'], bak['giver_id']['id']),
                        ),
                      ],
                    ),
                  );
                },
              );
  }

  Widget _buildTransactionsBakTab() {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;

    // Combine sent and received baks into a single list for transactions
    List<Map<String, dynamic>> transactions = [
      ..._sentBakken,
      ..._receivedBakkenTransaction
    ];
    transactions.sort((a, b) => DateTime.parse(b['created_at'])
        .compareTo(DateTime.parse(a['created_at']))); // Sort by newest first

    return _isLoadingSent || _isLoadingReceived
        ? const Center(child: CircularProgressIndicator())
        : transactions.isEmpty
            ? const Center(child: Text('No transactions found.'))
            : ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final bak = transactions[index];
                  final date = DateTime.parse(bak['created_at']).toLocal();
                  final formattedDate =
                      '${date.day}/${date.month}/${date.year}';

                  final isSent = bak['giver_id']['id'] == currentUserId;

                  return ListTile(
                    title: Text(
                      isSent
                          ? 'Sent to: ${bak['receiver_id']['name']}'
                          : 'Received from: ${bak['giver_id']['name']}',
                    ),
                    subtitle:
                        Text('Amount: ${bak['amount']} | Date: $formattedDate'),
                    trailing: Text('Status: ${bak['status']}'),
                  );
                },
              );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bak'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Send Bak'),
            Tab(text: 'Received Bak'),
            Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendBakTab(context),
          _buildReceivedBakTab(),
          _buildTransactionsBakTab(),
        ],
      ),
    );
  }
}
