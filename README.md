# SongHelp 日语练唱

一个 Flutter 安卓 App，用于**播放本地歌曲 + 显示 LRC 歌词 + 日语汉字注音/释义辅助练唱**。

## 功能

- 🎵 读取手机公共存储固定文件夹下的歌曲文件（mp3 / flac / m4a 等）
- 📄 显示同名 `.lrc` 歌词，逐行滚动并高亮当前句
- 🇯🇵 **日语歌词辅助**：为日文汉字自动标注平假名读音 + 中文释义（离线，无需联网）
- 🔁 **点击歌词重唱**：点任意一句歌词，即跳转并重播该句
- 📱 竖屏锁定播放

## 目录约定

歌曲与歌词文件需放在手机内部存储的：

```
内部存储/Music/SongHelp/
├── 歌曲名.mp3
├── 歌曲名.lrc   <- 与歌曲同名、同目录
├── ...
```

> 首次打开 App 会申请存储权限（Android 11+ 需授权「所有文件访问」）。
> 若提示目录不存在，请先在文件管理器中创建 `Music/SongHelp/` 并放入文件。

## 歌词格式（LRC）

```lrc
[00:15.00]この手を伸ばして
[00:20.00]君の名前を呼ぶ
[00:25.00]届け この想いよ
```

- 支持 `[mm:ss.xx]` 与 `[mm:ss]` 时间标签
- 支持一行多个时间标签
- 自动忽略 `[ar:]`、`[ti:]` 等元信息行

## 本地开发

> 本地开发需安装 [Flutter SDK](https://docs.flutter.dev/get-started/install)。

```bash
flutter pub get
flutter run
```

## 在 GitHub 上自动构建 APK（免本地安装 SDK）

本项目已内置 GitHub Actions 工作流，无需在本地安装 Flutter 即可云端编译 APK：

1. 在 GitHub 新建仓库，把本项目推上去（`main` 分支）
2. 打开仓库的 **Actions** 标签页，会看到 `Build Android APK` 工作流
3. 点击 **Run workflow**（或直接 push 一次代码触发）
4. 构建完成后，在运行详情页的 **Artifacts** 区域下载 `songhelp-apk` 压缩包
5. 解压后得到 `app-arm64-v8a-release.apk` 等 APK 文件，安装到手机即可

> 说明：CI 使用 debug 签名构建，可直接安装使用；正式上架分发前请自行配置 release 签名。

## 项目结构

```
lib/
├── main.dart                 # 入口，锁竖屏
├── models/
│   ├── lyric_line.dart       # 歌词行 + 注音注释模型
│   └── song.dart             # 歌曲模型
├── services/
│   ├── audio_player_service.dart   # 音频播放（just_audio）
│   ├── song_scanner.dart           # 目录扫描
│   ├── permission_service.dart     # 存储权限
│   └── japanese_annotator.dart     # 日语注音/释义引擎（离线）
├── utils/
│   └── lrc_parser.dart       # LRC 解析器
├── screens/
│   ├── song_list_screen.dart # 歌曲列表
│   └── player_screen.dart    # 播放页
└── widgets/
    └── lyric_list_view.dart  # 逐行歌词 + 注音 + 点击重唱
```

## 技术栈

- **Flutter** + Dart
- **just_audio** —— 音频播放
- **permission_handler** —— 存储权限
- 日语注音/释义：内置离线汉字读音映射表（`lib/services/japanese_annotator.dart`）

## 扩展方向

- 词典数据外置为 asset JSON，便于扩充词库
- 支持在线注音 API（架构已预留，替换 `JapaneseAnnotator` 即可）
- 支持 SMI/ASS 字幕、双语歌词对译