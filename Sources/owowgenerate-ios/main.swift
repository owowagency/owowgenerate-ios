import Foundation

let configData = try! Data(contentsOf: URL(fileURLWithPath: "owowgenerate.json"))
let config = try! JSONDecoder().decode(Configuration.self, from: configData)

precondition(!config.stringsFiles.isEmpty, "At least one input strings file is required.")
precondition(!config.tasks.isEmpty, "At least one task is required.")

let inputFilePath = config.stringsFiles[0]
let inputData = try! Data(contentsOf: URL(fileURLWithPath: inputFilePath))
let inputString = String(data: inputData, encoding: .utf8)!

var parser = StringsParser()
parser.parse(input: inputString)

for task in config.tasks {
    let code: String
    
    switch task.type {
    case .generateSwiftUIMapping:
        code = makeSwiftUICode(strings: parser.collection)
    case .generateNSLocalizedStringMapping:
        code = makeLocalizedStringCode(strings: parser.collection)
    }
    
    let output = "/* Generated using OWOWGenerate. Do not edit. */\n"
        + code
    
    let outputURL = URL(fileURLWithPath: task.output)
    
    if let existingCodeData = try? Data(contentsOf: outputURL), let existingCode = String(data: existingCodeData, encoding: .utf8), existingCode == output {
        /// Don't overwrite the file if not changed.
        continue
    }
    
    try! output.write(to: outputURL, atomically: true, encoding: .utf8)
}
