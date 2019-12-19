struct Configuration: Decodable {
    /// A list of input file paths of localizable strings files.
    /// The first file in this array serves as "master" file.
    var stringsFiles: [String]
    
    /// Tasks to execute when running `owowgenerate`.
    var tasks: [Task]
}

struct Task: Decodable {
    enum TaskType: String, Codable {
        case generateSwiftUIMapping
        case generateNSLocalizedStringMapping
        case rewriteTranslationFiles
    }
    
    /// The task type.
    var type: TaskType
    
    /// The output file of the task.
    var output: String?
}
