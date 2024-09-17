import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangeDisplayNameScreen extends StatefulWidget {
  const ChangeDisplayNameScreen({super.key});

  @override
  _ChangeDisplayNameScreenState createState() =>
      _ChangeDisplayNameScreenState();
}

class _ChangeDisplayNameScreenState extends State<ChangeDisplayNameScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  bool _isLoading = false;
  bool _isFetchingName = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentDisplayName(); // Fetch current display name when the screen loads
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  // Method to fetch the current display name from the database
  Future<void> _fetchCurrentDisplayName() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    try {
      final response = await supabase
          .from(
              'users') // Assuming 'users' table stores the user's display name
          .select('name')
          .eq('id', userId)
          .single();

      final currentName = response['name'];

      // Populate the controller with the current name
      _displayNameController.text = currentName;

      setState(() {
        _isFetchingName = false; // Fetching completed
      });
    } catch (e) {
      print('Error fetching current display name: $e');
      setState(() {
        _isFetchingName = false;
      });
    }
  }

  Future<void> _updateDisplayName(String newName) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    setState(() {
      _isLoading = true;
    });

    try {
      await supabase.from('users').update({'name': newName}).eq('id', userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Display name changed to $newName')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error updating display name: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update display name')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Display Name'),
      ),
      body: _isFetchingName
          ? const Center(
              child:
                  CircularProgressIndicator()) // Show loading spinner while fetching
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your new display name:',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  const SizedBox(height: 8.0),
                  TextField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'New display name',
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () {
                            final newName = _displayNameController.text;
                            if (newName.isNotEmpty) {
                              _updateDisplayName(newName);
                            }
                          },
                          child: const Text('Save'),
                        ),
                ],
              ),
            ),
    );
  }
}
