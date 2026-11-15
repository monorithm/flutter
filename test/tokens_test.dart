import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Brightness, Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:monorithm_ui/monorithm_ui.dart';

// The tests run from the root of the package. They read the pinned IR in the submodule design/.
Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Color _color(Map<String, dynamic> c) {
  final rgb = int.parse((c['hex'] as String).substring(1), radix: 16);
  final alpha = (c['alpha'] as num).toDouble();
  if (alpha == 1) return Color(0xFF000000 | rgb);
  return Color.from(
    alpha: alpha,
    red: (rgb >> 16 & 0xFF) / 255,
    green: (rgb >> 8 & 0xFF) / 255,
    blue: (rgb & 0xFF) / 255,
  );
}

double _px(Object? d) =>
    ((d as Map<String, dynamic>)['value'] as num).toDouble();

void main() {
  final version = _json('design/package.json')['version'] as String;
  final canonical = _json('design/ir/$version/canonical.json');
  Map<String, dynamic> token(String path) =>
      canonical[path] as Map<String, dynamic>;
  Map<String, dynamic> values(String path) =>
      token(path)['values'] as Map<String, dynamic>;

  test('tokens/ir: the generated tokens have the values of the pinned IR', () {
    expect(language, version);

    // A color with no axis has the same value in each theme.
    final amber = _color(
      token('color.amber.400')['value'] as Map<String, dynamic>,
    );
    expect(MonoColor.dark.amber400, amber);
    expect(MonoColor.light.amber400, amber);

    // A color of a role, of the axis theme.
    final accent = values('color.role.accent');
    expect(
      MonoColor.dark.accent,
      _color(accent['theme=dark'] as Map<String, dynamic>),
    );
    expect(
      MonoColor.light.accent,
      _color(accent['theme=light'] as Map<String, dynamic>),
    );

    // A color with an alpha less than 1.
    expect(
      MonoColor.light.avatarRing,
      _color(
        values('color.avatar.ring')['theme=light'] as Map<String, dynamic>,
      ),
    );

    // A dimension of the axis density.
    final control = values('size.control-md');
    expect(MonoSize.pointer.controlMd, _px(control['density=pointer']));
    expect(MonoSize.touch.controlMd, _px(control['density=touch']));

    // A name that starts with a digit, a duration, and a number.
    expect(MonoSpace.touch.x4, _px(token('space.4')['value']));
    expect(
      MonoDuration.standard.press,
      Duration(
        milliseconds: (token('duration.press')['value'] as Map)['value'] as int,
      ),
    );
    expect(MonoOpacity.standard.disabled, token('opacity.disabled')['value']);
  });

  test('tokens/axes: MonoTokens selects the instances of each context', () {
    const tokens = MonoTokens(
      brightness: Brightness.light,
      density: MonoDensity.touch,
    );
    expect(tokens.color, same(MonoColor.light));
    expect(tokens.size, same(MonoSize.touch));
    expect(tokens.duration, same(MonoDuration.standard));

    // The fallbacks of the axes of the IR: dark and pointer.
    expect(const MonoTokens().color, same(MonoColor.dark));
    expect(const MonoTokens().size, same(MonoSize.pointer));
  });
}
