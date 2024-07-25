import 'package:drift/drift.dart';

class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 50)();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  TextColumn get description => text().nullable()(); // 新添加的字段
}
