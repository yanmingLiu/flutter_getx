/// RTC Proxy

class ZegoStream {}

abstract class RTCCnctListener {
  /// 房间断开
  void onRtcRoomDisconnected;

  /// 房间重连中
  void onRtcRoomReconnecting;

  /// 房间已重连
  void onRtcRoomReconnected;

  /// 相同账号登录被踢出房间
  void onRtcRoomKickout;
}

abstract class RtcStreamEventListener {
  void onRtcAddStream(ZegoStream stream);
  void onRtcRemoveStream(ZegoStream stream);
  void onRtcStreamSoundLevelUpdate({String streamID, double soundLevel});
  void onRtcStreamCapturedSoundLevelUpdate(double soundLevel);
  void onRtcStreamRemoteMicUpdate({String streamID, bool micOn});
  void onRtcMixStreamSoundLevelUpdate(Map<int, double> soundLevels);
  void onRtcLocalMicStateUpdate(bool micOn);
}
