import 'dart:io';
import '../models/song.dart';

/// 歌曲文件扫描服务。
///
/// 从手机公共存储的固定文件夹读取歌曲与同名歌词文件。
/// 默认目录：`/storage/emulated/0/Music/SongHelp/`（可配置）。
/// 支持规避 Android 11+ 分区存储限制——通过直接读取公共 Music 目录。
class SongScanner {
  /// 默认扫描目录（可被外部覆盖）。
  String baseDir;

  SongScanner({String? baseDir})
      : baseDir = baseDir ?? _defaultBaseDir;

  static const supportedAudioExt = {
    '.mp3', '.m4a', '.aac', '.flac', '.wav', '.ogg', '.opus', '.wma',
  };

  static const lyricExt = '.lrc';

  /// 默认：放在 Music 目录下，规避分区存储依然可读（公共音乐目录）。
  static String get _defaultBaseDir => '/storage/emulated/0/Music/SongHelp';

  /// 扫描目录，返回歌曲列表。
  ///
  /// [errorHandler] 用于把目录不存在的提示回传给 UI。
  Future<List<Song>> scan() async {
    final dir = Directory(baseDir);
    if (!await dir.exists()) {
      throw DirectoryNotFoundException(
        '歌曲目录不存在：$baseDir\n'
        '请在手机「文件管理器」中创建:\n'
        '内部存储/Music/SongHelp/\n'
        '并把歌曲(.mp3等)和同名歌词(.lrc)放进去。',
      );
    }

    final songs = <Song>[];
    await for (final entity in dir.list(recursive: false)) {
      if (entity is! File) continue;
      final lower = entity.path.toLowerCase();

      if (supportedAudioExt.any((e) => lower.endsWith(e))) {
        final songPath = entity.path;
        final lyricPath = Song.deriveLyricPath(songPath);
        songs.add(Song(
          id: songPath,
          title: _titleFromFileName(entity.uri.pathSegments.last),
          artist: '',
          filePath: songPath,
          lyricPath: lyricPath,
        ));
      }
    }

    // 按标题排序
    songs.sort((a, b) => a.title.compareTo(b.title));
    return songs;
  }

  /// 读取歌词文件内容。找不到返回 null。
  Future<String?> readLyric(String songPath) async {
    final lyricPath = Song.deriveLyricPath(songPath);
    if (lyricPath == null) return null;
    final file = File(lyricPath);
    if (!await file.exists()) return null;
    return await file.readAsString();
  }

  /// 从文件名去掉扩展名作为标题。
  String _titleFromFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot > 0) return fileName.substring(0, dot);
    return fileName;
  }
}

/// 目录不存在异常。
class DirectoryNotFoundException implements Exception {
  final String message;
  DirectoryNotFoundException(this.message);
  @override
  String toString() => message;
}