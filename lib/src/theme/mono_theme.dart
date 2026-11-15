import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../tokens/tokens.g.dart';

/// Gives the tokens of the language to the widgets below it.
///
/// With no [brightness], the platform brightness of the [MediaQuery] applies. With no [density], the density of the
/// platform applies (see [platformDensity]). A [MonoTheme] in a different [MonoTheme] keeps the axis that it does not
/// set: `MonoTheme(density: MonoDensity.touch, child: ...)` keeps the theme of the [MonoTheme] above it.
class MonoTheme extends StatelessWidget {
  /// Applies [brightness] and [density] to [child]. A null value keeps the context above.
  const MonoTheme({
    super.key,
    this.brightness,
    this.density,
    required this.child,
  });

  /// The context of the axis theme. If it is null, the context above applies.
  final Brightness? brightness;

  /// The context of the axis density. If it is null, the context above applies.
  final MonoDensity? density;

  /// The widgets that get the tokens.
  final Widget child;

  /// The tokens of [context]. With no [MonoTheme] above [context], the settings of the platform apply.
  static MonoTokens of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MonoScope>()?.tokens ??
      MonoTokens(
        brightness:
            MediaQuery.maybePlatformBrightnessOf(context) ??
            const MonoTokens().brightness,
        density: platformDensity(defaultTargetPlatform),
      );

  @override
  Widget build(BuildContext context) {
    final above = MonoTheme.of(context);
    return _MonoScope(
      tokens: MonoTokens(
        brightness: brightness ?? above.brightness,
        density: density ?? above.density,
      ),
      child: child,
    );
  }
}

/// The density of [platform]: touch on Android, iOS, and Fuchsia, and pointer on the desktop platforms.
MonoDensity platformDensity(TargetPlatform platform) => switch (platform) {
  TargetPlatform.android ||
  TargetPlatform.iOS ||
  TargetPlatform.fuchsia => MonoDensity.touch,
  TargetPlatform.linux ||
  TargetPlatform.macOS ||
  TargetPlatform.windows => MonoDensity.pointer,
};

class _MonoScope extends InheritedWidget {
  const _MonoScope({required this.tokens, required super.child});

  final MonoTokens tokens;

  @override
  bool updateShouldNotify(_MonoScope oldWidget) => tokens != oldWidget.tokens;
}

/// The tokens of the language for a [BuildContext].
extension MonoContext on BuildContext {
  /// The tokens for this context, for example `context.mono.color.accent`. The same as [MonoTheme.of].
  MonoTokens get mono => MonoTheme.of(this);
}
