import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class FilePickerHelper {
  static Future<PickedFile?> pickImage() async {
    final XFile? pickedFile = await ImagePicker().pickImage(
      source: kIsWeb ? ImageSource.gallery : ImageSource.gallery,
    );
    
    if (pickedFile == null) return null;
    
    return PickedFile(
      path: pickedFile.path,
      bytes: kIsWeb ? await pickedFile.readAsBytes() : null,
      name: pickedFile.name,
    );
  }

  static Future<PickedFile?> pickVideo(ImageSource source) async {
    final XFile? pickedFile = await ImagePicker().pickVideo(
      source: kIsWeb ? ImageSource.gallery : source,
    );
    
    if (pickedFile == null) return null;
    
    return PickedFile(
      path: pickedFile.path,
      bytes: kIsWeb ? await pickedFile.readAsBytes() : null,
      name: pickedFile.name,
    );
  }
}

class PickedFile {
  final String path;
  final Uint8List? bytes;
  final String name;

  PickedFile({
    required this.path,
    this.bytes,
    required this.name,
  });

  bool get isWeb => bytes != null;
}
