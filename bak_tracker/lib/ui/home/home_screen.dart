import 'dart:async';
import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/core/const/permissions_constants.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/models/leaderboard_entry.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:bak_tracker/ui/association_settings/association_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:bak_tracker/ui/home/widgets/leaderboard_widget.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:badges/badges.dart' as badges;

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
  late ImageUploadService _imageUploadService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _imageUploadService = ImageUploadService(Supabase.instance.client);
    _fetchLeaderboard(); // Call the fetch leaderboard once during initialization.
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Fetch leaderboard only if the selected association has changed
    if (oldWidget.selectedAssociation?.id != widget.selectedAssociation?.id) {
      _fetchLeaderboard();
    }
  }

  Future<void> _fetchLeaderboard() async {
    if (widget.selectedAssociation == null) return;

    setState(() {
      _isLoading = true;
    });

    context.read<AssociationBloc>().add(SelectAssociation(
          selectedAssociation: widget.selectedAssociation!,
        ));
  }

  // Handle pull to refresh
  Future<void> _handlePullToRefresh() async {
    await _fetchLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AssociationBloc, AssociationState>(
      listener: (context, state) {
        if (state is AssociationLoaded &&
            state.selectedAssociation.id == widget.selectedAssociation?.id) {
          final newLeaderboardEntries = state.members.map((member) {
            return LeaderboardEntry(
              rank: 0,
              member: member,
            );
          }).toList();

          // Sort the leaderboard by 'baksConsumed'
          newLeaderboardEntries.sort(
              (a, b) => b.member.baksConsumed.compareTo(a.member.baksConsumed));

          // Assign ranks to leaderboard entries
          for (int i = 0; i < newLeaderboardEntries.length; i++) {
            newLeaderboardEntries[i] =
                newLeaderboardEntries[i].copyWith(rank: i + 1);
          }

          setState(() {
            _leaderboardEntries = newLeaderboardEntries;
            _isLoading = false;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: widget.associations.length > 1
              ? DropdownButtonHideUnderline(
                  child: DropdownButton<AssociationModel>(
                    value: widget.selectedAssociation,
                    onChanged: (AssociationModel? newAssociation) {
                      widget.onAssociationChanged(newAssociation);
                    },
                    dropdownColor: AppColors.lightPrimaryVariant,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    items: widget.associations.map((association) {
                      return DropdownMenuItem(
                        value: association,
                        child: Text(
                          association.name,
                          style: Theme.of(context).dropdownMenuTheme.textStyle,
                        ),
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

                  // Check if the member has any relevant permissions
                  bool hasAssociationPermissions = memberData.permissions
                          .hasPermission(PermissionEnum.canManagePermissions) ||
                      memberData.permissions
                          .hasPermission(PermissionEnum.canInviteMembers) ||
                      memberData.permissions
                          .hasPermission(PermissionEnum.canRemoveMembers) ||
                      memberData.permissions
                          .hasPermission(PermissionEnum.canManageRoles) ||
                      memberData.permissions
                          .hasPermission(PermissionEnum.canManageBaks) ||
                      memberData.permissions
                          .hasPermission(PermissionEnum.canApproveBaks);

                  if (hasAssociationPermissions) {
                    return badges.Badge(
                      position: badges.BadgePosition.topEnd(top: 0, end: 3),
                      showBadge: state.pendingAproveBaksCount > 0,
                      badgeContent: Text(
                        state.pendingAproveBaksCount.toString(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      badgeStyle:
                          const badges.BadgeStyle(badgeColor: Colors.red),
                      child: IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () {
                          Navigator.of(context)
                              .push(
                            MaterialPageRoute(
                              builder: (context) => AssociationSettingsScreen(
                                memberData: memberData,
                                associationId: state.selectedAssociation.id,
                                pendingAproveBaksCount:
                                    state.pendingAproveBaksCount,
                              ),
                            ),
                          )
                              .then((_) {
                            // Reload the leaderboard when returning from the Association settings screen
                            _fetchLeaderboard();
                          });
                        },
                      ),
                    );
                  }
                }
                return const SizedBox();
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
      ),
    );
  }
}
