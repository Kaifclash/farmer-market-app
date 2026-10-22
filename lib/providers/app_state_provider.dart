import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds onboarding state that is not tied to a signed-in user.
class AppStateProvider extends ChangeNotifier {
  static const _onboardingKey = 'onboarding_done';

  bool _onboardingDone = false;
  bool get onboardingDone => _onboardingDone;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingDone = prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    _onboardingDone = true;
    notifyListeners();
  }
}
