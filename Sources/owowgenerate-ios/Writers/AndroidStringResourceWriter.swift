import Foundation

struct AndroidStringResourceWriter {
    private let strings: StringsCollection
    private var resources: [AndroidResourceFile] = []
    
    init(strings: StringsCollection) {
        self.strings = strings
    }
    
    mutating func createResources() -> [AndroidResourceFile] {
        self.createResources(collection: self.strings)
        return self.resources
    }
    
    private mutating func createResources(collection: StringsCollection) {
        self.createResources(entries: collection.keys)
        self.createResources(subcollections: collection.subCollections)
    }
    
    private mutating func createResources(entries: [StringsEntry]) {
        for entry in entries {
            let resource = self.getResourceFile(file: entry.file)
            resource.addEntry(entry)
        }
    }
    
    private mutating func createResources(subcollections: [String: StringsCollection]) {
        for (_, collection) in subcollections {
            self.createResources(collection: collection)
        }
    }
    
    private mutating func getResourceFile(file: String) -> AndroidResourceFile {
        guard let resource = self.resources.first(where: { resource in resource.originalFile == file }) else {
            let resource = AndroidResourceFile(originalFile: file)
            self.resources.append(resource)
            return resource
        }
        return resource
    }
    
}

struct AndroidResourceFile {
    let document: XMLDocument
    let originalFile: String

    private static let illegalCharacterExpression = try! NSRegularExpression(pattern: "(^[^a-zA-Z]|[^0-9a-zA-Z_])")
    
    var xmlString: String {
        self.document.xmlString(options: [
            XMLNode.Options.nodePrettyPrint,
            XMLNode.Options.nodeUseDoubleQuotes,
            XMLNode.Options.documentTidyXML
        ])
    }
    
    init(originalFile: String) {
        self.originalFile = originalFile
        self.document = AndroidResourceFile.createDocument()
    }
    
    private static func createDocument() -> XMLDocument {
        let resources = XMLNode.element(withName: "resources") as! XMLElement
        let owowGenerateNamespace = XMLNode.namespace(withName: "ios", stringValue: "http://github.com/owowagency/owowgenerate-ios") as! XMLNode
        resources.addNamespace(owowGenerateNamespace)
        let document = XMLDocument(rootElement: resources)
        document.characterEncoding = "UTF-8"
        document.isStandalone = true
        return document
    }
    
    private static func safeAndroidResourceIdentifier(_ value: String) -> String {
        let mutableString = NSMutableString(string: value)
        let range = NSMakeRange(0, value.count)
        AndroidResourceFile.illegalCharacterExpression.replaceMatches(
            in: mutableString,
            options: [],
            range: range,
            withTemplate: "_"
        )
        return String(mutableString)
    }
    
    func addEntry(_ entry: StringsEntry) {
        guard let rootElement = self.document.rootElement() else {
            return
        }
        
        if !entry.comment.isEmpty {
            let comment = XMLNode.comment(withStringValue: entry.comment) as! XMLNode
            rootElement.addChild(comment)
        }
        
        let stringEntry = XMLNode.element(withName: "string", stringValue: entry.value ?? "") as! XMLElement
        let androidResourceIdentifier = AndroidResourceFile.safeAndroidResourceIdentifier(entry.key)
        let androidName = XMLNode.attribute(withName: "name", stringValue: androidResourceIdentifier) as! XMLNode
        let iosName = XMLNode.attribute(withName: "ios:key", stringValue: entry.key) as! XMLNode
        
        stringEntry.addAttribute(androidName)
        stringEntry.addAttribute(iosName)
        
        rootElement.addChild(stringEntry)
    }
}
