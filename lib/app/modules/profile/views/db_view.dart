import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:getx_demo1/app/db/database.dart';

class DbView extends StatefulWidget {
  const DbView({super.key});

  @override
  State<DbView> createState() => _DbViewState();
}

class _DbViewState extends State<DbView> {
  final db = Database();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drift Demo'),
      ),
      body: FutureBuilder<List<Todo>>(
        future: db.todosDao.getAllTodos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Text('No todos yet!');
          }

          final todos = snapshot.data!;
          return ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return ListTile(
                title: Text(todo.title),
                trailing: Checkbox(
                  value: todo.completed,
                  onChanged: (value) async {
                    await db.todosDao.updateTodo(todo.copyWith(completed: value!));
                    setState(() {});
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTodo = TodosCompanion(
            title: Value(
              'New Todo ${DateTime.now()}',
            ),
            description: Value('New Todo ${DateTime.now()} - desc'),
          );
          await db.todosDao.insertTodo(newTodo);
          setState(() {});
        },
        tooltip: 'Add Todo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
