import 'package:flutter/foundation.dart';

/// Demo build flag. Turned on with `--dart-define=DEMO_MODE=true`.
///
/// A demo build exists to show the app to people with nothing in the way:
///
///   * **Pro is unlocked locally.** Every gate opens. RevenueCat is still
///     configured, so the paywall can still be shown on purpose with real
///     prices from the offering.
///   * **No sign-in screen.** The app opens an anonymous Firebase session in
///     the background, which is enough to register for push.
///   * **Onboarding replays on every launch**, so the first-run experience can
///     be shown again and again.
///   * **Notifications start on `instant`** so pushes can be tested.
///
/// `&& !kReleaseMode` is a safety catch: a store build ignores the flag
/// entirely, so an accidental `--dart-define` can never ship unlocked Pro.
const bool kDemoMode = bool.fromEnvironment('DEMO_MODE') && !kReleaseMode;
