/// 单句歌词模型。
///
/// 存储一句歌词及其时间戳（毫秒），以及针对日语文本生成的注音/释义信息。
/// 点击歌词重唱、逐行高亮都依赖 [startMs] 来定位。
class LyricLine {
  /// 该句起始时间，单位毫秒（LRC 中的 [mm:ss.xx] 解析而来）。
  final int startMs;

  /// 歌词原文文本（去除时间标签后的纯文本）。
  final String text;

  /// 是否为纯注音/翻译行（如 LRC 中常见的原文+假名双行），
  /// 这里保留扩展位，默认 false。
  final bool isMeta;

  /// 日语注释结果：每个字符/词素及其注音与释义。
  /// 当 [text] 不是日语或用户未开启注音时为空。
  final List<RubyAnnotation>? annotations;

  const LyricLine({
    required this.startMs,
    required this.text,
    this.isMeta = false,
    this.annotations,
  });

  /// 该句是否包含（活动高亮）某个播放时间点。
  bool contains(int ms) => ms >= startMs;

  /// 判断此句是否有需要显示的日语注音。
  bool get hasRuby => annotations != null && annotations!.isNotEmpty;

  /// 是否为日文文本（包含假名或日文汉字）。
  bool get isJapanese {
    for (final c in text.runes) {
      if (c >= 0x3040 && c <= 0x30FF) return true; // 平假名/片假名
      if (c >= 0x4E00 && c <= 0x9FFF) return true; // 汉字
    }
    return false;
  }

  factory LyricLine.fromJson(Map<String, dynamic> json) => LyricLine(
        startMs: json['startMs'] as int,
        text: json['text'] as String,
        isMeta: json['isMeta'] as bool? ?? false,
        annotations: (json['annotations'] as List?)
            ?.map((e) => RubyAnnotation.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'startMs': startMs,
        'text': text,
        'isMeta': isMeta,
        'annotations': annotations?.map((e) => e.toJson()).toList(),
      };
}

/// 单个日语字/词的注音与释义。
class RubyAnnotation {
  /// 原文片段，如「読」。
  final String surface;

  /// 该片段对应的读音（平假名），如「よ」。
  final String reading;

  /// 释义（中文），如「读」，可为空。
  final String? meaning;

  const RubyAnnotation({
    required this.surface,
    required this.reading,
    this.meaning,
  });

  /// 是否为汉字（需要注音的对象）。假名本身无需注音。
  bool get isKanji => surface.codeUnits.any(_isKanjiCode);

  factory RubyAnnotation.fromJson(Map<String, dynamic> json) =>
      RubyAnnotation(
        surface: json['surface'] as String,
        reading: json['reading'] as String,
        meaning: json['meaning'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'surface': surface,
        'reading': reading,
        'meaning': meaning,
      };

  static bool _isKanjiCode(int code) =>
      (code >= 0x4E00 && code <= 0x9FFF) || // CJK 统一表意文字
      (code >= 0x3400 && code <= 0x4DBF); // CJK 扩展 A
}