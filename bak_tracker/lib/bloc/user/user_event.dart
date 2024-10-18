import 'package:bak_tracker/models/user_model.dart';
import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadUser extends UserEvent {
  final String userId;

  const LoadUser(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateUserProfile extends UserEvent {
  final UserModel updatedUser;

  const UpdateUserProfile(this.updatedUser);

  @override
  List<Object?> get props => [updatedUser];
}

class LogAlcoholConsumption extends UserEvent {
  final String alcoholType;

  const LogAlcoholConsumption(this.alcoholType);

  @override
  List<Object?> get props => [alcoholType];
}

class ToggleNotifications extends UserEvent {
  final bool isEnabled;

  const ToggleNotifications(this.isEnabled);

  @override
  List<Object?> get props => [isEnabled];
}

class ToggleStreakNotifications extends UserEvent {
  final bool isEnabled;

  const ToggleStreakNotifications(this.isEnabled);

  @override
  List<Object?> get props => [isEnabled];
}
