import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'screens/screens.dart';
import 'services/dashboard_service.dart';
import 'services/order_service.dart';
import 'services/theme_service.dart';

/// The root application configuration widget containing routing and themes.
class SweetBitesApp extends StatelessWidget {
  const SweetBitesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();

    return MaterialApp(
      title: 'SweetBites',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.themeMode,
      debugShowCheckedModeBanner: false,
      home: const MainNavigation(),
      routes: {
        '/create-order': (context) => const CreateOrderScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/customers': (context) => const CustomerManagementScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/order-detail') {
          final orderId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => OrderDetailScreen(orderId: orderId),
            settings: settings,
          );
        }
        if (settings.name == '/receipt') {
          final orderId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => ReceiptPreviewScreen(orderId: orderId),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}

/// The bottom navigation shell wrapping the main tabs (Dashboard, Orders, Products).
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(
        onSwitchTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      const OrderListScreen(),
      const ProductManagementScreen(),
      const InventoryScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 0) {
              context.read<DashboardService>().loadDashboard();
            } else if (index == 1) {
              context.read<OrderService>().loadOrders();
            }
          },
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurfaceVariant.withValues(
            alpha: 0.6,
          ),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.cake_outlined),
              activeIcon: Icon(Icons.cake),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Inventory',
            ),
          ],
        ),
      ),
    );
  }
}
