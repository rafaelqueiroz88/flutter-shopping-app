import 'dart:convert';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../models/http_exception.dart';

class Auth with ChangeNotifier {
  String? _token;
  String? _userId;
  DateTime? _expiryDate = DateTime.now();
  Timer? _authTimer;

  bool get isAuth {
    return token != null;
  }

  String? get token {
    if (_expiryDate != null &&
        _expiryDate!.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }

    return null;
  }

  String? get userId {
    return _userId;
  }

  Future<void> _authenticate(
      String email, String password, String action) async {
    final url = '${Constants.baseAuthApi}:$action?key=${Constants.apiKey}';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: json.encode(
          {'email': email, 'password': password, 'returnSecureToken': true},
        ),
      );

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['error'] != null) {
        throw HttpException(jsonResponse['error']['message']);
      }

      _token = jsonResponse['idToken'];
      _userId = jsonResponse['localId'];
      _expiryDate = DateTime.now()
          .add(Duration(seconds: int.parse(jsonResponse['expiresIn'])));

      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('token', _token!);
      await preferences.setString('userId', _userId!);
      await preferences.setString('expiryDate', _expiryDate.toString());

      _autoLogout();

      notifyListeners();
    } catch (err) {
      throw err;
    }
  }

  Future<void> signup(String email, String password) async {
    return _authenticate(email, password, 'signUp');
  }

  Future<void> login(String email, String password) async {
    return _authenticate(email, password, 'signInWithPassword');
  }

  Future<bool> tryAutoLogin() async {
    final preferences = await SharedPreferences.getInstance();
    if (!preferences.containsKey('token')) return false;

    _token = preferences.getString('token');
    _userId = preferences.getString('userId');

    final DateTime expiration =
        DateTime.parse(preferences.getString('expiryDate') as String);

    if (expiration.isBefore(DateTime.now())) return false;

    _token = preferences.getString('token');
    _userId = preferences.getString('userId');
    _expiryDate = DateTime.parse(preferences.getString('expiryDate') as String);

    notifyListeners();
    _autoLogout();

    return true;
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _expiryDate = null;

    if (_authTimer != null) {
      _authTimer!.cancel();
      _authTimer = null;
    }

    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    preferences.remove('token');
    preferences.remove('userId');
    preferences.remove('expiryDate');
  }

  void _autoLogout() {
    if (_authTimer != null) _authTimer!.cancel();

    final expiration = _expiryDate?.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: expiration as int), logout);
  }
}
