import 'package:flutter_test/flutter_test.dart';
import 'package:songhelp/main.dart';

void main() {
  testWidgets('SongHelpApp 可以正常启动', (WidgetTester tester) async {
    await tester.pumpWidget(const SongHelpApp());
    // 首屏为歌曲列表页，应显示标题
    expect(find.text('SongHelp 日语练唱'), findsOneWidget);
  });
}