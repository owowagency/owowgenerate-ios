import Foundation

// TODO: Generate an extension on LocalizedStringKey
//       Maybe that can be used like Text(.myString) instead of Text extensions.

// TODO: Xcode warnings when strings are missing in a translation file or are not present in the main translation file.

let configData = try! Data(contentsOf: URL(fileURLWithPath: "owowgenerate.json"))
let config = try! JSONDecoder().decode(Configuration.self, from: configData)

precondition(!config.stringsFiles.isEmpty, "At least one input strings file is required.")
precondition(!config.tasks.isEmpty, "At least one task is required.")

let inputFilePath = config.stringsFiles[0]

let strings = StringsParser.parse(inputPath: inputFilePath)

for task in config.tasks {
    let output: String
    
    switch task.type {
    case .generateSwiftUIMapping:
        output = makeSwiftUICode(strings: strings)
    case .generateNSLocalizedStringMapping:
        output = makeLocalizedStringCode(strings: strings)
    case .rewriteTranslationFiles:
        rewriteTranslationFiles(paths: config.stringsFiles)
        continue
    case .generateInputXcFileList:
        output = config.inputFiles.subtracting(config.outputFiles).sorted().joined(separator: "\n")
    case .generateOutputXcFileList:
        output = config.outputFiles.sorted().joined(separator: "\n")
    }
    
    guard let outputPath = task.output else {
        preconditionFailure("Task \(task.type) requires output path.")
    }
    
    let outputURL = URL(fileURLWithPath: outputPath)
    
    if let existingCodeData = try? Data(contentsOf: outputURL), let existingCode = String(data: existingCodeData, encoding: .utf8), existingCode == output {
        /// Don't overwrite the file if not changed.
        continue
    }
    
    try! output.write(to: outputURL, atomically: true, encoding: .utf8)
}
