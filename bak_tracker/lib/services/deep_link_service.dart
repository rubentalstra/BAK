import 'package:app_links/app_links.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/services/join_association_service.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  final AssociationBloc associationBloc;
  final JoinAssociationService _joinAssociationService =
      JoinAssociationService();
  final Function navigateToMainScreen;
  final Function(String error) onError; // Callback for error handling

  DeepLinkService({
    required this.associationBloc,
    required this.navigateToMainScreen,
    required this.onError, // Use callback for error handling
  });

  Future<void> initialize() async {
    try {
      // Handle any existing link on app startup
      final Uri? initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        await _processLink(initialLink);
      }

      // Listen for new deep links while the app is running
      _appLinks.uriLinkStream.listen((Uri? uri) {
        if (uri != null) {
          _processLink(uri);
        }
      });
    } catch (e) {
      print('Error initializing deep link service: $e');
      onError('Error initializing deep link: $e');
    }
  }

  Future<void> _processLink(Uri uri) async {
    if (uri.pathSegments.contains('invite') && uri.pathSegments.length > 1) {
      final inviteCode = uri.pathSegments.last;

      try {
        // Call the joinAssociation method which already handles the logic of joining an association
        final newAssociation =
            await _joinAssociationService.joinAssociation(inviteCode);

        // Update the state via Bloc
        associationBloc.add(JoinNewAssociation(newAssociation: newAssociation));

        // Dispatch event to select the association and load its data
        associationBloc
            .add(SelectAssociation(selectedAssociation: newAssociation));

        // Navigate to the MainScreen
        navigateToMainScreen();
      } catch (error) {
        // Handle the error and pass it to the UI via the onError callback
        print('Error joining association via deep link: $error');
        onError('Error joining association: $error');
      }
    }
  }

  void dispose() {
    // Nothing to dispose for app_links, but could be added if needed
  }
}
