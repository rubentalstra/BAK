import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/models/association_model.dart';

class SendBakScreen extends StatefulWidget {
  @override
  _SendBakScreenState createState() => _SendBakScreenState();
}

class _SendBakScreenState extends State<SendBakScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _users = [];
  List<AssociationModel> _associations = [];
  String? _selectedReceiverId;
  String? _selectedAssociation;
  final _amountController = TextEditingController();

  late TabController _tabController;

  List<Map<String, dynamic>> _sentBakken = [];
  List<Map<String, dynamic>> _receivedBakken = [];
  bool _isLoadingSent = false;
  bool _isLoadingReceived = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();

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

  Future<void> _fetchData() async {
    setState(() {
      _isLoadingSent = true;
      _isLoadingReceived = true;
    });

    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser!.id;

    // Fetch both sent and received baks
    final List<dynamic> sentResponse = await supabase
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
      _sentBakken = List<Map<String, dynamic>>.from(sentResponse);
      _receivedBakken = List<Map<String, dynamic>>.from(receivedResponse);
      _isLoadingSent = false;
      _isLoadingReceived = false;
    });
  }

  Future<void> _fetchUsers() async {
    if (_selectedAssociation == null) return;

    // Fetch users based on the selected association
    final List<dynamic> userResponse = await Supabase.instance.client
        .from('association_members')
        .select('user_id (id, name)')
        .eq('association_id', _selectedAssociation!);

    if (userResponse.isNotEmpty) {
      setState(() {
        _users = userResponse.map((data) {
          final userMap = data['user_id'] as Map<String, dynamic>;
          return {
            'id': userMap['id'],
            'name': userMap['name'],
          };
        }).toList();
        _selectedReceiverId = _users.isNotEmpty ? _users.first['id'] : null;
      });
    }
  }

  Future<void> sendBak({
    required String receiverId,
    required String associationId,
    required int amount,
    String? boardYearId,
  }) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.from('bak_send').insert({
        'giver_id': Supabase.instance.client.auth.currentUser!.id,
        'receiver_id': receiverId,
        'association_id': associationId,
        'board_year_id': boardYearId,
        'amount': amount,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _fetchSentBakken() async {
    setState(() {
      _isLoadingSent = true;
    });

    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('bak_send')
        .select(
            'id, amount, status, created_at, receiver_id (id, name), giver_id (id, name)')
        .eq('giver_id', Supabase.instance.client.auth.currentUser!.id)
        .order('created_at', ascending: false);

    setState(() {
      _sentBakken = List<Map<String, dynamic>>.from(response);
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

      if (giverResponse != null && giverResponse['baks_consumed'] != null) {
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
          _buildSentBakTab(),
        ],
      ),
    );
  }

  Widget _buildSendBakTab(BuildContext context) {
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
                      color: Colors.deepPurple,
                    ),
              ),
              const SizedBox(height: 8.0),
              DropdownButton<String>(
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
                underline: Container(
                  height: 2,
                  color: Colors.deepPurpleAccent,
                ),
              ),
              const SizedBox(height: 16.0),
            ],
            Text(
              'Select Receiver',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
            ),
            const SizedBox(height: 8.0),
            DropdownButton<String>(
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
              underline: Container(
                height: 2,
                color: Colors.deepPurpleAccent,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Amount',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurpleAccent),
                ),
                labelText: 'Enter amount',
                labelStyle: const TextStyle(color: Colors.deepPurple),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () async {
                try {
                  await sendBak(
                    receiverId: _selectedReceiverId!,
                    associationId: _selectedAssociation!,
                    amount: int.parse(_amountController.text),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bak sent successfully!')));
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              style: ElevatedButton.styleFrom(
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Send Bak',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentBakTab() {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;

    // Combine sent and received baks into a single list for transactions
    List<Map<String, dynamic>> transactions = [
      ..._sentBakken,
      ..._receivedBakken
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

  Widget _buildReceivedBakTab() {
    return _isLoadingReceived
        ? const Center(child: CircularProgressIndicator())
        : _receivedBakken.isEmpty
            ? const Center(child: Text('No received baks found.'))
            : ListView.builder(
                itemCount: _receivedBakken.length,
                itemBuilder: (context, index) {
                  final bak = _receivedBakken[index];
                  final bakStatus = bak['status']; // Get the current status
                  final date = DateTime.parse(bak['created_at']).toLocal();
                  final formattedDate =
                      '${date.day}/${date.month}/${date.year}';

                  return ListTile(
                    title: Text('Received from: ${bak['giver_id']['name']}'),
                    subtitle:
                        Text('Amount: ${bak['amount']} | Date: $formattedDate'),
                    trailing: bakStatus == 'pending'
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () => approveBak(
                                    bak['id'],
                                    bak['receiver_id']['id'],
                                    bak['giver_id']['id']),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () => declineBak(
                                    bak['id'], bak['giver_id']['id']),
                              ),
                            ],
                          )
                        : Text(bakStatus == 'approved'
                            ? 'Approved'
                            : 'Declined'), // Display status if already processed
                  );
                },
              );
  }
}
