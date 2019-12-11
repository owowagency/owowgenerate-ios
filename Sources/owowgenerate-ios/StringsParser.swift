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
}

struct StringsEntry {
    /// The full key of the string, like `alert.logout.title`.
    var key: String
    
    /// The comment related to the string.
    var comment: String
}

/// A type that parses a Strings file.
struct StringsParser {
    var collection = StringsCollection()
    
    mutating func parse(input: String) {
        /// The comment that was last parsed.
        var comment = ""
        
        /// Add the specified line to the comment
        func addCommentLine<S: StringProtocol>(_ text: S) {
            if !comment.isEmpty {
                comment += "\n"
            }
            
            comment += text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        for rawLine in input.split(separator: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if line.hasPrefix("// MARK:") {
                // Ignore `MARK` comments.
                continue
            } else if line.hasPrefix("/*") {
                // Skip these kinds of comments for now
                continue
            } else if line.hasPrefix("//") {
                let commentText: Substring
                if line.hasPrefix("///") {
                    commentText = line.suffix(from: "///".endIndex)
                } else {
                    commentText = line.suffix(from: "//".endIndex)
                }
                
                addCommentLine(commentText)
            } else if line.hasPrefix("\"") {
                // A string line
                let keyRegex = """
                "[^"]*"
                """
                
                let range = line.range(of: keyRegex, options: .regularExpression)!
                let keyStringLiteral = line[range]
                let keyString = keyStringLiteral.dropFirst().dropLast()
                
                let entry = StringsEntry(key: String(keyString), comment: comment)
                comment = ""
                storeEntry(entry)
            }
        }
    }
    
    mutating func storeEntry(_ entry: StringsEntry) {
        collection[collectionForKey: entry.key].keys.append(entry)
    }
}
