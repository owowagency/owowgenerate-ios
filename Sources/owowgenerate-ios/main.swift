import Foundation

// TODO: Generate an extension on LocalizedStringKey
//       Maybe that can be used like Text(.myString) instead of Text extensions.

let arguments = ProcessInfo.processInfo.arguments
let defaultConfigFilename = "owowgenerate.json"
let configFilename = arguments.count > 1 ? arguments.last! : defaultConfigFilename

let config = Configuration.load(from: configFilename)

precondition(!config.stringsFiles.isEmpty, "At least one input strings file is required.")
precondition(!config.tasks.isEmpty, "At least one task is required.")

let inputFilePath = config.stringsFiles[0]

let strings = StringsParser.parse(inputPath: inputFilePath)

for task in config.tasks {
    let output: String
    
    switch task.type {
    case .generateSwiftUIMapping:
        output = makeSwiftUICode(
            strings: strings,
            accessLevel: task.options?.accessLevel,
            bundle: task.options?.bundle
        )
    case .generateNSLocalizedStringMapping:
        output = makeLocalizedStringCode(
            strings: strings,
            accessLevel: task.options?.accessLevel,
            bundle: task.options?.bundle
        )
    case .rewriteTranslationFiles:
        try! rewriteTranslationFiles(paths: config.stringsFiles)
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
    
    try! output.writeIfNeeded(to: outputURL)
}
