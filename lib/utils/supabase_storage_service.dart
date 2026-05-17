import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'dart:typed_data';

class SupabaseStorageService {
  final _supabase = Supabase.instance.client;
  final String _bucketName = 'chat_media'; 

  Future<String?> uploadFile(File file, String userId) async {
    try {
      final fileName = path.basename(file.path);
      final fileExtension = path.extension(file.path);
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$userId$fileExtension';
      final filePath = '$userId/$uniqueFileName';   
      print('uno: $filePath');

      await _supabase.storage.from(_bucketName).upload(
            filePath,
            file,
          );

      final String publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(filePath);
      return publicUrl;
      
    } catch (e) {
      print('Error subiendo archivo a Supabase: $e');
      return null;
    }
  }

  Future<String?> uploadBytes(Uint8List bytes, String userId, String extension) async {
    try {
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$userId$extension';
      final filePath = '$userId/$uniqueFileName'; 

      await _supabase.storage.from(_bucketName).uploadBinary(
            filePath,
            bytes,
          );

      final String publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(filePath);
      return publicUrl;
      
    } catch (e) {
      print('Error subiendo bytes a Supabase: $e');
      return null;
    }
  }
}