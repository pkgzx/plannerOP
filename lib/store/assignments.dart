import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:plannerop/core/model/assignment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AssignmentsProvider extends ChangeNotifier {
  List<Assignment> _assignments = [];
  bool _isLoading = false;

  List<Assignment> get assignments => _assignments;
  bool get isLoading => _isLoading;

  List<Assignment> get pendingAssignments =>
      _assignments.where((a) => a.status == 'pending').toList();

  List<Assignment> get inProgressAssignments =>
      _assignments.where((a) => a.status == 'in_progress').toList();

  List<Assignment> get completedAssignments =>
      _assignments.where((a) => a.status == 'completed').toList();

  AssignmentsProvider() {
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final assignmentsJson = prefs.getString('assignments');

      if (assignmentsJson != null) {
        final List<dynamic> decodedList = json.decode(assignmentsJson);
        _assignments =
            decodedList.map((item) => Assignment.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading assignments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveAssignments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final assignmentsJson = json.encode(
          _assignments.map((assignment) => assignment.toJson()).toList());
      await prefs.setString('assignments', assignmentsJson);
    } catch (e) {
      debugPrint('Error saving assignments: $e');
    }
  }

  Future<void> addAssignment({
    required List<Map<String, dynamic>> workers,
    required String area,
    required String task,
    required DateTime date,
    required String time,
  }) async {
    final uuid = const Uuid();
    final newAssignment = Assignment(
      id: uuid.v4(),
      workers: workers,
      area: area,
      task: task,
      date: date,
      time: time,
      endTime: 'No ha finalizado',
    );

    _assignments.add(newAssignment);
    await _saveAssignments();
    notifyListeners();
  }

  Future<void> updateAssignmentStatus(String id, String status) async {
    final index = _assignments.indexWhere((a) => a.id == id);
    if (index >= 0) {
      _assignments[index].status = status;

      if (status == 'completed') {
        _assignments[index].completedDate = DateTime.now();
      }

      await _saveAssignments();
      notifyListeners();
    }
  }

  Future<void> updateAssignmentEndTime(String id, String endTime) async {
    final index = _assignments.indexWhere((a) => a.id == id);
    if (index >= 0) {
      _assignments[index].endTime = endTime;
      await _saveAssignments();
      notifyListeners();
    }
  }

  Future<void> deleteAssignment(String id) async {
    _assignments.removeWhere((a) => a.id == id);
    await _saveAssignments();
    notifyListeners();
  }

  Assignment? getAssignmentById(String id) {
    try {
      return _assignments.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }
}
