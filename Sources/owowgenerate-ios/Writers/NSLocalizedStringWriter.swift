fileprivate var isConstructingForLibrary = false

func makeLocalizedStringCode(strings: StringsCollection, isForLibrary: Bool) -> String {
    if isForLibrary {
        isConstructingForLibrary = isForLibrary
    }
    
    var writer = SwiftCodeWriter()
    
    writer.addLine("import Foundation")
    
    var extensionText = (isConstructingForLibrary ? "public " : "") + "enum Strings"
    
    writer.inBlock(extensionText) { writer in
        writeStrings(strings: strings, writer: &writer)
    }
    
    return writer.output
}

private func writeStrings(strings: StringsCollection, writer: inout SwiftCodeWriter) {
    for (name, collection) in strings.subCollections.sorted(by: { $0.key < $1.key }) {
        writer.addLine()
        
        let variableName = name.camelCase(from: config.caseStyle, upper: false).swiftIdentifier
        let typeName = (name.camelCase(from: config.caseStyle, upper: true)).swiftIdentifier
        
        var line = (isConstructingForLibrary ? "public " : "") + "static var \(variableName): \(typeName).Type { \(typeName).self }"
        var structBlock = (isConstructingForLibrary ? "public " : "") + "struct \(typeName)"
        
        writer.addLine(line)
        writer.inBlock(structBlock) { writer in
            writeStrings(strings: collection, writer: &writer)
        }
    }
    
    for key in strings.keys {
        writer.addDocComment(key.comment)
        
        let memberName = (key.key.split(separator: ".").last ?? "").camelCase(from: config.caseStyle, upper: false)
        let getLocalizedString = "NSLocalizedString(\"\(key.key)\", comment: \(SwiftCodeWriter.makeStringLiteral(key.comment)))"
                
        if key.placeholders.isEmpty {
            let line = (isConstructingForLibrary ? "public " : "") + "static var \(memberName): String { \(getLocalizedString) }"
            writer.addLine(line)
        } else {
            let parameters = key.placeholders.enumerated().map { index, type in
                "_ placeholder\(index): \(type.rawValue)"
            }.joined(separator: ", ")
            
            let parameterUsage = key.placeholders.indices.map { "placeholder\($0)" }.joined(separator: ", ")
            
            let functionBlock = (isConstructingForLibrary ? "public " : "") + "static func \(memberName)(\(parameters)) -> String"
            
            writer.inBlock(functionBlock) { writer in
                writer.addLine("let format = \(getLocalizedString)")
                writer.addLine("return String(format: format, \(parameterUsage))")
            }
        }
    }
}
