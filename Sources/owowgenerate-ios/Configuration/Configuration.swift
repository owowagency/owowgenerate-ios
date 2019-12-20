struct Configuration: Decodable {
    /// A list of input file paths of localizable strings files.
    /// The first file in this array serves as "master" file.
    var stringsFiles: [String]
    
    /// Tasks to execute when running `owowgenerate`.
    var tasks: [Task]
    
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
}
