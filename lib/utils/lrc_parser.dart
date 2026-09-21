import '../models/lyric_line.dart';

/// LRC 歌词解析器。
///
/// 支持 LRC 标准格式：
/// - `[mm:ss.xx]` 逐行时间标签（支持一行多个时间标签，如 `[00:12.34][01:02.03]歌词`）
/// - `[ar:歌手]` `[ti:标题]` 等元信息标签（被识别并忽略/收集）
/// - 无时间戳的纯文本行（作为普通行保留）
class LrcParser {
  /// 解析 LRC 文本（原始字符串），返回按时间排序的歌词行列表。
  static List<LyricLine> parse(String lrcText) {
    final lines = <LyricLine>[];
    final linesByTime = <LyricLine>[];
    final plainLines = <String>[];

    final regTime = RegExp(r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]');
    final regMeta = RegExp(r'^\[(ar|ti|al|by|offset|re|ve):(.+)\]$');

    for (final rawLine in lrcText.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // 跳过纯元信息行
      if (regMeta.hasMatch(line)) continue;

      // 提取所有时间标签
      final timeMatches = regTime.allMatches(line).toList();
      final text = line.replaceAll(regTime, '').trim();

      if (timeMatches.isEmpty) {
        // 无时间戳的行：保留原文（可能是翻译、注音等）
        if (text.isNotEmpty) {
          plainLines.add(text);
        }
        continue;
      }

      // 一行可有多个时间标签，展开为多行（时间不同、文本相同）
      for (final m in timeMatches) {
        final minutes = int.parse(m.group(1)!);
        final seconds = int.parse(m.group(2)!);
        final fracStr = m.group(3) ?? '0';
        // 处理不同精度的小数：.5 表示 500ms，.50 表示 500ms，.500 表示 500ms
        final frac = _parseFraction(fracStr);
        final ms = (minutes * 60 + seconds) * 1000 + frac;

        if (text.isEmpty) continue;
        linesByTime.add(LyricLine(startMs: ms, text: text));
      }
    }

    // 按时间排序
    linesByTime.sort((a, b) => a.startMs.compareTo(b.startMs));
    lines.addAll(linesByTime);

    return lines;
  }

  /// 解析小数部分（.xx 或 .xxx），归一化为毫秒。
  static int _parseFraction(String s) {
    if (s.isEmpty) return 0;
    // LRC 常见两位小数（百分之一秒）或三位（千分之一秒）
    if (s.length == 1) return int.parse(s) * 100; // .5 -> 500ms
    if (s.length == 2) return int.parse(s) * 10; // .50 -> 500ms
    final v = int.parse(s.substring(0, 3));
    if (s.length >= 3) return v; // .500 -> 500ms
    return v;
  }

  /// 解析 LRC 元信息（标题、歌手等），返回 map。
  static Map<String, String> parseMetadata(String lrcText) {
    final result = <String, String>{};
    final regMeta = RegExp(r'^\[(ar|ti|al|by|offset|re|ve):(.+)\]$',
        multiLine: true);
    for (final m in regMeta.allMatches(lrcText)) {
      final key = m.group(1)!;
      final value = m.group(2)!.trim();
      result[key] = value;
    }
    return result;
  }
}