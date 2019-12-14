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
    
    func makeStringLiteral(_ text: String) -> String {
        "\"\(text.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n"))\""
    }
}
