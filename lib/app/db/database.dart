import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:getx_demo1/app/db/table_todo.dart';
import 'package:getx_demo1/app/db/todos_dao.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// 指定生成的文件 确保 database.dart 和生成的 database.g.dart 文件位于正确的路径，并且文件名拼写完全一致。手动创建database.g.dart
part 'database.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}

@DriftDatabase(
  tables: [Todos],
  daos: [TodosDao],
)
class Database extends _$Database {
  Database() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(todos, todos.description);
          }
        },
      );
}
