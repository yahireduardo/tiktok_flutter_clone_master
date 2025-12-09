import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/models/video.dart';
import 'package:tiktok_tutorial/utils/file_picker_helper.dart';

class UploadVideoController extends GetxController {
  
  Future<String> _uploadVideoToStorage(String id, PickedFile videoFile) async {
    try {
      print('Starting video upload to Storage: $id');
      Reference ref = firebaseStorage.ref().child('videos').child(id);

      UploadTask uploadTask;
      if (kIsWeb && videoFile.bytes != null) {
        print('Uploading video bytes, size: ${videoFile.bytes!.length}');
        // En web, subimos directamente los bytes sin compresión
        uploadTask = ref.putData(
          videoFile.bytes!,
          SettableMetadata(contentType: 'video/mp4'),
        );
      } else {
        throw UnsupportedError('Mobile upload not implemented in this version');
      }

      TaskSnapshot snap = await uploadTask;
      String downloadUrl = await snap.ref.getDownloadURL();
      print('Video uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading video to storage: $e');
      rethrow;
    }
  }

  Future<String> _uploadImageToStorage(String id, Uint8List thumbnailBytes) async {
    try {
      print('Starting thumbnail upload: $id');
      Reference ref = firebaseStorage.ref().child('thumbnails').child(id);
      UploadTask uploadTask = ref.putData(
        thumbnailBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      TaskSnapshot snap = await uploadTask;
      String downloadUrl = await snap.ref.getDownloadURL();
      print('Thumbnail uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading thumbnail: $e');
      rethrow;
    }
  }

  // upload video
  Future<void> uploadVideo(String songName, String caption, PickedFile videoFile) async {
    try {
      print('=== Starting video upload process ===');
      Get.snackbar('Uploading', 'Please wait while your video is being uploaded...');
      
      String uid = firebaseAuth.currentUser!.uid;
      print('Current user UID: $uid');
      
      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(uid).get();
      
      if (!userDoc.exists) {
        print('ERROR: User document not found');
        Get.snackbar('Error', 'User data not found');
        return;
      }
      
      print('User document found');
      
      // get id
      var allDocs = await firestore.collection('videos').get();
      int len = allDocs.docs.length;
      print('Current videos count: $len');
      
      String videoUrl = await _uploadVideoToStorage("Video $len", videoFile);
      print('Video URL obtained: $videoUrl');
      
      // Generar un thumbnail simple con un pixel (placeholder pequeño)
      // En producción real, deberías capturar un frame del video
      Uint8List thumbnailBytes = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
        0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
        0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
        0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
        0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
        0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
        0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
        0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x03, 0xFF, 0xC4, 0x00, 0x14, 0x10, 0x01, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00,
        0x7F, 0xFF, 0xD9
      ]); // JPEG 1x1 pixel negro válido
      
      String thumbnail = await _uploadImageToStorage("Video $len", thumbnailBytes);
      print('Thumbnail URL obtained: $thumbnail');

      Video video = Video(
        username: (userDoc.data()! as Map<String, dynamic>)['name'],
        uid: uid,
        id: "Video $len",
        likes: [],
        commentCount: 0,
        shareCount: 0,
        songName: songName,
        caption: caption,
        videoUrl: videoUrl,
        profilePhoto: (userDoc.data()! as Map<String, dynamic>)['profilePhoto'],
        thumbnail: thumbnail,
      );

      print('Saving video to Firestore...');
      await firestore.collection('videos').doc('Video $len').set(
            video.toJson(),
          );
      
      print('Video saved successfully to Firestore!');
      Get.snackbar('Success', 'Video uploaded successfully!');
      Get.back();
    } catch (e, stackTrace) {
      print('ERROR uploading video: $e');
      print('Stack trace: $stackTrace');
      Get.snackbar(
        'Error Uploading Video',
        e.toString(),
      );
    }
  }
}
