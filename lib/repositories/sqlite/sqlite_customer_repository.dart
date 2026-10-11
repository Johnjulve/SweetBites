import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';
import '../../database/database_helper.dart';
import '../../models/customer.dart';
import '../customer_repository.dart';

/// SQLite-backed implementation of [CustomerRepository].
class SqliteCustomerRepository implements CustomerRepository {
  final DatabaseHelper _dbHelper;

  SqliteCustomerRepository(this._dbHelper);

  @override
  Future<List<Customer>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.tableCustomers,
      orderBy: 'name ASC',
    );
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  @override
  Future<Customer?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.tableCustomers,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  @override
  Future<List<Customer>> search(String query) async {
    final db = await _dbHelper.database;
    final pattern = '%$query%';
    final maps = await db.query(
      AppConstants.tableCustomers,
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: [pattern, pattern],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  @override
  Future<void> insert(Customer customer) async {
    final db = await _dbHelper.database;
    await db.insert(
      AppConstants.tableCustomers,
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> update(Customer customer) async {
    final db = await _dbHelper.database;
    await db.update(
      AppConstants.tableCustomers,
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      AppConstants.tableCustomers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomersWithOrderCount() async {
    final db = await _dbHelper.database;
    return db.rawQuery('''
      SELECT c.id, c.name, c.phone, c.created_at, COUNT(o.id) AS order_count
      FROM ${AppConstants.tableCustomers} c
      LEFT JOIN ${AppConstants.tableOrders} o ON c.id = o.customer_id
      GROUP BY c.id
      ORDER BY c.name ASC
    ''');
  }
}
