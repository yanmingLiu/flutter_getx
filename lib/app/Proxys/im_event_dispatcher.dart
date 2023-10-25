import 'package:getx_demo1/app/Proxys/im_proxy.dart';

class ImEventDispatcher implements ImDispatchEventListener {
  final List<ImDispatchEventListener> listeners = [];

  void appendListener(ImDispatchEventListener listener) {
    listeners.add(listener);
  }

  @override
  void onRoomMemberJoined(List<ZIMUserInfo> memberList, String roomID) {
    for (var listener in listeners) {
      listener.onRoomMemberJoined(memberList, roomID);
    }
  }

  @override
  void onRoomMemberLeft(List<ZIMUserInfo> memberList, String roomID) {
    for (var listener in listeners) {
      listener.onRoomMemberLeft(memberList, roomID);
    }
  }
}
