import 'dart:developer';
import 'dart:io';

import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class CloudinaryService {
  static CloudinaryPublic get _cloudinary => CloudinaryPublic(
    dotenv.env['CLOUDINARY_CLOUD_NAME']!,
    dotenv.env['CLOUDINARY_UPLOAD_PRESET']!,
    cache: false,
  );

  static Future<String> uploadImage({
    required File imageFile,
    required String chatId,
  }) async {
    log('CLOUD NAME: ${dotenv.env['CLOUDINARY_CLOUD_NAME']}');
    log('UPLOAD PRESET: ${dotenv.env['CLOUDINARY_UPLOAD_PRESET']}');
    // Compress first
    final String tempPath = imageFile.path.replaceAll(
      '.jpg',
      '_compressed.jpg',
    );
    final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
      imageFile.path,
      tempPath,
      quality: 75,
      minWidth: 1080,
      minHeight: 1080,
    );

    final File fileToUpload =
        compressed != null ? File(compressed.path) : imageFile;

    // Upload to Cloudinary
    final response = await _cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        fileToUpload.path,
        folder: 'chat_images/$chatId',
        resourceType: CloudinaryResourceType.Image,
      ),
    );

    return response.secureUrl;
  }
}
