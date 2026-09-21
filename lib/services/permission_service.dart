import 'package:permission_handler/permission_handler.dart';

/// 存储权限处理。
///
/// Android 11+ 使用 MANAGE_EXTERNAL_STORAGE；
/// Android 6-10 使用 READ_EXTERNAL_STORAGE；
/// 低版本无需权限。
class PermissionService {
  static const Permission _storage = Permission.storage;
  static const Permission _manageStorage = Permission.manageExternalStorage;

  /// 判断并请求所需的存储权限。返回是否可读。
  Future<bool> ensureStoragePermission() async {
    // Android 11+（API 30+）
    if (await _manageStorage.isGranted) return true;
    if (await _manageStorage.request().isGranted) return true;

    // 尝试传统存储权限
    if (await _storage.isGranted) return true;
    if (await _storage.request().isGranted) return true;

    return false;
  }
}