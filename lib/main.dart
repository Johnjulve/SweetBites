import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'database/database_helper.dart';
import 'repositories/customer_repository.dart';
import 'repositories/sqlite/sqlite_costing_profile_repository.dart';
import 'repositories/sqlite/sqlite_customer_repository.dart';
import 'repositories/sqlite/sqlite_inventory_repository.dart';
import 'repositories/sqlite/sqlite_order_repository.dart';
import 'repositories/sqlite/sqlite_payment_repository.dart';
import 'repositories/sqlite/sqlite_product_repository.dart';
import 'repositories/sqlite/sqlite_recipe_repository.dart';
import 'services/costing_service.dart';
import 'services/dashboard_service.dart';
import 'services/inventory_service.dart';
import 'services/order_service.dart';
import 'services/payment_service.dart';
import 'services/product_service.dart';
import 'services/theme_service.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized prior to async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database instance
  final dbHelper = DatabaseHelper.instance;
  // Trigger database creation and seed data execution eagerly at startup
  await dbHelper.database;

  // Instantiate SQLite repositories
  final customerRepo = SqliteCustomerRepository(dbHelper);
  final productRepo = SqliteProductRepository(dbHelper);
  final recipeRepo = SqliteRecipeRepository(dbHelper);
  final orderRepo = SqliteOrderRepository(dbHelper);
  final paymentRepo = SqlitePaymentRepository(dbHelper);
  final inventoryRepo = SqliteInventoryRepository(dbHelper);
  final costingProfileRepo = SqliteCostingProfileRepository(dbHelper);

  // Instantiate application business services
  final productService = ProductService(
    productRepo: productRepo,
    recipeRepo: recipeRepo,
  );
  final paymentService = PaymentService(
    paymentRepo: paymentRepo,
  );
  final orderService = OrderService(
    orderRepo: orderRepo,
    customerRepo: customerRepo,
  );
  final dashboardService = DashboardService(
    orderRepo: orderRepo,
    paymentRepo: paymentRepo,
  );
  final inventoryService = InventoryService(
    repository: inventoryRepo,
  );
  final costingService = CostingService(
    productRepo: productRepo,
    recipeRepo: recipeRepo,
    inventoryRepo: inventoryRepo,
    costingProfileRepo: costingProfileRepo,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<CustomerRepository>.value(
          value: customerRepo,
        ),
        ChangeNotifierProvider<ProductService>(
          create: (_) => productService..loadProducts(),
        ),
        ChangeNotifierProvider<PaymentService>(
          create: (_) => paymentService,
        ),
        ChangeNotifierProvider<OrderService>(
          create: (_) => orderService..loadOrders(),
        ),
        ChangeNotifierProvider<DashboardService>(
          create: (_) => dashboardService,
        ),
        ChangeNotifierProvider<InventoryService>(
          create: (_) => inventoryService..loadInventory(),
        ),
        ChangeNotifierProvider<CostingService>(
          create: (_) => costingService..loadCostings(),
        ),
        ChangeNotifierProvider<ThemeService>(
          create: (_) => ThemeService(),
        ),
      ],
      child: const SweetBitesApp(),
    ),
  );
}
