class RoomManager {
  static RoomManager _instance;

  factory RoomManager() {
    _instance ??= RoomManager._internal();
    return _instance;
  }

  RoomManager._internal();

  // 在这里添加其他实例方法和属性
}
