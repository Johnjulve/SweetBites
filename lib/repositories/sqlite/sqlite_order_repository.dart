import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../../database/database_helper.dart';
import '../../models/order.dart';
import '../../models/order_item.dart';
import '../order_repository.dart';

/// SQLite-backed implementation of [OrderRepository].
///
/// Order queries JOIN with the customers table to fetch `customer_name`,
/// and order-item queries JOIN with the products table to fetch
/// `product_name`, so the UI never needs a separate lookup.
class SqliteOrderRepository implements OrderRepository {
  final DatabaseHelper _dbHelper;

  SqliteOrderRepository(this._dbHelper);

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  @override
  Future<List<Order>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT o.*, c.name AS customer_name
      FROM ${AppConstants.tableOrders} o
      LEFT JOIN ${AppConstants.tableCustomers} c ON o.customer_id = c.id
      ORDER BY o.created_at DESC
    ''');

    return _hydrateOrders(db, maps);
  }

  @override
  Future<Order?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT o.*, c.name AS customer_name
      FROM ${AppConstants.tableOrders} o
      LEFT JOIN ${AppConstants.tableCustomers} c ON o.customer_id = c.id
      WHERE o.id = ?
      LIMIT 1
    ''', [id]);

    if (maps.isEmpty) return null;

    final orders = await _hydrateOrders(db, maps);
    return orders.first;
  }

  @override
  Future<List<Order>> getByStatus(OrderStatus status) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT o.*, c.name AS customer_name
      FROM ${AppConstants.tableOrders} o
      LEFT JOIN ${AppConstants.tableCustomers} c ON o.customer_id = c.id
      WHERE o.status = ?
      ORDER BY o.pickup_date ASC
    ''', [status.name]);

    return _hydrateOrders(db, maps);
  }

  @override
  Future<List<Order>> getByDate(DateTime date) async {
    final db = await _dbHelper.database;
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final maps = await db.rawQuery('''
      SELECT o.*, c.name AS customer_name
      FROM ${AppConstants.tableOrders} o
      LEFT JOIN ${AppConstants.tableCustomers} c ON o.customer_id = c.id
      WHERE o.pickup_date >= ? AND o.pickup_date < ?
      ORDER BY o.pickup_date ASC
    ''', [toDbString(dayStart), toDbString(dayEnd)]);

    return _hydrateOrders(db, maps);
  }

  @override
  Future<List<Order>> getRecent(int limit) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT o.*, c.name AS customer_name
      FROM ${AppConstants.tableOrders} o
      LEFT JOIN ${AppConstants.tableCustomers} c ON o.customer_id = c.id
      WHERE o.status != 'cancelled'
      ORDER BY o.created_at DESC
      LIMIT ?
    ''', [limit]);

    return _hydrateOrders(db, maps);
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  @override
  Future<void> insert(Order order) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Insert order header
      await txn.insert(
        AppConstants.tableOrders,
        order.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert each line item
      for (final item in order.items) {
        await txn.insert(
          AppConstants.tableOrderItems,
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<void> updateStatus(String id, OrderStatus status) async {
    final db = await _dbHelper.database;
    await db.update(
      AppConstants.tableOrders,
      {
        'status': status.name,
        'updated_at': toDbString(DateTime.now()),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Delete payments linked to this order
      await txn.delete(
        AppConstants.tablePayments,
        where: 'order_id = ?',
        whereArgs: [id],
      );
      // Delete order items
      await txn.delete(
        AppConstants.tableOrderItems,
        where: 'order_id = ?',
        whereArgs: [id],
      );
      // Delete the order itself
      await txn.delete(
        AppConstants.tableOrders,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Analytics
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> getDailySummary(DateTime date) async {
    final db = await _dbHelper.database;
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final startStr = toDbString(dayStart);
    final endStr = toDbString(dayEnd);

    // Total orders and revenue for the day
    final totalsResult = await db.rawQuery('''
      SELECT
        COUNT(*)          AS total_orders,
        COALESCE(SUM(total_amount), 0.0) AS total_revenue
      FROM ${AppConstants.tableOrders}
      WHERE pickup_date >= ? AND pickup_date < ? AND status != 'cancelled'
    ''', [startStr, endStr]);

    final totals = totalsResult.first;

    // Per-status counts
    final statusResult = await db.rawQuery('''
      SELECT status, COUNT(*) AS cnt
      FROM ${AppConstants.tableOrders}
      WHERE pickup_date >= ? AND pickup_date < ?
      GROUP BY status
    ''', [startStr, endStr]);

    final statusCounts = <String, int>{};
    for (final row in statusResult) {
      statusCounts[row['status'] as String] = row['cnt'] as int;
    }

    return {
      'totalOrders': totals['total_orders'] as int,
      'totalRevenue': (totals['total_revenue'] as num).toDouble(),
      'pendingCount': statusCounts[OrderStatus.pending.name] ?? 0,
      'bakingCount': statusCounts[OrderStatus.baking.name] ?? 0,
      'readyCount': statusCounts[OrderStatus.ready.name] ?? 0,
      'completedCount': statusCounts[OrderStatus.completed.name] ?? 0,
      'cancelledCount': statusCounts[OrderStatus.cancelled.name] ?? 0,
    };
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Fetch order items (with product names) for each order map and
  /// return fully hydrated [Order] objects.
  Future<List<Order>> _hydrateOrders(
    Database db,
    List<Map<String, dynamic>> orderMaps,
  ) async {
    final orders = <Order>[];

    for (final orderMap in orderMaps) {
      final orderId = orderMap['id'] as String;

      // Join order_items with products to get product_name
      final itemMaps = await db.rawQuery('''
        SELECT oi.*, p.name AS product_name
        FROM ${AppConstants.tableOrderItems} oi
        LEFT JOIN ${AppConstants.tableProducts} p ON oi.product_id = p.id
        WHERE oi.order_id = ?
        ORDER BY p.name ASC
      ''', [orderId]);

      final items = itemMaps.map((m) => OrderItem.fromMap(m)).toList();
      orders.add(Order.fromMap(orderMap, items: items));
    }

    return orders;
  }
}
