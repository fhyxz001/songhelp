import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

/// 音频播放服务：包装 just_audio，提供播放/暂停/进度/seek。
///
/// 通过 [positionStream] 和 [durationStream] 驱动 UI 的进度条与歌词高亮。
class AudioPlayerService {
  final AudioPlayer player = AudioPlayer();

  /// 当前播放歌曲。
  Song? currentSong;

  /// 是否正在播放。
  Stream<bool> get playingStream => player.playingStream;

  /// 当前播放进度（毫秒）。由 position 流换算。
  Stream<Duration> get positionStream => player.positionStream;

  /// 总时长。
  Stream<Duration?> get durationStream => player.durationStream;

  /// 当前进度（同步获取，用于点击重唱时的兜底）。
  Duration get position => player.position;

  /// 加载并播放一首歌。
  Future<void> loadAndPlay(Song song) async {
    currentSong = song;
    await player.setFilePath(song.filePath);
    await player.play();
  }

  /// 暂停/继续。
  Future<void> toggle() async {
    if (player.playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  /// 跳转到指定毫秒位置。用于点击歌词重唱。
  Future<void> seekToMs(int ms) async {
    await player.seek(Duration(milliseconds: ms));
    // seek 后若处于暂停状态则自动播放，保证「重唱」体验
    if (!player.playing) {
      await player.play();
    }
  }

  /// 停止并释放资源。
  Future<void> dispose() async {
    await player.dispose();
  }
}