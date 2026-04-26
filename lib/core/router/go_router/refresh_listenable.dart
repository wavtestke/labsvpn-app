import 'package:flutter/material.dart';
import 'package:labsvpn/core/preferences/general_preferences.dart';
import 'package:labsvpn/core/router/deep_linking/my_app_links.dart';
import 'package:labsvpn/features/profile/notifier/active_profile_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// For temporary storage of the link received from AppLinks.
String newUrlFromAppLink = '';

class RefreshListenable extends ChangeNotifier {
  RefreshListenable(this.ref) {
    ref.listen(myAppLinksProvider, (_, next) {
      if (next.value != null) {
        newUrlFromAppLink = next.value!;
        notifyListeners();
      }
    });
    ref.listen(Preferences.introCompleted, (_, _) => notifyListeners());
    // Re-evaluate redirect when profile list changes so Intro shows if no profile
    ref.listen(hasAnyProfileProvider, (_, _) => notifyListeners());
  }
  final Ref ref;
}
