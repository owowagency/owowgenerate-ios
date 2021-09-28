var shouldBePublic = false
var isConstructingForLibrary = false

func makeLocalizedStringCode(strings: StringsCollection, isForLibrary: Bool) -> String {
    if isForLibrary {
        isConstructingForLibrary = isForLibrary
        shouldBePublic = false
    }
    
    var writer = SwiftCodeWriter()
    
    writer.addLine("import Foundation")
    
    writer.inBlock("public enum Strings") { writer in
        writeStrings(strings: strings, writer: &writer)
    }
    
    return writer.output
}

private func writeStrings(strings: StringsCollection, writer: inout SwiftCodeWriter) {
    for (name, collection) in strings.subCollections.sorted(by: { $0.key < $1.key }) {
        writer.addLine()
        
        let variableName = name.camelCase(from: config.caseStyle, upper: false).swiftIdentifier
        let typeName = (name.camelCase(from: config.caseStyle, upper: true)).swiftIdentifier
        
        if shouldBePublic && isConstructingForLibrary {
            writer.addLine("public static var \(variableName): \(typeName).Type { \(typeName).self }")
            
            writer.inBlock("public struct \(typeName)") { writer in
                writeStrings(strings: collection, writer: &writer)
            }
        } else {
            writer.addLine("static var \(variableName): \(typeName).Type { \(typeName).self }")
            
            writer.inBlock("struct \(typeName)") { writer in
                writeStrings(strings: collection, writer: &writer)
            }
        }
    }
    
    for key in strings.keys {
        writer.addDocComment(key.comment)
        
        let memberName = (key.key.split(separator: ".").last ?? "").camelCase(from: config.caseStyle, upper: false)
        let getLocalizedString = "NSLocalizedString(\"\(key.key)\", comment: \(SwiftCodeWriter.makeStringLiteral(key.comment)))"
        
        if key.placeholders.isEmpty {
            writer.addLine("static var \(memberName): String { \(getLocalizedString) }")
        } else {
            let parameters = key.placeholders.enumerated().map { index, type in
                "_ placeholder\(index): \(type.rawValue)"
            }.joined(separator: ", ")
            
            let parameterUsage = key.placeholders.indices.map { "placeholder\($0)" }.joined(separator: ", ")
            
            writer.inBlock("static func \(memberName)(\(parameters)) -> String") { writer in
                writer.addLine("let format = \(getLocalizedString)")
                writer.addLine("return String(format: format, \(parameterUsage))")
            }
        }
    }
}
