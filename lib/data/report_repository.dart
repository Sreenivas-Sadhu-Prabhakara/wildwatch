import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/report.dart';

/// Local-only store for reports. There is no backend — this is the system of
/// record on the device. Reports survive restarts so the offline queue and the
/// "My reports" history work without connectivity.
///
/// Backed by [SharedPreferences] (a single JSON blob) which keeps it portable
/// across Android, iOS and web. Notifies listeners so the UI rebuilds on any
/// change.
class ReportRepository extends ChangeNotifier {
  ReportRepository._();

  /// Singleton — one source of truth shared across screens.
  static final ReportRepository instance = ReportRepository._();

  static const _storageKey = 'wildwatch.reports.v1';

  final List<Report> _reports = [];
  bool _loaded = false;

  /// All reports, newest first.
  List<Report> get all {
    final copy = List<Report>.from(_reports);
    copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy;
  }

  /// Reports waiting to be (re)sent.
  List<Report> get queued =>
      _reports.where((r) => r.status == ReportStatus.queued).toList();

  Report? byId(String id) {
    for (final r in _reports) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _reports
          ..clear()
          ..addAll(
            list.map((e) => Report.fromJson(e as Map<String, dynamic>)),
          );
      } catch (e) {
        debugPrint('WildWatch: failed to load reports: $e');
      }
    }
    _loaded = true;
    notifyListeners();
  }

  /// Insert or update a report, then persist.
  Future<void> save(Report report) async {
    final i = _reports.indexWhere((r) => r.id == report.id);
    if (i >= 0) {
      _reports[i] = report;
    } else {
      _reports.add(report);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _reports.removeWhere((r) => r.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_reports.map((r) => r.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
}
