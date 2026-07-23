import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class UploadSafeImageNormalizer {
  const UploadSafeImageNormalizer._();

  /// iOS photos can arrive as HEIC / HDR / wide-color images.
  /// Re-encoding them to plain JPEG before preview/upload avoids the
  /// occasional green-tint issue seen on some devices.
  ///
  /// Web never touches `dart:io`, since [XFile.path] there is a `blob:` URL,
  /// not a filesystem path.
  static Future<XFile> normalizeForUpload(
    XFile input, {
    String prefix = 'upload_image',
    int quality = 88,
    int maxWidth = 2048,
    int maxHeight = 2048,
  }) async {
    if (kIsWeb) return input;

    final inputFile = File(input.path);
    if (!await inputFile.exists()) return input;

    // Keep Android path untouched unless you want global normalization later.
    if (!Platform.isIOS) return input;

    final tempDir = await getTemporaryDirectory();
    final safePrefix = prefix.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final outputPath = p.join(
      tempDir.path,
      '${safePrefix}_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      inputFile.absolute.path,
      outputPath,
      format: CompressFormat.jpeg,
      quality: quality,
      minWidth: maxWidth,
      minHeight: maxHeight,
      autoCorrectionAngle: true,
      keepExif: false,
      numberOfRetries: 3,
    );

    if (result == null) return input;
    return XFile(result.path);
  }

  static Future<List<XFile>> normalizeMany(
    Iterable<XFile> files, {
    String prefix = 'upload_image',
    int quality = 88,
    int maxWidth = 2048,
    int maxHeight = 2048,
  }) async {
    final out = <XFile>[];
    var i = 0;

    for (final file in files) {
      out.add(
        await normalizeForUpload(
          file,
          prefix: '${prefix}_$i',
          quality: quality,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
      );
      i++;
    }

    return out;
  }
}
