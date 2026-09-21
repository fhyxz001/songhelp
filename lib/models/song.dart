/// 一首歌的完整描述：文件路径 + 歌词文件路径 + 元数据。
class Song {
  final String id;
  final String title;
  final String artist;
  final String filePath;

  /// 歌词文件路径（LRC）。与歌曲同名、同目录，扩展名 .lrc。
  final String? lyricPath;

  /// 是否有对应的歌词文件。
  bool get hasLyric => lyricPath != null && lyricPath!.isNotEmpty;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.filePath,
    this.lyricPath,
  });

  /// 从文件路径推导歌词路径：把扩展名替换为 .lrc。
  static String? deriveLyricPath(String songPath) {
    final dot = songPath.lastIndexOf('.');
    if (dot <= 0) return null;
    return '${songPath.substring(0, dot)}.lrc';
  }

  factory Song.fromJson(Map<String, dynamic> json) => Song(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String,
        filePath: json['filePath'] as String,
        lyricPath: json['lyricPath'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'filePath': filePath,
        'lyricPath': lyricPath,
      };
}