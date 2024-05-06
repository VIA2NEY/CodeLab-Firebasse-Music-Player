import 'dart:io';

import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:music_player/firebase_options.dart';
import 'package:music_player/src/authentication.dart';

class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    init();
  }

  String? _deviceId;
  String? _uid;

  Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loginState = ApplicationLoginState.loggedIn;
        _uid = user.uid;
        _addUserDevice();
      } else {
        _loginState = ApplicationLoginState.loggedOut;
      }
      notifyListeners();
    });
  }

  ApplicationLoginState _loginState = ApplicationLoginState.loggedOut;
  ApplicationLoginState get loginState => _loginState;

  String? _email;
  String? get email => _email;

  void startLoginFlow() {
    _loginState = ApplicationLoginState.emailAddress;
    notifyListeners();
  }

  Future<void> verifyEmail(
    String email,
    void Function(FirebaseAuthException e) errorCallback,
  ) async {
    try {
      var methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.contains('password')) {
        _loginState = ApplicationLoginState.password;
      } else {
        _loginState = ApplicationLoginState.register;
      }
      _email = email;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  Future<void> signInWithEmailAndPassword(
    String email,
    String password,
    void Function(FirebaseAuthException e) errorCallback,
  ) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  void cancelRegistration() {
    _loginState = ApplicationLoginState.emailAddress;
    notifyListeners();
  }

  Future<void> registerAccount(
      String email,
      String displayName,
      String password,
      void Function(FirebaseAuthException e) errorCallback) async {
    try {
      var credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await credential.user!.updateDisplayName(displayName);
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  void signOut() {
    FirebaseAuth.instance.signOut();
  }

  Future<void> _addUserDevice() async {
    _uid = FirebaseAuth.instance.currentUser?.uid;

    String deviceType = _getDevicePlatform();
    // Create two objects which we will write to the
    // Realtime database when this device is offline or online
    var isOfflineForDatabase = {
      'type': deviceType,
      'state': 'offline',
      'last_changed': ServerValue.timestamp,
    };
    var isOnlineForDatabase = {
      'type': deviceType,
      'state': 'online',
      'last_changed': ServerValue.timestamp,
    };

    var devicesRef =
        FirebaseDatabase.instance.ref().child('/users/$_uid/devices');

    FirebaseInstallations.instance
        .getId()
        .then((id) => _deviceId = id)
        .then((_) {
      // Use the semi-persistent Firebase Installation Id to key devices
      var deviceStatusRef = devicesRef.child('$_deviceId');

      // RTDB Presence API
      FirebaseDatabase.instance
          .ref()
          .child('.info/connected')
          .onValue
          .listen((data) {
        if (data.snapshot.value == false) {
          return;
        }

        deviceStatusRef.onDisconnect().set(isOfflineForDatabase).then((_) {
          deviceStatusRef.set(isOnlineForDatabase);
        });
      });
    });
  }

  String _getDevicePlatform() {
    if (kIsWeb) {
      return 'Web';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else if (Platform.isAndroid) {
      return 'Android';
    }
    return 'Unknown';
  }
  
  
}