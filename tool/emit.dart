// The emitter of monorithm_ui. It reads only the intermediate form (IR) of the language: ir/<version>/ of the
// submodule design/ (monorithm/design at a tag), at the version of that checkout. It writes:
//   lib/src/tokens/tokens.g.dart   the tokens as Dart constants
//
//   dart run tool/emit.dart           write the file
//   dart run tool/emit.dart --check   fail if a file of the IR does not match its checksum in the manifest, or if the
//                                     committed file differs from the output (the drift check of CI)
//
// The file has one class for each group of tokens: the first part of the token path (color, size, radius, and the
// other groups). A group that changes with an axis has one const instance for each context of the axis, for example
// MonoColor.dark and MonoColor.light. MonoTokens selects the instances for one context of each axis.
//
// The axes: the axis theme is the Brightness of Flutter. The axis density is the enum MonoDensity. The emitter stops
// with an error for a different axis.
//
// This emitter is a stub. It writes the tokens of four types: color, dimension, duration, and number. The other types
// (cubicBezier, fontWeight, shadow, transition) come with the components that use them.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// The folder of the submodule of the language source.
const designDir = 'design';

/// The generated file.
const output = 'lib/src/tokens/tokens.g.dart';

/// The language version: the version of the checked-out language source.
String languageVersion() =>
    (_json('$designDir/package.json') as Map<String, dynamic>)['version']
        as String;

/// The IR of that version.
String irDir() => '$designDir/ir/${languageVersion()}';

Object? _json(String path) => jsonDecode(File(path).readAsStringSync());

/// Stops with an error if a file of the IR does not match its checksum in the manifest, or if the versions differ.
void verifyIr() {
  final dir = irDir();
  final manifest = _json('$dir/manifest.json') as Map<String, dynamic>;
  if (manifest['language'] != languageVersion()) {
    throw StateError(
      'The IR is language ${manifest['language']}, the source is ${languageVersion()}',
    );
  }
  final files = manifest['files'] as Map<String, dynamic>;
  for (final MapEntry(key: name, value: sum) in files.entries) {
    final actual = sha256
        .convert(File('$dir/$name').readAsBytesSync())
        .toString();
    if (actual != sum) {
      throw StateError(
        'The IR file $name does not match its checksum in the manifest',
      );
    }
  }
}

/// The types of the stub.
const _types = {'color', 'dimension', 'duration', 'number'};

/// The Dart words that cannot be a member name.
const _reserved = {
  'assert',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'default', //
  'do', 'else', 'enum', 'extends', 'false', 'final', 'finally', 'for', 'if', //
  'in', 'is', 'new', 'null', 'rethrow', 'return', 'super', 'switch', 'this', //
  'throw', 'true', 'try', 'var', 'void', 'while', 'with', 'hashCode', //
};

List<String> _words(Iterable<String> parts) => [
  for (final p in parts) ...p.split('-'),
];

String _pascal(Iterable<String> words) =>
    words.map((w) => w[0].toUpperCase() + w.substring(1)).join();

String _camel(List<String> words) => words.first + _pascal(words.skip(1));

/// The group of a token: the first part of its path, for example font-size.
String groupOf(String path) => path.split('.').first;

/// The name of the class of a group: font-size gives MonoFontSize.
String groupClass(String group) => 'Mono${_pascal(_words([group]))}';

/// The name of the getter of a group in MonoTokens: font-size gives fontSize.
String groupGetter(String group) => _camel(_words([group]));

/// The name of a token in its group, in lowerCamelCase: size.control-md gives controlMd. In the group color, the
/// colors of the roles have no prefix: color.role.accent-fg gives accentFg. A name that starts with a digit gets the
/// prefix x: space.4 gives x4.
String memberName(String path) {
  var parts = path.split('.').skip(1).toList();
  if (groupOf(path) == 'color' && parts.first == 'role') {
    parts = parts.skip(1).toList();
  }
  final name = _camel(_words(parts));
  return RegExp(r'^[0-9]').hasMatch(name) ? 'x$name' : name;
}

/// A color of the IR as a Dart constant.
String _color(Map<String, dynamic> c) {
  final hex = (c['hex'] as String).substring(1).toUpperCase();
  final alpha = (c['alpha'] as num).toDouble();
  if (alpha == 1) return 'Color(0xFF$hex)';
  String channel(int i) =>
      (int.parse(hex.substring(i, i + 2), radix: 16) / 255).toString();
  return 'Color.from(alpha: $alpha, red: ${channel(0)}, green: ${channel(2)}, blue: ${channel(4)})';
}

/// The Dart type and the Dart constant of a plain value of the four types of the stub.
(String, String) _value(String type, Object? v) {
  switch (type) {
    case 'color':
      return ('Color', _color(v as Map<String, dynamic>));
    case 'dimension':
      final d = v as Map<String, dynamic>;
      if (d['unit'] != 'px') {
        throw StateError('The emitter knows only px, not ${d['unit']}');
      }
      return ('double', '${(d['value'] as num).toDouble()}');
    case 'duration':
      final d = v as Map<String, dynamic>;
      if (d['unit'] != 'ms') {
        throw StateError('The emitter knows only ms, not ${d['unit']}');
      }
      return ('Duration', 'Duration(milliseconds: ${d['value']})');
    case 'number':
      return ('double', '${(v as num).toDouble()}');
  }
  throw StateError('The stub does not emit the type $type');
}

/// An axis in Dart: the type, the field of MonoTokens, and the Dart value of a context.
typedef _Axis = ({String type, String field, String Function(String) value});

_Axis _axis(String axis, List<String> contexts) {
  switch (axis) {
    case 'theme':
      if (!contexts.every({'dark', 'light'}.contains)) {
        throw StateError('Brightness has no context ${contexts.join(', ')}');
      }
      return (
        type: 'Brightness',
        field: 'brightness',
        value: (c) => 'Brightness.$c',
      );
    case 'density':
      return (
        type: 'MonoDensity',
        field: 'density',
        value: (c) => 'MonoDensity.$c',
      );
  }
  throw StateError('The emitter does not know the axis $axis');
}

/// One token of a group.
typedef _Token = ({
  String path,
  String name,
  String type,
  String? description,
  String? axis,
  Map<String, String> values,
});

/// The text of the generated file.
String emit() {
  final dir = irDir();
  final canonical = _json('$dir/canonical.json') as Map<String, dynamic>;
  final axesJson = _json('$dir/axes.json') as Map<String, dynamic>;
  final manifest = _json('$dir/manifest.json') as Map<String, dynamic>;

  final axes = <String, ({List<String> contexts, String fallback, _Axis dart})>{
    for (final MapEntry(key: axis, value: a as Map<String, dynamic>)
        in axesJson.entries)
      axis: (
        contexts: (a['contexts'] as List).cast<String>(),
        fallback: a['default'] as String,
        dart: _axis(axis, (a['contexts'] as List).cast<String>()),
      ),
  };

  // The tokens of the four types, by group, in the order of the IR. A token with no axis has one value with the key ''.
  final groups = <String, List<_Token>>{};
  for (final MapEntry(key: path, value: e as Map<String, dynamic>)
      in canonical.entries) {
    final type = e['type'] as String;
    if (!_types.contains(type)) continue;
    final tokenAxes = (e['axes'] as List?)?.cast<String>() ?? const [];
    if (tokenAxes.length > 1) {
      throw StateError(
        '$path changes with ${tokenAxes.join(' and ')}: the emitter knows one axis for each token',
      );
    }
    final values = tokenAxes.isEmpty
        ? {'': _value(type, e['value']).$2}
        : {
            for (final MapEntry(key: k, value: v)
                in (e['values'] as Map<String, dynamic>).entries)
              // A key of values is <axis>=<context>, for example theme=dark.
              k.split('=')[1]: _value(type, v).$2,
          };
    final name = memberName(path);
    if (_reserved.contains(name)) {
      throw StateError('The name $name of $path is a word of Dart');
    }
    (groups[groupOf(path)] ??= []).add((
      path: path,
      name: name,
      type: _value(
        type,
        tokenAxes.isEmpty ? e['value'] : (e['values'] as Map).values.first,
      ).$1,
      description: (e['description'] as String?)?.trim().replaceAll(
        RegExp(r'\s+'),
        ' ',
      ),
      axis: tokenAxes.isEmpty ? null : tokenAxes.single,
      values: values,
    ));
  }

  final out = StringBuffer()
    ..writeln(
      '// Generated by tool/emit.dart from design/ir/${manifest['language']}/. Do not edit: change the language source.',
    )
    ..writeln()
    ..writeln("import 'dart:ui' show Brightness, Color;")
    ..writeln()
    ..writeln('/// The language version of these tokens.')
    ..writeln("const String language = '${manifest['language']}';")
    ..writeln()
    ..writeln(
      '/// The contexts of the axis density. The fallback is ${axes['density']!.fallback}.',
    )
    ..writeln('enum MonoDensity { ${axes['density']!.contexts.join(', ')} }');

  // The axis of each group. A group has a maximum of one axis.
  final groupAxis = <String, String?>{};
  for (final MapEntry(key: group, value: tokens) in groups.entries) {
    final used = {for (final t in tokens) ?t.axis};
    if (used.length > 1) {
      throw StateError(
        'The group $group changes with ${used.join(' and ')}: the emitter knows one axis for each group',
      );
    }
    final names = {for (final t in tokens) t.name};
    if (names.length != tokens.length) {
      throw StateError('Two tokens of the group $group have the same name');
    }
    groupAxis[group] = used.firstOrNull;
  }

  // MonoTokens: the instances of the groups for one context of each axis.
  out
    ..writeln()
    ..writeln(
      '/// The tokens for one context of each axis: the theme ([brightness]) and the [density].',
    )
    ..writeln('///')
    ..writeln(
      '/// Get the tokens of a widget with `context.mono` or `MonoTheme.of(context)`.',
    )
    ..writeln('final class MonoTokens {')
    ..writeln(
      '  /// The tokens for [brightness] and [density]. The fallbacks are the fallbacks of the axes.',
    )
    ..writeln(
      '  const MonoTokens({${[for (final a in axes.values) 'this.${a.dart.field} = ${a.dart.value(a.fallback)}'].join(', ')}});',
    );
  for (final MapEntry(key: axis, value: a) in axes.entries) {
    out
      ..writeln()
      ..writeln('  /// The context of the axis $axis.')
      ..writeln('  final ${a.dart.type} ${a.dart.field};');
  }
  for (final group in groups.keys) {
    final cls = groupClass(group);
    final axis = groupAxis[group];
    out.writeln();
    if (axis == null) {
      out
        ..writeln('  /// The tokens $group.*. They do not change with an axis.')
        ..writeln('  $cls get ${groupGetter(group)} => $cls.standard;');
      continue;
    }
    final a = axes[axis]!;
    out
      ..writeln('  /// The tokens $group.* for the context of the axis $axis.')
      ..writeln(
        '  $cls get ${groupGetter(group)} => switch (${a.dart.field}) { ${[for (final c in a.contexts) '${a.dart.value(c)} => $cls.$c'].join(', ')} };',
      );
  }
  out
    ..writeln()
    ..writeln('  @override')
    ..writeln(
      '  bool operator ==(Object other) => other is MonoTokens && ${[for (final a in axes.values) 'other.${a.dart.field} == ${a.dart.field}'].join(' && ')};',
    )
    ..writeln()
    ..writeln('  @override')
    ..writeln(
      '  int get hashCode => Object.hash(${[for (final a in axes.values) a.dart.field].join(', ')});',
    )
    ..writeln('}');

  // One class for each group, with one const instance for each context of its axis.
  for (final MapEntry(key: group, value: tokens) in groups.entries) {
    final cls = groupClass(group);
    final axis = groupAxis[group];
    final instances = axis == null ? ['standard'] : axes[axis]!.contexts;
    out
      ..writeln()
      ..writeln(
        axis == null
            ? '/// The tokens $group.*. They do not change with an axis.'
            : '/// The tokens $group.*, with one instance for each context of the axis $axis.',
      )
      ..writeln('final class $cls {')
      ..writeln(
        '  const $cls._({${tokens.map((t) => 'required this.${t.name}').join(', ')}});',
      );
    for (final instance in instances) {
      final args = [
        for (final t in tokens)
          '${t.name}: ${t.values[t.axis == null ? '' : instance]!}',
      ];
      out
        ..writeln()
        ..writeln(
          axis == null
              ? '  /// The values of the tokens.'
              : '  /// The values for the context $instance of the axis $axis.',
        )
        ..writeln('  static const $instance = $cls._(${args.join(', ')});');
    }
    for (final t in tokens) {
      out
        ..writeln()
        ..writeln(
          t.description == null
              ? '  /// The token ${t.path}.'
              : '  /// ${t.path}: ${t.description}',
        )
        ..writeln('  final ${t.type} ${t.name};');
    }
    out.writeln('}');
  }
  return out.toString();
}

void main(List<String> args) {
  final text = emit();
  final file = File(output);
  if (args.contains('--check')) {
    verifyIr();
    if (!file.existsSync() || file.readAsStringSync() != text) {
      stderr.writeln(
        'emit: $output differs from the output of the emitter. Run: dart run tool/emit.dart',
      );
      exitCode = 1;
      return;
    }
    stdout.writeln(
      'emit: the IR of language ${languageVersion()} matches its manifest, and $output matches the IR.',
    );
    return;
  }
  file
    ..createSync(recursive: true)
    ..writeAsStringSync(text);
  stdout.writeln('emit: wrote $output');
}
