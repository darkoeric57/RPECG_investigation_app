library backendless_sdk;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

class Backendless {
  static final UserService userService = UserService();
  static final Data data = Data();
  static final Files files = Files();
  
  static String? _appId;
  static String? _apiKey;

  static Future<void> initApp({
    String? applicationId,
    String? iosApiKey,
    String? androidApiKey,
    String? jsApiKey,
  }) async {
    _appId = applicationId;
    // Use JS API Key for REST calls in this fake implementation as it's most compatible with Web
    _apiKey = jsApiKey ?? androidApiKey ?? iosApiKey;
    debugPrint('FAKE_BACKENDLESS: Initialized with ID: $_appId');
  }

  static String get _baseUrl => 'https://api.backendless.com/$_appId/$_apiKey';
}

class Data {
  DataStore<Map<String, dynamic>> of(String tableName) => DataStore<Map<String, dynamic>>(tableName);
  // Support for specific types could be added if needed, but the current app uses Map mostly
}

class Files {
  Future<String?> upload(dynamic file, String path, {bool? overwrite}) async => null;
}

class BackendlessException {
  final String? code;
  final String? message;
  BackendlessException([this.code = '0', this.message = 'Unknown error']);
  @override
  String toString() => 'BackendlessException: $code - $message';
}

class UserService {
  static String? _userToken;
  static BackendlessUser? _currentUser;

  Future<BackendlessUser?> login(String email, String password, [bool? stayLoggedIn]) async {
    final response = await http.post(
      Uri.parse('${Backendless._baseUrl}/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _userToken = data['user-token'];
      final user = BackendlessUser()..email = email;
      user.putProperties(Map<String, dynamic>.from(data));
      _currentUser = user;
      return user;
    } else {
      final error = jsonDecode(response.body);
      throw BackendlessException(error['code']?.toString(), error['message']);
    }
  }

  Future<BackendlessUser?> register(BackendlessUser user) async {
    final body = Map<String, dynamic>.from(user.properties);
    body['email'] = user.email;
    body['password'] = user.password;

    final response = await http.post(
      Uri.parse('${Backendless._baseUrl}/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newUser = BackendlessUser()..email = user.email;
      newUser.putProperties(Map<String, dynamic>.from(data));
      return newUser;
    } else {
      final error = jsonDecode(response.body);
      throw BackendlessException(error['code']?.toString(), error['message']);
    }
  }

  Future<void> logout() async {
    await http.get(
      Uri.parse('${Backendless._baseUrl}/users/logout'),
      headers: _userToken != null ? {'user-token': _userToken!} : {},
    );
    _userToken = null;
    _currentUser = null;
  }

  Future<BackendlessUser?> getCurrentUser() async => _currentUser;
  Future<bool> isValidLogin() async => _userToken != null; 
  Future<BackendlessUser?> update(BackendlessUser user) async => user;
}

class BackendlessUser {
  String? email;
  String? password;
  Map<String, dynamic> properties = {};
  
  void setProperty(String key, dynamic value) => properties[key] = value;
  void putProperties(Map<String, dynamic> props) => properties.addAll(props);
  dynamic getProperty(String key) => properties[key];
  
  String? get userId => properties['objectId'];
  set userId(String? value) => properties['objectId'] = value;
}

class DataStore<T> {
  final String tableName;
  DataStore(this.tableName);

  Future<T?> save(T entity) async {
    final data = entity is Map ? entity : (entity as dynamic).toMap();
    final response = await http.post(
      Uri.parse('${Backendless._baseUrl}/data/$tableName'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as T;
    } else {
      final error = jsonDecode(response.body);
      throw BackendlessException(error['code']?.toString(), error['message']);
    }
  }

  Future<List<T>?> find([dynamic query]) async {
    String? whereClause;
    if (query is DataQueryBuilder) {
      whereClause = query._where;
    }

    var url = '${Backendless._baseUrl}/data/$tableName';
    if (whereClause != null) {
      url += '?where=${Uri.encodeComponent(whereClause)}';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<T>().toList();
    } else {
      final error = jsonDecode(response.body);
      throw BackendlessException(error['code']?.toString(), error['message']);
    }
  }
}

class DataQueryBuilder {
  String? _where;
  static DataQueryBuilder create() => DataQueryBuilder();
  void whereClause(String where) => _where = where;
}

