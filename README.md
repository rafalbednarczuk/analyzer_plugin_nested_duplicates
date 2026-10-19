# The whole minimal reproducible repository is AI generated including README
## Analyzer plugin diagnostics are duplicated in nested packages

## Problem

When a package contains a nested package (its own `pubspec.yaml` and
`.dart_tool/package_config.json`) whose `analysis_options.yaml` includes the
parent options, every diagnostic of an `analysis_server_plugin` plugin in the
nested package is reported twice in the IDE.

```
app/                          context root, enables the plugin
  analysis_options.yaml       plugins: plugin: path: ../plugin
  lib/a.dart
  nested/                     nested context root
    analysis_options.yaml     include: ../analysis_options.yaml
    lib/b.dart
plugin/                       rule reporting one diagnostic per file
```

## Reproduce

```bash
(cd plugin && dart pub get)
(cd app && dart pub get)
(cd app/nested && dart pub get)
```

Open `app/` in IntelliJ / Android Studio or VS Code.

Expected:

```
lib/a.dart:1:1        Reported once per file.
nested/lib/b.dart:1:1 Reported once per file.
```

Actual:

```
lib/a.dart:1:1        Reported once per file.
nested/lib/b.dart:1:1 Reported once per file.
nested/lib/b.dart:1:1 Reported once per file.
```

Reproduced with both the legacy analysis server protocol (IntelliJ) and LSP
(VS Code). `dart analyze` does not show the duplicate.

## Why

1. The analysis server starts one plugin isolate per context root. Here there
   are two context roots, `app` and `app/nested`, so there are two isolates,
   with entrypoints in `~/.dartServer/.plugin_manager/<md5 of context root>/`.
2. The `app` isolate receives the `app` context root. `PluginServer` creates
   `AnalysisContextCollectionImpl(includedPaths: [app])` and does not pass the
   nested context root as excluded.
3. That collection discovers `app/nested` as a separate context and analyzes
   it as well, using `app/nested/analysis_options.yaml`, which enables the
   plugin through the include.
4. The `app/nested` isolate analyzes the same files.
5. The server merges the errors of both isolates, so each diagnostic in
   `app/nested` appears twice.

The rule is visited exactly once per file in each isolate, so this is not
caused by the rule implementation.

Related: https://github.com/dart-lang/sdk/issues/64223 (fixed in
`analysis_server_plugin` 0.3.23) restricted plugin roots to the plugin's
context roots, but a nested context root is inside its parent context root, so
it is still analyzed by both isolates.

## Environment

- Dart SDK 3.11.5 (stable), macOS arm64
- `analysis_server_plugin` 0.3.24
- `analyzer` 14.5.0
