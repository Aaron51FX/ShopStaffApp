import 'package:flutter/foundation.dart';

class AuthenticationChangeNotifier extends ChangeNotifier {
  void notifyAuthenticationChanged() => notifyListeners();
}

final authenticationChangeNotifier = AuthenticationChangeNotifier();
