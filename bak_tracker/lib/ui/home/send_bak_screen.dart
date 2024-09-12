import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SendBakScreen extends StatefulWidget {
  @override
  _SendBakScreenState createState() => _SendBakScreenState();
}

class _SendBakScreenState extends State<SendBakScreen> {
  List<Map<String, dynamic>> _users = [];
  List<AssociationModel> _associations = [];
  String? _selectedReceiverId;
  String? _selectedAssociation;
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final supabase = Supabase.instance.client;

    // Fetch associations
    final List<dynamic> associationResponse =
        await supabase.from('associations').select();
    if (associationResponse.isNotEmpty) {
      setState(() {
        _associations = associationResponse
            .map((data) =>
                AssociationModel.fromMap(data as Map<String, dynamic>))
            .toList();
        _selectedAssociation =
            _associations.isNotEmpty ? _associations.first.id : null;
      });
    }

    // Fetch users
    final List<dynamic> userResponse =
        await supabase.from('association_members').select('''
id,
  user_id ( id, name )
  ''').eq('association_id', _selectedAssociation!);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Bak'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Association',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            DropdownButton<String>(
              value: _selectedAssociation,
              hint: Text('Choose an Association'),
              onChanged: (value) {
                setState(() {
                  _selectedAssociation = value;
                });
                _fetchData(); // Fetch users when the association changes
              },
              items: _associations.map((association) {
                return DropdownMenuItem<String>(
                  value: association.id,
                  child: Text(association.name),
                );
              }).toList(),
            ),
            SizedBox(height: 16.0),
            Text(
              'Select Receiver',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            DropdownButton<String>(
              value: _selectedReceiverId,
              hint: Text('Choose a Receiver'),
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
            ),
            SizedBox(height: 16.0),
            Text(
              'Amount',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter amount',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              ),
            ),
            SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () async {
                try {
                  await sendBak(
                    receiverId: _selectedReceiverId!,
                    associationId: _selectedAssociation!,
                    amount: int.parse(_amountController.text),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Bak sent successfully!')));
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: Text('Send Bak'),
            ),
          ],
        ),
      ),
    );
  }
}
