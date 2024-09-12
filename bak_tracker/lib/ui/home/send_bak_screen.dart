import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:bak_tracker/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SendBakScreen extends StatefulWidget {
  @override
  _SendBakScreenState createState() => _SendBakScreenState();
}

class _SendBakScreenState extends State<SendBakScreen> {
  List<AssociationMemberModel> _users = [];
  List<AssociationModel> _associations = [];
  String? _selectedGiverId;
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
  user_id ( id, name )
  ''').eq('association_id', _selectedAssociation!);

    print(userResponse);
    if (userResponse.isNotEmpty) {
      setState(() {
        _selectedGiverId = _users.isNotEmpty ? _users.first.userId : null;
        _selectedReceiverId = _users.isNotEmpty ? _users.first.userId : null;
      });
    }
  }

  Future<void> sendBak({
    required String giverId,
    required String receiverId,
    required String associationId,
    required int amount,
    String? boardYearId,
  }) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.from('bak_send').insert({
        'id': supabase
            .auth.currentUser!.id, // You may want to generate a unique ID here
        'giver_id': giverId,
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
      appBar: AppBar(title: Text('Send Bak')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedAssociation,
              hint: Text('Select Association'),
              onChanged: (value) {
                setState(() {
                  _selectedAssociation = value;
                });
              },
              items: _associations.map((association) {
                return DropdownMenuItem<String>(
                  value: association.id,
                  child: Text(association.name),
                );
              }).toList(),
            ),
            DropdownButton<String>(
              value: _selectedGiverId,
              hint: Text('Select Giver'),
              onChanged: (value) {
                setState(() {
                  _selectedGiverId = value;
                });
              },
              items: _users.map((user) {
                return DropdownMenuItem<String>(
                  value: user.userId,
                  child: Text(user.name!),
                );
              }).toList(),
            ),
            DropdownButton<String>(
              value: _selectedReceiverId,
              hint: Text('Select Receiver'),
              onChanged: (value) {
                setState(() {
                  _selectedReceiverId = value;
                });
              },
              items: _users.map((user) {
                return DropdownMenuItem<String>(
                  value: user.userId,
                  child: Text(user.name!),
                );
              }).toList(),
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Amount'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await sendBak(
                    giverId: _selectedGiverId!,
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
