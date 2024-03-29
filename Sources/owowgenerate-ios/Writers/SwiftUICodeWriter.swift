func makeSwiftUICode(strings: StringsCollection, accessLevel: String?, bundle: String?) -> String {
    var writer = SwiftCodeWriter()
    writer.addLine("import SwiftUI")
    writer.addLine()
    
    let aclPrefix = accessLevel.map { $0 + " " } ?? ""
    
    writer.inBlock("@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)\nextension SwiftUI.Text") { writer in
        writeStrings(strings: strings, writer: &writer, aclPrefix: aclPrefix, bundle: bundle, mode: .text, static: true)
    }
    
    writer.inBlock("@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)\nextension SwiftUI.LocalizedStringKey") { writer in
        writeStrings(strings: strings, writer: &writer, aclPrefix: aclPrefix, bundle: bundle, mode: .localizedStringKey, static: true)
    }
    
    return writer.output
}

fileprivate enum WriteMode {
    case text, localizedStringKey
}

fileprivate func writeStrings(strings: StringsCollection, writer: inout SwiftCodeWriter, aclPrefix: String, bundle: String?, mode: WriteMode, static: Bool) {
    var aclStaticPrefix = aclPrefix
    if `static` {
        aclStaticPrefix += "static "
    }
    
    for (name, collection) in strings.subCollections.sorted(by: { $0.key < $1.key }) {
        writer.addLine()
        
        let variableName = name.camelCase(from: config.caseStyle, upper: false).swiftIdentifier
        let typeName = (name.camelCase(from: config.caseStyle, upper: true) + "StringsNamespace").swiftIdentifier
        
        writer.addLine(aclStaticPrefix + "var \(variableName): \(typeName) { \(typeName)() }")
        
        writer.inBlock(aclPrefix + "struct \(typeName)") { writer in
            writeStrings(strings: collection, writer: &writer, aclPrefix: aclPrefix, bundle: bundle, mode: mode, static: false)
        }
    }
    
    for key in strings.keys {
        let memberName = (key.key.split(separator: ".").last ?? "").camelCase(from: config.caseStyle, upper: false)
        
        if key.placeholders.isEmpty {
            writer.addDocComment(key.comment)
            
            switch mode {
            case .text:
                var additionalArguments = ""
                
                if let bundle = bundle {
                    additionalArguments += ", bundle: \(bundle)"
                }
                
                if !key.comment.isEmpty {
                    additionalArguments += ", comment: \(SwiftCodeWriter.makeStringLiteral(key.comment))"
                }
                
                writer.addLine(aclStaticPrefix + "var \(memberName): Text { Text(\"\(key.key)\"\(additionalArguments)) }")
            case .localizedStringKey:
                writer.addLine(aclStaticPrefix + "var \(memberName): LocalizedStringKey { LocalizedStringKey(\"\(key.key)\") }")
            }
        } else if mode == .text { // TODO: Support placeholders with LocalizedStringKey
            let parameters = key.placeholders.enumerated().map { index, type in
                "_ placeholder\(index): \(type.rawValue)"
            }.joined(separator: ", ")
            
            let parameterUsage = key.placeholders.indices.map { "placeholder\($0)" }.joined(separator: ", ")
            
            writer.addDocComment(key.comment)
            writer.inBlock(aclStaticPrefix + "func \(memberName)(\(parameters)) -> Text") { writer in
                writer.addLine("let format = NSLocalizedString(\"\(key.key)\", comment: \(SwiftCodeWriter.makeStringLiteral(key.comment)))")
                writer.addLine("let string = String(format: format, \(parameterUsage))")
                writer.addLine("return Text(verbatim: string)")
            }
            
            if key.placeholders.contains(.object) {
                // Generate a variant that works with text concatenation
                writeTextConcatenationFunction(writer: &writer, key: key, memberName: memberName)
            }
        }
    }
}

fileprivate func writeTextConcatenationFunction(writer: inout SwiftCodeWriter, key: StringsEntry, memberName: String) {
    func makePlaceholder(index: Int) -> String {
        "⚠️OWOWGENERATE PLACEHOLDER \(index)⚠️"
    }
    
    let parameters = key.placeholders.enumerated().map { index, type in
        let parameterType: String
        if type == .object {
            parameterType = "Text"
        } else {
            parameterType = type.rawValue
        }
        
        return "_ placeholder\(index): \(parameterType)"
    }.joined(separator: ", ")
    
    let parameterUsage = key.placeholders.enumerated().map { index, type in
        if type == .object {
            return SwiftCodeWriter.makeStringLiteral(makePlaceholder(index: index))
        } else {
            return "placeholder\(index)"
        }
    }.joined(separator: ", ")
    
    guard let firstTextPlaceholderIndex = key.placeholders.firstIndex(of: .object), let lastTextPlaceholderIndex = key.placeholders.lastIndex(of: .object) else {
        fatalError("No object placeholders while writing text concatenation function")
    }
    
    writer.addDocComment(key.comment)
    writer.inBlock("func \(memberName)(\(parameters)) -> Text") { writer in
        writer.addLine("let format = NSLocalizedString(\"\(key.key)\", comment: \(SwiftCodeWriter.makeStringLiteral(key.comment)))")
        writer.addLine("let temporaryString = String(format: format, \(parameterUsage))")
        
        // first placeholder range
        writer.inBlock("guard let placeholder\(firstTextPlaceholderIndex)Range = temporaryString.range(of: \(SwiftCodeWriter.makeStringLiteral(makePlaceholder(index: firstTextPlaceholderIndex)))) else") { writer in
            writer.addLine("fatalError(\"Placeholder \(firstTextPlaceholderIndex) not found in string\")")
        }
        
        writer.addDocComment("Construct the first part of the text view, consisting of the static first portion until the first placeholder + the value for the first placeholder")
        writer.addLine("var text = Text(verbatim: String(temporaryString[temporaryString.startIndex..<placeholder\(firstTextPlaceholderIndex)Range.lowerBound])) + placeholder\(firstTextPlaceholderIndex)")
        
        let lastCodeGeneratedPlaceholderNumber = firstTextPlaceholderIndex
        
        if firstTextPlaceholderIndex != lastTextPlaceholderIndex {
            for (index, element) in key.placeholders.enumerated() where index > firstTextPlaceholderIndex && element == .object {
                let placeholderString = makePlaceholder(index: index)
                let placeholderStringLiteral = SwiftCodeWriter.makeStringLiteral(placeholderString)
                
                writer.inBlock("guard let placeholder\(index)Range = temporaryString.range(of: \(placeholderStringLiteral)) else") { writer in
                    writer.addLine("fatalError(\"Placeholder \(index) not found in string\")")
                }
                
                writer.addLine("text = text + Text(verbatim: String(temporaryString[placeholder\(lastCodeGeneratedPlaceholderNumber)Range.upperBound..<placeholder\(index)Range.lowerBound])) + placeholder\(index)")
            }
        }
        
        writer.addLine("text = text + Text(verbatim: String(temporaryString[placeholder\(lastTextPlaceholderIndex)Range.upperBound..<temporaryString.endIndex]))")
        writer.addLine("return text")
    }
}
