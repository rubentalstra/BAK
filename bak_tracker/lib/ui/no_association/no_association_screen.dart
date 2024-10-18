import 'package:bak_tracker/ui/no_association/no_association_home_screen.dart';
import 'package:bak_tracker/ui/profile/profile_screen.dart';
import 'package:bak_tracker/ui/no_association/widgets/bottem_nav_bar_no_association.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/bloc/user/user_bloc.dart';
import 'package:bak_tracker/bloc/user/user_state.dart';
import 'package:bak_tracker/bloc/user/user_event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NoAssociationScreen extends StatefulWidget {
  const NoAssociationScreen({super.key});

  @override
  _NoAssociationScreenState createState() => _NoAssociationScreenState();
}

class _NoAssociationScreenState extends State<NoAssociationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const NoAssociationHomeScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Fetch the user data when the screen initializes
    final userId = Supabase
        .instance.client.auth.currentUser!.id; // Assumes user is authenticated
    context.read<UserBloc>().add(LoadUser(userId));

    // Load user details at initialization via UserBloc
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      context.read<UserBloc>().add(LoadUser(currentUser.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<UserBloc, UserState>(
          listener: (context, state) {
            if (state is UserLoaded) {
              // Handle user data (e.g., FCM token registration or profile updates)
              print('User Loaded: ${state.user.name}');
            } else if (state is UserError) {
              // Handle error
              print('Error loading user: ${state.errorMessage}');
            }
          },
        ),
      ],
      child: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavBarNoAssociation(
          selectedIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }
}
