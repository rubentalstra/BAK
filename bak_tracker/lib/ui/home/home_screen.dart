import 'dart:async';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:bak_tracker/ui/association_settings/association_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:bak_tracker/ui/home/widgets/leaderboard_widget.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:badges/badges.dart' as badges; // Import badges

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
  StreamSubscription? _associationBlocSubscription;

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
    if (oldWidget.selectedAssociation?.id != widget.selectedAssociation?.id) {
      _fetchLeaderboard();
    }
  }

  @override
  void dispose() {
    _associationBlocSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchLeaderboard() async {
    if (widget.selectedAssociation == null) return;

    setState(() {
      _isLoading = true;
      _leaderboardEntries = [];
    });

    // Dispatch event to update the association in the bloc
    context.read<AssociationBloc>().add(SelectAssociation(
          selectedAssociation: widget.selectedAssociation!,
        ));

    // Listen for the AssociationBloc updates
    _associationBlocSubscription?.cancel();
    _associationBlocSubscription =
        context.read<AssociationBloc>().stream.listen((state) {
      if (state is AssociationLoaded &&
          state.selectedAssociation.id == widget.selectedAssociation?.id) {
        if (!mounted) return;

        List<LeaderboardEntry> newLeaderboardEntries =
            state.members.map((member) {
          return LeaderboardEntry(
            rank: 0,
            name: member.name!,
            bio: member.bio,
            role: member.role,
            profileImage: member.profileImage,
            baksConsumed: member.baksConsumed,
            baksDebt: member.baksReceived,
            betsWon: member.betsWon,
            betsLost: member.betsLost,
          );
        }).toList();

        newLeaderboardEntries
            .sort((a, b) => b.baksConsumed.compareTo(a.baksConsumed));

        for (int i = 0; i < newLeaderboardEntries.length; i++) {
          newLeaderboardEntries[i] =
              newLeaderboardEntries[i].copyWith(rank: i + 1);
        }

        setState(() {
          _leaderboardEntries = newLeaderboardEntries;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _handlePullToRefresh() async {
    await _fetchLeaderboard();
  }

  void _handleAssociationChange(AssociationModel? newAssociation) {
    widget.onAssociationChanged(newAssociation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.associations.length > 1
            ? DropdownButtonHideUnderline(
                child: DropdownButton<AssociationModel>(
                  value: widget.selectedAssociation,
                  onChanged: _handleAssociationChange,
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
        actions: [
          BlocBuilder<AssociationBloc, AssociationState>(
            builder: (context, state) {
              if (state is AssociationLoaded) {
                final memberData = state.memberData;
                bool hasAssociationPermissions =
                    memberData.canManagePermissions ||
                        memberData.canInviteMembers ||
                        memberData.canRemoveMembers ||
                        memberData.canManageRoles ||
                        memberData.canManageBaks ||
                        memberData.canApproveBaks;

                // Display a badge if there are pending approval baks
                if (hasAssociationPermissions) {
                  return badges.Badge(
                    position: badges.BadgePosition.topEnd(top: 0, end: 3),
                    showBadge: state.pendingBaksCount > 0,
                    badgeContent: Text(
                      state.pendingBaksCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                    badgeStyle: const badges.BadgeStyle(
                      badgeColor: Colors.red, // Customize badge color
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        Navigator.of(context)
                            .push(
                          MaterialPageRoute(
                            builder: (context) => AssociationSettingsScreen(
                              memberData: memberData,
                              associationId: state.selectedAssociation.id,
                              pendingBaksCount: state.pendingBaksCount,
                            ),
                          ),
                        )
                            .then((_) {
                          // Reload the leaderboard when returning from the settings screen
                          _fetchLeaderboard();
                        });
                      },
                    ),
                  );
                }
              }
              return const SizedBox(); // Return empty widget if no permission
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.selectedAssociation != null)
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.lightSecondary,
                  onRefresh: _handlePullToRefresh,
                  child: LeaderboardWidget(
                    entries: _leaderboardEntries,
                    imageUploadService: _imageUploadService,
                    isLoading: _isLoading,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
