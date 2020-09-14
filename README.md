# owowgenerate-ios

## 🧐 Readme

A tool, written in Swift, that parses iOS `Localizable.strings` files.

It currently reads a file `owowgenerate.json`. Example contents:

```json
{
    "stringsFiles": [
        "MyProject/nl.lproj/Localizable.strings",
        "MyProject/en.lproj/Localizable.strings"
    ],
    "tasks": [
        {
            "type": "generateSwiftUIMapping",
            "output": "MyProject/Assets/Strings-SwiftUI.swift"
        },
        {
            "type": "generateNSLocalizedStringMapping",
            "output": "MyProject/Assets/Strings-NSLocalizedString.swift"
        },
        {
            "type": "rewriteTranslationFiles"
        }
    ]
}
```
See [Configuration.swift](Sources/owowgenerate-ios/Configuration/Configuration.swift) for details about the configuration options.

## Features

- Generate a SwiftUI `Text` extension for typesafe access to strings. Comments are also copied into the `Text` init and generated properties.
- Generate other (`NSLocalizedString`) extensions for typesafe access to strings. Comments are also copied into the `NSLocalizedString` call.
- Rewrite secondary translation files, copying comments and general structure from the primary file.
- [WIP] Generate Android strings files (XML) from the iOS files
