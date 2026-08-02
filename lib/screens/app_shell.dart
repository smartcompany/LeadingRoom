import 'package:flutter/material.dart';
import 'package:leading_room/l10n/app_localizations.dart';
import 'package:leading_room/screens/home_tabs.dart';
import 'package:leading_room/screens/login_screen.dart';
import 'package:leading_room/services/auth_service.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var _index = 0;
  var _guest = false;
  String _tier = 'free';

  @override
  void initState() {
    super.initState();
    _refreshTier();
    AuthService.shared.onAuthStateChange.listen((_) {
      _refreshTier();
      if (mounted) setState(() {});
    });
  }

  Future<void> _refreshTier() async {
    final tier = await AuthService.shared.currentTier();
    if (mounted) setState(() => _tier = tier);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = AuthService.shared.session;

    if (session == null && !_guest) {
      return LoginScreen(onGuest: () => setState(() => _guest = true));
    }

    final pages = [
      SignalsScreen(tier: _tier),
      MarketsScreen(tier: _tier),
      const PerformanceScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          if (session != null)
            IconButton(
              tooltip: l10n.signOut,
              onPressed: () async {
                await AuthService.shared.signOut();
                setState(() => _guest = false);
              },
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.bolt_outlined),
            selectedIcon: const Icon(Icons.bolt),
            label: l10n.tabSignals,
          ),
          NavigationDestination(
            icon: const Icon(Icons.candlestick_chart_outlined),
            selectedIcon: const Icon(Icons.candlestick_chart),
            label: l10n.tabMarkets,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: l10n.tabPerformance,
          ),
        ],
      ),
    );
  }
}
