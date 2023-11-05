import 'dart:convert';

enum RoomMessageType {
  text,
  announcement,
  joined,
  gift,
  dropDownMic,
}

class Gift {
  String? id;
  String? name;
  String? price;
  String? icon;
  int? count;

  Gift({
    this.id,
    this.name,
    this.price,
    this.icon,
    this.count = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'icon': icon,
      'count': count,
    };
  }

  factory Gift.fromJson(Map<String, dynamic>? json) {
    return Gift(
      id: json?['id'],
      name: json?['name'],
      price: json?['price'],
      icon: json?['icon'],
      count: json?['count'] ?? 0,
    );
  }

  String toJsonString() {
    return json.encode(toJson());
  }

  factory Gift.fromJsonString(String jsonString) {
    return Gift.fromJson(json.decode(jsonString));
  }
}

class RoomMessage {
  String? content;
  String? senderID;
  String? senderName;
  List<String>? receiveIds;
  RoomMessageType? type;
  Gift? gift;

  RoomMessage({
    this.content,
    this.senderID,
    this.senderName,
    this.receiveIds,
    this.type = RoomMessageType.text,
    this.gift,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'senderID': senderID,
      'senderName': senderName,
      'receiveIds': receiveIds,
      'type': type?.toString().split('.').last, // converting enum to string
      'gift': gift != null ? gift!.toJson() : null,
    };
  }

  factory RoomMessage.fromJson(Map<String, dynamic>? json) {
    return RoomMessage(
      content: json?['content'],
      senderID: json?['senderID'],
      senderName: json?['senderName'],
      receiveIds: json?['receiveIds'] != null ? List<String>.from(json?['receiveIds']) : null,
      type: json?['type'] != null
          ? RoomMessageType.values.firstWhere(
              (e) => e.toString().split('.').last == json!['type'],
              orElse: () => RoomMessageType.text,
            )
          : RoomMessageType.text,
      gift: json?['gift'] != null ? Gift.fromJson(json!['gift']) : null,
    );
  }

  String toJsonString() {
    return json.encode(toJson());
  }

  factory RoomMessage.fromJsonString(String jsonString) {
    return RoomMessage.fromJson(json.decode(jsonString));
  }
}
