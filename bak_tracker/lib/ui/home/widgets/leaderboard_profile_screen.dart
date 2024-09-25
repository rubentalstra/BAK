import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bak_tracker/ui/widgets/full_screen_profile_image.dart';

class LeaderboardProfileScreen extends StatefulWidget {
  final String username;
  final File? localImageFile; // File? instead of String
  final String? bio;
  final String? role;
  final int baksConsumed;
  final int baksDebt;

  const LeaderboardProfileScreen({
    super.key,
    required this.username,
    this.localImageFile, // Receiving File? directly
    this.bio,
    required this.role,
    required this.baksConsumed,
    required this.baksDebt,
  });

  @override
  _LeaderboardProfileScreenState createState() =>
      _LeaderboardProfileScreenState();
}

class _LeaderboardProfileScreenState extends State<LeaderboardProfileScreen> {
  File? _localImageFile;

  @override
  void initState() {
    super.initState();
    _localImageFile = widget.localImageFile; // Directly use the passed File?
  }

  // Method to show full-screen image view
  void _showFullScreenImage() {
    if (_localImageFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              FullScreenImage(localImageFile: _localImageFile!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildProfileImageSection(),
              const SizedBox(height: 30),
              _buildProfileCard(), // Profile information in a card
              const SizedBox(height: 20),
              _buildStatsCard(), // Stats information in a card
            ],
          ),
        ),
      ),
    );
  }

  // Method to build the profile image section
  Widget _buildProfileImageSection() {
    return GestureDetector(
      onTap: _showFullScreenImage,
      child: CircleAvatar(
        radius: 80,
        backgroundColor: Colors.grey[200],
        backgroundImage:
            _localImageFile != null ? FileImage(_localImageFile!) : null,
        child: _localImageFile == null
            ? const Icon(
                Icons.person,
                size: 80,
                color: Colors.grey,
              )
            : null,
      ),
    );
  }

  // Method to build the profile information card
  Widget _buildProfileCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Role', widget.role ?? 'No role available',
                Icons.supervisor_account),
            const SizedBox(height: 12),
            _buildInfoRow('Bio', widget.bio ?? 'No bio available', Icons.info),
          ],
        ),
      ),
    );
  }

  // Method to create an info row for profile data
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Method to build the stats card
  Widget _buildStatsCard() {
    return Card(
      color: Colors.white.withOpacity(0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatColumn('Chucked', widget.baksConsumed, Icons.local_drink),
            _buildStatColumn(
                'BAK Debt', widget.baksDebt, Icons.account_balance),
          ],
        ),
      ),
    );
  }

  // Method to create a column for displaying stats
  Widget _buildStatColumn(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 36),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
