import 'dart:async';
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/lyric_line.dart';
import '../services/audio_player_service.dart';
import '../services/song_scanner.dart';
import '../utils/lrc_parser.dart';
import '../widgets/lyric_list_view.dart';

/// 播放器页面：播放 + 逐行歌词 + 日语注音 + 点击重唱。
class PlayerScreen extends StatefulWidget {
  final Song song;
  const PlayerScreen({super.key, required this.song});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final AudioPlayerService _audio = AudioPlayerService();
  final SongScanner _scanner = SongScanner();

  List<LyricLine> _lyrics = [];
  int _positionMs = 0;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _showRuby = true;

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<bool>? _playSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 加载歌词
    final lrcText = await _scanner.readLyric(widget.song.filePath);
    if (lrcText != null && mounted) {
      setState(() {
        _lyrics = LrcParser.parse(lrcText);
      });
    }

    // 加载并播放
    await _audio.loadAndPlay(widget.song);

    // 订阅状态
    _posSub = _audio.positionStream.listen((d) {
      if (mounted) setState(() => _positionMs = d.inMilliseconds);
    });
    _durSub = _audio.durationStream.listen((d) {
      if (mounted && d != null) setState(() => _duration = d);
    });
    _playSub = _audio.playingStream.listen((p) {
      if (mounted) setState(() => _isPlaying = p);
    });
  }

  /// 点击歌词行 -> 重唱该句。
  void _onTapLine(int startMs) {
    _audio.seekToMs(startMs);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _playSub?.cancel();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.song.title),
      ),
      body: Column(
        children: [
          // 歌曲信息区
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              children: [
                Icon(Icons.album, size: 72, color: theme.colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  widget.song.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 进度条
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              children: [
                Slider(
                  value: _positionMs.toDouble().clamp(
                        0,
                        _duration.inMilliseconds.toDouble(),
                      ).toDouble(),
                  max: _duration.inMilliseconds > 0
                      ? _duration.inMilliseconds.toDouble()
                      : 1.0,
                  onChanged: (v) => _audio.seekToMs(v.toInt()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(Duration(milliseconds: _positionMs)),
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 日语注音开关
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('日语注音'),
              Switch(
                value: _showRuby,
                onChanged: (v) => setState(() => _showRuby = v),
              ),
            ],
          ),

          // 歌词区域（占据剩余空间）
          Expanded(
            child: LyricListView(
              lines: _lyrics,
              positionMs: _positionMs,
              showRuby: _showRuby,
              onTapLine: _onTapLine,
            ),
          ),

          // 底部播放控制
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 40,
                    icon: Icon(
                      Icons.replay_10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      final target = _positionMs - 10000;
                      _audio.seekToMs(target < 0 ? 0 : target);
                    },
                  ),
                  IconButton(
                    iconSize: 64,
                    icon: Icon(
                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: _audio.toggle,
                  ),
                  IconButton(
                    iconSize: 40,
                    icon: Icon(
                      Icons.forward_10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => _audio.seekToMs(_positionMs + 10000),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}