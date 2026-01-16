import 'dart:convert';

class MUser {
  String? id;
  String? deviceId;
  String? token;
  String? platform;
  int? gems;
  dynamic audioSwitch;
  dynamic subscriptionEnd;
  String? nickname;
  String? idfa;
  String? adid;
  String? androidId;
  String? gpsAdid;
  bool? autoTranslate;
  bool? enableAutoTranslate;
  String? sourceLanguage;
  String? targetLanguage;
  int createImg;
  int createVideo;

  MUser({
    this.id,
    this.deviceId,
    this.token,
    this.platform,
    this.gems,
    this.audioSwitch,
    this.subscriptionEnd,
    this.nickname,
    this.idfa,
    this.adid,
    this.androidId,
    this.gpsAdid,
    this.autoTranslate,
    this.enableAutoTranslate,
    this.sourceLanguage,
    this.targetLanguage,
    this.createImg = 0,
    this.createVideo = 0,
  });

  factory MUser.fromRawJson(String str) => MUser.fromJson(json.decode(str));
  String toRawJson() => json.encode(toJson());

  factory MUser.fromJson(Map<String, dynamic> json) => MUser(
    id: json["id"],
    deviceId: json["device_id"],
    token: json["token"],
    platform: json["platform"],
    gems: json["gems"],
    audioSwitch: json["audio_switch"],
    subscriptionEnd: json["subscription_end"],
    nickname: json["nickname"],
    idfa: json["idfa"],
    adid: json["adid"],
    androidId: json["android_id"],
    gpsAdid: json["gps_adid"],
    autoTranslate: json["auto_translate"],
    enableAutoTranslate: json["enable_auto_translate"],
    sourceLanguage: json["source_language"],
    targetLanguage: json["target_language"],
    createImg: json["create_img"] ?? 0,
    createVideo: json["create_video"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "device_id": deviceId,
    "token": token,
    "platform": platform,
    "gems": gems,
    "audio_switch": audioSwitch,
    "subscription_end": subscriptionEnd,
    "nickname": nickname,
    "idfa": idfa,
    "adid": adid,
    "android_id": androidId,
    "gps_adid": gpsAdid,
    "auto_translate": autoTranslate,
    "enable_auto_translate": enableAutoTranslate,
    "source_language": sourceLanguage,
    "target_language": targetLanguage,
    "create_img": createImg,
    "create_video": createVideo,
  };
}
