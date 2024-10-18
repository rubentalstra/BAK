import 'package:equatable/equatable.dart';
import 'package:bak_tracker/models/user_model.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final UserModel user;

  const UserLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class UserError extends UserState {
  final String errorMessage;

  const UserError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

class UserNotificationsUpdated extends UserState {
  final bool notificationsEnabled;

  const UserNotificationsUpdated(this.notificationsEnabled);

  @override
  List<Object?> get props => [notificationsEnabled];
}

class UserStreakNotificationsUpdated extends UserState {
  final bool streakNotificationsEnabled;

  const UserStreakNotificationsUpdated(this.streakNotificationsEnabled);

  @override
  List<Object?> get props => [streakNotificationsEnabled];
}