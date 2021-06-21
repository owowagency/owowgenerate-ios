import Foundation

struct StringsCollection {
    /// The string entries.
    var keys: [StringsEntry] = []
    
    /// Any collections part of this collection.
    /// Key: The (partial) name of the collection. For example, with `alert.logout.title`, this might be `"logout"`.
    var subCollections: [String: StringsCollection] = [:]
    
    /// Returns the collection for the given key. May return `self`.
    subscript(collectionForKey key: String) -> StringsCollection {
        get {
            let parts = key.split(separator: ".")
            let firstPart = String(parts.first ?? "")
            
            if parts.count <= 1 {
                return self
            }
            
            let remainingParts = parts.suffix(from: 1)
            let firstCollection = subCollections[firstPart] ?? StringsCollection()
            
            if remainingParts.count > 1 {
                return firstCollection[collectionForKey: remainingParts.joined(separator: ".")]
            } else {
                return firstCollection
            }
        }
        set {
            let parts = key.split(separator: ".")
            let firstPart = String(parts.first ?? "")
            
            if parts.count <= 1 {
                self = newValue
                return
            }
            
            let remainingParts = parts.suffix(from: 1)
            var subCollection = subCollections[firstPart] ?? StringsCollection()
            
            if remainingParts.count > 1 {
                subCollection[collectionForKey: remainingParts.joined(separator: ".")] = newValue
            } else {
                subCollection = newValue
            }
            
            subCollections[firstPart] = subCollection
        }
    }
    
    subscript(key: String) -> StringsEntry? {
        get {
            self[collectionForKey: key].keys.first { $0.key == key }
        }
    }
}

struct StringsEntry {
    /// The full key of the string, like `alert.logout.title`.
    var key: String
    
    /// The comment related to the string.
    var comment: String
    
    /// The value of the entry.
    var value: String?
    
    /// The path of the file the entry belongs to.
    var file: String
    
    /// The line number in `file` of this entry.
    var line: Int
    
    /// Any placeholders in the string, like `%@`.
    var placeholders: [PlaceholderType]
}

/// A type that parses a Strings file.
struct StringsParser {
    var collection = StringsCollection()
    
    // MARK: Line-by-line parsing.
    
    enum LineResult {
        /// The line was not recognized. The associated value contains the full line.
        case unrecognized(Substring)
        
        /// The line was a comment. The associated value contains only text of the comment, without the leading `//`, `///` or `/*`.
        case comment(String)
        
        /// The line contains a strings entry.
        case entry(StringsEntry)
    }
    
    /// Parses the given line into `self.collection` and returns the result
    ///
    /// - parameter rawLine: The line to parse.
    /// - parameter pairs: A dictionary containing the key/value pairs in the strings file, parsed by Apples dictionary init.
    /// - parameter file: The name/path of the file this line belongs to.
    /// - parameter lineNumber: The line number in the file that is being parsed.
    @discardableResult
    mutating func parseLine(line rawLine: Substring, pairs: [String: String], file: String, lineNumber: Int) -> LineResult {
        let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if line.hasPrefix("// MARK:") || line.hasPrefix("/*") {
            // Ignore `MARK` and multiline comments for now.
            return .unrecognized(rawLine)
        } else if line.hasPrefix("//") {
            let commentText: Substring
            if line.hasPrefix("///") {
                commentText = line.suffix(from: "///".endIndex)
            } else {
                commentText = line.suffix(from: "//".endIndex)
            }
            
            addCommentLine(commentText)
            
            return .comment(commentText.trimmingCharacters(in: .whitespacesAndNewlines))
        } else if line.hasPrefix("\"") {
            // A string line
            let keyRegex = """
            "[^"]+"
            """
            
            let range = line.range(of: keyRegex, options: .regularExpression)!
            let keyStringLiteral = line[range]
            let keyString = String(keyStringLiteral.dropFirst().dropLast())
            let value = pairs[keyString]
            let placeholders = try! PlaceholderType.placeholders(fromFormat: value ?? "")
            
            assert(value != nil)
            
            let entry = StringsEntry(key: keyString, comment: comment, value: value, file: file, line: lineNumber, placeholders: placeholders)
            comment = ""
            
            storeEntry(entry)
            
            return .entry(entry)
        } else {
            return .unrecognized(rawLine)
        }
    }
    
    // MARK: Comment parsing
    
    /// Add the specified line to the comment
    mutating private func addCommentLine<S: StringProtocol>(_ text: S) {
        if !comment.isEmpty {
            comment += "\n"
        }
        
        comment += text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// The comment that was last parsed.
    private var comment = ""
    
    // MARK: File parsing
    
    /// Parses the strings file at `inputPath` and returns the result.
    static func parse(inputPath: String) -> StringsCollection {
        var parser = StringsParser()
        parser.parse(inputPath: inputPath)
        return parser.collection
    }
    
    /// Parses the strings file at `inputPath` into `self.collection`.
    mutating func parse(inputPath: String) {
        /// Parsing happens in two stages.
        /// - For extracting values, we use Apple's parser in NSDictionary
        /// - For context with the values (comments etc), we use our own parser.
        let inputData = try! Data(contentsOf: URL(fileURLWithPath: inputPath))
        let parsedDictionary = try! PropertyListDecoder().decode([String: String].self, from: inputData)
        let input = String(data: inputData, encoding: .utf8) ?? String(data: inputData, encoding: .utf16)!
        
        self.comment = ""
        
        for (lineNumber, rawLine) in input.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            parseLine(line: rawLine, pairs: parsedDictionary, file: inputPath, lineNumber: lineNumber)
        }
        
        self.comment = ""
        
        // TODO: Assert this
//        assert(parsedDictionary.count == collection.count)
    }
    
    mutating func storeEntry(_ entry: StringsEntry) {
        collection[collectionForKey: entry.key].keys.append(entry)
    }
}
