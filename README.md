# monorithm_ui

The Flutter package of the Monorithm Experience Language. It will give the components of the language as Flutter widgets, with the tokens of the language.

At this time the package is a skeleton. It has the tokens of language 0.4.0, the widget `MonoTheme`, and no components. The 20 components of version 1 follow in the order of the list in `monorithm/design` (`contracts/v1-components.md`).

## Use the package

The package is not on pub.dev at this time.

1. Add the package to `pubspec.yaml` as a git dependency:

```yaml
dependencies:
  monorithm_ui:
    git:
      url: https://github.com/monorithm/flutter.git
      ref: main
```

2. Get the tokens of a widget with `context.mono`:

```dart
import 'package:flutter/widgets.dart';
import 'package:monorithm_ui/monorithm_ui.dart';

class Field extends StatelessWidget {
  const Field({super.key});

  @override
  Widget build(BuildContext context) {
    final mono = context.mono;
    return Container(
      height: mono.size.controlMd,
      padding: EdgeInsets.symmetric(horizontal: mono.space.x4),
      decoration: BoxDecoration(
        color: mono.color.surface,
        borderRadius: BorderRadius.circular(mono.radius.md),
      ),
    );
  }
}
```

The language has two axes: the theme (dark or light) and the density (pointer or touch). `context.mono` gives the tokens for the context of each axis:

- The theme is the platform brightness, from the `MediaQuery`.
- The density is touch on Android, iOS, and Fuchsia, and pointer on the desktop platforms.

3. To set an axis for a part of the app, put a `MonoTheme` above it. A `MonoTheme` keeps the axis that it does not set:

```dart
MonoTheme(
  brightness: Brightness.light,
  child: MonoTheme(density: MonoDensity.touch, child: app),
)
```

The tokens are in groups: `color`, `size`, `radius`, `space`, `fontSize`, `focus`, `duration`, `opacity`, and `scale`. A group is the first part of the token path: `size.control-md` is `mono.size.controlMd`. In the group `color`, the colors of the roles have no prefix: `color.role.surface` is `mono.color.surface`. A name that starts with a digit gets the prefix `x`: `space.4` is `mono.space.x4`.

Outside a widget, use the const instance of a context, for example `MonoColor.dark.accent` or `MonoSize.touch.controlMd`.

## How the package gets the language

The language source is the git submodule `design/`. It is `github.com/monorithm/design` at the commit of one tag, for example `v0.4.0`. The emitter reads `design/ir/<version>/`. The version is the version in `design/package.json`.

| Step | Command | Result |
| --- | --- | --- |
| Get the language | `git submodule update --init` | Checks out the pinned commit of the language source |
| Change the version | `git -C design fetch --tags`, then `git -C design checkout v<version>`, then `git add design` | Pins the commit of that tag |
| Emit | `dart run tool/emit.dart` | Writes `lib/src/tokens/tokens.g.dart` from `ir/<version>/` |
| Drift check | `dart run tool/emit.dart --check` | Stops with an error if a file of the IR does not match its checksum in the manifest. Also stops if the generated file differs from the output of the emitter |

Do not edit `lib/src/tokens/`. Change the language source in `monorithm/design`, tag a version, then change the version here and emit again.

The emitter writes one class for each group, with one const instance for each context of the axis of the group. `MonoTokens` selects the instances for one context of each axis. The emitter is a stub at this time. It writes the tokens of four types: the colors, the dimensions (in logical pixels), the durations, and the numbers. The other types of the IR come with the components that use them: the cubic Bézier curves, the font weights, the shadows, and the transitions.

## The layout of the source

| Path | Contents |
| --- | --- |
| `lib/monorithm_ui.dart` | The exports of the package |
| `lib/src/theme/` | The widget `MonoTheme` and the extension `context.mono` |
| `lib/src/tokens/` | The generated tokens. Do not edit them |
| `tool/emit.dart` | The emitter |
| `test/` | The tests |
| `design/` | The submodule of the language source |

## The tests

`flutter test` runs the tests:

- `tokens/ir` reads `canonical.json` of the pinned IR and compares its values with the generated tokens.
- `tokens/axes` and `theme/...` examine how `MonoTokens` and `MonoTheme` select the context of each axis.

The name of each test of a component will start with the id of a clause of the contract of the component, for example `switch/keyboard`.

## The checks of CI

CI does these steps on each pull request and on each push to `main`:

1. The drift check: `dart run tool/emit.dart --check`.
2. The format check: `dart format`. The check does not include the generated file.
3. The analysis: `flutter analyze`.
4. The tests: `flutter test`.
5. The build of the package archive: `flutter pub publish --dry-run`. A dry run does not upload the package.

## The tools

Flutter 3.47 or a newer version is necessary. To clone the repository with the language source, run `git clone --recurse-submodules https://github.com/monorithm/flutter.git`. Then run `flutter pub get`.

## The text

All text is in ASD-STE100 Simplified Technical English.

## License

Copyright 2026 Harnicode. The Apache License, Version 2.0 applies to this repository (`LICENSE`). Harnicode is the owner of the name Monorithm, the Monorithm icon, and the related branding (`NOTICE`).
