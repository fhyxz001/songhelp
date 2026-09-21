import 'package:flutter_test/flutter_test.dart';
import 'package:songhelp/utils/lrc_parser.dart';
import 'package:songhelp/services/japanese_annotator.dart';

void main() {
  group('LrcParser', () {
    test('解析标准时间标签', () {
      const lrc = '[00:10.50]第一句\n[00:20.00]第二句';
      final lines = LrcParser.parse(lrc);
      expect(lines.length, 2);
      expect(lines[0].startMs, 10500);
      expect(lines[0].text, '第一句');
      expect(lines[1].startMs, 20000);
      expect(lines[1].text, '第二句');
    });

    test('忽略元信息行', () {
      const lrc = '[ti:标题]\n[ar:歌手]\n[00:05.00]歌词';
      final lines = LrcParser.parse(lrc);
      expect(lines.length, 1);
      expect(lines[0].text, '歌词');
    });

    test('一行多时间标签', () {
      const lrc = '[00:10.00][01:00.00]重复句';
      final lines = LrcParser.parse(lrc);
      expect(lines.length, 2);
      expect(lines[0].startMs, 10000);
      expect(lines[1].startMs, 60000);
    });

    test('按时间排序', () {
      const lrc = '[00:30.00]晚\n[00:10.00]早';
      final lines = LrcParser.parse(lrc);
      expect(lines[0].text, '早');
      expect(lines[1].text, '晚');
    });
  });

  group('JapaneseAnnotator', () {
    test('识别日文', () {
      expect(JapaneseAnnotator.instance.isJapanese('読む'), true);
      expect(JapaneseAnnotator.instance.isJapanese('hello'), false);
    });

    test('多字词注音优先匹配', () {
      final ann = JapaneseAnnotator.instance.annotate('読む');
      expect(ann.any((a) => a.surface == '読む' && a.reading == 'よむ'), true);
    });

    test('单字注音兜底', () {
      final ann = JapaneseAnnotator.instance.annotate('海');
      expect(ann.any((a) => a.surface == '海'), true);
    });
  });
}