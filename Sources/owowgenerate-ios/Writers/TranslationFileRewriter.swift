import Foundation

func rewriteTranslationFiles(paths: [String]) {
    let primaryFilePath = paths.first!
    let nonPrimaryFilePaths = paths[1..<paths.endIndex]
    
    let primaryFileData = try! Data(contentsOf: URL(fileURLWithPath: primaryFilePath))
    let primaryParsedDictionary = try! PropertyListDecoder().decode([String: String].self, from: primaryFileData)
    
    typealias File = (path: String, output: String, strings: StringsCollection)
    var error = false
    var nonPrimaryFiles: [File] = nonPrimaryFilePaths.map { path in
        let file: File = (path, "", StringsParser.parse(inputPath: path))
        
        // Check if all keys also exist in the primary file – if not, print an error
        let fileData = try! Data(contentsOf: URL(fileURLWithPath: file.path))
        let parsedDictionary = try! PropertyListDecoder().decode([String: String].self, from: fileData)
        
        let absolutePath = URL(fileURLWithPath: file.path).path
        
        for key in parsedDictionary.keys where !primaryParsedDictionary.keys.contains(key) {
            error = true
            
            guard let entry = file.strings[key] else {
                print("\(absolutePath):\(1): error: key \"\(key)\" was not correctly parsed")
                fatalError()
            }
            
            print("\(absolutePath):\(entry.line+1): error: key \"\(key)\" was not found in the primary translation file")
        }
        
        return file
    }
    
    if error {
        // Don't rewrite anything if there was an error.
        exit(1)
    }
    
    var primaryParser = StringsParser()
    
    for (lineNumber, line) in String(data: primaryFileData, encoding: .utf8)!.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
        let lineResult = primaryParser.parseLine(line: line, pairs: primaryParsedDictionary, file: primaryFilePath, lineNumber: lineNumber)
        
        nonPrimaryFiles = nonPrimaryFiles.map { file in
            func l<S: StringProtocol>(_ line: S) -> File {
                var output = file.output
                if !output.isEmpty {
                    output += "\n"
                }
                output += line
                
                if output.range(of: "<#.+#>", options: .regularExpression) != nil {
                    print("")
                }
                
                return (file.path, output, file.strings)
            }
            
            switch lineResult {
            case .unrecognized(let substring):
                return l(substring)
            case .comment(let substring):
                return l("/// \(substring)")
            case .entry(let entry):
                if let translatedEntry = file.strings[entry.key] {
                    return l("\"\(entry.key)\" = \(SwiftCodeWriter.makeStringLiteral(translatedEntry.value ?? ""));")
                } else {
                    return l("\"\(entry.key)\" = \"<#\(entry.value ?? "Translated text")#>\";")
                }
            }
        }
    }
    
    for file in nonPrimaryFiles {
        try! file.output.write(toFile: file.path, atomically: true, encoding: .utf8)
    }
}
