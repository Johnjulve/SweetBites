import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../../database/database_helper.dart';
import '../../models/payment.dart';
import '../payment_repository.dart';

/// SQLite-backed implementation of [PaymentRepository].
class SqlitePaymentRepository implements PaymentRepository {
  final DatabaseHelper _dbHelper;

  SqlitePaymentRepository(this._dbHelper);

  @override
  Future<List<Payment>> getByOrderId(String orderId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.tablePayments,
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'paid_at ASC',
    );
    return maps.map((m) => Payment.fromMap(m)).toList();
  }

  @override
  Future<void> insert(Payment payment) async {
    final db = await _dbHelper.database;
    await db.insert(
      AppConstants.tablePayments,
      payment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      AppConstants.tablePayments,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<double> getTotalPaidForOrder(String orderId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount_paid), 0.0) AS total
      FROM ${AppConstants.tablePayments}
      WHERE order_id = ? AND is_voided = 0
    ''', [orderId]);

    return (result.first['total'] as num).toDouble();
  }

  @override
  Future<double> getRevenueForDate(DateTime date) async {
    final db = await _dbHelper.database;
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount_paid), 0.0) AS total
      FROM ${AppConstants.tablePayments}
      WHERE paid_at >= ? AND paid_at < ? AND is_voided = 0
    ''', [toDbString(dayStart), toDbString(dayEnd)]);

    return (result.first['total'] as num).toDouble();
  }

  @override
  Future<void> voidPaymentsForOrder(String orderId) async {
    final db = await _dbHelper.database;
    await db.update(
      AppConstants.tablePayments,
      {'is_voided': 1},
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }

  @override
  Future<void> voidPayment(String paymentId) async {
    final db = await _dbHelper.database;
    await db.update(
      AppConstants.tablePayments,
      {'is_voided': 1},
      where: 'id = ?',
      whereArgs: [paymentId],
    );
  }
}
