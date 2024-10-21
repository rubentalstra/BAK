import 'package:bak_tracker/services/notifications_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bak_tracker/services/user_service.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserService userService;
  final NotificationsService notificationsService;

  UserBloc(this.userService, this.notificationsService) : super(UserInitial()) {
    on<LoadUser>(_onLoadUser);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<LogAlcoholConsumption>(_onLogAlcoholConsumption);
    on<ToggleNotifications>(_onToggleNotifications);
    on<ToggleStreakNotifications>(_onToggleStreakNotifications);
  }

  Future<void> _onLoadUser(LoadUser event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      final user = await userService.getUserById(event.userId);

      if (user.streakNotificationsEnabled) {
        await notificationsService.scheduleStreakReminder(user);
      }

      // // Example of triggering achievement notification
      // await notificationsService.checkAndNotifyAchievements(user);

      emit(UserLoaded(user));
    } catch (error) {
      emit(UserError(error.toString()));
    }
  }

  Future<void> _onUpdateUserProfile(
      UpdateUserProfile event, Emitter<UserState> emit) async {
    try {
      await userService.updateUser(event.updatedUser);

      // Reschedule streak notifications if streaks are enabled
      if (event.updatedUser.streakNotificationsEnabled) {
        await notificationsService.scheduleStreakReminder(event.updatedUser);
      } else {
        await notificationsService.cancelStreakReminder();
      }

      emit(UserLoaded(event.updatedUser));
    } catch (error) {
      emit(UserError(error.toString()));
    }
  }

  Future<void> _onLogAlcoholConsumption(
      LogAlcoholConsumption event, Emitter<UserState> emit) async {
    final currentState = state;
    if (currentState is UserLoaded) {
      try {
        final updatedUser = await userService.logAlcoholConsumption(
            currentState.user, event.alcoholType);

        if (updatedUser.streakNotificationsEnabled) {
          await notificationsService.scheduleStreakReminder(updatedUser);
        }

        // // Check for achievements and notify
        // await notificationsService.checkAndNotifyAchievements(updatedUser);

        emit(UserLoaded(updatedUser));
      } catch (error) {
        emit(UserError(error.toString()));
      }
    }
  }

  Future<void> _onToggleNotifications(
      ToggleNotifications event, Emitter<UserState> emit) async {
    final currentState = state;
    if (currentState is UserLoaded) {
      try {
        // Toggle general notifications and update the user model
        await userService.toggleNotifications(
            currentState.user.id, event.isEnabled);
        final updatedUser = currentState.user.copyWith(
          notificationsEnabled: event.isEnabled,
        );
        emit(UserLoaded(updatedUser));
      } catch (error) {
        emit(UserError('Failed to update notifications: ${error.toString()}'));
      }
    }
  }

  Future<void> _onToggleStreakNotifications(
      ToggleStreakNotifications event, Emitter<UserState> emit) async {
    final currentState = state;
    if (currentState is UserLoaded) {
      try {
        await userService.toggleStreakNotifications(
            currentState.user.id, event.isEnabled);
        final updatedUser = currentState.user.copyWith(
          streakNotificationsEnabled: event.isEnabled,
        );

        if (updatedUser.streakNotificationsEnabled) {
          await notificationsService.scheduleStreakReminder(updatedUser);
        } else {
          await notificationsService.cancelStreakReminder();
        }

        emit(UserLoaded(updatedUser));
      } catch (error) {
        emit(UserError(
            'Failed to update streak notifications: ${error.toString()}'));
      }
    }
  }
}
