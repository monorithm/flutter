# Rules for agents in this repository

- This repository is the Flutter package of the Monorithm Experience Language, `monorithm_ui`. It is greenfield. Do not copy files or history from an archived repository.
- Write all text in ASD-STE100 Simplified Technical English.
- The values come from the design: the submodule `design/` at the commit of one tag of `monorithm/design`. Do not type a value of the design into a widget. Get the tokens with `context.mono`.
- Do not edit `lib/src/tokens/`. Change the commit of the submodule `design/`, then emit again (`dart run tool/emit.dart`).
- Do not edit the files of `design/`. Change the design source in `monorithm/design`.
- Each test of a component starts its name with the id of a clause of the contract of the component.
- A component emits a moment of the design. It never starts a haptic or a sound directly.
- Put each component in one folder in `lib/src/components/`, with snake_case file names: `<component>.dart` and its parts.
- To add a Flutter project (for example an example app), use `flutter create`, then edit the files. Do not write the project files by hand.
- The repository is public. Do not add these items:
  - A private name
  - The ID of a decision or of a private process
  - The name of a canvas board
