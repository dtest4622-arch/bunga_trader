class AppConstants {
  // App Info
  static const String appName = 'Bunga Trader';
  static const String appTagline = 'Kenya\'s Smart Semi-Auto Trading';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'support@bungatrader.com';
  static const String websiteUrl = 'https://bungatrader.com';

  // API Configuration
  static const String supabaseUrl = 'https://xvpggkaavmekkencdkbh.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh2cGdra2Fhdm1la2tlbmNka2JoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0Nzk1MzUsImV4cCI6MjA5MDA1NTUzNX0.ZLrY2VY0x9sZoe6RB0YTNxW2faNg4WRdIdAbKds5LNE';
  // Backend API URL - update to your backend server
  static const String apiBaseUrl = 'https://bunga-trader.onrender.com/v1';
  static const String wsBaseUrl = 'wss://bunga-trader.onrender.com/ws';
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;

  // Local Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String settingsKey = 'app_settings';
  static const String lastAccountKey = 'last_active_account';

  // Trading Constants
  static const List<String> supportedBrokers = [
    'exness',
    'xm',
    'hotforex',
    'icmarkets'
  ];
  static const List<String> accountTypes = [
    'CENT',
    'STANDARD',
    'RAW',
    'ZERO',
    'PRO'
  ];
  static const List<String> supportedPairs = [
    'EURUSD',
    'GBPUSD',
    'USDJPY',
    'AUDUSD',
    'USDCAD',
    'USDCHF',
    'NZDUSD',
    'EURGBP',
    'EURJPY',
    'GBPJPY',
    'XAUUSD',
    'XAGUSD',
    'US30',
    'NAS100',
    'UK100'
  ];
  static const List<int> leverageOptions = [
    1,
    10,
    20,
    50,
    100,
    200,
    400,
    500,
    1000,
    2000
  ];
  static const List<double> lotSizeOptions = [
    0.01,
    0.02,
    0.05,
    0.1,
    0.2,
    0.5,
    1.0,
    2.0,
    5.0
  ];
  static const double defaultRiskPercent = 1.0;
  static const double maxRiskPercent = 5.0;
  static const double minRiskPercent = 0.1;

  // M-Pesa Configuration
  static const String mpesaShortcode = '174379';
  static const List<int> depositAmounts = [100, 500, 1000, 5000, 10000, 50000];
  static const int minDepositKes = 100;
  static const int maxDepositKes = 150000;
  static const double minWithdrawalUsd = 10.0;
  static const double kesToUsdRate = 0.0077; // Approximate rate

  // Signal Configuration
  static const int signalExpiryMinutes = 30;
  static const int maxSignalsPerDay = 50;
  static const int confidenceThreshold = 70;
  static const List<String> signalStatuses = [
    'PENDING',
    'EXECUTED',
    'REJECTED',
    'EXPIRED',
    'CLOSED'
  ];

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultRadius = 12.0;
  static const double cardRadius = 16.0;
  static const double buttonHeight = 56.0;
  static const double inputHeight = 56.0;
  static const double iconSize = 24.0;
  static const double avatarSize = 48.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Refresh Intervals
  static const Duration balanceRefreshInterval = Duration(seconds: 5);
  static const Duration tradesRefreshInterval = Duration(seconds: 3);
  static const Duration signalsRefreshInterval = Duration(seconds: 10);

  // Error Messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError =
      'Network connection error. Please check your internet.';
  static const String authError = 'Authentication failed. Please login again.';
  static const String invalidCredentials = 'Invalid email or password.';
  static const String accountNotFound = 'Trading account not found.';
  static const String insufficientBalance =
      'Insufficient balance for this operation.';
  static const String signalExpired = 'This signal has expired.';
  static const String tradeExecutionFailed =
      'Failed to execute trade. Please try again.';

  // Success Messages
  static const String loginSuccess = 'Welcome back!';
  static const String registrationSuccess = 'Account created successfully!';
  static const String depositSuccess =
      'Deposit initiated. Check your phone for M-Pesa prompt.';
  static const String withdrawalSuccess =
      'Withdrawal request submitted successfully.';
  static const String tradeExecuted = 'Trade executed successfully!';
  static const String settingsSaved = 'Settings saved successfully.';

  // Feature Flags
  static const bool enableDemoMode = true;
  static const bool enableAutoTrading = true;
  static const bool enablePushNotifications = true;
  static const bool enableBiometricAuth = false;
  static const bool enableDarkModeOnly = true;
}

// Route Names
class RouteNames {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String signals = '/signals';
  static const String trades = '/trades';
  static const String accounts = '/accounts';
  static const String accountDetail = '/accounts/:id';
  static const String deposit = '/deposit';
  static const String withdraw = '/withdraw';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String kyc = '/kyc';
  static const String support = '/support';
  static const String about = '/about';
}

// Asset Paths
class AssetPaths {
  static const String images = 'assets/images/';
  static const String icons = 'assets/icons/';
  static const String animations = 'assets/animations/';

  static const String logo = '${images}logo.png';
  static const String logoWhite = '${images}logo_white.png';
  static const String onboarding1 = '${images}onboarding_1.png';
  static const String onboarding2 = '${images}onboarding_2.png';
  static const String onboarding3 = '${images}onboarding_3.png';
  static const String emptyState = '${images}empty_state.png';
  static const String noSignals = '${images}no_signals.png';
  static const String noTrades = '${images}no_trades.png';

  static const String homeIcon = '${icons}home.svg';
  static const String signalsIcon = '${icons}signals.svg';
  static const String tradesIcon = '${icons}trades.svg';
  static const String accountIcon = '${icons}account.svg';
  static const String settingsIcon = '${icons}settings.svg';
}
