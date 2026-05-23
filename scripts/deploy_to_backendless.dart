import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

const String appId = '8ADEB922-FBDE-4DF0-8B4B-01090D72F1C9';
const String apiKey = '9B648E1D-5CA4-4EC8-A676-0E128B0AB2F5';
const String baseDir = 'build/web';

void main() async {
  final dir = Directory(baseDir);
  if (!await dir.exists()) {
    print('Error: build/web does not exist. Run flutter build web first.');
    exit(1);
  }

  print('--- Backendless Multi-Path Deployment Script ---');
  print('App ID: $appId');
  print('Source: $baseDir');
  print('------------------------------------------------');

  try {
    print('\nDeploying to Root (/) ...');
    await uploadDir(dir, '');
    
    print('\n\nDeploying to Web Folder (/web) ...');
    await uploadDir(dir, 'web');
    
    print('\n\nDeployment complete!');
    print('\nAccess your app at:');
    print('1. Custom Domain: https://sovereignintelligence.backendless.app');
    print('2. Direct Link:   https://api.backendless.com/$appId/$apiKey/files/web/index.html');
    print('3. Root Link:     https://api.backendless.com/$appId/$apiKey/files/index.html');
  } catch (e) {
    print('\nCritical error during deployment: $e');
    exit(1);
  }
}

Future<void> uploadDir(Directory dir, String remotePath) async {
  final entities = dir.listSync();
  for (final entity in entities) {
    final name = path.basename(entity.path);
    // Construct the remote path for this entity
    final entityRemotePath = remotePath.isEmpty ? name : '$remotePath/$name';
    
    if (entity is File) {
      await uploadFile(entity, entityRemotePath);
    } else if (entity is Directory) {
      await uploadDir(entity, entityRemotePath);
    }
  }
}

Future<void> uploadFile(File file, String remotePath) async {
  final normalizedPath = remotePath.replaceAll('\\', '/');
  final url = Uri.parse('https://api.backendless.com/$appId/$apiKey/files/$normalizedPath?overwrite=true');
  
  int attempts = 0;
  while (attempts < 3) {
    try {
      final request = http.MultipartRequest('POST', url)
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send().timeout(const Duration(minutes: 2));
      if (response.statusCode == 200) {
        stdout.write('.');
        return;
      } else {
        final body = await response.stream.bytesToString();
        print('\nFailed: $normalizedPath (Status: ${response.statusCode})');
        print('Error: $body');
        return;
      }
    } catch (e) {
      attempts++;
      if (attempts >= 3) {
        print('\nFailed: $normalizedPath after $attempts attempts. Error: $e');
        rethrow;
      }
      stdout.write('R'); // Retry indicator
      await Future.delayed(Duration(seconds: 2 * attempts));
    }
  }
}
