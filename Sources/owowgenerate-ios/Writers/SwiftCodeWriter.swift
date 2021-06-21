struct SwiftCodeWriter {
    private(set) var output = ""
    
    var indentationLevel = 0
    
    var indentation: String {
        String(repeating: " ", count: indentationLevel * 4)
    }

    mutating func addLine(_ text: String = "") {
        output += (output.isEmpty ? "" : "\n") + indentation + text
    }
    
    mutating func withIndentation(_ action: (inout SwiftCodeWriter) -> ()) {
        indentationLevel += 1
        action(&self)
        indentationLevel -= 1
    }
    
    mutating func inBlock(_ header: String, action: (inout SwiftCodeWriter) -> ()) {
        addLine(header + " {")
        withIndentation { writer in
            action(&writer)
        }
        addLine("}")
    }
    
    mutating func addDocComment(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else { return }
        
        // Above a comment, always include a newline
        addLine("")
        
        for line in trimmed.split(separator: "\n") {
            addLine("/// " + line)
        }
    }
    
    static func makeStringLiteral(_ text: String) -> String {
        "\"\(text.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n"))\""
    }
}

extension String {
    var swiftIdentifier: String {
        switch self {
        case "associatedtype", "class", "deinit", "enum", "extension", "fileprivate", "func", "import", "init",
             "inout", "internal", "let", "open", "operator", "private", "protocol", "public", "rethrows", "static",
             "struct", "subscript", "typealias", "var", "break", "case", "continue", "default", "defer", "do", "else",
             "fallthrough", "for", "guard", "if", "in", "repeat", "return", "switch", "where", "while", "as", "Any",
             "catch", "false", "is", "nil", "super", "self", "Self", "throw", "throws", "true", "try", "_",
             "associativity", "convenience", "dynamic", "didSet", "final", "get", "infix", "indirect", "lazy", "left",
             "mutating", "none", "nonmutating", "optional", "override", "postfix", "precedence", "prefix", "Protocol",
             "required", "right", "set", "Type", "unowned", "weak", "willSet":
            return "`" + self + "`"
        default:
            return self
        }
    }
}
