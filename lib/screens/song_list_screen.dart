import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/song_scanner.dart';
import '../services/permission_service.dart';
import 'player_screen.dart';

/// 歌曲列表页：扫描指定目录，展示歌曲。
class SongListScreen extends StatefulWidget {
  const SongListScreen({super.key});

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  final SongScanner _scanner = SongScanner();
  final PermissionService _permission = PermissionService();

  List<Song> _songs = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // 先确保存储权限
    final ok = await _permission.ensureStoragePermission();
    if (!ok) {
      setState(() {
        _loading = false;
        _error = '未获得存储权限，请到系统设置中允许「所有文件访问」。';
      });
      return;
    }

    try {
      final songs = await _scanner.scan();
      setState(() {
        _songs = songs;
        _loading = false;
      });
    } on DirectoryNotFoundException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '扫描失败：$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SongHelp 日语练唱'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadSongs,
        icon: const Icon(Icons.refresh),
        label: const Text('重新扫描'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildError(_error!);
    }
    if (_songs.isEmpty) {
      return _buildEmpty();
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _songs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final song = _songs[index];
        return _SongTile(song: song);
      },
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_note, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '目录中还没有歌曲。\n请把歌曲(.mp3/.flac等)和同名歌词(.lrc)放入：\n内部存储/Music/SongHelp/',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final Song song;
  const _SongTile({required this.song});

  @override
  Widget build(BuildContext context) {
    final hasLyric = song.hasLyric;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlayerScreen(song: song),
            ),
          );
        },
        leading: CircleAvatar(
          child: Icon(hasLyric ? Icons.lyrics : Icons.music_note),
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(hasLyric ? '有歌词' : '无歌词'),
        trailing: const Icon(Icons.play_arrow),
      ),
    );
  }
}