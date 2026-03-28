import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/api_service.dart';
import 'package:hive/hive.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService = ApiService();
  late Box<UserModel> _userBox;

  AuthBloc() : super(AuthInitial()) {
    _initHive();
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<ProfileUpdated>(_onProfileUpdated);
    on<PasswordChanged>(_onPasswordChanged);
  }

  Future<void> _initHive() async {
    _userBox = Hive.box<UserModel>('userBox');
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      final token = await _apiService.getAuthToken();
      
      if (token != null && token.isNotEmpty) {
        // Validate token and get user data
        final userData = await _apiService.getCurrentUser();
        final user = UserModel.fromJson(userData);
        
        // Save to local storage
        await _userBox.put('current_user', user);
        
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      // Token might be invalid, clear it
      await _apiService.clearTokens();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      final response = await _apiService.login(event.email, event.password);
      final user = UserModel.fromJson(response);
      
      // Save to local storage
      await _userBox.put('current_user', user);
      
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onRegisterRequested(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      await _apiService.register(
        event.email,
        event.password,
        event.phoneNumber,
        event.mpesaNumber,
        fullName: event.fullName,
      );
      
      // Auto login after registration
      final response = await _apiService.login(event.email, event.password);
      final user = UserModel.fromJson(response);
      
      await _userBox.put('current_user', user);
      
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    try {
      await _apiService.logout();
      await _userBox.delete('current_user');
      emit(AuthUnauthenticated());
    } catch (e) {
      // Still logout locally even if API fails
      await _userBox.delete('current_user');
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onProfileUpdated(ProfileUpdated event, Emitter<AuthState> emit) async {
    if (state is AuthAuthenticated) {
      try {
        final response = await _apiService.updateProfile(event.data);
        final updatedUser = UserModel.fromJson(response);
        
        await _userBox.put('current_user', updatedUser);
        
        emit(AuthAuthenticated(user: updatedUser));
      } catch (e) {
        emit(AuthError(message: _getErrorMessage(e)));
      }
    }
  }

  Future<void> _onPasswordChanged(PasswordChanged event, Emitter<AuthState> emit) async {
    if (state is AuthAuthenticated) {
      try {
        await _apiService.changePassword(event.oldPassword, event.newPassword);
        emit(PasswordChangeSuccess());
        // Re-emit authenticated state
        emit(AuthAuthenticated(user: (state as AuthAuthenticated).user));
      } catch (e) {
        emit(AuthError(message: _getErrorMessage(e)));
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('401')) {
        return 'Invalid email or password';
      } else if (message.contains('409')) {
        return 'Email already registered';
      } else if (message.contains('network')) {
        return 'Network error. Please check your connection';
      }
    }
    return 'An error occurred. Please try again';
  }

  UserModel? get currentUser {
    if (state is AuthAuthenticated) {
      return (state as AuthAuthenticated).user;
    }
    return _userBox.get('current_user');
  }
}
