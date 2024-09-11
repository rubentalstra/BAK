import 'package:flutter_bloc/flutter_bloc.dart';

// Notification Events
abstract class NotificationsEvent {}

class NotificationsToggled extends NotificationsEvent {
  final bool isEnabled;

  NotificationsToggled({required this.isEnabled});
}

// Notification State
class NotificationsState {
  final bool isEnabled;

  NotificationsState({required this.isEnabled});
}

// Notifications Bloc
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc() : super(NotificationsState(isEnabled: true)) {
    on<NotificationsToggled>((event, emit) {
      emit(NotificationsState(isEnabled: event.isEnabled));
    });
  }
}
