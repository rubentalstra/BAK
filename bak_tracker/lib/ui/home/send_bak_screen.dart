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

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this); // Initialize tab controller
    _fetchData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final supabase = Supabase.instance.client;

    // Fetch associations the current user belongs to using association_members table
    final List<dynamic> memberResponse = await supabase
        .from('association_members')
        .select('association_id, associations (id, name)')
        .eq('user_id', supabase.auth.currentUser!.id);

    if (memberResponse.isNotEmpty) {
      setState(() {
        _associations = memberResponse.map((data) {
          final association = data['associations'] as Map<String, dynamic>;
          return AssociationModel(
            id: association['id'],
            name: association['name'],
          );
        }).toList();

        // Automatically select the first association if only one, otherwise allow user to choose
        if (_associations.length == 1) {
          _selectedAssociation = _associations.first.id;
          _fetchUsers(); // Fetch users for the selected association
        }
      });
    }
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

  Future<List<Map<String, dynamic>>> _fetchSentBakken() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('bak_send')
        .select()
        .eq('giver_id', Supabase.instance.client.auth.currentUser!.id);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _fetchReceivedBakken() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('bak_send')
        .select()
        .eq('receiver_id', Supabase.instance.client.auth.currentUser!.id);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bak Tracker'),
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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchSentBakken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No sent baks found.'));
        }
        final sentBakken = snapshot.data!;
        return ListView.builder(
          itemCount: sentBakken.length,
          itemBuilder: (context, index) {
            final bak = sentBakken[index];
            return ListTile(
              title: Text('Sent to: ${bak['receiver_id']}'),
              subtitle: Text('Amount: ${bak['amount']}'),
              trailing: Text('Status: ${bak['status']}'),
            );
          },
        );
      },
    );
  }

  Widget _buildReceivedBakTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchReceivedBakken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No received baks found.'));
        }
        final receivedBakken = snapshot.data!;
        return ListView.builder(
          itemCount: receivedBakken.length,
          itemBuilder: (context, index) {
            final bak = receivedBakken[index];
            return ListTile(
              title: Text('Received from: ${bak['giver_id']}'),
              subtitle: Text('Amount: ${bak['amount']}'),
              trailing: Text('Status: ${bak['status']}'),
            );
          },
        );
      },
    );
  }
}
