import 'package:bak_tracker/services/association_service.dart';
import 'package:bak_tracker/services/image_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'achievements_tab.dart';
import 'members_tab.dart';

class AchievementManagementScreen extends StatefulWidget {
  final String associationId;
  final ImageUploadService imageUploadService;

  const AchievementManagementScreen({
    super.key,
    required this.associationId,
    required this.imageUploadService,
  });

  @override
  _AchievementManagementScreenState createState() =>
      _AchievementManagementScreenState();
}

class _AchievementManagementScreenState
    extends State<AchievementManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AssociationService associationService;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    associationService =
        AssociationService(_supabase); // Initialize the service
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Achievements'),
        bottom: TabBar(
          dividerColor: Colors.transparent,
          controller: _tabController,
          tabs: const [
            Tab(text: 'Members'),
            Tab(text: 'Achievements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MembersTab(
            associationId: widget.associationId,
            imageUploadService: widget.imageUploadService,
            associationService:
                associationService, // Pass the association service
          ),
          AchievementsTab(
            associationId: widget.associationId,
            associationService:
                associationService, // Pass the association service
          ),
        ],
      ),
    );
  }
}
