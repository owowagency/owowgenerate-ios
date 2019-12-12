import Foundation

let arguments = CommandLine.arguments

guard arguments.count >= 3 else {
    fatalError("Invalid arguments. Usage: \(arguments.first ?? "owowgenerate-ios") inputfile outputfile")
}

let inputFilePath = arguments[1]
let inputData = try! Data(contentsOf: URL(fileURLWithPath: inputFilePath))
let inputString = String(data: inputData, encoding: .utf8)!

var parser = StringsParser()
parser.parse(input: inputString)

let code = "/* Generated using OWOWGenerate. Do not edit. */\n"
    + makeSwiftUICode(strings: parser.collection)
    + "\n"
    + makeLocalizedStringCode(strings: parser.collection)

let outputPath = arguments[2]

if let existingCodeData = try? Data(contentsOf: URL(fileURLWithPath: outputPath)), let existingCode = String(data: existingCodeData, encoding: .utf8), existingCode == code {
    print("No change needed in code; not overwriting output")
    exit(0)
}

try! code.write(toFile: outputPath, atomically: true, encoding: .utf8)
