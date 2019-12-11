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

let code = makeSwiftUICode(strings: parser.collection)

try! code.write(toFile: arguments[2], atomically: true, encoding: .utf8)
