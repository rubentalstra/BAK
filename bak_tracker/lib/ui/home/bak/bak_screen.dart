import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';

class BakScreen extends StatefulWidget {
  const BakScreen({super.key});

  @override
  _BakScreenState createState() => _BakScreenState();
}

class _BakScreenState extends State<BakScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _users = [];
  String? _selectedReceiverId;
  final _amountController = TextEditingController();

  late TabController _tabController;
  String? _selectedAssociationId;

  List<Map<String, dynamic>> _sentBakken = [];
  List<Map<String, dynamic>> _receivedBakken = [];
  List<Map<String, dynamic>> _receivedBakkenTransaction = [];
  bool _isLoadingSent = false;
  bool _isLoadingReceived = false;
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _fetchReceivedBakken(); // Fetch received bakken when this tab is selected
      } else if (_tabController.index == 3 && _selectedAssociationId != null) {
        _fetchSentBakken(
            _selectedAssociationId!); // Fetch sent bakken (transactions) with associationId
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Fetch users for the selected association when it's loaded
  void _fetchUsers(String associationId) async {
    setState(() {
      _isLoadingUsers = true;
    });

    final supabase = Supabase.instance.client;
    final List<dynamic> userResponse = await supabase
        .from('association_members')
        .select('user_id (id, name)')
        .eq('association_id', associationId);

    // Post-frame callback to update state after the build is done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
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
    });
  }

  Future<void> sendBak({
    required String receiverId,
    required String associationId,
    required int amount,
  }) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    try {
      await supabase.from('bak_send').insert({
        'giver_id': userId,
        'receiver_id': receiverId,
        'association_id': associationId,
        'amount': amount,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow; // Optional: Re-throw the error if needed for further handling
    }
  }

  Future<void> requestConsumedBak({
    required String associationId,
    required int amount,
  }) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    try {
      await supabase.from('bak_consumed').insert({
        'taker_id': userId,
        'association_id': associationId,
        'amount': amount,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _fetchSentBakken(String associationId) async {
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
        .eq('association_id', associationId)
        .order('created_at', ascending: false);

    final List<dynamic> receivedResponse = await supabase
        .from('bak_send')
        .select(
            'id, amount, status, created_at, receiver_id (id, name), giver_id (id, name)')
        .eq('receiver_id', currentUserId)
        .eq('association_id', associationId)
        .neq('status', 'pending') // Exclude pending baks
        .order('created_at', ascending: false);

    setState(() {
      _sentBakken = List<Map<String, dynamic>>.from(response);
      _receivedBakkenTransaction =
          List<Map<String, dynamic>>.from(receivedResponse);
      _isLoadingSent = false;
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
    } catch (e) {
      print('Error declining bak: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bak'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Send Bak'),
            Tab(text: 'Request Consumed Bak'),
            Tab(text: 'Received Bak'),
            Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: BlocBuilder<AssociationBloc, AssociationState>(
        builder: (context, state) {
          if (state is AssociationLoaded) {
            final associationId = state.selectedAssociation.id;
            if (_selectedAssociationId != associationId) {
              _selectedAssociationId = associationId;

              // Delay fetching users until the next frame
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fetchUsers(associationId);
              });
            }
            return TabBarView(
              controller: _tabController,
              children: [
                _buildSendBakTab(context, associationId),
                _buildRequestConsumedBakTab(context, associationId),
                _buildReceivedBakTab(),
                _buildTransactionsBakTab(),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

// Tab 1: Send Bak
  Widget _buildSendBakTab(BuildContext context, String associationId) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Dismiss the keyboard
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_users.isNotEmpty) ...[
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
                alignment: MediaQuery.of(context).size.width < 600
                    ? Alignment.center
                    : Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_selectedReceiverId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Please select a receiver and enter an amount.')),
                      );
                      return;
                    }
                    try {
                      await sendBak(
                        receiverId: _selectedReceiverId!,
                        associationId: associationId,
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

  // Tab 2: Request Consumed Bak
  Widget _buildRequestConsumedBakTab(
      BuildContext context, String associationId) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Dismiss the keyboard
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              alignment: MediaQuery.of(context).size.width < 600
                  ? Alignment.center
                  : Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await requestConsumedBak(
                      associationId: associationId,
                      amount: int.parse(_amountController.text),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Consumed Bak request sent!'),
                      backgroundColor: Colors.green,
                    ));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error requesting consumed bak: $e'),
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
                icon: const Icon(Icons.receipt_long),
                label: const Text('Request Consumed Bak'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tab 3: Received Bak
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

  // Tab 4: Transactions
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
}
