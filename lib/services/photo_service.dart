import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Captures or picks a photo and, on mobile/desktop, copies it into permanent
/// app storage so the report's evidence survives even after the OS clears the
/// camera's temp cache.
class PhotoService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> capture() => _pick(ImageSource.camera);
  Future<String?> pickFromGallery() => _pick(ImageSource.gallery);

  Future<String?> _pick(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 82,
    );
    if (file == null) return null;

    // On web there is no writable file system; keep the blob path as-is so the
    // image still displays within the session.
    if (kIsWeb) return file.path;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(dir.path, 'photos'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }
      final ext = p.extension(file.path).isEmpty
          ? '.jpg'
          : p.extension(file.path);
      final dest = p.join(
        photosDir.path,
        '${DateTime.now().millisecondsSinceEpoch}$ext',
      );
      await File(file.path).copy(dest);
      return dest;
    } catch (e) {
      debugPrint('WildWatch: failed to persist photo, using temp path: $e');
      return file.path;
    }
  }

  /// Best-effort cleanup when a photo is replaced or its report deleted.
  Future<void> deleteIfManaged(String? path) async {
    if (path == null || kIsWeb) return;
    try {
      final f = File(path);
      if (await f.exists() && path.contains('${p.separator}photos${p.separator}')) {
        await f.delete();
      }
    } catch (_) {
      // Non-fatal.
    }
  }
}
