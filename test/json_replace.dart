import 'dart:io';

// 在终端中直接运行 main 方法：
/*
dart run /Users/ai3/Documents/ai_mi/test/text_replace.dart
*/
/// 入口方法
void main() {
  // 指定文件夹路径（你的开发机上的绝对路径）
  const String folderPath = '/Users/ai3/Documents/soul_talk/lib/domain/entities';
  // 调用替换方法
  replaceJsonModel(folderPath);

  // 替换 api path 中的字符串
  const String filePath = '/Users/ai3/Documents/soul_talk/lib/core/constants/api_values.dart';
  replaceApiPath(filePath);
}

/// 替换 api path 路径
void replaceApiPath(String filePath) {
  print('开始处理文件: $filePath');
  // 替换规则
  final Map<String, String> replacementMap = {
    "agjrdl": "message",
    "awgifq": "getGiftConf",
    "bisdvu": "aiChatConversation",
    "cpzpyv": "undressResult",
    "cquykf": "rechargeOrders",
    "dvqldr": "characters",
    "efjceu": "platformConfig",
    "epkeao": "translate",
    "eyosgp": "register",
    "fcikdb": "getClothingConf",
    "fjbcji": "getChatLevel",
    "fxyxix": "creationStyleOptions",
    "giirhf": "conversation",
    "gmayiz": "getUndressWithVideoResult",
    "hjkgdy": "subscriptionTransactions",
    "hlczsh": "getRecommendRole",
    "hmkdss": "unlock",
    "hwehyj": "selectGenImg",
    "ifgail": "noDress",
    "ixzgrc": "creationMoreDetails",
    "jgafkq": "lang",
    "jrsgbn": "getStyleConfig",
    "krxiil": "userProfile",
    "ktvpxp": "voices",
    "lekemu": "gems",
    "mxuhjo": "gift",
    "mzeuvf": "setChatBackground",
    "ncybai": "characterProfile",
    "nggfff": "roleplay",
    "pkhncc": "getUndressWith",
    "pwmaeq": "appUserReport",
    "seezlz": "subscription",
    "tdymub": "consumption",
    "uaucok": "creationCharacter",
    "vbpyqu": "getGenImg",
    "vswlrp": "editMsg",
    "warjaz": "getUndressWithVideo",
    "xalucl": "aiWrite",
    "xhjbuq": "appUser",
    "xlpilp": "undress",
    "xzjegp": "clothes",
    "zwtcwx": "getUndressWithResult",
  };

  // 判断文件是否存在
  final File file = File(filePath);
  if (!file.existsSync()) {
    print('文件不存在: $filePath');
    return;
  }
  print('文件存在，开始读取内容');

  String fileContent = file.readAsStringSync();
  String replacedContent = fileContent;

  // 遍历替换：只替换等号后单引号内的路径内容
  for (final entry in replacementMap.entries) {
    final String newPathSegment = entry.key; // 原路径中的片段（如register）
    final String oldPathSegment = entry.value; // 要替换成的片段（如auiasv）
    print('替换 $oldPathSegment 为 $newPathSegment');

    // 正则匹配规则：
    // 匹配 = 后面的单引号内容中包含 oldPathSegment 的部分
    // 只替换单引号内的目标片段，保留其他内容和变量名
    replacedContent = replacedContent.replaceAllMapped(
      RegExp(
        r'=.*?\'
                "'(.*?" +
            oldPathSegment +
            ".*?)'",
      ),
      (match) {
        // 按路径段替换，只替换被 / 包围的完整路径段
        String matchedContent = match.group(1)!;
        String replacedString = matchedContent.replaceAll(
          RegExp(r'(?<=^|/)' + RegExp.escape(oldPathSegment) + r'(?=/|$)'),
          newPathSegment,
        );
        return "= '$replacedString'";
      },
    );
  }

  file.writeAsStringSync(replacedContent);
  print('文件已成功替换: $filePath');
}

/// 替换 model
void replaceJsonModel(String folderPath) {
  // 替换规则
  final Map<String, String> replacementMap = {
    "ajhxtl": "cid",
    "alvxrt": "email",
    "ambvvr": "lora_model",
    "apczzs": "style",
    "axtqtf": "video_message",
    "bajhvg": "order_num",
    "bjhniu": "style_id",
    "bymrge": "voice_id",
    "cfilke": "shelving",
    "cgdmsn": "next_msgs",
    "ciuqkf": "scene",
    "cnvygg": "audit_status",
    "cofdjq": "generate_image",
    "dcwael": "receipt",
    "deneih": "generate_video",
    "dpinav": "chat_video_price",
    "dqmnkt": "target_language",
    "dyttyj": "visibility",
    "ehdsdf": "lora_strength",
    "ejbios": "upgrade",
    "emimrx": "ctype",
    "eutkqw": "order_type",
    "fdwojm": "update_time",
    "fkbqfv": "product_id",
    "gfpnej": "duration",
    "gndxwy": "chat_model",
    "gpjxyp": "subscription",
    "grxlno": "video_chat",
    "gsjlkw": "style_path",
    "gtxeuf": "text_message",
    "guotkz": "taskId",
    "gwjeli": "time_need",
    "gyqsos": "fileMd5",
    "hdsnxb": "media",
    "hdullo": "activate",
    "hepdit": "chat_audio_price",
    "hfrbkv": "greetings_voice",
    "hijrou": "create_img",
    "hmsqqm": "approved_character_id",
    "hmvjuo": "estimated_time",
    "hnejtx": "style_type",
    "hnffka": "prompt",
    "hyzxla": "nickname",
    "ibrklo": "gen_video",
    "ieuqhw": "translate_answer",
    "ifqsbr": "choose_env",
    "injjll": "amount",
    "ipjtkq": "deserved_gems",
    "iueqln": "enable_auto_translate",
    "iupbww": "device_id",
    "iwptry": "gen_photo",
    "jcyrfe": "gtype",
    "jdobsc": "thumbnail_url",
    "jgxtbn": "name",
    "jjiuit": "gen_img_id",
    "jpocex": "template_id",
    "jsbtpo": "age",
    "kaemhv": "character_video_chat",
    "klflop": "currency_code",
    "kmjhfp": "answer",
    "kokujr": "idfa",
    "kpndrk": "source_language",
    "kraode": "likes",
    "kumdyh": "token",
    "kvujjj": "nsfw",
    "lbnqan": "adid",
    "lhvieu": "gname",
    "ljxlvb": "creation_id",
    "lplemr": "nick_name",
    "luqlhc": "conversation_id",
    "lvszjf": "greetings",
    "lvyeja": "gen_photo_tags",
    "mkryiz": "chat_image_price",
    "mmxvyn": "conv_id",
    "mwtuxr": "translate_question",
    "nsyzwq": "about_me",
    "nszsqd": "gender",
    "ohvazp": "scene_change",
    "ojwetu": "hide_character",
    "oobrzq": "visual",
    "osokys": "lock_level_media",
    "osvkuj": "character_name",
    "owqiia": "msg_id",
    "owyzxc": "sign",
    "phvfef": "recharge_status",
    "pjahtu": "auto_translate",
    "pjjpxh": "report_type",
    "qfhccc": "voice_duration",
    "qfsgdo": "vip",
    "qguhno": "voice_url",
    "qhzagm": "question",
    "qiqyvn": "password",
    "qjmyyb": "value",
    "qpfisp": "unlock_card_num",
    "qphehp": "audit_time",
    "qstedu": "message",
    "qvkkhh": "engine",
    "rbzvir": "more_details",
    "retnon": "currency_symbol",
    "rjsvon": "characterId",
    "rmzxft": "call_ai_characters",
    "rpuogl": "source",
    "rukhgz": "user_id",
    "rvsgtm": "profile_change",
    "ryxwwx": "audio_message",
    "smiwpt": "signature",
    "ssdwpi": "result_path",
    "ssjrnx": "session_count",
    "stoggo": "model_id",
    "swarsy": "video_unlock",
    "sxxlzd": "price",
    "tfehuw": "last_message",
    "thpnrc": "profile_id",
    "tltzbg": "pay",
    "tukxgh": "describe_img",
    "turgnb": "tags",
    "ueonck": "create_video",
    "ufoqzj": "subscription_end",
    "uitvsd": "chat_model",
    "umqafe": "image_path",
    "upzmko": "photo_message",
    "usjfqu": "visual_style",
    "uxpnyz": "url",
    "vberqe": "key",
    "vctkwz": "undress_count",
    "vmjgnw": "free_message",
    "vmtiyi": "lora_path",
    "vnrzov": "gems",
    "vqoifz": "avatar",
    "whayht": "free_overrun",
    "wspelv": "price",
    "xbldvh": "character_id",
    "xezfdt": "original_transaction_id",
    "xlvofw": "rewards",
    "xnjsyl": "change_clothing",
    "xpqfmr": "chat",
    "yejipp": "lock_level",
    "yfvxif": "platform",
    "ylmsjk": "create_time",
    "ynewls": "card_num",
    "yqkfgr": "render_style",
    "zcbldz": "planned_msg_id",
    "zkugjr": "uid",
    "zmlxmv": "cname",
    "znicer": "app_user_chat_level",
    "zqdykz": "height",
    "zsbwgq": "transaction_id",
  };

  // 获取文件夹
  final Directory directory = Directory(folderPath);
  if (!directory.existsSync()) {
    print('文件夹不存在: $folderPath');
    return;
  }
  final List<FileSystemEntity> files = directory.listSync();

  for (final FileSystemEntity entity in files) {
    if (entity is File) {
      String fileContent = entity.readAsStringSync();

      // 使用简单的字符串替换来避免正则表达式格式化问题
      String replacedContent = fileContent;

      // 遍历所有需要替换的值
      for (final entry in replacementMap.entries) {
        final String oldKey = entry.key;
        final String newValue = entry.value;

        // 替换 JSON 对象中的键名: "key": value
        replacedContent = replacedContent.replaceAll(
          '"$newValue":',
          '"$oldKey":',
        );

        // 替换 JSON 访问: json['key'] 和 json["key"]
        replacedContent = replacedContent.replaceAll(
          "json['$newValue']",
          "json['$oldKey']",
        );
        replacedContent = replacedContent.replaceAll(
          'json["$newValue"]',
          'json["$oldKey"]',
        );

        // 替换 Map 字面量中的键名: 'key': value 和 "key": value
        replacedContent = replacedContent.replaceAll(
          "'$newValue':",
          "'$oldKey':",
        );
        replacedContent = replacedContent.replaceAll(
          '"$newValue":',
          '"$oldKey":',
        );
      }

      entity.writeAsStringSync(replacedContent);
      print('文件已成功替换: ${entity.path}');
    }
  }
}
