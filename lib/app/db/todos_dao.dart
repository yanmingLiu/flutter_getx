import 'package:drift/drift.dart';
import 'package:getx_demo1/app/db/table_todo.dart';

import 'database.dart';

part 'todos_dao.g.dart'; // 生成的文件

@DriftAccessor(tables: [Todos])
class TodosDao extends DatabaseAccessor<Database> with _$TodosDaoMixin {
  final Database db;

  // 构造函数
  TodosDao(this.db) : super(db);

  // 查询所有 Todos
  Future<List<Todo>> getAllTodos() => select(todos).get();

  // 插入一个新的 Todo
  Future insertTodo(Insertable<Todo> todo) => into(todos).insert(todo);

  // 更新一个 Todo
  Future updateTodo(Insertable<Todo> todo) => update(todos).replace(todo);

  // 删除一个 Todo
  Future deleteTodo(Insertable<Todo> todo) => delete(todos).delete(todo);
}
