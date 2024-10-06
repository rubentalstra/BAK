import 'package:badges/badges.dart' as badges;
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/bloc/association/association_state.dart';
import 'package:bak_tracker/core/themes/colors.dart';
import 'package:bak_tracker/models/association_model.dart';
import 'package:bak_tracker/models/leaderboard_entry.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:bak_tracker/ui/association_settings/association_settings_screen.dart';
import 'package:bak_tracker/ui/home/widgets/leaderboard_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    _fetchLeaderboard();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedAssociation?.id != widget.selectedAssociation?.id) {
      _fetchLeaderboard();
    }
  }

  void _fetchLeaderboard() {
    if (widget.selectedAssociation == null) return;

    setState(() => _isLoading = true);

    context.read<AssociationBloc>().add(
          SelectAssociation(selectedAssociation: widget.selectedAssociation!),
        );
  }

  Future<void> _handlePullToRefresh() async {
    _fetchLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AssociationBloc, AssociationState>(
      listener: (context, state) {
        if (state is AssociationLoaded &&
            state.selectedAssociation.id == widget.selectedAssociation?.id) {
          final newEntries = state.members
              .map((member) => LeaderboardEntry(
                    rank: 0,
                    member: member,
                  ))
              .toList();

          newEntries.sort(
              (a, b) => b.member.baksConsumed.compareTo(a.member.baksConsumed));

          for (int i = 0; i < newEntries.length; i++) {
            newEntries[i] = newEntries[i].copyWith(rank: i + 1);
          }

          setState(() {
            _leaderboardEntries = newEntries;
            _isLoading = false;
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: widget.associations.length > 1
                ? DropdownButtonHideUnderline(
                    child: DropdownButton<AssociationModel>(
                      value: widget.selectedAssociation,
                      onChanged: widget.onAssociationChanged,
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
                            style:
                                Theme.of(context).dropdownMenuTheme.textStyle,
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
              if (state is AssociationLoaded) _buildSettingsIcon(state),
            ],
          ),
          body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: RefreshIndicator(
                color: AppColors.lightSecondary,
                onRefresh: _handlePullToRefresh,
                child: LeaderboardWidget(
                  entries: _leaderboardEntries,
                  imageUploadService: _imageUploadService,
                  isLoading: _isLoading,
                ),
              )),
        );
      },
    );
  }

  Widget _buildSettingsIcon(AssociationLoaded state) {
    final memberData = state.memberData;
    final canAccessSettings = memberData.permissions.canAccessSettings();

    if (!canAccessSettings) return const SizedBox();

    return badges.Badge(
      position: badges.BadgePosition.topEnd(top: 0, end: 3),
      showBadge: state.pendingApproveBaksCount > 0,
      badgeContent: Text(
        state.pendingApproveBaksCount.toString(),
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      badgeStyle: const badges.BadgeStyle(badgeColor: Colors.red),
      child: IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) => AssociationSettingsScreen(
                    memberData: memberData,
                    association: state.selectedAssociation,
                    pendingApproveBaksCount: state.pendingApproveBaksCount,
                  ),
                ),
              )
              .then((_) => _fetchLeaderboard());
        },
      ),
    );
  }
}
