part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String phoneNumber;
  final String mpesaNumber;
  final String? fullName;

  const RegisterRequested({
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.mpesaNumber,
    this.fullName,
  });

  @override
  List<Object?> get props => [email, password, phoneNumber, mpesaNumber, fullName];
}

class LogoutRequested extends AuthEvent {}

class ProfileUpdated extends AuthEvent {
  final Map<String, dynamic> data;

  const ProfileUpdated({required this.data});

  @override
  List<Object?> get props => [data];
}

class PasswordChanged extends AuthEvent {
  final String oldPassword;
  final String newPassword;

  const PasswordChanged({
    required this.oldPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [oldPassword, newPassword];
}
