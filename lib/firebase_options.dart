import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBF35MFcYTmIWyU14JwgowDqp1fF_yEFeM',
    appId: '1:242887564068:web:9b93cbd6215ae95e68b1b1',
    messagingSenderId: '242887564068',
    projectId: 'easternrp-cd71e',
    authDomain: 'easternrp-cd71e.firebaseapp.com',
    storageBucket: 'easternrp-cd71e.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBF35MFcYTmIWyU14JwgowDqp1fF_yEFeM',
    appId: '1:242887564068:android:fbdf2b8c548b99f368b1b1',
    messagingSenderId: '242887564068',
    projectId: 'easternrp-cd71e',
    storageBucket: 'easternrp-cd71e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCDm66lp40P1NAjxJMLtySHVtU-z2BR0v4',
    appId: '1:242887564068:ios:95ea907c8bc4575b68b1b1',
    messagingSenderId: '242887564068',
    projectId: 'easternrp-cd71e',
    storageBucket: 'easternrp-cd71e.firebasestorage.app',
    iosBundleId: 'com.example.files',
  );
}
