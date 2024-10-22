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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final ImageUploadService imageUploadService =
        ImageUploadService(Supabase.instance.client);

    return BlocBuilder<AssociationBloc, AssociationState>(
      builder: (context, state) {
        List<LeaderboardEntry> entries = [];
        bool isLoading = true;

        if (state is AssociationLoaded &&
            state.selectedAssociation.id == selectedAssociation?.id) {
          // Process entries
          entries = state.members
              .map((member) => LeaderboardEntry(rank: 0, member: member))
              .toList();

          entries.sort(
              (a, b) => b.member.baksConsumed.compareTo(a.member.baksConsumed));

          for (int i = 0; i < entries.length; i++) {
            entries[i] = entries[i].copyWith(rank: i + 1);
          }

          isLoading = false;
        } else if (state is AssociationError) {
          // Handle error state
          return Scaffold(
            appBar: _buildAppBar(context, null),
            body: Center(child: Text('Error: ${state.message}')),
          );
        } else if (state is AssociationLoading) {
          isLoading = true;
        }

        return Scaffold(
          appBar:
              _buildAppBar(context, state is AssociationLoaded ? state : null),
          body: Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: RefreshIndicator(
              color: AppColors.lightSecondary,
              onRefresh: () async {
                if (selectedAssociation != null) {
                  context.read<AssociationBloc>().add(SelectAssociation(
                      selectedAssociation: selectedAssociation!));
                }
              },
              child: LeaderboardWidget(
                entries: entries,
                imageUploadService: imageUploadService,
                isLoading: isLoading,
              ),
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, AssociationLoaded? state) {
    return AppBar(
      title: associations.length > 1
          ? _buildAssociationDropdown(context)
          : Text(selectedAssociation?.name ?? 'Loading...'),
      actions: [
        if (state != null) _buildSettingsIcon(context, state),
      ],
    );
  }

  Widget _buildAssociationDropdown(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<AssociationModel>(
        value: selectedAssociation,
        onChanged: onAssociationChanged,
        dropdownColor: AppColors.lightPrimaryVariant,
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: Theme.of(context).iconTheme.color,
        ),
        items: associations.map((association) {
          return DropdownMenuItem(
            value: association,
            child: Text(
              association.name,
              style: Theme.of(context).dropdownMenuTheme.textStyle,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsIcon(BuildContext context, AssociationLoaded state) {
    final memberData = state.memberData;

    return badges.Badge(
      position: badges.BadgePosition.topEnd(top: 0, end: 35),
      showBadge: state.pendingApproveBaksCount > 0,
      badgeContent: Text(
        state.pendingApproveBaksCount.toString(),
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      badgeStyle: const badges.BadgeStyle(badgeColor: Colors.red),
      child: IconButton(
        tooltip: 'Association Options',
        icon: const Icon(FontAwesomeIcons.usersGear),
        onPressed: () {
          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (context) => AssociationSettingsScreen(
                memberData: memberData,
                association: state.selectedAssociation,
                pendingApproveBaksCount: state.pendingApproveBaksCount,
                imageUploadService:
                    ImageUploadService(Supabase.instance.client),
              ),
            ),
          )
              .then((_) {
            // Refresh data when returning from settings
            if (selectedAssociation != null) {
              context.read<AssociationBloc>().add(
                  SelectAssociation(selectedAssociation: selectedAssociation!));
            }
          });
        },
      ),
    );
  }
}
