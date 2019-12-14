struct Configuration: Decodable {
    /// A list of input file paths of localizable strings files.
    /// The first file in this array serves as "master" file.
    var stringsFiles: [String]
    
    var tasks: [Task]
}

struct Task: Decodable {
    enum TaskType: String, Codable {
        case generateSwiftUIMapping
        case generateNSLocalizedStringMapping
    }
    
    /// The task type.
    var type: TaskType
    
    /// The output file of the task.
    var output: String
}
