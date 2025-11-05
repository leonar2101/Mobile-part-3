import 'package:flutter/foundation.dart';
import 'package:stridelog/models/activity.dart';
import 'package:stridelog/services/database_service.dart';
import 'package:stridelog/controllers/auth_provider.dart';

class ActivityProvider with ChangeNotifier {
  final AuthProvider? _authProvider;
  String? get _userId => _authProvider?.currentUser?.id;

  ActivityProvider(this._authProvider) {
    if (_userId != null) {
      loadData();
    }
  }

  List<Activity> _activities = [];
  List<Activity> get activities => _activities;

  Map<String, dynamic> _statistics = {};
  Map<String, dynamic> get statistics => _statistics;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> loadData() async {
    if (_userId == null) return;
    _setLoading(true);

    _activities = await DatabaseService.getActivitiesByUser(_userId!);
    _statistics = await _calculateStatistics(_activities);

    _setLoading(false);
    notifyListeners();
  }

  Future<bool> addActivity(Activity activity) async {
    try {
      await DatabaseService.insertActivity(activity);
      await loadData();
      return true;
    } catch (e) {
      debugPrint('ActivityProvider.addActivity failed: $e');
      return false;
    }
  }

  Future<bool> deleteActivity(String id) async {
    try {
      await DatabaseService.deleteActivity(id);
      await loadData();
      return true;
    } catch (e) {
      debugPrint('ActivityProvider.deleteActivity failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _calculateStatistics(List<Activity> activities) async {
    if (activities.isEmpty) {
      return {
        'totalActivities': 0,
        'totalTime': 0,
        'totalDistance': 0.0,
        'totalCalories': 0,
        'averagePerWeek': 0.0,
      };
    }

    final totalTime = activities.fold(0, (sum, a) => sum + a.durationMinutes);
    final totalDistance = activities.fold(0.0, (sum, a) => sum + (a.distanceKm ?? 0));
    final totalCalories = activities.fold(0, (sum, a) => sum + (a.calories ?? 0));

    final oldest = activities.last.date;
    final weeks = DateTime.now().difference(oldest).inDays / 7;
    final avg = weeks > 0 ? activities.length / weeks : 0.0;

    return {
      'totalActivities': activities.length,
      'totalTime': totalTime,
      'totalDistance': totalDistance,
      'totalCalories': totalCalories,
      'averagePerWeek': avg,
    };
  }
}