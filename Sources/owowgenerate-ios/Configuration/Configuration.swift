import Foundation

struct Configuration: Decodable {
    /// A list of input file paths of localizable strings files.
    /// The first file in this array serves as "master" file.
    var stringsFiles: [String]
    
    /// Tasks to execute when running `owowgenerate`.
    var tasks: [Task]
    
    /// The case style that the strings files are keyed with.
    private var inputCaseStyle: CaseStyle?
    
    var caseStyle: CaseStyle {
        inputCaseStyle ?? .kebabCase
    }
    
    var inputFiles: Set<String> {
        return Set(stringsFiles)
    }
    
    var outputFiles: Set<String> {
        return Set(tasks.compactMap { task -> [String]? in
            switch task.type {
            case .generateSwiftUIMapping, .generateNSLocalizedStringMapping:
                return task.output.map { [$0] }
            case .rewriteTranslationFiles:
                return Array(stringsFiles.suffix(from: 1))
            case .generateInputXcFileList, .generateOutputXcFileList:
                return nil
            }
        }.reduce([], +))
    }
    
    static func load(from filename: String) -> Configuration {
        do {
            let configData = try Data(contentsOf: URL(fileURLWithPath: filename))
            return try JSONDecoder().decode(Configuration.self, from: configData)
        } catch {
            fatalError("Couldn't load \(filename): \(error)")
        }
    }
}

struct Task: Decodable {
    enum TaskType: String, Codable {
        case generateSwiftUIMapping
        case generateNSLocalizedStringMapping
        case rewriteTranslationFiles
        case generateInputXcFileList
        case generateOutputXcFileList
    }
    
    /// The task type.
    var type: TaskType
    
    /// The output file of the task.
    var output: String?
    
    /// Options for the task.
    var options: TaskOptions?
}

enum CaseStyle: String, Codable {
    case camelCase
    case kebabCase
    case snakeCase
    
    var delimiter: Character? {
        switch self {
        case .camelCase: return nil
        case .kebabCase: return "-"
        case .snakeCase: return "_"
        }
    }
}

struct TaskOptions: Codable {
    /// The access level modifier (`internal`, `public`, etc) to use for generated code in the task.
    var accessLevel: String? = nil
    
    /// The `Bundle` to use in generated code. For example: `.module`, `Bundle(for: SomeClass.self)`,  `Bundle(identifier: ...)`
    var bundle: String? = nil
}
