import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload image bytes to Firebase Storage
  /// Returns the download URL
  Future<String> uploadImage({
    required String path,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final ref = _storage.ref().child(path).child(fileName);
    final metadata = SettableMetadata(
      contentType: _getContentType(fileName),
    );

    final uploadTask = await ref.putData(bytes, metadata);
    return await uploadTask.ref.getDownloadURL();
  }

  /// Upload multiple images with progress tracking
  Future<List<String>> uploadImages({
    required String path,
    required List<MapEntry<String, Uint8List>> files,
    void Function(double)? onProgress,
  }) async {
    final urls = <String>[];
    final totalFiles = files.length;
    
    if (totalFiles == 0) {
      onProgress?.call(1.0);
      return [];
    }

    int totalBytes = files.fold(0, (sum, file) => sum + file.value.length);
    int uploadedBytes = 0;

    for (final file in files) {
      final ref = _storage.ref().child(path).child(file.key);
      final metadata = SettableMetadata(contentType: _getContentType(file.key));

      final uploadTask = ref.putData(file.value, metadata);
      
      var sub = uploadTask.snapshotEvents.listen((event) {
        if (onProgress != null) {
          final currentFileUploaded = event.bytesTransferred;
          // Calculate overall progress across all files
          final overall = (uploadedBytes + currentFileUploaded) / totalBytes;
          // Clamp to 1.0 just in case
          onProgress(overall > 1.0 ? 1.0 : overall);
        }
      });

      await uploadTask;
      await sub.cancel();
      
      uploadedBytes += file.value.length;
      
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    
    onProgress?.call(1.0);
    return urls;
  }

  /// Delete a file from storage by URL
  Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // File may already be deleted
    }
  }

  /// Delete multiple files
  Future<void> deleteByUrls(List<String> urls) async {
    for (final url in urls) {
      await deleteByUrl(url);
    }
  }

  Future<List<Reference>> _getAllFiles(Reference ref) async {
    final result = await ref.listAll();
    final files = List<Reference>.from(result.items);
    for (final prefix in result.prefixes) {
      files.addAll(await _getAllFiles(prefix));
    }
    return files;
  }

  /// Delete an entire folder and its contents
  Future<void> deleteFolder(String path, {void Function(double)? onProgress}) async {
    try {
      final rootRef = _storage.ref().child(path);
      final allFiles = await _getAllFiles(rootRef);
      
      if (allFiles.isEmpty) {
        onProgress?.call(1.0);
        return;
      }

      int deletedCount = 0;
      for (final file in allFiles) {
        await file.delete();
        deletedCount++;
        onProgress?.call(deletedCount / allFiles.length);
      }
    } catch (e) {
      onProgress?.call(1.0);
      // Ignore errors (e.g., folder doesn't exist)
    }
  }

  String _getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
