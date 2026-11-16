import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_driver.dart';

/// محرك تخزين للويب (والمتصفحات) يعتمد على SharedPreferences بدون أي dart:io أو dart:ffi
class _WebStorageDriver implements AzmStorageDriver {
  static const _prefix = 'azm_ai_v2_tbl_';
  SharedPreferences? _prefs;

  @override
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _store async {
    await init();
    return _prefs!;
  }

  List<Map<String, dynamic>> _readRaw(SharedPreferences prefs, String table) {
    final raw = prefs.getString('$_prefix$table');
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <Map<String, dynamic>>[];
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> _writeRaw(
    SharedPreferences prefs,
    String table,
    List<Map<String, dynamic>> rows,
  ) async {
    await prefs.setString('$_prefix$table', jsonEncode(rows));
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(
    String table, {
    String? orderBy,
  }) async {
    final prefs = await _store;
    final rows = _readRaw(prefs, table);
    if (orderBy != null && orderBy.isNotEmpty) {
      final parts = orderBy.trim().split(RegExp(r'\s+'));
      final col = parts.first;
      final desc = parts.length > 1 && parts[1].toUpperCase() == 'DESC';
      rows.sort((a, b) {
        final av = (a[col] ?? '').toString();
        final bv = (b[col] ?? '').toString();
        return desc ? bv.compareTo(av) : av.compareTo(bv);
      });
    }
    return rows;
  }

  @override
  Future<void> upsert(String table, Map<String, dynamic> data) async {
    final prefs = await _store;
    final rows = _readRaw(prefs, table);
    final id = data['id']?.toString();
    if (id != null) {
      final idx = rows.indexWhere((r) => r['id']?.toString() == id);
      if (idx >= 0) {
        rows[idx] = Map<String, dynamic>.from(data);
      } else {
        rows.add(Map<String, dynamic>.from(data));
      }
    } else {
      rows.add(Map<String, dynamic>.from(data));
    }
    await _writeRaw(prefs, table, rows);
  }

  @override
  Future<void> deleteById(String table, String id) async {
    final prefs = await _store;
    final rows = _readRaw(prefs, table)
      ..removeWhere((r) => r['id']?.toString() == id);
    await _writeRaw(prefs, table, rows);
  }

  @override
  Future<void> replaceAll(String table, List<Map<String, dynamic>> rows) async {
    final prefs = await _store;
    await _writeRaw(
      prefs,
      table,
      rows.map((e) => Map<String, dynamic>.from(e)).toList(),
    );
  }

  @override
  Future<int> deleteOlderThan(
    String table,
    String column,
    String isoCutoff,
  ) async {
    final prefs = await _store;
    final rows = _readRaw(prefs, table);
    final before = rows.length;
    rows.removeWhere((r) {
      final v = r[column]?.toString();
      if (v == null || v.isEmpty) return false;
      return v.compareTo(isoCutoff) < 0;
    });
    await _writeRaw(prefs, table, rows);
    return before - rows.length;
  }

  @override
  Future<void> clearAll() async {
    final prefs = await _store;
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}

AzmStorageDriver createStorageDriver() => _WebStorageDriver();
