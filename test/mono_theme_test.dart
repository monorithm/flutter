import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monorithm_ui/monorithm_ui.dart';

/// Builds [child] in a MediaQuery with [brightness], and returns the tokens of the widget in the middle.
Future<MonoTokens> _tokens(
  WidgetTester tester, {
  required Brightness brightness,
  required Widget Function(Widget probe) wrap,
}) async {
  late MonoTokens tokens;
  final probe = Builder(
    builder: (context) {
      tokens = context.mono;
      return const SizedBox();
    },
  );
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(platformBrightness: brightness),
      child: wrap(probe),
    ),
  );
  return tokens;
}

void main() {
  testWidgets(
    'theme/platform: with no MonoTheme, the settings of the platform apply',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final tokens = await _tokens(
        tester,
        brightness: Brightness.light,
        wrap: (probe) => probe,
      );
      debugDefaultTargetPlatformOverride = null;
      expect(tokens.brightness, Brightness.light);
      expect(tokens.density, MonoDensity.pointer);
      expect(tokens.color.accent, MonoColor.light.accent);
    },
  );

  testWidgets('theme/override: a MonoTheme sets the axes of its widgets', (
    tester,
  ) async {
    final tokens = await _tokens(
      tester,
      brightness: Brightness.light,
      wrap: (probe) => MonoTheme(
        brightness: Brightness.dark,
        density: MonoDensity.touch,
        child: probe,
      ),
    );
    expect(tokens.color, same(MonoColor.dark));
    expect(tokens.size.controlMd, MonoSize.touch.controlMd);
  });

  testWidgets('theme/nested: a MonoTheme keeps the axis that it does not set', (
    tester,
  ) async {
    final tokens = await _tokens(
      tester,
      brightness: Brightness.dark,
      wrap: (probe) => MonoTheme(
        brightness: Brightness.light,
        density: MonoDensity.touch,
        child: MonoTheme(density: MonoDensity.pointer, child: probe),
      ),
    );
    expect(tokens.brightness, Brightness.light);
    expect(tokens.density, MonoDensity.pointer);
  });

  test(
    'theme/density: touch on the phone platforms, pointer on the desktop',
    () {
      expect(platformDensity(TargetPlatform.android), MonoDensity.touch);
      expect(platformDensity(TargetPlatform.iOS), MonoDensity.touch);
      expect(platformDensity(TargetPlatform.macOS), MonoDensity.pointer);
      expect(platformDensity(TargetPlatform.windows), MonoDensity.pointer);
    },
  );
}
