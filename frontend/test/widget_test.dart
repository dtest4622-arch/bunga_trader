// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bunga_trader/main.dart';
import 'package:bunga_trader/core/di/injection.dart';
import 'package:bunga_trader/presentation/blocs/auth/auth_bloc.dart';
import 'package:bunga_trader/presentation/blocs/trading/trading_bloc.dart';
import 'package:bunga_trader/presentation/blocs/account/account_bloc.dart';
import 'package:bunga_trader/presentation/blocs/signal/signal_bloc.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<AuthBloc>()),
          BlocProvider(create: (_) => getIt<TradingBloc>()),
          BlocProvider(create: (_) => getIt<AccountBloc>()),
          BlocProvider(create: (_) => getIt<SignalBloc>()),
        ],
        child: const BungaTraderApp(),
      ),
    );

    // Verify that the app loads
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
