func makeLocalizedStringCode(strings: StringsCollection) -> String {
    var writer = SwiftCodeWriter()
    
    writer.inBlock("enum Strings") { writer in
        writeStrings(strings: strings, writer: &writer)
    }
    
    return writer.output
}

private func writeStrings(strings: StringsCollection, writer: inout SwiftCodeWriter) {
    for (name, collection) in strings.subCollections.sorted(by: { $0.key < $1.key }) {
        writer.addLine()
        
        let variableName = name.camelCase(delimiter: "-", upper: false)
        let typeName = name.camelCase(delimiter: "-", upper: true)
        
        writer.addLine("static var \(variableName): \(typeName).Type { \(typeName).self }")
        
        writer.inBlock("struct \(typeName)") { writer in
            writeStrings(strings: collection, writer: &writer)
        }
    }
    
    for key in strings.keys {
        writer.addDocComment(key.comment)
        
        let variableName = (key.key.split(separator: ".").last ?? "").camelCase(delimiter: "-", upper: false)
        
        writer.addLine("static var \(variableName): String { NSLocalizedString(\"\(key.key)\", comment: \(writer.makeStringLiteral(key.comment))) }")
    }
}
