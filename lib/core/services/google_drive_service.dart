import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart' as auth;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import '../config/app_config.dart';

class GoogleDriveService {
  static const _folderId = AppConfig.googleDriveFolderId;
  
  final auth.GoogleSignIn _googleSignIn = auth.GoogleSignIn.instance;
  auth.GoogleSignInAccount? _currentUser;

  Stream<auth.GoogleSignInAccount?> get onCurrentUserChanged => 
    _googleSignIn.authenticationEvents.map((event) {
      if (event is auth.GoogleSignInAuthenticationEventSignIn) {
        _currentUser = event.user;
        return event.user;
      } else if (event is auth.GoogleSignInAuthenticationEventSignOut) {
        _currentUser = null;
        return null;
      }
      return _currentUser;
    });

  auth.GoogleSignInAccount? get currentUser => _currentUser;

  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.authenticate(
        scopeHint: [drive.DriveApi.driveFileScope],
      );
      _currentUser = account;
      return true;
    } catch (e, stack) {
      print('Sign-in failed: $e\n$stack');
      return false;
    }
  }

  Future<bool> isSignedIn() async {
    return _currentUser != null;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  Future<String?> uploadFile({
    required File file,
    required String fileName,
  }) async {
    final scopes = [drive.DriveApi.driveFileScope];
    final currentAccount = _currentUser;
    
    if (currentAccount == null) {
      final signedIn = await signIn();
      if (!signedIn || _currentUser == null) throw Exception('User not signed in to Google Drive');
    }

    final finalAuthz = await _currentUser!.authorizationClient.authorizeScopes(scopes);
    final client = finalAuthz.authClient(scopes: scopes);

    final driveApi = drive.DriveApi(client);

    final extension = fileName.split('.').last.toLowerCase();
    String mimeType = 'application/octet-stream';
    if (extension == 'jpg' || extension == 'jpeg') mimeType = 'image/jpeg';
    if (extension == 'png') mimeType = 'image/png';
    if (extension == 'mp4') mimeType = 'video/mp4';

    final media = drive.Media(file.openRead(), file.lengthSync(), contentType: mimeType);
    
    final driveFile = drive.File();
    driveFile.name = fileName;
    driveFile.parents = [_folderId];

    try {
      final response = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
        supportsAllDrives: true,
      );

      if (response.id != null) {
        return 'https://drive.google.com/uc?export=view&id=${response.id}';
      }
      return null;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('storage quota')) {
        throw Exception('QUOTA_ERROR: Storage quota exceeded. Please clear some space in your Google Drive or use a different account.');
      }
      if (errorStr.contains('insufficient permissions') || errorStr.contains('403')) {
        throw Exception('PERMISSION_ERROR: You do not have permission to upload to this shared folder. Please contact the administrator.');
      }
      rethrow;
    }
  }
}

