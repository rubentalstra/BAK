import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/services/bak_service.dart';
import 'package:bak_tracker/services/image_upload_service.dart';

class OngoingBetsTab extends StatefulWidget {
  final String associationId;
  final ImageUploadService imageUploadService;

  const OngoingBetsTab({
    super.key,
    required this.associationId,
    required this.imageUploadService,
  });

  @override
  _OngoingBetsTabState createState() => _OngoingBetsTabState();
}

class _OngoingBetsTabState extends State<OngoingBetsTab> {
  List<Map<String, dynamic>> _ongoingBets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOngoingBets();
  }

  Future<void> _fetchOngoingBets() async {
    final supabase = Supabase.instance.client;
    try {
      setState(() {
        _isLoading = true;
      });
      final response = await supabase
          .from('bets')
          .select(
              'id, bet_creator_id(id, name, profile_image), bet_receiver_id(id, name, profile_image), amount, bet_description, status, association_id')
          .eq('association_id', widget.associationId)
          .inFilter('status', ['pending', 'accepted']).order('created_at',
              ascending: false);

      setState(() {
        _ongoingBets = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching ongoing bets: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateBetStatus(
      String betId, String newStatus, String creatorId) async {
    final supabase = Supabase.instance.client;
    final receiverId = supabase.auth.currentUser!.id;

    try {
      await BakService.updateBetStatus(
        betId: betId,
        newStatus: newStatus,
        receiverId: receiverId,
        creatorId: creatorId,
      );
      _fetchOngoingBets();
    } catch (e) {
      print('Error updating bet status: $e');
    }
  }

  Future<void> _settleBet(
      String betId, String winnerId, String loserId, int amount) async {
    try {
      await BakService.settleBet(
        betId: betId,
        winnerId: winnerId,
        loserId: loserId,
        amount: amount,
        associationId: widget.associationId,
      );
      _fetchOngoingBets();
    } catch (e) {
      print('Error settling bet: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ongoingBets.isEmpty) {
      return const Center(child: Text('No ongoing bets.'));
    }

    return ListView.builder(
      itemCount: _ongoingBets.length,
      itemBuilder: (context, index) {
        final bet = _ongoingBets[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBetParticipants(bet),
                const SizedBox(height: 12),
                Text(
                  'Bet: ${bet['amount']} bakken',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Description: ${bet['bet_description']}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                _buildStatusIndicator(bet['status']),
                const SizedBox(height: 8),
                if (bet['status'] == 'pending') _buildPendingActions(bet),
                if (bet['status'] == 'accepted') _buildWinnerSelection(bet),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBetParticipants(Map<String, dynamic> bet) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            FutureBuilder<File?>(
              future: (bet['bet_creator_id']['profile_image'] != null &&
                      bet['bet_creator_id']['profile_image'] is String &&
                      bet['bet_creator_id']['profile_image'].isNotEmpty)
                  ? widget.imageUploadService.fetchOrDownloadProfileImage(
                      bet['bet_creator_id']['profile_image'])
                  : Future.value(null),
              builder: (context, snapshot) {
                final creatorImage = snapshot.data;
                return _buildProfileImage(
                    creatorImage, bet['bet_creator_id']['name']);
              },
            ),
            Positioned(
              left: 30,
              child: FutureBuilder<File?>(
                future: (bet['bet_receiver_id']['profile_image'] != null &&
                        bet['bet_receiver_id']['profile_image'] is String &&
                        bet['bet_receiver_id']['profile_image'].isNotEmpty)
                    ? widget.imageUploadService.fetchOrDownloadProfileImage(
                        bet['bet_receiver_id']['profile_image'])
                    : Future.value(null),
                builder: (context, snapshot) {
                  final receiverImage = snapshot.data;
                  return _buildProfileImage(
                      receiverImage, bet['bet_receiver_id']['name']);
                },
              ),
            ),
          ],
        ),
        const SizedBox(width: 40),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Creator: ${bet['bet_creator_id']['name']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Receiver: ${bet['bet_receiver_id']['name']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileImage(File? imageFile, String userName) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: imageFile == null ? Colors.grey[300] : null,
      backgroundImage: imageFile != null ? FileImage(imageFile) : null,
      child: imageFile == null
          ? Text(
              userName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            )
          : null,
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color statusColor;
    String statusText;

    if (status == 'pending') {
      statusColor = Colors.orange;
      statusText = 'Pending Approval';
    } else if (status == 'accepted') {
      statusColor = Colors.green;
      statusText = 'Accepted - Ready to Settle';
    } else {
      statusColor = Colors.grey;
      statusText = 'Unknown Status';
    }

    return Row(
      children: [
        Icon(
          Icons.circle,
          color: statusColor,
          size: 12,
        ),
        const SizedBox(width: 6),
        Text(
          statusText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingActions(Map<String, dynamic> bet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => _updateBetStatus(
              bet['id'], 'accepted', bet['bet_creator_id']['id']),
          child: const Text(
            'Accept',
            style: TextStyle(color: Colors.green),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => _updateBetStatus(
              bet['id'], 'rejected', bet['bet_creator_id']['id']),
          child: const Text(
            'Reject',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildWinnerSelection(Map<String, dynamic> bet) {
    String? selectedWinner;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select the Winner:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FutureBuilder<File?>(
              future: widget.imageUploadService.fetchOrDownloadProfileImage(
                  bet['bet_creator_id']['profile_image']),
              builder: (context, snapshot) {
                final creatorImage = snapshot.data;
                return _buildSelectableWinnerOption(
                  userId: bet['bet_creator_id']['id'],
                  userName: bet['bet_creator_id']['name'],
                  profileImage: creatorImage,
                  isSelected: selectedWinner == bet['bet_creator_id']['id'],
                  onTap: () {
                    setState(() {
                      selectedWinner = bet['bet_creator_id']['id'];
                      _handleWinnerSelection(bet, selectedWinner!);
                    });
                  },
                );
              },
            ),
            const Text(
              'vs',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            FutureBuilder<File?>(
              future: widget.imageUploadService.fetchOrDownloadProfileImage(
                  bet['bet_receiver_id']['profile_image']),
              builder: (context, snapshot) {
                final receiverImage = snapshot.data;
                return _buildSelectableWinnerOption(
                  userId: bet['bet_receiver_id']['id'],
                  userName: bet['bet_receiver_id']['name'],
                  profileImage: receiverImage,
                  isSelected: selectedWinner == bet['bet_receiver_id']['id'],
                  onTap: () {
                    setState(() {
                      selectedWinner = bet['bet_receiver_id']['id'];
                      _handleWinnerSelection(bet, selectedWinner!);
                    });
                  },
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectableWinnerOption({
    required String userId,
    required String userName,
    File? profileImage,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundImage:
                profileImage != null ? FileImage(profileImage) : null,
            backgroundColor: profileImage == null ? Colors.grey[300] : null,
            child: profileImage == null
                ? Text(
                    userName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            userName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _handleWinnerSelection(
      Map<String, dynamic> bet, String selectedWinnerId) {
    final loserId = selectedWinnerId == bet['bet_creator_id']['id']
        ? bet['bet_receiver_id']['id']
        : bet['bet_creator_id']['id'];
    _settleBet(bet['id'], selectedWinnerId, loserId, bet['amount']);
  }
}
