import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/trading/trading_bloc.dart';
import 'presentation/blocs/account/account_bloc.dart';
import 'presentation/blocs/signal/signal_bloc.dart';
import 'presentation/screens/auth/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'data/services/websocket_service.dart';
import 'data/models/user_model.dart';
import 'data/models/trading_account_model.dart';
import 'data/models/signal_model.dart';
import 'data/models/trade_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(TradingAccountModelAdapter());
  Hive.registerAdapter(SignalModelAdapter());
  Hive.registerAdapter(TradeModelAdapter());

  // Open Hive Boxes
  await Hive.openBox<UserModel>('userBox');
  await Hive.openBox<TradingAccountModel>('accountsBox');
  await Hive.openBox<SignalModel>('signalsBox');
  await Hive.openBox<TradeModel>('tradesBox');
  await Hive.openBox('settingsBox');

  // Initialize Dependency Injection
  await configureDependencies();

  runApp(const BungaTraderApp());
}

class BungaTraderApp extends StatelessWidget {
  const BungaTraderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthBloc>()),
        BlocProvider(create: (_) => getIt<TradingBloc>()),
        BlocProvider(create: (_) => getIt<AccountBloc>()),
        BlocProvider(create: (_) => getIt<SignalBloc>()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Check authentication status
    context.read<AuthBloc>().add(AppStarted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const SplashScreen();
        } else if (state is AuthAuthenticated) {
          // Initialize WebSocket connection
          getIt<WebSocketService>().connect(state.user.authToken ?? '');
          return const DashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
