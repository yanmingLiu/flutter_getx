import 'package:getx_demo1/app/Proxys/data/room_info.dart';
import 'package:getx_demo1/app/Proxys/data/room_user.dart';
import 'package:getx_demo1/app/Proxys/data/seat.dart';
import 'package:getx_demo1/app/Proxys/im_manager.dart';
import 'package:getx_demo1/app/Proxys/invite_service.dart';
import 'package:getx_demo1/app/Proxys/sdk_cnct_service.dart';
import 'package:getx_demo1/app/Proxys/seat_service.dart';
import 'package:getx_demo1/app/Proxys/stream_service.dart';
import 'package:getx_demo1/app/Proxys/user_service.dart';

abstract class RunningRoomEventListener {
  /// 房间断开回调
  void onRoomDisconnected;

  /// 房间正在重连回调
  void onRoomReconnecting;

  /// 房间已重连回调
  void onRoomReconnected;

  /// 被踢出房间
  void onRoomKickout;

  void onRoomClosed;

  void onSeatListUpdate(List<Seat> seatList);
  void onRoomUserCountUpdate(int count);
  void onAwaringMySelf(RoomUser myself);
  void onSoundLevelUpdate({double value, int seatIndex});
}

class RunningRoomService {
  final RunningRoomEventListener listener;

  RunningRoomService(this.listener);

  late RoomInfo roomInfo;
  late UserService userService = UserService();
  late StreamService streamService;
  late SDKCnctService roomCnctService;
  late InviteService inviteService;
  late SeatService seatService;

  void start() {
    IMManager().eventDispatcher.appendListener(userService);
  }

  void stop() {}
}
