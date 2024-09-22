import 'dart:convert';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:bak_tracker/models/association_member_model.dart';
import 'package:bak_tracker/ui/home/widgets/leaderboard_widget.dart';

class HomeScreen extends StatefulWidget {
  final List<AssociationModel> associations;
  final AssociationModel? selectedAssociation;
  final ValueChanged<AssociationModel?> onAssociationChanged;

  const HomeScreen({
    super.key,
    required this.associations,
    required this.selectedAssociation,
    required this.onAssociationChanged,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<LeaderboardEntry> _leaderboardEntries = [];
  final supabase = Supabase.instance.client;
  late ImageUploadService _imageUploadService;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _imageUploadService = ImageUploadService(supabase);
    _fetchLeaderboard(); // Initial fetch for the leaderboard
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger leaderboard reload if the selected association has changed
    if (oldWidget.selectedAssociation != widget.selectedAssociation) {
      _fetchLeaderboard();
    }
  }

  // Fetch leaderboard for the selected association
  Future<void> _fetchLeaderboard() async {
    if (widget.selectedAssociation == null) return;

    setState(() {
      _isLoading = true;
      _leaderboardEntries = [];
    });

    // Fetch association members for the selected association
    final List<dynamic> memberResponse = await supabase
        .from('association_members')
        .select(
            'user_id (id, name, profile_image_path), association_id, role, permissions, joined_at, baks_received, baks_consumed')
        .eq('association_id', widget.selectedAssociation!.id);

    if (memberResponse.isNotEmpty) {
      List<AssociationMemberModel> members = memberResponse.map((data) {
        final userMap = data['user_id'] as Map<String, dynamic>;

        return AssociationMemberModel(
          userId: userMap['id'],
          name: userMap['name'],
          profileImagePath: userMap['profile_image_path'],
          associationId: data['association_id'],
          role: data['role'],
          permissions: data['permissions'] is String
              ? jsonDecode(data['permissions']) as Map<String, dynamic>
              : data['permissions'] as Map<String, dynamic>,
          joinedAt: DateTime.parse(data['joined_at']),
          baksReceived: data['baks_received'],
          baksConsumed: data['baks_consumed'],
        );
      }).toList();

      setState(() {
        _leaderboardEntries = members.map((member) {
          return LeaderboardEntry(
            rank: 0,
            name: member.name!,
            profileImagePath: member.profileImagePath,
            baksConsumed: member.baksConsumed,
            baksDebt: member.baksReceived,
          );
        }).toList();

        _leaderboardEntries
            .sort((a, b) => b.baksConsumed.compareTo(a.baksConsumed));

        for (int i = 0; i < _leaderboardEntries.length; i++) {
          _leaderboardEntries[i] = _leaderboardEntries[i].copyWith(rank: i + 1);
        }
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _handleAssociationChange(AssociationModel? newAssociation) {
    widget.onAssociationChanged(newAssociation); // Inform the parent widget
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.associations.length > 1
            ? DropdownButtonHideUnderline(
                child: DropdownButton<AssociationModel>(
                  value: widget.selectedAssociation,
                  onChanged: _handleAssociationChange, // Trigger reload
                  dropdownColor: AppColors.lightPrimaryVariant,
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: Theme.of(context).iconTheme.color),
                  items: widget.associations.map((association) {
                    return DropdownMenuItem(
                      value: association,
                      child: Text(association.name,
                          style: Theme.of(context).dropdownMenuTheme.textStyle),
                    );
                  }).toList(),
                ),
              )
            : Text(
                widget.selectedAssociation?.name ?? 'Loading...',
                style: Theme.of(context).dropdownMenuTheme.textStyle,
              ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.selectedAssociation != null)
              Expanded(
                child: LeaderboardWidget(
                  entries: _leaderboardEntries,
                  imageUploadService: _imageUploadService,
                  isLoading: _isLoading, // Pass the isLoading flag here
                ),
              ),
          ],
        ),
      ),
    );
  }
}
