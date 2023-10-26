abstract class ImCnctListener {
  /// IM 正进行房间重连
  void onImRoomReconnecting;

  /// IM 已完成房间重连
  void onImRoomReconnected;

  /// IM 已断开与房间的连接
  void onImRoomDisconnected;

  /// 被踢出
  void onImRoomKickedOut;

  /// 房间销毁
  void onImRoomClosed;
}

abstract class RoomAttributesListener {
  /// 接收到房间属性更新通知
  void onRoomAttributesUpdated(Map<String, String> attributes);
}

abstract class InvitationListener {
  /// 被邀请者收到的呼叫邀请的通知回调。
  void onCallInvitationReceived(String info, String callID);

  /// 邀请者收到的接受邀请的通知回调。
  void onCallInvitationAccepted(String info);

  /// 邀请者收到的被邀请者拒绝邀请的通知回调。
  void onCallInvitationRejected(String info);

  /// 被邀请者的呼叫邀请超时的通知回调 || 邀请者呼叫邀请超时的通知回调。
  void onCallInvitationTimeout(String callID);
}

// TODO: Delegate
class ZIMUserInfo {}

abstract class ImDispatchEventListener {
  /// 其他成员加入房间的回调。
  void onRoomMemberJoined(List<ZIMUserInfo> memberList, String roomID);

  /// 其他成员离开房间的回调。
  void onRoomMemberLeft(List<ZIMUserInfo> memberList, String roomID);
}
