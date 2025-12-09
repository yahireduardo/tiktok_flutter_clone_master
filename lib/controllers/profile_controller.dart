import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';

class ProfileController extends GetxController {
  final Rx<Map<String, dynamic>> _user = Rx<Map<String, dynamic>>({});
  Map<String, dynamic> get user => _user.value;

  final Rx<String> _uid = "".obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = "".obs;
  
  bool get isLoading => _isLoading.value;
  String get error => _error.value;

  void updateUserId(String uid) {
    print('ProfileController: updateUserId called with uid: $uid');
    _uid.value = uid;
    _user.value = {}; // Reset user data
    _error.value = ""; // Reset error
    getUserData();
  }

  Future<void> getUserData() async {
    try {
      _isLoading.value = true;
      update();
      
      print('ProfileController: Getting user data for uid: ${_uid.value}');
      
      if (_uid.value.isEmpty) {
        print('ProfileController: ERROR - UID is empty');
        _isLoading.value = false;
        _error.value = "User ID is empty";
        update();
        return;
      }
      
      List<String> thumbnails = [];
      var myVideos = await firestore
          .collection('videos')
          .where('uid', isEqualTo: _uid.value)
          .get();

      print('ProfileController: Found ${myVideos.docs.length} videos');
      
      for (int i = 0; i < myVideos.docs.length; i++) {
        thumbnails.add((myVideos.docs[i].data() as dynamic)['thumbnail']);
      }

      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(_uid.value).get();
      
      if (!userDoc.exists) {
        print('ProfileController: ERROR - User document not found!');
        _isLoading.value = false;
        _error.value = "User not found in database";
        update();
        return;
      }
      
      final userData = userDoc.data()! as dynamic;
      print('ProfileController: User data retrieved successfully');
    String name = userData['name'];
    String profilePhoto = userData['profilePhoto'];
    int likes = 0;
    int followers = 0;
    int following = 0;
    bool isFollowing = false;

    for (var item in myVideos.docs) {
      likes += (item.data()['likes'] as List).length;
    }
    var followerDoc = await firestore
        .collection('users')
        .doc(_uid.value)
        .collection('followers')
        .get();
    var followingDoc = await firestore
        .collection('users')
        .doc(_uid.value)
        .collection('following')
        .get();
    followers = followerDoc.docs.length;
    following = followingDoc.docs.length;

    firestore
        .collection('users')
        .doc(_uid.value)
        .collection('followers')
        .doc(authController.user.uid)
        .get()
        .then((value) {
      if (value.exists) {
        isFollowing = true;
      } else {
        isFollowing = false;
      }
    });

    _user.value = {
      'followers': followers.toString(),
      'following': following.toString(),
      'isFollowing': isFollowing,
      'likes': likes.toString(),
      'profilePhoto': profilePhoto,
      'name': name,
      'thumbnails': thumbnails,
    };
    
    _isLoading.value = false;
    print('ProfileController: User profile data set successfully');
    update();
    } catch (e, stackTrace) {
      _isLoading.value = false;
      _error.value = e.toString();
      print('ProfileController: ERROR - $e');
      print('Stack trace: $stackTrace');
      update();
    }
  }

  Future<void> followUser() async {
    var doc = await firestore
        .collection('users')
        .doc(_uid.value)
        .collection('followers')
        .doc(authController.user.uid)
        .get();

    if (!doc.exists) {
      await firestore
          .collection('users')
          .doc(_uid.value)
          .collection('followers')
          .doc(authController.user.uid)
          .set({});
      await firestore
          .collection('users')
          .doc(authController.user.uid)
          .collection('following')
          .doc(_uid.value)
          .set({});
      _user.value.update(
        'followers',
        (value) => (int.parse(value) + 1).toString(),
      );
    } else {
      await firestore
          .collection('users')
          .doc(_uid.value)
          .collection('followers')
          .doc(authController.user.uid)
          .delete();
      await firestore
          .collection('users')
          .doc(authController.user.uid)
          .collection('following')
          .doc(_uid.value)
          .delete();
      _user.value.update(
        'followers',
        (value) => (int.parse(value) - 1).toString(),
      );
    }
    _user.value.update('isFollowing', (value) => !value);
    update();
  }
}
