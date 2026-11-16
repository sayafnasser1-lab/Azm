import 'storage_web.dart' if (dart.library.io) 'storage_io.dart';

/// واجهة موحدة للتخزين المحلي تعمل على Windows و Android و iOS و Linux و macOS و Web
abstract class AzmStorageDriver {
  factory AzmStorageDriver() => createStorageDriver();

  Future<void> init();

  /// استعلام كل السجلات في جدول/مجموعة محددة
  Future<List<Map<String, dynamic>>> getAll(
    String table, {
    String? orderBy,
  });

  /// إدراج أو تحديث سجل عبر المفتاح الأساسي `id`
  Future<void> upsert(String table, Map<String, dynamic> data);

  /// حذف سجل عبر `id`
  Future<void> deleteById(String table, String id);

  /// استبدال جدول كامل (مفيد عند الاستيراد أو التصفير)
  Future<void> replaceAll(String table, List<Map<String, dynamic>> rows);

  /// حذف سجلات أقدم من تاريخ محدد حسب عمود زمني
  Future<int> deleteOlderThan(String table, String column, String isoCutoff);

  /// تفريغ كل الجداول
  Future<void> clearAll();
}
