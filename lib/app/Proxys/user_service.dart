import 'package:getx_demo1/app/Proxys/im_proxy.dart';

class UserService implements ImDispatchEventListener {
  @override
  void onRoomMemberJoined(List<ZIMUserInfo> memberList, String roomID) {
    // TODO: implement onRoomMemberJoined
  }

  @override
  void onRoomMemberLeft(List<ZIMUserInfo> memberList, String roomID) {
    // TODO: implement onRoomMemberLeft
  }
}
