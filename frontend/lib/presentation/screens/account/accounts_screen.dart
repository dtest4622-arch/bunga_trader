import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/trading_account_model.dart';
import '../../blocs/account/account_bloc.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Trading Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showConnectAccountDialog(context);
            },
          ),
        ],
      ),
      body: BlocBuilder<AccountBloc, AccountState>(
        builder: (context, state) {
          if (state is AccountsLoaded) {
            final accounts = state.accounts;
            
            if (accounts.isEmpty) {
              return _buildEmptyState(context);
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                context.read<AccountBloc>().add(LoadAccounts());
              },
              color: AppTheme.primaryPurple,
              backgroundColor: AppTheme.cardBackground,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  final isSelected = state.selectedAccount?.id == account.id;
                  return _buildAccountCard(context, account, isSelected);
                },
              ),
            );
          }
          
          if (state is AccountLoading) {
            return _buildLoadingState();
          }
          
          return _buildEmptyState(context);
        },
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, TradingAccountModel account, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? _colorWithOpacity(AppTheme.primaryPurple, 0.5)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: account.isDemo ? Colors.orange : Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    account.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (account.isDefault) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _colorWithOpacity(AppTheme.primaryPurple, 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'DEFAULT',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.primaryPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryPurple,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn('Balance', account.formattedBalance),
              _buildInfoColumn('Equity', account.formattedEquity),
              _buildInfoColumn('Margin Level', account.formattedMarginLevel),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isSelected 
                      ? null 
                      : () {
                          context.read<AccountBloc>().add(SwitchAccount(accountId: account.id));
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? Colors.grey : AppTheme.primaryPurple,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: Text(isSelected ? 'Active' : 'Select'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  context.read<AccountBloc>().add(SyncAccount(accountId: account.id));
                },
                icon: const Icon(Icons.sync),
                color: AppTheme.textSecondary,
              ),
              IconButton(
                onPressed: () {
                  _showDisconnectDialog(context, account);
                },
                icon: const Icon(Icons.delete_outline),
                color: AppTheme.dangerRed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showConnectAccountDialog(BuildContext context) {
    final brokerController = TextEditingController();
    final loginController = TextEditingController();
    final passwordController = TextEditingController();
    final serverController = TextEditingController();
    String selectedPlatform = 'MT5';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Connect Account',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPlatform,
                    dropdownColor: AppTheme.cardBackground,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Platform',
                    ),
                    items: ['MT4', 'MT5'].map((platform) {
                      return DropdownMenuItem(
                        value: platform,
                        child: Text(platform),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPlatform = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: brokerController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Broker (exness, xm, etc.)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: loginController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Account Number',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: serverController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Server',
                      hintText: 'Exness-MT5Trial',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AccountBloc>().add(ConnectAccount(
                        broker: brokerController.text,
                        login: loginController.text,
                        password: passwordController.text,
                        server: serverController.text,
                        platform: selectedPlatform,
                      ));
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Connect Account'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDisconnectDialog(BuildContext context, TradingAccountModel account) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text(
            'Disconnect Account',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: Text(
            'Are you sure you want to disconnect ${account.displayName}?',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AccountBloc>().add(DisconnectAccount(accountId: account.id));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerRed,
              ),
              child: const Text('Disconnect'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Accounts Connected',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect your trading account to start',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showConnectAccountDialog(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Connect Account'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Color _colorWithOpacity(Color color, double opacity) {
    return color.withValues(
      alpha: opacity,
    );
  }
}
