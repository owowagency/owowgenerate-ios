func makeSwiftUICode(strings: StringsCollection) -> String {
    var writer = SwiftCodeWriter()
    writer.addLine("import SwiftUI")
    writer.addLine()
    
    writer.inBlock("extension SwiftUI.Text") { writer in
        writeStrings(strings: strings, writer: &writer)
    }
    
    return writer.output
}

private func writeStrings(strings: StringsCollection, writer: inout SwiftCodeWriter) {
    for (name, collection) in strings.subCollections.sorted(by: { $0.key < $1.key }) {
        writer.addLine()
        
        let variableName = name.camelCase(delimiter: "-", upper: false)
        let typeName = name.camelCase(delimiter: "-", upper: true) + "StringsNamespace"
        
        writer.addLine("static var \(variableName): \(typeName).Type { \(typeName).self }")
        
        writer.inBlock("struct \(typeName)") { writer in
            writeStrings(strings: collection, writer: &writer)
        }
    }
    
    for key in strings.keys {
        writer.addDocComment(key.comment)
        
        let variableName = (key.key.split(separator: ".").last ?? "").camelCase(delimiter: "-", upper: false)
        
        let additionalArguments: String
        if !key.comment.isEmpty {
            additionalArguments = ", comment: \(SwiftCodeWriter.makeStringLiteral(key.comment))"
        } else {
            additionalArguments = ""
        }
        
        writer.addLine("static var \(variableName): Text { Text(\"\(key.key)\"\(additionalArguments)) }")
    }
}
