import 'dart:convert';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';

class UploadResult {
  UploadResult(this.id, this.url, this.size);
  final int id;
  final String url; // path relativo, ej. "/api/uploads/12"
  final int size;
}

class UploadsRepository {
  UploadsRepository(this._api);
  final ApiClient _api;
  final ImagePicker _picker = ImagePicker();

  /// Abre camara o galeria, comprime y sube. Devuelve null si el usuario cancela.
  Future<UploadResult?> pickAndUpload({
    required ImageSource source,
    int maxWidth = 1024,
    int quality = 78,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 90, // primera reduccion del picker
      maxWidth: maxWidth.toDouble(),
    );
    if (picked == null) return null;
    return uploadFile(File(picked.path), maxWidth: maxWidth, quality: quality);
  }

  /// Comprime el archivo y lo sube como base64.
  Future<UploadResult> uploadFile(
    File file, {
    int maxWidth = 1024,
    int quality = 78,
  }) async {
    final compressed = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: maxWidth,
      minHeight: maxWidth,
      quality: quality,
      format: CompressFormat.jpeg,
    );
    final bytes = compressed ?? await file.readAsBytes();
    final b64 = base64Encode(bytes);

    final res = await _api.dio.post('/uploads', data: {
      'mimeType': 'image/jpeg',
      'base64': b64,
    });
    final data = res.data as Map<String, dynamic>;
    return UploadResult(
      data['id'] as int,
      data['url'] as String,
      data['size'] as int,
    );
  }
}
