import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import '../../data/services/api_service.dart';
import '../../data/services/websocket_service.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/trading/trading_bloc.dart';
import '../../presentation/blocs/account/account_bloc.dart';
import '../../presentation/blocs/signal/signal_bloc.dart';

final getIt = GetIt.instance;

@injectableInit
Future<void> configureDependencies() async {
  // Services
  getIt.registerLazySingleton<ApiService>(() => ApiService());
  getIt.registerLazySingleton<WebSocketService>(() => WebSocketService());

  // BLoCs
  getIt.registerFactory<AuthBloc>(() => AuthBloc());
  getIt.registerFactory<TradingBloc>(() => TradingBloc());
  getIt.registerFactory<AccountBloc>(() => AccountBloc());
  getIt.registerFactory<SignalBloc>(() => SignalBloc());
}
