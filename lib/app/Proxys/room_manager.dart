import 'package:getx_demo1/app/Proxys/running_room_service.dart';

class RoomManager {
  RoomManager._internal();

  factory RoomManager() => _instance;

  static final RoomManager _instance = RoomManager._internal();

  // 在这里添加其他实例方法和属性

  RunningRoomService? runningRoomService;
}
