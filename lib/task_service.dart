import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TaskService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addTask(String userId, String title, String description, DateTime dueDate, String category, String priority) async {
    await _firestore.collection('users').doc(userId).collection('tasks').add({
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'completed': false,
      'category': category,
      'priority': priority,
    });
    notifyListeners();
  }

  Stream<QuerySnapshot> getTasks(String userId) {
    return _firestore.collection('users').doc(userId).collection('tasks').snapshots();
  }

  Future<void> updateTaskCompletion(String userId, String taskId, bool completed) async {
    await _firestore.collection('users').doc(userId).collection('tasks').doc(taskId).update({
      'completed': completed,
    });
    notifyListeners();
  }

  Future<void> updateTask(String userId, String taskId, String title, String description, bool completed) async {
    await _firestore.collection('users').doc(userId).collection('tasks').doc(taskId).update({
      'title': title,
      'description': description,
      'completed': completed,
    });
    notifyListeners();
  }

  Future<void> deleteTask(String userId, String taskId) async {
    await _firestore.collection('users').doc(userId).collection('tasks').doc(taskId).delete();
    notifyListeners();
  }
}