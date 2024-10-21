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
      // Fetch user data
      final user = await userService.getUserById(event.userId);

      // Fetch total consumption data
      final totalConsumption =
          await userService.getTotalConsumption(event.userId);

      // Schedule streak reminder if enabled
      if (user.streakNotificationsEnabled) {
        await notificationsService.scheduleStreakReminder(user);
      }

      // Emit both user and total consumption as one state
      emit(UserLoaded(user, totalConsumption));
    } catch (error) {
      emit(UserError(error.toString()));
    }
  }

  Future<void> _onUpdateUserProfile(
      UpdateUserProfile event, Emitter<UserState> emit) async {
    try {
      await userService.updateUser(event.updatedUser);

      if (event.updatedUser.streakNotificationsEnabled) {
        await notificationsService.scheduleStreakReminder(event.updatedUser);
      } else {
        await notificationsService.cancelStreakReminder();
      }

      // Fetch total consumption after updating user
      final totalConsumption =
          await userService.getTotalConsumption(event.updatedUser.id);

      emit(UserLoaded(event.updatedUser, totalConsumption));
    } catch (error) {
      emit(UserError(error.toString()));
    }
  }

  Future<void> _onLogAlcoholConsumption(
      LogAlcoholConsumption event, Emitter<UserState> emit) async {
    final currentState = state;
    if (currentState is UserLoaded) {
      try {
        // Log the alcohol consumption
        final updatedUser = await userService.logAlcoholConsumption(
            currentState.user, event.alcoholType);

        // Fetch the updated total consumption
        final updatedTotalConsumption =
            await userService.getTotalConsumption(updatedUser.id);

        if (updatedUser.streakNotificationsEnabled) {
          await notificationsService.scheduleStreakReminder(updatedUser);
        }

        // Emit the updated user and total consumption states together
        emit(UserLoaded(updatedUser, updatedTotalConsumption));
      } catch (error) {
        emit(UserError(
            'Failed to log alcohol consumption: ${error.toString()}'));
      }
    }
  }

  Future<void> _onToggleNotifications(
      ToggleNotifications event, Emitter<UserState> emit) async {
    final currentState = state;
    if (currentState is UserLoaded) {
      try {
        await userService.toggleNotifications(
            currentState.user.id, event.isEnabled);
        final updatedUser = currentState.user.copyWith(
          notificationsEnabled: event.isEnabled,
        );

        // Fetch total consumption to keep the state consistent
        final totalConsumption =
            await userService.getTotalConsumption(updatedUser.id);

        emit(UserLoaded(updatedUser, totalConsumption));
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

        // Fetch total consumption to keep the state consistent
        final totalConsumption =
            await userService.getTotalConsumption(updatedUser.id);

        emit(UserLoaded(updatedUser, totalConsumption));
      } catch (error) {
        emit(UserError(
            'Failed to update streak notifications: ${error.toString()}'));
      }
    }
  }
}
