import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hides the app's contents from the phone's app switcher (and, on Android,
/// from the recent-apps thumbnail) while it is in the background.
///
/// Only the native shell can do this: the picture the system keeps is taken
/// the moment the app stops being active, before Flutter can draw anything.
abstract interface class PrivacyShield {
  Future<void> setEnabled(bool enabled);
}

/// Talks to the iOS and Android shells over one method channel. A platform
/// without a shell (tests, desktop) simply ignores the call.
final class ChannelPrivacyShield implements PrivacyShield {
  const ChannelPrivacyShield();

  static const _channel = MethodChannel('app.mooncycle/privacy_shield');

  @override
  Future<void> setEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setEnabled', enabled);
    } on MissingPluginException {
      // No native side on this platform.
    } on PlatformException {
      // The shield is a convenience; failing to set it must never break the app.
    }
  }
}

final privacyShieldProvider = Provider<PrivacyShield>(
  (ref) => const ChannelPrivacyShield(),
);
