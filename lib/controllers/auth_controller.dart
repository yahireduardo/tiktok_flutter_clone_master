import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';
import 'package:tiktok_tutorial/models/user.dart' as model;
import 'package:tiktok_tutorial/views/screens/auth/login_screen.dart';
import 'package:tiktok_tutorial/views/screens/home_screen.dart';
import 'package:tiktok_tutorial/utils/file_picker_helper.dart';

class AuthController extends GetxController {
  static AuthController instance = Get.find();
  late Rx<User?> _user;
  final _pickedImage = Rx<PickedFile?>(null);

  PickedFile? get profilePhoto => _pickedImage.value;
  User get user => _user.value!;

  @override
  void onReady() {
    super.onReady();
    _user = Rx<User?>(firebaseAuth.currentUser);
    _user.bindStream(firebaseAuth.authStateChanges());
    ever(_user, _setInitialScreen);
  }

  void _setInitialScreen(User? user) {
    if (user == null) {
      Get.offAll(() => LoginScreen());
    } else {
      Get.offAll(() => const HomeScreen());
    }
  }

  void pickImage() async {
    final pickedImage = await FilePickerHelper.pickImage();
    if (pickedImage != null) {
      Get.snackbar('Profile Picture',
          'You have successfully selected your profile picture!');
      _pickedImage.value = pickedImage;
    }
  }

  // upload to firebase storage
  Future<String> _uploadToStorage(PickedFile image) async {
    Reference ref = firebaseStorage
        .ref()
        .child('profilePics')
        .child(firebaseAuth.currentUser!.uid);

    UploadTask uploadTask;
    if (kIsWeb && image.bytes != null) {
      uploadTask = ref.putData(image.bytes!);
    } else {
      // Para móvil, necesitamos dart:io File
      throw UnsupportedError('Mobile upload not implemented in this version');
    }
    
    TaskSnapshot snap = await uploadTask;
    String downloadUrl = await snap.ref.getDownloadURL();
    return downloadUrl;
  }

  // registering the user
  void registerUser(
      String username, String email, String password, PickedFile? image) async {
    try {
      print('=== Starting user registration ===');
      if (username.isNotEmpty &&
          email.isNotEmpty &&
          password.isNotEmpty &&
          image != null) {
        print('Creating user in Firebase Auth...');
        // save out user to our ath and firebase firestore
        UserCredential cred = await firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('User created in Auth with UID: ${cred.user!.uid}');
        
        print('Uploading profile photo...');
        String downloadUrl = await _uploadToStorage(image);
        print('Profile photo uploaded: $downloadUrl');
        
        model.User user = model.User(
          name: username,
          email: email,
          uid: cred.user!.uid,
          profilePhoto: downloadUrl,
        );
        
        print('Saving user to Firestore...');
        await firestore
            .collection('users')
            .doc(cred.user!.uid)
            .set(user.toJson());
        print('User saved to Firestore successfully!');
        
        Get.snackbar('Success', 'Account created successfully!');
      } else {
        Get.snackbar(
          'Error Creating Account',
          'Please enter all the fields',
        );
      }
    } catch (e) {
      print('Error during registration: $e');
      Get.snackbar(
        'Error Creating Account',
        e.toString(),
      );
    }
  }

  void loginUser(String email, String password) async {
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        UserCredential cred = await firebaseAuth.signInWithEmailAndPassword(
            email: email, password: password);
        
        // Verificar si el usuario existe en Firestore
        var userDoc = await firestore.collection('users').doc(cred.user!.uid).get();
        
        if (!userDoc.exists) {
          print('User document not found in Firestore, creating one...');
          // Crear documento básico si no existe
          model.User user = model.User(
            name: email.split('@')[0], // Usar parte del email como nombre temporal
            email: email,
            uid: cred.user!.uid,
            profilePhoto: 'https://www.pngitem.com/pimgs/m/150-1503945_transparent-user-png-default-user-image-png-png.png',
          );
          await firestore
              .collection('users')
              .doc(cred.user!.uid)
              .set(user.toJson());
          print('User document created successfully');
        }
      } else {
        Get.snackbar(
          'Error Logging in',
          'Please enter all the fields',
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error Logging in',
        e.toString(),
      );
    }
  }

  void signOut() async {
    await firebaseAuth.signOut();
  }
}
