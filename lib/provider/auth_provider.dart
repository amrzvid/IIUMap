import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iiumap/model/user_model.dart';
import 'package:flutter_iiumap/screens/otp_screen.dart';
import 'package:flutter_iiumap/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class AuthProvider extends ChangeNotifier {
  var verificationId = "".obs;
  bool _isSignedIn = false;
  bool get isSignedIn => _isSignedIn;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _uid;
  String get uid => _uid!;
  UserModel? _userModel;
  UserModel get getUserModel => _userModel!;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthProvider() {
    checkSignIn();
  }

  void checkSignIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _isSignedIn = prefs.getBool("isSignedIn") ?? false;
    notifyListeners();
  }

  Future setSignIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isSignedIn", true);
    _isSignedIn = true;
    notifyListeners();
  }

  Future<void> signInWithPhone(BuildContext context, String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential phoneAuthCredential) async {
          await _auth.signInWithCredential(phoneAuthCredential);
        },
        verificationFailed: (error) {
          throw Exception(error.message);
        },
        codeSent: (verificationId, forceResendingToken) {
          this.verificationId.value = verificationId;
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      OTPScreen(verificationId: verificationId)));
        },
        codeAutoRetrievalTimeout: (verficationId) {
          this.verificationId.value = verficationId;
        },
      );
    } on FirebaseException catch (e) {
      showSnackBar(context, e.message.toString());
    }
  }

  void verifyOtp({
    required BuildContext context,
    required String verificationId,
    required String userOtp,
    required Function onSuccess,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      PhoneAuthCredential phoneAuthCredential = PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: userOtp);
      User user = (await _auth.signInWithCredential(phoneAuthCredential)).user!;

      if (user != null) {
        _uid = user.uid;
        onSuccess();
      }
      _isLoading = false;
      notifyListeners();
    } on FirebaseException catch (e) {
      showSnackBar(context, e.message.toString());
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkExistingUser() async {
    DocumentSnapshot snapshot =
        await _firestore.collection("users").doc(_uid).get();
    if (snapshot.exists) {
      print("User already exists");
      return true;
    } else {
      print("User does not exist");
      return false;
    }
  }

  void saveUserDataToFirebase({
    required BuildContext context,
    required UserModel userModel,
    required Function onSuccess,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      userModel.phoneNumber = _auth.currentUser!.phoneNumber!;
      userModel.uid = _auth.currentUser!.uid;
      userModel.createdAt = DateTime.now().millisecondsSinceEpoch.toString();

      _userModel = userModel;

      await _firestore
          .collection("users")
          .doc(_auth.currentUser!.uid)
          .set(userModel.toMap())
          .then((value) => {
                onSuccess(),
                _isLoading = false,
                notifyListeners(),
              });
    } on FirebaseException catch (e) {
      showSnackBar(context, e.message.toString());
      _isLoading = false;
      notifyListeners();
    }
  }

  Future getUserDataFromFirestore() async {
    DocumentSnapshot snapshot =
        await _firestore.collection("users").doc(_auth.currentUser!.uid).get();
    _userModel = UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
    _uid = getUserModel.uid;
  }

  Future saveUserToSP() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_model", jsonEncode(getUserModel.toMap()));
  }

  Future getDataFromSP() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> map = jsonDecode(prefs.getString("user_model") ?? "");
    _userModel = UserModel.fromMap(map);
    _uid = _userModel!.uid;
    notifyListeners();
  }

  Future signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _auth.signOut();
    _isSignedIn = false;
    notifyListeners();
  }
}
