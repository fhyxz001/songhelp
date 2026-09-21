import 'package:flutter/material.dart';
import '../models/lyric_line.dart';
import '../services/japanese_annotator.dart';

/// 逐行歌词视图，支持：
/// - 滚动并让当前播放行始终居中高亮
/// - 日语汉字注音（上方显示平假名）+ 释义（下方小字）
/// - 点击任意歌词行 => 重唱该句（回调 [onTapLine]）
class LyricListView extends StatefulWidget {
  /// 已按时间排序的歌词行。
  final List<LyricLine> lines;

  /// 当前播放进度（毫秒）。
  final int positionMs;

  /// 是否启用日语注音。
  final bool showRuby;

  /// 点击歌词行回调（参数为该行起始毫秒）。
  final void Function(int startMs) onTapLine;

  const LyricListView({
    super.key,
    required this.lines,
    required this.positionMs,
    required this.showRuby,
    required this.onTapLine,
  });

  @override
  State<LyricListView> createState() => _LyricListViewState();
}

class _LyricListViewState extends State<LyricListView> {
  final ScrollController _scrollController = ScrollController();

  /// 活动行 division 的 key，用于精确测量其渲染位置以实现居中。
  final Map<int, GlobalKey> _rowKeys = {};

  /// ListView 本身的 context，用于计算行相对视口的位置。
  BuildContext? _listContext;

  int _lastActiveIndex = -1;

  /// 找到当前播放位置对应的歌词行索引（最后一个 startMs <= positionMs 的行）。
  int _activeIndex() {
    if (widget.lines.isEmpty) return -1;
    int idx = -1;
    for (int i = 0; i < widget.lines.length; i++) {
      if (widget.lines[i].startMs <= widget.positionMs) {
        idx = i;
      } else {
        break;
      }
    }
    return idx;
  }

  GlobalKey _keyFor(int index) => _rowKeys.putIfAbsent(index, GlobalKey.new);

  /// 把活动行滚动到视口垂直居中。放在布局完成后调用以确保测量准确。
  void _scheduleCenter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _centerActiveRow();
    });
  }

  void _centerActiveRow() {
    final idx = _activeIndex();
    if (idx < 0 || idx == _lastActiveIndex) return;
    _lastActiveIndex = idx;

    if (!_scrollController.hasClients || _listContext == null) return;

    final listRenderBox = _listContext!.findRenderObject() as RenderBox?;
    final rowRenderBox =
        _keyFor(idx).currentContext?.findRenderObject() as RenderBox?;
    if (listRenderBox == null || rowRenderBox == null || !rowRenderBox.attached) {
      return;
    }

    // 行顶边相对 ListView 视口顶边的偏移
    final rowTop =
        rowRenderBox.localToGlobal(Offset.zero, ancestor: listRenderBox).dy;
    final rowHeight = rowRenderBox.size.height;
    final viewportHeight = _scrollController.position.viewportDimension;

    // 让该行中心对齐到视口中心需要额外滚动的距离
    final delta = rowTop - (viewportHeight / 2 - rowHeight / 2);

    final maxExtent = _scrollController.position.maxScrollExtent;
    final target = (_scrollController.offset + delta).clamp(0.0, maxExtent);

    _scrollController.animateTo(
      target.toDouble(),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(LyricListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.positionMs != widget.positionMs) {
      _scheduleCenter();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lines.isEmpty) {
      return const Center(child: Text('暂无歌词'));
    }

    final activeIndex = _activeIndex();

    return Builder(builder: (listContext) {
      _listContext = listContext;
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 220),
        itemCount: widget.lines.length,
        itemBuilder: (context, index) {
          final line = widget.lines[index];
          final isActive = index == activeIndex;
          return Container(
            key: _keyFor(index),
            child: _LyricRow(
              line: line,
              isActive: isActive,
              showRuby: widget.showRuby,
              onTap: () => widget.onTapLine(line.startMs),
            ),
          );
        },
      );
    });
  }
}

/// 单行歌词 Widget。可读、可点击、可高亮，可显示日语注音。
class _LyricRow extends StatelessWidget {
  final LyricLine line;
  final bool isActive;
  final bool showRuby;
  final VoidCallback onTap;

  const _LyricRow({
    required this.line,
    required this.isActive,
    required this.showRuby,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.brightness == Brightness.dark
        ? Colors.white54
        : Colors.black54;

    Widget content;
    if (showRuby && line.isJapanese) {
      content = _RubyText(line: line, isActive: isActive);
    } else {
      content = Text(
        line.text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: isActive ? 20 : 17,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? activeColor : inactiveColor,
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: content,
      ),
    );
  }
}

/// 带日语注音的文字渲染。
///
/// 结构：每个「字+注音」单元竖排为一个 column，横向拼接成一行。
class _RubyText extends StatelessWidget {
  final LyricLine line;
  final bool isActive;

  const _RubyText({required this.line, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.brightness == Brightness.dark
        ? Colors.white54
        : Colors.black54;

    final annotations = JapaneseAnnotator.instance.annotate(line.text);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: annotations.map((a) {
        // 仅当该单元是汉字且存在正确读音时才显示注音
        final showFurigana = a.isKanji && a.reading.isNotEmpty && a.reading != a.surface;
        final footnoteColor = showFurigana
            ? (isActive ? activeColor : inactiveColor.withOpacity(0.75))
            : Colors.transparent;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showFurigana)
                Text(
                  a.reading,
                  style: TextStyle(
                    fontSize: 10,
                    color: footnoteColor,
                    height: 1.1,
                  ),
                ),
              Text(
                a.surface,
                style: TextStyle(
                  fontSize: isActive ? 20 : 17,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? activeColor : inactiveColor,
                  height: 1.2,
                ),
              ),
              if (showFurigana && a.meaning != null)
                Text(
                  a.meaning!,
                  style: TextStyle(
                    fontSize: 9,
                    color: footnoteColor,
                    height: 1.1,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}