func makeLocalizedStringCode(strings: StringsCollection, accessLevel: String?, bundle: String?) -> String {
    var writer = SwiftCodeWriter()
    writer.addLine("import Foundation")
    writer.addLine()
    
    let aclPrefix = accessLevel.map { $0 + " " } ?? ""
    
    writer.inBlock(aclPrefix + "enum Strings") { writer in
        writeStrings(strings: strings, writer: &writer, aclPrefix: aclPrefix, bundle: bundle)
    }
    
    return writer.output
}

private func writeStrings(strings: StringsCollection, writer: inout SwiftCodeWriter, aclPrefix: String, bundle: String?) {
    for (name, collection) in strings.subCollections.sorted(by: { $0.key < $1.key }) {
        writer.addLine()
        
        let variableName = name.camelCase(from: config.caseStyle, upper: false).swiftIdentifier
        let typeName = (name.camelCase(from: config.caseStyle, upper: true)).swiftIdentifier
        
        writer.addLine(aclPrefix + "static var \(variableName): \(typeName).Type { \(typeName).self }")
        
        writer.inBlock(aclPrefix + "struct \(typeName)") { writer in
            writeStrings(strings: collection, writer: &writer, aclPrefix: aclPrefix, bundle: bundle)
        }
    }
    
    for key in strings.keys {
        writer.addDocComment(key.comment)
        
        let memberName = (key.key.split(separator: ".").last ?? "").camelCase(from: config.caseStyle, upper: false)
        let bundleArgument = bundle.map { ", bundle: " + $0 } ?? ""
        let getLocalizedString = "NSLocalizedString(\"\(key.key)\"\(bundleArgument), comment: \(SwiftCodeWriter.makeStringLiteral(key.comment)))"
        
        if key.placeholders.isEmpty {
            writer.addLine(aclPrefix + "static var \(memberName): String { \(getLocalizedString) }")
        } else {
            let parameters = key.placeholders.enumerated().map { index, type in
                "_ placeholder\(index): \(type.rawValue)"
            }.joined(separator: ", ")
            
            let parameterUsage = key.placeholders.indices.map { "placeholder\($0)" }.joined(separator: ", ")
            
            writer.inBlock(aclPrefix + "static func \(memberName)(\(parameters)) -> String") { writer in
                writer.addLine("let format = \(getLocalizedString)")
                writer.addLine("return String(format: format, \(parameterUsage))")
            }
        }
    }
}
