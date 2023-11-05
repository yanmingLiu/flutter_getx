
class Message {
  String? senderId;
  String? type;
  String? senderName;
  String? content;
  dynamic receiveIds;
  dynamic gift;

  Message({this.senderId, this.type, this.senderName, this.content, this.receiveIds, this.gift});

  Message.fromJson(Map<String, dynamic> json) {
    if(json["senderID"] is String) {
      senderId = json["senderID"];
    }
    if(json["type"] is String) {
      type = json["type"];
    }
    if(json["senderName"] is String) {
      senderName = json["senderName"];
    }
    if(json["content"] is String) {
      content = json["content"];
    }
    receiveIds = json["receiveIds"];
    gift = json["gift"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> _data = <String, dynamic>{};
    _data["senderID"] = senderId;
    _data["type"] = type;
    _data["senderName"] = senderName;
    _data["content"] = content;
    _data["receiveIds"] = receiveIds;
    _data["gift"] = gift;
    return _data;
  }
}