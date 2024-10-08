import 'package:app_links/app_links.dart';
import 'package:bak_tracker/bloc/association/association_bloc.dart';
import 'package:bak_tracker/bloc/association/association_event.dart';
import 'package:bak_tracker/services/join_association_service.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  final AssociationBloc associationBloc;
  final JoinAssociationService joinAssociationService;
  final Function navigateToMainScreen;
  final Function(String error) onError;

  DeepLinkService({
    required this.associationBloc,
    required this.joinAssociationService,
    required this.navigateToMainScreen,
    required this.onError,
  });

  Future<void> initialize() async {
    try {
      final Uri? initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        await _processLink(initialLink);
      }

      _appLinks.uriLinkStream.listen((Uri? uri) {
        if (uri != null) {
          _processLink(uri);
        }
      });
    } catch (e) {
      onError('Error initializing deep link: $e');
    }
  }

  Future<void> _processLink(Uri uri) async {
    if (uri.pathSegments.contains('invite') && uri.pathSegments.length > 1) {
      final inviteCode = uri.pathSegments.last;

      try {
        final newAssociation =
            await joinAssociationService.joinAssociation(inviteCode);

        associationBloc.add(JoinNewAssociation(newAssociation: newAssociation));
        associationBloc
            .add(SelectAssociation(selectedAssociation: newAssociation));

        navigateToMainScreen();
      } catch (error) {
        onError('Error joining association: $error');
      }
    }
  }

  void dispose() {}
}
