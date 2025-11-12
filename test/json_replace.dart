import 'dart:io';

// 在终端中直接运行 main 方法：
/*
dart run /Users/ai3/Documents/ai_mi/test/text_replace.dart
*/
/// 入口方法
void main() {
  // 指定文件夹路径（你的开发机上的绝对路径）
  const String folderPath = '/Users/ai3/Documents/ai_mi/lib/core/models';
  // 调用替换方法
  replaceJsonModel(folderPath);

  // 替换 api path 中的字符串
  const String filePath = '/Users/ai3/Documents/ai_mi/lib/core/api/api_url.dart';
  replaceApiPath(filePath);
}

/// 替换 api path 路径
void replaceApiPath(String filePath) {
  print('开始处理文件: $filePath');
  // 替换规则
  final Map<String, String> replacementMap = {
    "auiasv": "register",
    "bpzadf": "getClothingConf",
    "cplruh": "getUndressWithResult",
    "dkxzar": "roleplay",
    "elamdo": "creationCharacter",
    "feiqrr": "getStyleConfig",
    "fovfwt": "getChatLevel",
    "heibep": "unlock",
    "htpntv": "characterProfile",
    "ihijyx": "getUndressWith",
    "ipvylv": "noDress",
    "kbaprr": "creationMoreDetails",
    "kbmrtf": "gift",
    "kcxzvf": "getRecommendRole",
    "kuuqlg": "getUndressWithVideo",
    "lntmig": "userProfile",
    "mjdplh": "characters",
    "mtxktl": "setChatBackground",
    "nkjuvi": "translate",
    "nupyum": "subscriptionTransactions",
    "nwtzyx": "platformConfig",
    "nxvlvw": "consumption",
    "onitpm": "subscription",
    "oohfyv": "lang",
    "paroqs": "getGenImg",
    "pwxbyq": "creationStyleOptions",
    "srthpf": "clothes",
    "tbkzvc": "editMsg",
    "tukxny": "voices",
    "urytev": "appUser",
    "vbmowk": "rechargeOrders",
    "vtkspo": "aiWrite",
    "vuwjef": "aiChatConversation",
    "wkglrg": "getUndressWithVideoResult",
    "wlgaue": "appUserReport",
    "wuvuit": "gems",
    "xkcmfz": "getGiftConf",
    "xlofia": "undress",
    "xvvmfz": "message",
    "ygugnm": "undressResult",
    "zjmnio": "selectGenImg",
    "zudyte": "conversation",
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
        // 将匹配到的单引号内的内容中的旧片段替换为新片段
        return "= '${match.group(1)!.replaceAll(oldPathSegment, newPathSegment)}'";
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
    "abiegb": "prompt",
    "ahdtkf": "upgrade",
    "ahmngs": "render_style",
    "aqyqmn": "planned_msg_id",
    "azgvdo": "nickname",
    "azhukr": "pay",
    "azqhxe": "change_clothing",
    "azrlwm": "height",
    "bkthgw": "describe_img",
    "bmvnqw": "rewards",
    "ccqyzx": "gen_video",
    "cfqqqx": "lock_level",
    "cibejf": "create_time",
    "ctbuje": "original_transaction_id",
    "cuwczt": "undress_count",
    "cwnnug": "user_id",
    "dbqhwm": "platform",
    "djgsyg": "answer",
    "dkmeoy": "greetings_voice",
    "drqjdp": "tags",
    "dvmdrp": "lora_strength",
    "eeseds": "generate_image",
    "eisbfw": "style",
    "ewmggr": "free_message",
    "eylxzo": "style_id",
    "ezdtpr": "scene",
    "fagnhd": "visual",
    "fbgqpm": "signature",
    "fcvfgt": "profile_change",
    "felier": "lora_path",
    "fmgvzp": "more_details",
    "fvrryv": "free_overrun",
    "fwjrix": "likes",
    "gclrll": "estimated_time",
    "gdkpjk": "nick_name",
    "hfgimn": "vip",
    "hfpuwz": "media",
    "hggoux": "age",
    "ihfffs": "card_num",
    "ihtxjn": "character_video_chat",
    "iioadz": "target_language",
    "ikuxhi": "lock_level_media",
    "ivctax": "thumbnail_url",
    "ivphsr": "lora_model",
    "iyusiv": "price",
    "jblnjn": "ctype",
    "jggxqz": "shelving",
    "jglkfu": "duration",
    "jibpin": "chat_audio_price",
    "joiklg": "gen_photo_tags",
    "jonfmc": "order_num",
    "jpkoci": "key",
    "jqdolg": "gname",
    "jqnjtc": "approved_character_id",
    "juumge": "generate_video",
    "jwxdrt": "next_msgs",
    "kcfnlv": "photo_message",
    "kzpdsi": "gen_img_id",
    "latfnh": "voice_duration",
    "ldguwj": "audio_message",
    "lehkyr": "uid",
    "leifao": "fileMd5",
    "lhwapa": "transaction_id",
    "lkozuz": "adid",
    "lnqbqj": "text_message",
    "lpbcoo": "chat_model",
    "lrctzy": "device_id",
    "ltywka": "cid",
    "lvhdqn": "hide_character",
    "maduti": "value",
    "miuopf": "voice_url",
    "mklzcr": "conv_id",
    "mkokql": "product_id",
    "mpadvt": "gems",
    "mqpdfv": "greetings",
    "mtxwov": "enable_auto_translate",
    "mvjbjg": "question",
    "mxzqul": "character_name",
    "ndfbfw": "email",
    "necrdy": "characterId",
    "nflanf": "currency_symbol",
    "njhwuo": "about_me",
    "nodycg": "subscription",
    "nptokf": "currency_code",
    "nscrwv": "gtype",
    "nxeomn": "voice_id",
    "nxfjew": "chat_video_price",
    "oifgzg": "deserved_gems",
    "oifrzu": "engine",
    "okmhzu": "source",
    "oslbck": "auto_translate",
    "owvemr": "amount",
    "pffvsd": "audit_status",
    "pipprk": "style_path",
    "pynfci": "visibility",
    "pyzszl": "gen_photo",
    "quoeql": "conversation_id",
    "qwwpqe": "translate_answer",
    "rpiyxt": "call_ai_characters",
    "rsikyr": "report_type",
    "rwfohc": "video_chat",
    "rxjfel": "source_language",
    "sjxzof": "style_type",
    "spffna": "taskId",
    "susymt": "scene_change",
    "taxnqf": "message",
    "tkejoo": "gender",
    "trdbhb": "recharge_status",
    "trvlvs": "session_count",
    "tsknow": "sign",
    "tzhlug": "choose_env",
    "ubcutz": "chat_model",
    "ucpiof": "price",
    "ufempy": "activate",
    "ufrqzz": "update_time",
    "vbsuxy": "last_message",
    "vdgysp": "visual_style",
    "vksxcc": "url",
    "vkvbut": "unlock_card_num",
    "vnwddk": "template_id",
    "vocmhb": "password",
    "vokidn": "token",
    "vpvwqa": "profile_id",
    "vrodcv": "create_video",
    "vuyvdp": "msg_id",
    "vwfjrw": "subscription_end",
    "vxwwyi": "video_message",
    "wckpqy": "app_user_chat_level",
    "wfraur": "result_path",
    "wkbbmb": "model_id",
    "wmufkx": "receipt",
    "wrwhyp": "idfa",
    "xejpte": "time_need",
    "xetpre": "order_type",
    "xgjkfv": "creation_id",
    "xhnkrf": "translate_question",
    "xpxoug": "video_unlock",
    "xsxakq": "chat_image_price",
    "ydoqhw": "audit_time",
    "yhmzad": "name",
    "yionxh": "cname",
    "ykbpjg": "image_path",
    "ykxrou": "character_id",
    "yzwxcb": "create_img",
    "zfgybm": "chat",
    "zuhpdk": "avatar",
    "zzwvpc": "nsfw",
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
