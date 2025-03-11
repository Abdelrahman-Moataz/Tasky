import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../task_service.dart';
import 'add_task_screen.dart';
import 'edit_task_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(_fabController);
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskService = Provider.of<TaskService>(context);
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: taskService.getTasks(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final tasks = snapshot.data!.docs;

          return AnimatedList(
            key: _listKey,
            initialItemCount: tasks.length,
            itemBuilder: (context, index, animation) {
              final task = tasks[index];
              return _buildTaskItem(task, animation, taskService, userId, tasks);
            },
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddTaskScreen()),
            ).then((_) {
              // Refresh the list after adding a task
              setState(() {});
            });
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTaskItem(
      DocumentSnapshot task,
      Animation<double> animation,
      TaskService taskService,
      String userId,
      List<DocumentSnapshot> tasks, // Pass the tasks list here
      ) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        await taskService.deleteTask(userId, task.id);
        _listKey.currentState!.removeItem(
          tasks.indexOf(task),
              (context, animation) => _buildTaskItem(task, animation, taskService, userId, tasks),
        );
      },
      child: SizeTransition(
        sizeFactor: animation,
        child: Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text(
              task['title'],
              style: task['completed']
                  ? TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
            subtitle: Text(task['description']),
            trailing: Checkbox(
              value: task['completed'],
              onChanged: (value) {
                taskService.updateTaskCompletion(userId, task.id, value!);
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditTaskScreen(
                    taskId: task.id,
                    title: task['title'],
                    description: task['description'],
                    completed: task['completed'],
                  ),
                ),
              ).then((_) {
                // Refresh the list after editing a task
                setState(() {});
              });
            },
          ),
        ),
      ),
    );
  }
}