import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssociationRequestScreen extends StatefulWidget {
  const AssociationRequestScreen({super.key});

  @override
  _AssociationRequestScreenState createState() =>
      _AssociationRequestScreenState();
}

class _AssociationRequestScreenState extends State<AssociationRequestScreen> {
  final _nameController = TextEditingController();
  final _websiteUrlController = TextEditingController();

  Future<void> _submitRequest() async {
    final name = _nameController.text;
    final websiteUrl = _websiteUrlController.text;

    // Get the current user's auth ID
    final authUserId = Supabase.instance.client.auth.currentUser?.id;

    if (name.isEmpty || websiteUrl.isEmpty || authUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all fields')),
      );
      return;
    }

    try {
      // Insert the request into the 'association_requests' table

      await Supabase.instance.client.from('association_requests').insert({
        'user_id': Supabase.instance.client.auth.currentUser!.id,
        'website_url': websiteUrl,
        'name': name,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted successfully')),
      );
      // Optionally, clear the input fields
      _nameController.clear();
      _websiteUrlController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Association'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Association Name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _websiteUrlController,
              decoration: const InputDecoration(
                labelText: 'Association Website URL',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitRequest,
              child: const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}
